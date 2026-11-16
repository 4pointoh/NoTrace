"""The production cut, finished for the game (docs/video/ENHANCE.md): every clip `h3.py final` put in <library>/final/
upscaled 2x with SeedVR2 7B on the pods, brought to the art size (1152x1536) there, then encoded to Theora here with
the BT.709 -> BT.601 conversion Godot needs.

A seam loop starts at its base clip's frame `roll`, so each one also gets an intro: the base clip's frames 0..roll-1,
which run from the still into the loop. Clips longer than CHUNK frames are done in parts. Every part sees PAD real
frames on each side (from the other end of a loop, its neighbouring part, or the clip's own first / last frame
repeated), which are cut off again, so loop seams and part joins stay seamless.

    python -P -E finish.py plan POD [POD ...]     list the jobs and split them across those pods (pods.json names)
    python -P -E finish.py upload POD             copy that pod's source clips to its ComfyUI input folder
    python -P -E finish.py submit POD             queue that pod's jobs
    python -P -E finish.py fetch [--wait]         download finished parts from every pod
    python -P -E finish.py encode [--wait] [--again [--intros]]   Theora for every clip whose parts are all downloaded
                                                  (--again: every clip once more, after a settings change)
    python -P -E finish.py preview [--wait]       a browser copy of each Theora file, for h3.py serve's /finish page
    python -P -E finish.py gamelist               rewrite video/videos.gd from final/manifest.json, nothing encoded
    python -P -E finish.py stitch [--again]       the cycles in stitched.json: a picture's clips as one loop, cross-
                                                  faded at each join (then gamelist lists the cycle for that picture)
                                                  (after reordering picks on /plan and `h3.py final`: the game plays
                                                  each picture's first; pinned.json gives a picture one clip of
                                                  its own, eg copies of one still each playing a different pick)
    python -P -E finish.py status
    python -P -E finish.py sync                   rebuild which part is queued where from the pods themselves
    python -P -E finish.py move FROM TO FRAMES    move about FRAMES frames of waiting parts off a slow pod

Downloads go to FIN_WORK (default ~/Videos/ashely2_finish, outside the library: about 4 GB). The Theora files go
in the game's data/background_lists/<scene>/video/ (<slot>.ogv, and <slot>_intro.ogv for a loop's
intro), listed in video/videos.gd with whether each loops; src/vn/Background.gd reads that.
"""
import json
import math
import os
import subprocess
import sys
import time
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
LIBRARY = Path(os.environ.get('H3_LIBRARY', Path.home() / 'invoke-remote-data' / 'video'))
GAME_ART = TOOL_DIR.parents[1] / 'data' / 'background_lists'
WORK = Path(os.environ.get('FIN_WORK', Path.home() / 'Videos' / 'ashely2_finish'))
JOBS = WORK / 'jobs.json'
CHUNK = 250  # frames per part at most
PAD = 8
BIG = (1728, 2304)  # SeedVR2 works at 2x
ART = (1152, 1536)  # what the game gets
TILE = 1024  # VAE tiles; the template's 512 is about 1.5x slower
CRF = 8
# Theora keyframes: one per file. At ffmpeg's default (every 12 frames) each keyframe refreshes the fine detail
# that the frames between hold still, a faint pulse twice a second on calm shots. libtheora caps the spacing at
# the power of two at or below -g, so 512 covers the longest clips (486 frames).
GOP = 512
SVR = 'seedvr2_7b_fp16.safetensors'
SVR_VAE = 'seedvr2_ema_vae_fp16.safetensors'
COLOUR_601 = ('colorspace=space=bt470bg:ispace=bt709:range=tv:irange=tv:primaries=bt709:iprimaries=bt709:'
              'trc=bt709:itrc=bt709')


def read_json(p, default):
    try:
        return json.loads(Path(p).read_text(encoding='utf-8'))
    except FileNotFoundError:
        return default


def write_json(p, data):
    p = Path(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(p.suffix + '.tmp')
    tmp.write_text(json.dumps(data, indent=1), encoding='utf-8')
    os.replace(tmp, p)


def edit_jobs(change):
    """Read, change (change(jobs) edits the dict in place) and write jobs.json under a lock file, so a submit and the
    downloader can run at the same time without one writing back a copy that lacks the other's changes."""
    lock = JOBS.with_name('jobs.lock')
    JOBS.parent.mkdir(parents=True, exist_ok=True)
    for _ in range(600):
        try:
            fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            break
        except FileExistsError:
            time.sleep(0.1)
    else:
        sys.exit(f'{lock} has been held for a minute; delete it if nothing else is running')
    try:
        jobs = read_json(JOBS, {})
        change(jobs)
        write_json(JOBS, jobs)
        return jobs
    finally:
        os.close(fd)
        os.unlink(lock)


def pods():
    return read_json(LIBRARY / 'pods.json', {})


def ssh(pod, command, data=None, timeout=120):
    p = pods()[pod]
    args = ['ssh', '-i', os.path.expanduser(p['key']), '-p', str(p['port']), '-o', 'StrictHostKeyChecking=accept-new',
            '-o', 'ConnectTimeout=20', '-o', 'ServerAliveInterval=30', f'root@{p["host"]}', command]
    r = subprocess.run(args, input=data, capture_output=True, timeout=timeout)
    if r.returncode:
        raise RuntimeError(f'{pod}: {command[:60]}: {r.stderr.decode(errors="replace")[-500:]}')
    return r.stdout


def scp(pod, sources, dest, upload):
    p = pods()[pod]
    base = ['scp', '-q', '-i', os.path.expanduser(p['key']), '-P', str(p['port']), '-o', 'ConnectTimeout=20']
    remote = f'root@{p["host"]}:'
    if upload:
        subprocess.run(base + [str(s) for s in sources] + [remote + dest], check=True)
    else:
        subprocess.run(base + [remote + s for s in sources] + [str(dest)], check=True)


# ---------------------------------------------------------------- what to make

def clip_frames(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-count_packets', '-select_streams', 'v:0', '-show_entries',
                          'stream=nb_read_packets', '-of', 'csv=p=0', str(path)], capture_output=True, text=True)
    return int(out.stdout.strip())


def targets():
    """One entry per Theora file: its art path stem, the source clip, the frames of it to keep, and whether it loops."""
    manifest = read_json(LIBRARY / 'final' / 'manifest.json', None)
    if manifest is None:
        sys.exit('no final/manifest.json: run h3.py final first')
    out = []
    for slot in manifest['slots']:
        for f in slot['files']:
            stem = f['file'][:-len('.mp4')]
            src = LIBRARY / 'final' / f['file']
            n = clip_frames(src)
            out.append({'target': stem, 'source': str(src), 'upload': stem.replace('/', '__') + '.mp4', 'n': n,
                        'core': [0, n], 'loop': f['seamless_loop']})
            # where the loop starts in its first clip: a seam loop at its base clip's frame roll, a stitched one
            # (junctions.py) where its first segment starts
            segments = read_json((LIBRARY / f['clip']).with_suffix('.json'), {}).get('loop_segments') or []
            first = (f['base_clip'], f['roll']) if f.get('roll') else (segments[0][0], segments[0][1]) if (
                f['seamless_loop'] and segments and segments[0][1] > 0) else None
            base = next((LIBRARY / 'clips').glob(f'*/{first[0]}'), None) if first else None
            if base:
                out.append({'target': stem + '_intro', 'source': str(base), 'upload': base.name, 'n': clip_frames(base),
                            'core': [0, first[1]], 'loop': False, 'intro_of': stem})
    return out


def parts(t):
    """[(name, [(start, count, repeat)])]: per part, the source frames SeedVR2 sees, padding included. repeat means
    `count` copies of frame `start`."""
    n, loop = t['n'], t['loop']
    s0, e0 = t['core']
    k = math.ceil((e0 - s0) / CHUNK)
    bounds = [s0 + round(i * (e0 - s0) / k) for i in range(k + 1)]
    out = []
    for i in range(k):
        s, e = bounds[i], bounds[i + 1]
        tail = PAD + (1 - (e - s + 2 * PAD)) % 4  # SeedVR2 wants 4k+1 frames
        segs = []
        # in front: real frames before s, else the loop's end, else frame s repeated
        if s >= PAD:
            segs.append((s - PAD, PAD, False))
        elif loop:
            segs += [(n - (PAD - s), PAD - s, False)] + ([(0, s, False)] if s else [])
        else:
            segs += ([(s, PAD - s, True)] if PAD - s else []) + ([(0, s, False)] if s else [])
        segs.append((s, e - s, False))
        if e + tail <= n:
            segs.append((e, tail, False))
        else:
            have = n - e
            if have:
                segs.append((e, have, False))
            segs.append((0, tail - have, False) if loop else (n - 1, tail - have, True))
        name = t['target'].replace('/', '__') + (f'__p{i + 1}' if k > 1 else '')
        out.append((name, segs, e - s, i + 1))
    return out


class Graph(dict):
    def add(self, class_type, **inputs):
        name = f'n{len(self)}'
        self[name] = {'class_type': class_type, 'inputs': inputs}
        return [name, 0]


def graph(upload, segs, keep, prefix):
    g = Graph()
    images = g.add('VHS_LoadVideoFFmpeg', video=upload, force_rate=0, custom_width=0, custom_height=0, frame_load_cap=0,
                   start_time=0, format='AnimateDiff')  # VHS_LoadVideo (OpenCV) darkens clips by about 1.2/255
    batch = None
    for start, count, repeat in segs:
        piece = g.add('ImageFromBatch', image=images, batch_index=start, length=1 if repeat else count)
        if repeat:
            piece = g.add('RepeatImageBatch', image=piece, amount=count)
        batch = piece if batch is None else g.add('ImageBatch', image1=batch, image2=piece)
    model = g.add('UNETLoader', unet_name=SVR, weight_dtype='default')
    vae = g.add('VAELoader', vae_name=SVR_VAE)
    resized = g.add('ImageScale', image=batch, upscale_method='lanczos', width=BIG[0], height=BIG[1], crop='disabled')
    pre = g.add('SeedVR2Preprocess', resized_images=resized)
    latent = g.add('VAEEncodeTiled', pixels=pre, vae=vae, tile_size=TILE, overlap=128, temporal_size=64, temporal_overlap=8)
    chunk = g.add('SeedVR2TemporalChunk', latent=latent, temporal_overlap=4, chunking_mode='auto')
    cond = g.add('SeedVR2Conditioning', model=model, vae_conditioning=chunk)
    sampled = g.add('KSampler', model=model, seed=42, steps=1, cfg=1.0, sampler_name='euler', scheduler='simple',
                    positive=cond, negative=[cond[0], 1], latent_image=chunk, denoise=1.0)
    merged = g.add('SeedVR2TemporalMerge', latents=sampled, temporal_overlap=[chunk[0], 1])
    decoded = g.add('VAEDecodeTiled', samples=merged, vae=vae, tile_size=TILE, overlap=128, temporal_size=64,
                    temporal_overlap=8)
    post = g.add('SeedVR2PostProcessing', images=decoded, original_resized_images=resized, color_correction_method='lab')
    kept = g.add('ImageFromBatch', image=post, batch_index=PAD, length=keep)  # parts() always pads PAD frames in front
    art = g.add('ImageScale', image=kept, upscale_method='lanczos', width=ART[0], height=ART[1], crop='disabled')
    g.add('VHS_VideoCombine', images=art, frame_rate=24.0, loop_count=0, filename_prefix=f'fin/{prefix}',
          format='video/h264-mp4', pix_fmt='yuv420p', crf=CRF, save_metadata=False, trim_to_audio=False, pingpong=False,
          save_output=True)
    return g


# ---------------------------------------------------------------- commands

def cmd_plan(pod_names):
    jobs = {}
    for t in targets():
        for name, segs, keep, part in parts(t):
            total = sum(c for _, c, _ in segs)
            jobs[name] = {'target': t['target'], 'part': part, 'upload': t['upload'], 'source': t['source'],
                          'core': t['core'], 'segs': segs, 'keep': keep, 'frames': total, 'loop': t['loop'],
                          'intro_of': t.get('intro_of')}
    # longest first onto the least loaded pod
    load = {p: 0 for p in pod_names}
    for name in sorted(jobs, key=lambda j: -jobs[j]['frames']):
        pod = min(load, key=load.get)
        jobs[name]['pod'] = pod
        load[pod] += jobs[name]['frames']
    def merge(old):
        for name, j in old.items():  # keep what's already queued or done
            if name in jobs and (j.get('prompt_id') or j.get('done')):
                jobs[name] = j
        old.clear()
        old.update(jobs)
    edit_jobs(merge)
    total = sum(j['frames'] for j in jobs.values())
    print(f'{len(jobs)} parts, {total} frames SeedVR2 sees ({sum(j["keep"] for j in jobs.values())} kept), '
          f'about {total * 2.1 / 3600:.1f} GPU-hours at 2.1 s a frame')
    for p, f in load.items():
        print(f'  {p}: {sum(1 for j in jobs.values() if j["pod"] == p)} parts, {f} frames, about {f * 2.1 / 3600:.1f} h')


def cmd_upload(pod):
    jobs = read_json(JOBS, {})
    need = {}
    for j in jobs.values():
        if j['pod'] == pod:
            need[j['upload']] = j['source']
    have = set(ssh(pod, 'ls /ComfyUI/input').decode().split())
    todo = {u: s for u, s in need.items() if u not in have}
    stage = WORK / 'upload' / pod
    stage.mkdir(parents=True, exist_ok=True)
    for u, s in todo.items():  # copied under its upload name, so one scp call sends them all
        dst = stage / u
        if not dst.exists():
            dst.write_bytes(Path(s).read_bytes())
    if todo:
        scp(pod, [stage / u for u in todo], '/ComfyUI/input/', upload=True)
    for u in todo:
        (stage / u).unlink()
    print(f'{pod}: {len(todo)} clips uploaded, {len(need) - len(todo)} already there')


def cmd_submit(pod):
    jobs = read_json(JOBS, {})
    n = 0
    order = sorted((name for name, j in jobs.items() if j['pod'] == pod), key=lambda name: -jobs[name]['frames'])
    for name in order[-1:] + order[:-1]:  # the shortest first, so a broken graph shows within minutes; then longest first
        j = jobs[name]
        if j.get('prompt_id') or j.get('done'):
            continue
        body = json.dumps({'prompt': graph(j['upload'], j['segs'], j['keep'], name), 'client_id': 'finish'}).encode()
        r = json.loads(ssh(pod, 'curl -s -X POST -H "Content-Type: application/json" --data-binary @- '
                                'http://127.0.0.1:8188/prompt', data=body))
        if 'prompt_id' not in r:
            sys.exit(f'{name}: {json.dumps(r)[:2000]}')
        queued = {'prompt_id': r['prompt_id'], 'submitted': time.time()}
        edit_jobs(lambda js: js[name].update(queued))
        n += 1
    print(f'{pod}: {n} parts queued')


def cmd_move(src, dst, frames):
    """Moves about `frames` frames of parts still waiting in src's queue (the last to run first) to dst, for when a
    pod runs slower than the rest. Upload and submit dst afterwards."""
    q = json.loads(ssh(src, 'curl -s http://127.0.0.1:8188/queue'))
    pending = [item[1] for item in sorted(q['queue_pending'], key=lambda item: item[0])]
    jobs = read_json(JOBS, {})
    by_prompt = {j.get('prompt_id'): n for n, j in jobs.items() if j['pod'] == src and not j.get('done')}
    chosen, total = [], 0
    for prompt_id in reversed(pending):
        name = by_prompt.get(prompt_id)
        if name and total < frames:
            chosen.append((name, prompt_id))
            total += jobs[name]['frames']
    if not chosen:
        sys.exit(f'{src}: nothing waiting to move')
    ssh(src, 'curl -s -X POST -H "Content-Type: application/json" --data-binary @- http://127.0.0.1:8188/queue',
        data=json.dumps({'delete': [p for _, p in chosen]}).encode())
    q = json.loads(ssh(src, 'curl -s http://127.0.0.1:8188/queue'))
    still = {item[1] for item in q['queue_running'] + q['queue_pending']}
    moved = [(n, p) for n, p in chosen if p not in still]  # one that started meanwhile stays where it is

    def move(js):
        for name, _ in moved:
            js[name].pop('prompt_id', None)
            js[name]['pod'] = dst
    edit_jobs(move)
    print(f'{len(moved)} parts ({sum(jobs[n]["frames"] for n, _ in moved)} frames) moved from {src} to {dst}'
          + (f'; {len(chosen) - len(moved)} had started and stay' if len(moved) < len(chosen) else ''))


def cmd_sync():
    """Rebuilds which part is queued where from the pods' own queues and histories (each graph saves to fin/<part>).
    A part no pod has is marked unqueued, so submit queues it again."""
    found = {}
    for pod in sorted({j['pod'] for j in read_json(JOBS, {}).values()}):
        queue = json.loads(ssh(pod, 'curl -s http://127.0.0.1:8188/queue'))
        hist = json.loads(ssh(pod, 'curl -s "http://127.0.0.1:8188/history?max_items=2000"', timeout=60))
        items = queue['queue_running'] + queue['queue_pending'] + [h['prompt'] for h in hist.values()]
        for item in items:
            prompt_id, graph_ = item[1], item[2]
            for node in graph_.values():
                prefix = node['inputs'].get('filename_prefix', '') if node['class_type'] == 'VHS_VideoCombine' else ''
                if prefix.startswith('fin/'):
                    found.setdefault(prefix[4:], []).append((pod, prompt_id))

    def fix(jobs):
        moved = lost = 0
        for name, j in jobs.items():
            if j.get('done'):
                continue
            where = found.get(name, [])
            if len(where) > 1:
                print(f'{name} is queued more than once: {where}')
            if where:
                pod, prompt_id = where[0]
                moved += (pod, prompt_id) != (j['pod'], j.get('prompt_id'))
                j.update(pod=pod, prompt_id=prompt_id)
                j.setdefault('submitted', time.time())
            elif j.get('prompt_id'):
                j.pop('prompt_id')
                lost += 1
        print(f'{sum(len(w) for w in found.values())} parts on the pods; {moved} records corrected, '
              f'{lost} marked unqueued; {sum(1 for j in jobs.values() if not j.get("prompt_id") and not j.get("done"))} '
              f'to queue')
    edit_jobs(fix)


def cmd_fetch(wait):
    while True:
        jobs = read_json(JOBS, {})
        left, changed = 0, False
        for pod in sorted({j['pod'] for j in jobs.values()}):
            mine = {n: j for n, j in jobs.items() if j['pod'] == pod and j.get('prompt_id') and not j.get('done')
                    and not j.get('error')}
            left += sum(1 for j in jobs.values() if j['pod'] == pod and not j.get('done') and not j.get('error'))
            if not mine:
                continue
            try:
                hist = json.loads(ssh(pod, 'curl -s "http://127.0.0.1:8188/history?max_items=2000"', timeout=60))
            except (RuntimeError, subprocess.TimeoutExpired, json.JSONDecodeError) as e:
                print(f'{pod}: no answer ({str(e)[:120]}), trying again later', flush=True)
                continue
            for name, j in mine.items():
                h = hist.get(j['prompt_id'])
                if not h:
                    continue
                status = h.get('status', {})
                if status.get('status_str') == 'error':
                    msg = [m for m in status.get('messages', []) if m[0] == 'execution_error']
                    j['error'] = (msg[0][1].get('exception_message', '') if msg else 'error')[:500]
                    print(f'ERROR {name}: {j["error"]}', flush=True)
                    changed = True
                    continue
                if not status.get('completed'):
                    continue
                files = [f for out in h['outputs'].values() for f in out.get('gifs', [])]
                if not files:
                    continue
                f = files[0]
                local = WORK / 'parts' / f'{name}.mp4'
                local.parent.mkdir(parents=True, exist_ok=True)
                try:
                    scp(pod, [f'/ComfyUI/output/{f["subfolder"]}/{f["filename"]}'], local.with_suffix('.part'), upload=False)
                except subprocess.CalledProcessError as e:
                    print(f'{pod}: download of {name} failed ({e}), trying again later', flush=True)
                    continue
                os.replace(local.with_suffix('.part'), local)
                j['done'] = time.time()
                j['seconds'] = round(j['done'] - j['submitted'])
                left -= 1
                changed = True
                print(f'got {name} ({pod}, {j["frames"]} frames)', flush=True)
        if changed:
            news = {n: {k: j[k] for k in ('done', 'seconds', 'error') if k in j} for n, j in jobs.items()
                    if j.get('done') or j.get('error')}
            edit_jobs(lambda js: [js[n].update(u) for n, u in news.items() if n in js])
        if not wait or not left:
            print(f'{left} parts still to come', flush=True)
            return
        time.sleep(60)


def ogv_path(target):
    """ashely_poker2/WIN_L4_KISS/20 -> data/background_lists/ashely_poker2/video/WIN_L4_KISS/20.ogv"""
    scene, rest = target.split('/', 1)
    return GAME_ART / scene / 'video' / f'{rest}.ogv'


def rgb_mean(paths, start=0, count=None, every=1):
    """Mean R, G, B of frames start..start+count-1 (every `every`th) of the clips played back to back, decoded with
    accurate rounding (swscale's default reads 4:2:0 about 1.2 levels dark)."""
    import numpy as np
    total, n, index = np.zeros(3), 0, 0
    for path in paths:
        raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-vf',
                              'scale=144:192:flags=area+accurate_rnd+full_chroma_int', '-f', 'rawvideo', '-pix_fmt',
                              'rgb24', '-'], capture_output=True).stdout
        for f in np.frombuffer(raw, np.uint8).reshape(-1, 192, 144, 3):
            if index >= start and (count is None or index < start + count) and (index - start) % every == 0:
                total += f.reshape(-1, 3).mean(0)
                n += 1
            index += 1
    return total / max(1, n)


def luma_step(rgb_from, rgb_to):
    """The BT.709 limited-range luma change that takes one mean colour to the other."""
    d = rgb_to - rgb_from
    return (0.2126 * d[0] + 0.7152 * d[1] + 0.0722 * d[2]) * 219 / 255


ENCODED = WORK / 'encoded.json'
STITCHED = TOOL_DIR / 'stitched.json'
# Game pictures that play one particular clip, for copies of one still that each have a video of their own.
PINNED = TOOL_DIR / 'pinned.json'
BLEND = 8  # an intro's last frames cross-fade into the loop's own (see blended_intro)
BLEND_MAX = 4.0  # mean luma difference above which those frames don't show the same moment: no cross-fade


def yuv_frames(path):
    """A clip's frames as raw yuv420p rows (decoded with no colour conversion), writable."""
    import numpy as np
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'rawvideo', '-pix_fmt', 'yuv420p', '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(bytearray(raw), np.uint8).reshape(-1, ART[0] * ART[1] * 3 // 2)


def blended_intro(files, loop_last_part, lift, loop_lift):
    """An intro's frames, its last BLEND cross-fading into the loop's own last BLEND. Those show the same moments (the
    frames just before the loop's start), but upscaled in the loop's job: SeedVR2 draws its fine detail a little
    differently in every job, so a cut from the intro's frames to the loop's ticks. This way the intro ends on the
    loop's own frame and hands over the way the loop wraps. Each side gets its own lift here. Returns (raw yuv420p bytes,
    the mean luma difference of the blended frames before blending), or (None, None) when they don't show the same
    moment."""
    import numpy as np
    y = ART[0] * ART[1]
    intro = np.concatenate([yuv_frames(f) for f in files])
    tail = yuv_frames(loop_last_part)[-BLEND:]
    for frames, d in ((intro, lift), (tail, loop_lift)):  # as lutyuv=y=clipval+d does it
        lut = np.clip(np.clip(np.arange(256), 16, 235) + d, 0, 255).astype(np.uint8)
        frames[:, :y] = lut[frames[:, :y]]
    k = min(BLEND, len(intro))
    a, b = intro[-k:].astype(np.float32), tail[-k:].astype(np.float32)
    diff = float(np.abs(a[:, :y] - b[:, :y]).mean())
    if diff > BLEND_MAX:
        print(f'  no cross-fade: the intro\'s last frames differ from the loop\'s by {diff:.2f}', flush=True)
        return None, None
    w = (np.arange(1, k + 1, dtype=np.float32) / k)[:, None]
    intro[-k:] = np.round(a * (1 - w) + b * w).astype(np.uint8)
    return intro.tobytes(), diff


def cmd_encode(wait, again=False, intros_only=False):
    """Theora per target. SeedVR2's colour correction follows the frames VHS's loader decoded, which read about 1.4
    levels dark, so each clip's luma is lifted back to its source's (a whole step, measured per clip). An intro is
    matched to the loop it runs into instead: its last frame to the loop's first, after the loop's own lift.
    again: encode every target once more, even those already done (after a change to the settings); with
    intros_only, only the intros."""
    redone = set()
    while True:
        jobs = read_json(JOBS, {})
        encoded = read_json(ENCODED, {})
        by_target = {}
        for name, j in jobs.items():
            by_target.setdefault(j['target'], []).append(name)
        waiting = 0
        # loops before their intros: an intro's lift depends on its loop's
        for target in sorted(by_target, key=lambda t: (t.endswith('_intro'), t)):
            names = sorted(by_target[target], key=lambda n: jobs[n]['part'])
            out = ogv_path(target)
            if target in encoded and out.exists() and (not again or target in redone
                                                       or (intros_only and not target.endswith('_intro'))):
                continue
            j = jobs[names[0]]
            loop_of = j.get('intro_of')
            if not all(jobs[n].get('done') for n in names) or (loop_of and loop_of not in encoded):
                waiting += 1
                continue
            files = [WORK / 'parts' / f'{n}.mp4' for n in names]
            if loop_of:
                first = min((n for n, x in jobs.items() if x['target'] == loop_of), key=lambda n: jobs[n]['part'])
                step = luma_step(rgb_mean(files, start=j['core'][1] - j['core'][0] - 1, count=1),
                                 rgb_mean([WORK / 'parts' / f'{first}.mp4'], start=0, count=1))
                exact = encoded[loop_of]['lift_exact'] + step
            else:
                s0, e0 = j['core']
                exact = luma_step(rgb_mean(files, every=4), rgb_mean([j['source']], start=s0, count=e0 - s0, every=4))
            lift = round(exact)
            space = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries',
                                    'stream=color_space', '-of', 'csv=p=0', str(files[0])], capture_output=True,
                                   text=True).stdout.strip()
            filters = []
            if lift:
                filters.append(f'lutyuv=y=clipval{lift:+d}')
            if space not in ('bt470bg', 'smpte170m'):  # ComfyUI saves BT.709; Godot decodes Theora as BT.601
                filters.append(COLOUR_601)
            listing = WORK / 'parts' / f'{target.replace("/", "__")}.txt'
            listing.write_text(''.join(f"file '{f.as_posix()}'\n" for f in files), encoding='utf-8')
            out.parent.mkdir(parents=True, exist_ok=True)
            tmp = out.with_name(out.stem + '.tmp.ogv')
            theora = ['-an', '-c:v', 'libtheora', '-q:v', '9', '-g', str(GOP), str(tmp)]
            blend = None
            if loop_of:
                last = max((n for n, x in jobs.items() if x['target'] == loop_of), key=lambda n: jobs[n]['part'])
                raw, blend = blended_intro(files, WORK / 'parts' / f'{last}.mp4', lift, encoded[loop_of]['lift'])
            if blend is not None:  # the lift is in the frames already
                r = subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'yuv420p', '-s',
                                    f'{ART[0]}x{ART[1]}', '-r', '24', '-i', '-', '-vf', ','.join(filters[1:] if lift else
                                    filters) or 'null'] + theora, input=raw, capture_output=True)
                del raw
            else:
                r = subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', str(listing),
                                    '-vf', ','.join(filters) if filters else 'null'] + theora, capture_output=True)
            check = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(tmp), '-f', 'null', '-'], capture_output=True,
                                   text=True)
            frames = clip_frames(tmp) if not (r.returncode or check.stderr.strip()) else None
            want = j['core'][1] - j['core'][0]
            if frames != want:
                print(f'ENCODE FAILED {target}: {frames} frames, wanted {want}. '
                      f'{(r.stderr.decode(errors="replace") + check.stderr)[-400:]}', flush=True)
                tmp.unlink(missing_ok=True)
                continue
            os.replace(tmp, out)
            redone.add(target)
            encoded[target] = {'file': out.relative_to(GAME_ART).as_posix(), 'frames': frames, 'lift': lift,
                               'lift_exact': round(exact, 2), 'mb': round(out.stat().st_size / 1e6, 2)}
            if blend is not None:
                encoded[target]['blend_diff'] = round(blend, 2)
            write_json(ENCODED, encoded)
            print(f'encoded {encoded[target]["file"]} ({encoded[target]["mb"]} MB, luma {lift:+d} from {exact:+.2f}'
                  + (f', last {BLEND} frames into the loop\'s own, which differed by {blend:.2f}' if blend is not None
                     else '') + ')', flush=True)
        write_game_list(encoded)
        if not wait or not waiting:
            print(f'{waiting} clips waiting for parts', flush=True)
            return
        time.sleep(90)


def preview_path(target):
    return WORK / 'preview' / f'{target}.mp4'


def cmd_preview(wait):
    """Browsers no longer play Theora, so the /finish page (before / after) gets a copy of each game file: the same
    pixels in H.264, tagged with the BT.601 matrix Godot decodes Theora with, so it looks as it will in game."""
    while True:
        encoded = read_json(ENCODED, {})
        made = 0
        for target, e in sorted(encoded.items()):
            out = preview_path(target)
            ogv = GAME_ART / e['file']
            if out.exists() and out.stat().st_mtime >= ogv.stat().st_mtime:
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            tmp = out.with_name(out.stem + '.tmp.mp4')
            r = subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(ogv), '-c:v', 'libx264', '-crf', '12', '-preset',
                                'fast', '-pix_fmt', 'yuv420p', '-colorspace', 'bt470bg', '-color_primaries', 'bt709',
                                '-color_trc', 'bt709', '-color_range', 'tv', '-movflags', '+faststart', '-an', str(tmp)],
                               capture_output=True, text=True)
            if r.returncode:
                print(f'PREVIEW FAILED {target}: {r.stderr[-300:]}', flush=True)
                tmp.unlink(missing_ok=True)
                continue
            os.replace(tmp, out)
            made += 1
        jobs = read_json(JOBS, {})
        left = len({j['target'] for j in jobs.values()} - set(encoded))
        print(f'{made} previews made; {left} clips not encoded yet', flush=True)
        if not wait or not left:
            return
        time.sleep(120)


def clip_parts(target):
    """A finished clip's downloaded parts, in order (WORK/parts/<job>.mp4)."""
    jobs = read_json(JOBS, {})
    names = sorted((n for n, j in jobs.items() if j['target'] == target), key=lambda n: jobs[n]['part'])
    return [WORK / 'parts' / f'{n}.mp4' for n in names]


def cmd_stitch(again=False):
    """Each cycle in stitched.json, from its clips' finished parts: each clip lifted as encode lifted it, the clips
    cross-faded one into the next, the last into the first clip's own final frames, so the file ends on the frame
    before the first clip's start (the first clip is a seamless loop) and plays over and over without a seam. Then
    BT.601 and Theora as encode makes them. Recorded in encoded.json under the cycle's name; gamelist lists it."""
    encoded = read_json(ENCODED, {})
    for st in read_json(STITCHED, {'stitches': []})['stitches']:
        out_target = st['out']
        out = ogv_path(out_target)
        if out_target in encoded and out.exists() and not again:
            continue
        clips = st['clips']
        missing = [c for c in clips if c not in encoded or not clip_parts(c) or not all(f.exists() for f in clip_parts(c))]
        if missing:
            print(f'STITCH SKIPPED {out_target}: not finished yet: {", ".join(missing)}', flush=True)
            continue
        fade = int(round(st.get('seconds', 0.75) * 24))
        frames = [encoded[c]['frames'] for c in clips]
        if min(frames) <= 2 * fade:
            print(f'STITCH SKIPPED {out_target}: a clip is too short for {fade}-frame fades', flush=True)
            continue
        args, chains = [], []
        for i, c in enumerate(clips):
            parts = clip_parts(c)
            listing = WORK / 'parts' / f'{c.replace("/", "__")}.txt'
            listing.write_text(''.join(f"file '{f.as_posix()}'" + '\n' for f in parts), encoding='utf-8')
            args += ['-f', 'concat', '-safe', '0', '-i', str(listing)]
            lift = encoded[c].get('lift', 0)
            chains.append(f'[{i}:v]' + (f'lutyuv=y=clipval{lift:+d},' if lift else '') + f'settb=1/24,setpts=N,format=yuv420p[c{i}]')
        # the first clip twice: whole at the start, its last `fade` frames at the end
        chains.append(f'[c0]split[c0a][c0b]')
        chains.append(f'[c0b]trim=start_frame={frames[0] - fade},setpts=N[tail]')
        streams = ['c0a'] + [f'c{i}' for i in range(1, len(clips))] + ['tail']
        lengths = frames + [fade]
        length, current = lengths[0], streams[0]
        for k in range(1, len(streams)):
            nxt = f'x{k}'
            chains.append(f'[{current}][{streams[k]}]xfade=transition={st.get("transition", "fade")}:duration={fade / 24}:'
                          f'offset={(length - fade) / 24}[{nxt}]')
            length += lengths[k] - fade
            current = nxt
        chains.append(f'[{current}]{COLOUR_601},format=yuv420p[out]')
        out.parent.mkdir(parents=True, exist_ok=True)
        tmp = out.with_name(out.stem + '.tmp.ogv')
        r = subprocess.run(['ffmpeg', '-v', 'error', '-y'] + args + ['-filter_complex', ';'.join(chains), '-map', '[out]',
                            '-r', '24', '-an', '-c:v', 'libtheora', '-q:v', '9', '-g', str(GOP), str(tmp)],
                           capture_output=True, text=True)
        got = clip_frames(tmp) if r.returncode == 0 and tmp.exists() else None
        if got != length:
            print(f'STITCH FAILED {out_target}: {got} frames, wanted {length}. {r.stderr[-600:]}', flush=True)
            tmp.unlink(missing_ok=True)
            continue
        os.replace(tmp, out)
        encoded = read_json(ENCODED, {})
        encoded[out_target] = {'file': out.relative_to(GAME_ART).as_posix(), 'frames': got, 'stitched': clips,
                               'fade': fade, 'mb': round(out.stat().st_size / 1e6, 2)}
        write_json(ENCODED, encoded)
        print(f'stitched {encoded[out_target]["file"]}: {" -> ".join(c.rsplit("/", 1)[1] for c in clips)} -> back, '
              f'{got} frames ({got / 24:.1f} s), {fade}-frame fades, {encoded[out_target]["mb"]} MB', flush=True)
    write_game_list(read_json(ENCODED, {}))


def gd_value(x):
    return ('true' if x else 'false') if isinstance(x, bool) else json.dumps(x)


def write_game_list(encoded):
    """<scene>/video/videos.gd: per game picture (the res:// path of its art), its videos in pick order, for
    src/vn/Background.gd. A GDScript file rather than JSON, because the game's export leaves .json files out."""
    manifest = read_json(LIBRARY / 'final' / 'manifest.json', {'slots': []})
    scenes = {}
    for slot in manifest['slots']:
        videos = []
        for f in slot['files']:
            target = f['file'][:-len('.mp4')]
            if target not in encoded:
                continue
            entry = {'video': 'res://data/background_lists/' + encoded[target]['file'], 'loop': f['seamless_loop']}
            if target + '_intro' in encoded:
                entry['intro'] = 'res://data/background_lists/' + encoded[target + '_intro']['file']
            videos.append(entry)
        for art in slot['game_art'] if videos else []:
            scenes.setdefault(art.split('/', 1)[0], {})['res://data/background_lists/' + art] = videos
    # A picture with a cycle (stitched.json, made by stitch) plays that, after its first clip's intro.
    for st in read_json(STITCHED, {'stitches': []})['stitches']:
        if st['out'] not in encoded:
            continue
        entry = {'video': 'res://data/background_lists/' + encoded[st['out']]['file'], 'loop': True}
        if st['clips'][0] + '_intro' in encoded:
            entry['intro'] = 'res://data/background_lists/' + encoded[st['clips'][0] + '_intro']['file']
        scenes.setdefault(st['picture'].split('/', 1)[0], {})['res://data/background_lists/' + st['picture']] = [entry]
    # A pinned picture (pinned.json) plays that one clip, looping if the pin says so even when the clip isn't a
    # seamless loop. Game pictures that share a source picture share its picks; pins give copies of one still
    # (more slots of the same image, tooling/art_sort) a video each.
    for pin in read_json(PINNED, {'pins': []})['pins']:
        if pin['clip'] not in encoded:
            print(f'pinned.json: {pin["clip"]} is not encoded, so {pin["picture"]} keeps its own videos')
            continue
        entry = {'video': 'res://data/background_lists/' + encoded[pin['clip']]['file'], 'loop': pin['loop']}
        if pin['clip'] + '_intro' in encoded:
            entry['intro'] = 'res://data/background_lists/' + encoded[pin['clip'] + '_intro']['file']
        scenes.setdefault(pin['picture'].split('/', 1)[0], {})['res://data/background_lists/' + pin['picture']] = [entry]
    for scene, pictures in scenes.items():
        lines = ["# Made by tooling/video_gen/finish.py (encode): each picture's videos, in the order they were picked",
                 '# on the /plan page. "loop" plays seamlessly over and over, after its "intro" if it has one (the frames',
                 '# from the still into the loop); otherwise the video plays once. Read by src/vn/Background.gd.',
                 'const VIDEOS = {']
        for art in sorted(pictures):
            lines.append(f'\t"{art}": [')
            for v in pictures[art]:
                lines.append('\t\t{' + ', '.join(f'"{k}": {gd_value(x)}' for k, x in v.items()) + '},')
            lines.append('\t],')
        lines.append('}')
        path = GAME_ART / scene / 'video' / 'videos.gd'
        path.parent.mkdir(parents=True, exist_ok=True)
        text = '\n'.join(lines) + '\n'
        if not path.exists() or path.read_text(encoding='utf-8') != text:
            path.write_text(text, encoding='utf-8', newline='\n')


def cmd_status():
    jobs = read_json(JOBS, {})
    for pod in sorted({j['pod'] for j in jobs.values()}):
        mine = [j for j in jobs.values() if j['pod'] == pod]
        done = [j for j in mine if j.get('done')]
        frames = sum(j['frames'] for j in mine)
        # the pod's queue runs one part at a time from its first submit on, model loading included
        rate = ((max(j['done'] for j in done) - min(j['submitted'] for j in mine if j.get('submitted')))
                / sum(j['frames'] for j in done)) if done else None
        left = (frames - sum(j['frames'] for j in done)) * rate / 3600 if rate else None
        print(f'{pod}: {len(done)}/{len(mine)} parts, {sum(j["frames"] for j in done)}/{frames} frames, '
              f'{sum(1 for j in mine if j.get("error"))} errors'
              + (f', {rate:.2f} s a frame, about {left:.1f} h to go' if rate else ''))
    targets_ = {j['target'] for j in jobs.values()}
    print(f'{sum(1 for t in targets_ if t in read_json(ENCODED, {}))}/{len(targets_)} Theora files made')


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['plan'] and a[1:]:
        cmd_plan(a[1:])
    elif a[:1] == ['upload'] and len(a) == 2:
        cmd_upload(a[1])
    elif a[:1] == ['submit'] and len(a) == 2:
        cmd_submit(a[1])
    elif a[:1] == ['fetch']:
        cmd_fetch('--wait' in a)
    elif a[:1] == ['encode']:
        cmd_encode('--wait' in a, '--again' in a, '--intros' in a)
    elif a[:1] == ['status']:
        cmd_status()
    elif a[:1] == ['sync']:
        cmd_sync()
    elif a[:1] == ['move'] and len(a) == 4:
        cmd_move(a[1], a[2], int(a[3]))
    elif a[:1] == ['preview']:
        cmd_preview('--wait' in a)
    elif a[:1] == ['stitch']:
        cmd_stitch('--again' in a)
    elif a[:1] == ['gamelist']:
        write_game_list(read_json(ENCODED, {}))
    else:
        sys.exit(__doc__)
