"""Make video clips from the game's art with MiniMax H3 on a Runpod pod, and keep them in a library.

The pod runs ComfyUI with no public ports: this machine reaches it through an SSH tunnel, so the
clips only ever travel between the pod and here. Terminate the pod when a session ends; that wipes
its disks (and `wipe` clears ComfyUI's input and output folders before then).

The library lives outside the game repo (the export would ship anything under res://):
    <library>/pods.json           the pods: {name: {"host", "port", "key", "local_port", "pod_id"}}; --pod picks one
    <library>/batches/*.json      what to make (see BATCH below)
    <library>/clips/<KEY>/<KEY>_<NNN>.mp4 and .json   each try, with everything needed to remake it
    <library>/sources/            the pictures as uploaded (scaled to the canvas)
    <library>/pending.json        tries queued on the pod and not yet downloaded
    <library>/review.json         your verdicts: keep / reject, the production star, and notes
    <library>/pictures.json       the clips grouped by the picture they animate, made by `pictures`
    <library>/plan.json           per picture: what becomes of its clips, picked on the review server's /plan page
    <library>/redo.json           per reworked picture: your note, the clips before, what was tried (the /redo page)
    <library>/final/              the picked clips under their game art names, and manifest.json (made by `final`)
    <library>/finish_review.json  your verdicts on the /finish page: is each upscaled game file better than its clip
    <library>/thumbs/             the review page's small stills and the game art's prints (safe to delete)

Commands (-P stops Python importing files from the current folder):
    python -P -E h3.py tunnel               hold the SSH tunnel open (run it in the background)
    python -P -E h3.py check                the pod's GPU, ComfyUI, model files and node inputs
    python -P -E h3.py submit <batch.json>  queue a batch's tries on the pod
    python -P -E h3.py fetch [--wait]       download finished tries (--wait: until none are pending)
    python -P -E h3.py serve                the review page, http://127.0.0.1:8771
    python -P -E h3.py setup                ready a new pod: local input/output folders, download the models
    python -P -E h3.py wipe                 delete ComfyUI's input and output files on the pod
    python -P -E h3.py watch [--pods a,b] [--idle 15]   exit once a pod has had nothing to do (then end it)
    python -P -E h3.py join NAME clip... [--fade S]   chain segments (shared frames dropped) or crossfade shots
    python -P -E h3.py pictures [NAME]      the clips per picture, under the picture's game art name
    python -P -E h3.py plan                 the plan made on the /plan page: what becomes of each picture
    python -P -E h3.py final                copy the plan's picked clips to <library>/final/ under their game art names

A chain is one job per segment, each with "source" = picture N and "last_frame" = picture N+1, and the
prompt in the guide's FL2VA form. `join` then plays the chosen tries back to back.

BATCH:
    {"defaults": {"width": 864, "height": 1152, "frames": 124, "steps": 30, "fps": 24},
     "jobs": [{"key": "SQUEEZE_TOP", "source": "C:/.../picture.png", "prompt": "...", "tries": 4,
               "last_frame": "same" | "<path>" | null, "loras": [["name.safetensors", 0.8]],
               "seeds": [optional fixed seeds], "note": "what this job tests"}]}
"""
import argparse
import hashlib
import http.server
import io
import json
import os
import random
import re
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

LIBRARY = Path(os.environ.get('H3_LIBRARY', Path.home() / 'invoke-remote-data' / 'video'))
TOOL_DIR = Path(__file__).resolve().parent
LOCAL_PORT = int(os.environ.get('H3_PORT', 18188))
POD = os.environ.get('H3_POD', 'main')
SERVE_PORT = 8771
# finish.py's work folder: the /finish page plays its browser copies of the game's Theora files from preview/
FIN_WORK = Path(os.environ.get('FIN_WORK', Path.home() / 'Videos' / 'ashely2_finish'))

MODELS = {
    'unet': 'minimax_h3_fl2va_bf16.safetensors',
    'text_encoder': 'qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors',
    'video_vae': 'minimax_h3_video_vae_fp16.safetensors',
    'audio_vae': 'minimax_h3_audio_vae_fp32.safetensors',
}
DEFAULTS = {'width': 864, 'height': 1152, 'frames': 124, 'steps': 30, 'fps': 24,
            'sampler': 'res_multistep', 'scheduler': 'simple'}
NODES = ['MiniMaxH3ImageToVideo', 'UNETLoader', 'CLIPLoader', 'VAELoader', 'VHS_VideoCombine',
         'LoraLoaderModelOnly', 'VAEDecodeAudio', 'MiniMaxH3SigmaShift']
ENCODING_CRF = 8  # x264 quality the clips are saved at: about 15 Mbps at 864x1152


# ---------------------------------------------------------------- files

def read_json(path, default):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        return default


def write_json(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + '.tmp')
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    for attempt in range(40):  # Windows refuses to replace a file another process has open for a moment
        try:
            os.replace(tmp, path)
            return
        except PermissionError:
            if attempt == 39:
                raise
            time.sleep(0.05)


def pods():
    """{name: {"host", "port", "key", "local_port", "pod_id"}} from pods.json (or the older one-pod pod.json)."""
    found = read_json(LIBRARY / 'pods.json', None)
    if found is None:
        one = read_json(LIBRARY / 'pod.json', None)
        found = {'main': {**one, 'local_port': LOCAL_PORT}} if one else {}
    return found


def pod(name=None):
    name = name or POD
    found = pods().get(name)
    if not found:
        sys.exit(f'no pod "{name}" in {LIBRARY / "pods.json"}: add {{"host", "port", "key", "local_port"}}')
    found = dict(found, name=name)
    found['key'] = os.path.expanduser(found.get('key', '~/.ssh/id_ed25519'))
    return found


def use_pod(name):
    """Points comfy() at that pod's tunnel."""
    global LOCAL_PORT
    LOCAL_PORT = int(pod(name).get('local_port', LOCAL_PORT))


def ssh_args(p):
    return ['ssh', '-i', p['key'], '-p', str(p['port']), '-o', 'StrictHostKeyChecking=accept-new',
            '-o', 'ServerAliveInterval=30', f'root@{p["host"]}']


# ---------------------------------------------------------------- ComfyUI over the tunnel

def comfy(path, data=None, raw=False, timeout=60, content_type='application/json'):
    url = f'http://127.0.0.1:{LOCAL_PORT}{path}'
    if isinstance(data, (dict, list)):
        data = json.dumps(data).encode()
    req = urllib.request.Request(url, data=data, headers={'Content-Type': content_type} if data else {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read()
    except urllib.error.HTTPError as e:
        raise RuntimeError(f'{path}: HTTP {e.code}: {e.read().decode(errors="replace")[:2000]}')
    except urllib.error.URLError as e:
        raise RuntimeError(f'{path}: {e.reason} (is the tunnel up? run: h3.py tunnel)')
    return body if raw else json.loads(body)


def upload(png_bytes, name):
    boundary = uuid.uuid4().hex
    parts = [f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{name}"\r\n'
             f'Content-Type: image/png\r\n\r\n'.encode(), png_bytes,
             f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue'
             f'\r\n--{boundary}--\r\n'.encode()]
    return comfy('/upload/image', b''.join(parts), content_type=f'multipart/form-data; boundary={boundary}')['name']


def canvas_png(source, width, height):
    """The picture scaled to the canvas (Lanczos), as PNG bytes, and a short name from its content."""
    from PIL import Image
    with Image.open(source) as im:
        im = im.convert('RGB')
        if im.size != (width, height):
            if abs(im.width / im.height - width / height) > 0.01:
                sys.exit(f'{source} is {im.width}x{im.height}, not the canvas shape {width}x{height}')
            im = im.resize((width, height), Image.LANCZOS)
        out = io.BytesIO()
        im.save(out, 'PNG')
    data = out.getvalue()
    name = f'src_{hashlib.sha1(data).hexdigest()[:12]}_{width}x{height}.png'
    (LIBRARY / 'sources').mkdir(parents=True, exist_ok=True)
    (LIBRARY / 'sources' / name).write_bytes(data)
    return data, name


def workflow(s, seed, first, last):
    wf = {
        'unet': {'class_type': 'UNETLoader', 'inputs': {'unet_name': s['unet'], 'weight_dtype': 'default'}},
        'clip': {'class_type': 'CLIPLoader', 'inputs': {'clip_name': s['text_encoder'], 'type': 'minimax',
                                                        'device': 'default'}},
        'vae': {'class_type': 'VAELoader', 'inputs': {'vae_name': s['video_vae']}},
        'audio_vae': {'class_type': 'VAELoader', 'inputs': {'vae_name': s['audio_vae']}},
        'first': {'class_type': 'LoadImage', 'inputs': {'image': first}},
        'i2v': {'class_type': 'MiniMaxH3ImageToVideo',
                'inputs': {'prompt': s['prompt'], 'width': s['width'], 'height': s['height'], 'length': s['frames'],
                           'clip': ['clip', 0], 'vae': ['vae', 0], 'first_frame': ['first', 0]}},
        'noise': {'class_type': 'RandomNoise', 'inputs': {'noise_seed': seed}},
        'sampler': {'class_type': 'KSamplerSelect', 'inputs': {'sampler_name': s['sampler']}},
        'sample': {'class_type': 'SamplerCustomAdvanced',
                   'inputs': {'noise': ['noise', 0], 'guider': ['guider', 0], 'sampler': ['sampler', 0],
                              'sigmas': ['sched', 0], 'latent_image': ['i2v', 1]}},
        'decode': {'class_type': 'VAEDecode', 'inputs': {'samples': ['sample', 0], 'vae': ['vae', 0]}},
        'decode_audio': {'class_type': 'VAEDecodeAudio', 'inputs': {'samples': ['sample', 0], 'vae': ['audio_vae', 0]}},
        # ComfyUI's own SaveVideo writes only about 3 Mbps, which smears fine lines and bands shadows
        'save': {'class_type': 'VHS_VideoCombine',
                 'inputs': {'images': ['decode', 0], 'audio': ['decode_audio', 0], 'frame_rate': float(s['fps']),
                            'loop_count': 0, 'filename_prefix': f'h3/{s["key"]}', 'format': 'video/h264-mp4',
                            'pix_fmt': 'yuv420p', 'crf': ENCODING_CRF, 'save_metadata': False,
                            'trim_to_audio': False, 'pingpong': False, 'save_output': True}},
    }
    model = 'unet'
    for i, (name, strength) in enumerate(s.get('loras') or []):
        wf[f'lora{i}'] = {'class_type': 'LoraLoaderModelOnly',
                          'inputs': {'model': [model, 0], 'lora_name': name, 'strength_model': float(strength)}}
        model = f'lora{i}'
    if s.get('shift'):  # finetunes want their own [video, audio] sigma shift; stock uses the built-in 12/3
        wf['shift'] = {'class_type': 'MiniMaxH3SigmaShift',
                       'inputs': {'model': [model, 0], 'shift_video': float(s['shift'][0]),
                                  'shift_audio': float(s['shift'][1])}}
        model = 'shift'
    wf['guider'] = {'class_type': 'BasicGuider', 'inputs': {'model': [model, 0], 'conditioning': ['i2v', 0]}}
    wf['sched'] = {'class_type': 'BasicScheduler', 'inputs': {'scheduler': s['scheduler'], 'steps': s['steps'],
                                                              'denoise': 1.0, 'model': [model, 0]}}
    if last:
        wf['last'] = {'class_type': 'LoadImage', 'inputs': {'image': last}}
        wf['i2v']['inputs']['last_frame'] = ['last', 0]
    return wf


# ---------------------------------------------------------------- commands

def cmd_tunnel(_):
    p = pod()
    args = ssh_args(p)
    print(f'tunnel: 127.0.0.1:{LOCAL_PORT} -> pod 127.0.0.1:8188 ({p["host"]}:{p["port"]}); Ctrl+C to close', flush=True)
    sys.exit(subprocess.call(args[:1] + ['-N', '-o', 'ExitOnForwardFailure=yes',
                                         '-L', f'{LOCAL_PORT}:127.0.0.1:8188'] + args[1:]))


def cmd_check(_):
    stats = comfy('/system_stats')
    print('ComfyUI', stats['system'].get('comfyui_version'), '| python', stats['system'].get('python_version', '')[:6],
          '| torch', stats['system'].get('pytorch_version'))
    for d in stats.get('devices', []):
        print(f'  {d["name"]}: {d["vram_total"] / 2**30:.0f} GiB VRAM, {d["vram_free"] / 2**30:.0f} free')
    info = {}
    for node in NODES:
        try:
            info.update(comfy(f'/object_info/{node}'))
        except RuntimeError as e:
            print(f'  MISSING node {node}: {e}')
    lists = {'unet': ('UNETLoader', 'unet_name'), 'text_encoder': ('CLIPLoader', 'clip_name'),
             'video_vae': ('VAELoader', 'vae_name'), 'audio_vae': ('VAELoader', 'vae_name')}
    for what, (node, field) in lists.items():
        names = info.get(node, {}).get('input', {}).get('required', {}).get(field, [[]])[0]
        print(f'  {what}: {MODELS[what]} {"OK" if MODELS[what] in names else "NOT FOUND"}')
    loras = info.get('LoraLoaderModelOnly', {}).get('input', {}).get('required', {}).get('lora_name', [[]])[0]
    print('  loras:', ', '.join(loras) or '(none)')
    i2v = info.get('MiniMaxH3ImageToVideo', {}).get('input', {})
    for group in ('required', 'optional'):
        for name, spec in i2v.get(group, {}).items():
            extra = spec[1] if len(spec) > 1 and isinstance(spec[1], dict) else {}
            keep = {k: extra[k] for k in ('default', 'min', 'max', 'step') if k in extra}
            print(f'  i2v {group} {name}: {spec[0] if isinstance(spec[0], str) else "list"} {keep}')


class PendingLock:
    """pending.json is changed by `submit` and by a running `fetch --wait` at the same time: every
    read-change-write of it happens inside this lock (a file created exclusively)."""
    path = LIBRARY / 'pending.lock'

    def __enter__(self):
        for _ in range(600):
            try:
                os.close(os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_WRONLY))
                return self
            except FileExistsError:
                if time.time() - self.path.stat().st_mtime > 120:  # left behind by a killed run
                    self.path.unlink(missing_ok=True)
                time.sleep(0.1)
        sys.exit(f'{self.path} stays locked; delete it if no h3.py is running')

    def __exit__(self, *exc):
        self.path.unlink(missing_ok=True)


def next_number(key, pending):
    folder = LIBRARY / 'clips' / key
    taken = [int(m.group(1)) for f in folder.glob(f'{key}_*.json') if (m := re.search(r'_(\d+)\.json$', f.name))]
    queued = [t['number'] for t in pending if t['key'] == key]
    return max(taken + queued + [0]) + 1


def cmd_submit(a):
    batch = read_json(a.batch, None) or sys.exit(f'cannot read {a.batch}')
    defaults = {**DEFAULTS, **MODELS, **batch.get('defaults', {})}
    only = set(a.only.split(',')) if a.only else None
    client = uuid.uuid4().hex
    uploaded = {}
    local = {}
    count = 0
    for job in batch['jobs']:
        s = {**defaults, **job}
        if not re.fullmatch(r'[A-Z0-9_]+', s['key']):
            sys.exit(f'key {s["key"]!r}: use capitals, digits and _')
        if only and not any(s['key'] == k or s['key'].startswith(k) for k in only):
            continue
        for side in ('source', 'last_frame'):
            path = s.get(side)
            if path and path != 'same' and path not in uploaded:
                data, name = canvas_png(path, s['width'], s['height'])
                uploaded[path] = upload(data, name)
                local[path] = f'sources/{name}'
        first = uploaded[s['source']]
        last = first if s.get('last_frame') == 'same' else uploaded.get(s.get('last_frame'))
        seeds = list(s.get('seeds') or [])
        seeds += [random.randrange(2**48) for _ in range(max(0, int(s.get('tries', 1)) - len(seeds)))]
        for seed in seeds:
            settings = {k: s[k] for k in ('key', 'prompt', 'width', 'height', 'frames', 'steps', 'fps', 'sampler',
                                          'scheduler', 'unet', 'text_encoder', 'video_vae', 'audio_vae')}
            settings.update(seed=seed, source=str(s['source']), source_file=local[s['source']],
                            last_frame=s.get('last_frame'),
                            loras=s.get('loras') or [], shift=s.get('shift'), note=s.get('note', ''),
                            batch=Path(a.batch).name, encoding=f'libx264 crf {ENCODING_CRF} yuv420p, aac')
            body = {'prompt': workflow(s, seed, first, last), 'client_id': client}
            if a.front:
                body['front'] = True  # ComfyUI puts it ahead of everything already waiting
            r = comfy('/prompt', body)
            if r.get('node_errors'):
                sys.exit(f'{s["key"]}: {json.dumps(r["node_errors"])[:2000]}')
            with PendingLock():
                pending = read_json(LIBRARY / 'pending.json', [])
                number = next_number(s['key'], pending)
                pending.append({'key': s['key'], 'number': number, 'prompt_id': r['prompt_id'], 'pod': POD,
                                'queued_at': time.time(), 'settings': settings})
                write_json(LIBRARY / 'pending.json', pending)
            count += 1
            print(f'queued {s["key"]}_{number:03d} on {POD}, seed {seed} ({r["prompt_id"]})')
    print(f'{count} queued on {POD}')


def cmd_fetch(a):
    while True:
        pending = read_json(LIBRARY / 'pending.json', [])
        done, unreachable = set(), set()
        for t in pending:
            name = t.get('pod', 'main')
            if name in unreachable:
                continue
            try:
                use_pod(name)
                h = comfy(f'/history/{t["prompt_id"]}').get(t['prompt_id'])
            except RuntimeError as e:
                print(f'{name}: {e}')
                unreachable.add(name)
                continue
            if not h or not h.get('status', {}).get('completed'):
                if h and h.get('status', {}).get('status_str') == 'error':
                    print(f'FAILED {t["key"]}_{t["number"]:03d}: {json.dumps(h["status"].get("messages"))[-1500:]}')
                    done.add(t['prompt_id'])
                continue
            files = [f for out in h.get('outputs', {}).values() for v in out.values() if isinstance(v, list)
                     for f in v if isinstance(f, dict) and f.get('filename', '').endswith(('.mp4', '.webm', '.mkv'))]
            if not files:
                print(f'NO VIDEO {t["key"]}_{t["number"]:03d}: {json.dumps(h.get("outputs"))[:500]}')
                done.add(t['prompt_id'])
                continue
            f = files[0]
            data = comfy('/view?' + urllib.parse.urlencode({'filename': f['filename'], 'subfolder': f.get('subfolder', ''),
                                                             'type': f.get('type', 'output')}), raw=True, timeout=600)
            stem = f'{t["key"]}_{t["number"]:03d}'
            folder = LIBRARY / 'clips' / t['key']
            folder.mkdir(parents=True, exist_ok=True)
            (folder / f'{stem}.mp4').write_bytes(data)
            stamps = {m[0]: m[1].get('timestamp') for m in h['status'].get('messages', []) if isinstance(m, list)}
            took = None
            if stamps.get('execution_start') and stamps.get('execution_success'):
                took = round((stamps['execution_success'] - stamps['execution_start']) / 1000, 1)
            write_json(folder / f'{stem}.json', {**t['settings'], 'file': f'{stem}.mp4', 'seconds_to_make': took,
                                                 'made_at': time.strftime('%Y-%m-%d %H:%M:%S'),
                                                 'prompt_id': t['prompt_id'], 'pod': name})
            done.add(t['prompt_id'])
            print(f'got {stem}.mp4 from {name} ({len(data) / 1e6:.1f} MB, {took} s)', flush=True)
        with PendingLock():
            left = [t for t in read_json(LIBRARY / 'pending.json', []) if t['prompt_id'] not in done]
            write_json(LIBRARY / 'pending.json', left)
        if a.forever:
            time.sleep(20)
            continue
        if not a.wait or not left:
            by_pod = {}
            for t in left:
                by_pod[t.get('pod', 'main')] = by_pod.get(t.get('pod', 'main'), 0) + 1
            if left:
                print('still pending: ' + ', '.join(f'{n} on {p}' for p, n in by_pod.items()))
            return
        time.sleep(20)


def probe(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-count_frames', '-show_entries',
                          'stream=nb_read_frames,r_frame_rate,width,height', '-of', 'json', str(path)],
                         capture_output=True, text=True, check=True)
    s = json.loads(out.stdout)['streams'][0]
    num, den = s['r_frame_rate'].split('/')
    return int(s['nb_read_frames']), float(num) / float(den), int(s['width']), int(s['height'])


def cmd_join(a):
    """Joins clips into one: chained segments (each starts on the frame the last one ended on, so that
    frame is dropped once) or separate shots with a crossfade (--fade seconds) between them."""
    parts = []
    for name in a.clips:
        p = Path(name)
        if not p.exists():
            found = list((LIBRARY / 'clips').glob(f'*/{name}.mp4')) + list((LIBRARY / 'clips').glob(f'*/{name}'))
            p = found[0] if found else sys.exit(f'no clip {name}')
        parts.append(p)
    info = [probe(p) for p in parts]
    fps = info[0][1]
    w, h = info[0][2], info[0][3]
    chains, fades, offset, length = [], [], 0.0, 0.0
    for i, (p, (frames, _, _, _)) in enumerate(zip(parts, info)):
        drop = 1 if (i and not a.fade and not a.keep_shared) else 0
        chains.append(f'[{i}:v]fps={fps},scale={w}:{h}:flags=lanczos,format=yuv420p,trim=start_frame={drop},'
                      f'setpts=PTS-STARTPTS,settb=AVTB[v{i}]')
        seconds = (frames - drop) / fps
        if i == 0:
            length = seconds
            continue
        if a.fade:
            offset = length - a.fade
            src = 'v0' if i == 1 else f'x{i - 1}'
            fades.append(f'[{src}][v{i}]xfade=transition={a.transition}:duration={a.fade}:offset={offset:.4f}[x{i}]')
            length = offset + seconds
    if a.fade and len(parts) > 1:
        graph = ';'.join(chains + fades)
        last = f'[x{len(parts) - 1}]'
    else:
        graph = ';'.join(chains) + ';' + ''.join(f'[v{i}]' for i in range(len(parts))) + f'concat=n={len(parts)}:v=1:a=0[out]'
        last = '[out]'
    key = a.name.upper()
    if not re.fullmatch(r'[A-Z0-9_]+', key):
        sys.exit('name: capitals, digits and _')
    key = 'JOIN_' + key if not key.startswith('JOIN_') else key
    folder = LIBRARY / 'clips' / key
    folder.mkdir(parents=True, exist_ok=True)
    number = next_number(key, [])
    out = folder / f'{key}_{number:03d}.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + [x for p in parts for x in ('-i', str(p))] +
                   ['-filter_complex', graph, '-map', last, '-an', '-c:v', 'libx264', '-crf', '14', '-preset', 'slow',
                    '-pix_fmt', 'yuv420p', str(out)], check=True)
    frames, _, _, _ = probe(out)
    metas = [read_json(p.with_suffix('.json'), {}) for p in parts]
    write_json(out.with_suffix('.json'), {
        'key': key, 'file': out.name, 'frames': frames, 'fps': fps, 'width': w, 'height': h,
        'steps': '-', 'seed': '-', 'source': metas[0].get('source'), 'source_file': metas[0].get('source_file'),
        'note': (a.note + ' | ' if a.note else '') + ('crossfade %.2fs (%s)' % (a.fade, a.transition) if a.fade
                                                      else 'chained, shared frames dropped') + ': ' + ' + '.join(p.stem for p in parts),
        'prompt': '\n\n'.join(f'[{p.stem}]\n{m.get("prompt", "")}' for p, m in zip(parts, metas)),
        'parts': [str(p.relative_to(LIBRARY)) if LIBRARY in p.parents else str(p) for p in parts],
        'made_at': time.strftime('%Y-%m-%d %H:%M:%S')})
    print(f'{out} ({frames} frames, {frames / fps:.1f} s)')


def cmd_watch(a):
    """Exits once one of the watched pods has had nothing to do for --idle minutes: its ComfyUI queue
    empty and every try from it downloaded. Run it in the background; its exit is the cue to wipe
    and terminate that pod."""
    names = a.pods.split(',') if a.pods else list(pods())
    idle_since = {}
    while True:
        pending = read_json(LIBRARY / 'pending.json', [])
        for name in names:
            use_pod(name)
            try:
                q = comfy('/queue', timeout=20)
            except RuntimeError:
                idle_since.pop(name, None)  # can't see it: don't count it as idle
                continue
            busy = q.get('queue_running') or q.get('queue_pending') or any(t.get('pod', 'main') == name for t in pending)
            if busy:
                idle_since.pop(name, None)
            else:
                idle_since.setdefault(name, time.time())
                if time.time() - idle_since[name] >= a.idle * 60:
                    print(f'IDLE {name}: queue empty and everything downloaded for {a.idle} min', flush=True)
                    return
        time.sleep(60)


SETUP = r'''set -e
cd /ComfyUI
for d in input output; do if [ -L $d ]; then rm $d; mkdir -p $d; echo "$d: now a local folder"; fi; done
cd /ComfyUI/models
env -u HF_TOKEN HF_XET_HIGH_PERFORMANCE=1 /opt/venv/bin/hf download Comfy-Org/MiniMax-H3 \
  diffusion_models/minimax_h3_fl2va_bf16.safetensors text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors \
  vae/minimax_h3_video_vae_fp16.safetensors vae/minimax_h3_audio_vae_fp32.safetensors \
  loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors --local-dir /ComfyUI/models > /root/dl.log 2>&1
du -sh /ComfyUI/models/diffusion_models /ComfyUI/models/text_encoders /ComfyUI/models/vae /ComfyUI/models/loras
'''


def cmd_setup(_):
    """Gets a fresh pod ready: ComfyUI's input/output off the network volume, the models downloaded."""
    # bytes, not text: text mode on Windows would turn the newlines into CRLF, which bash rejects
    sys.exit(subprocess.run(ssh_args(pod()) + ['bash -s'], input=SETUP.encode()).returncode)


def cmd_wipe(_):
    p = pod()
    script = ('for d in /workspace/ComfyUI /ComfyUI /root/ComfyUI; do [ -d "$d" ] && rm -rf "$d"/output/* '
              '"$d"/input/* "$d"/temp/* && echo "wiped $d/output, input, temp"; done; true')
    sys.exit(subprocess.call(ssh_args(p) + [script]))


# ---------------------------------------------------------------- pictures

GAME_ART = TOOL_DIR.parents[1] / 'data' / 'background_lists'
ART_INDEX = LIBRARY / 'thumbs' / 'game_art.npz'
GAME_MATCHES = {}  # picture -> the game art files it is; filled in the background by name_pictures_soon()
GAME_LOCK = threading.Lock()


def picture_of(clip, by_name):
    """The picture a clip animates, as its file in sources/. A clip that starts on another clip's last
    frame (a source named <CLIP>_last.png, as the extensions do) animates that clip's picture."""
    for _ in range(10):  # an extension of an extension
        m = re.search(r'([A-Z0-9_]+_\d{3})_last\.png$', str(clip.get('source') or ''))
        if not m or m[1] not in by_name:
            break
        clip = by_name[m[1]]
    return clip.get('source_file') or ''


def art_print(path):
    """A picture's shape (width / height) and a 24x32 colour thumbnail of it."""
    import numpy as np
    from PIL import Image
    with Image.open(path) as im:
        rgb = (im.convert('RGBA') if im.mode == 'P' else im).convert('RGB')
        return im.width / im.height, np.asarray(rgb.resize((24, 32), Image.BILINEAR), dtype=np.uint8)


def game_art_index(say=lambda *_: None):
    """(names, shapes, prints) for every picture under data/background_lists. The prints are kept in
    thumbs/game_art.npz and remade only for files that changed; the first run reads every file (minutes)."""
    import numpy as np
    old = {}
    try:
        with np.load(ART_INDEX) as z:
            for row in zip(z['names'], z['sizes'], z['mtimes'], z['shapes'], z['prints']):
                old[str(row[0])] = (int(row[1]), float(row[2]), float(row[3]), row[4])
    except (OSError, KeyError, ValueError):
        pass
    files = sorted(p for p in GAME_ART.rglob('*') if p.suffix.lower() in ('.webp', '.png', '.jpg', '.jpeg'))
    entries, changed = {}, len(old) != len(files)
    for i, p in enumerate(files):
        name, st = p.relative_to(GAME_ART).as_posix(), p.stat()
        hit = old.get(name)
        if hit and hit[:2] == (st.st_size, st.st_mtime):
            entries[name] = hit
            continue
        if i % 100 == 0:
            say(f'reading the game art: {i}/{len(files)}')
        try:
            entries[name] = (st.st_size, st.st_mtime, *art_print(p))
        except OSError:
            continue
        changed = True
    names = list(entries)
    shapes = np.array([entries[n][2] for n in names], dtype=np.float64)
    prints = np.array([entries[n][3] for n in names], dtype=np.uint8).reshape(len(names), 32, 24, 3)
    if changed:
        ART_INDEX.parent.mkdir(parents=True, exist_ok=True)
        tmp = ART_INDEX.with_name(ART_INDEX.name + '.tmp')
        with open(tmp, 'wb') as f:
            np.savez(f, names=np.array(names), sizes=np.array([entries[n][0] for n in names], dtype=np.int64),
                     mtimes=np.array([entries[n][1] for n in names]), shapes=shapes, prints=prints)
        os.replace(tmp, ART_INDEX)
    return names, shapes, prints


def match_game_art(pictures, say=lambda *_: None):
    """{picture: the files under data/background_lists that are the same image}. Copies differ by a level
    or two after compression and scaling; the closest lookalikes (the same pose with the expression or a hand
    changed) differ by 13 or more somewhere, so a copy is one whose 99.9th-percentile difference is 4 or less."""
    import numpy as np
    names, shapes, prints = game_art_index(say)
    out = {}
    for pic in pictures:
        out[pic] = []
        if not pic or not (LIBRARY / pic).is_file():
            continue
        shape, fp = art_print(LIBRARY / pic)
        near = np.flatnonzero(np.abs(shapes - shape) < 0.01)
        if len(near):
            diff = np.abs(prints[near].astype(np.int16) - fp.astype(np.int16)).reshape(len(near), -1)
            out[pic] = [names[i] for i in near[np.percentile(diff, 99.9, axis=1) <= 4]]
    return out


def name_pictures_soon(pictures):
    """Matches the pictures not matched yet to their game art, in the background, for the review page."""
    todo = set(pictures) - GAME_MATCHES.keys()
    if not todo or not GAME_LOCK.acquire(blocking=False):
        return

    def run():
        try:
            GAME_MATCHES.update(match_game_art(todo))
        except Exception as e:  # the page still works, under the pictures' file names
            print('matching pictures to the game art failed:', e, flush=True)
        finally:
            GAME_LOCK.release()
    threading.Thread(target=run, daemon=True).start()


def picture_name(pic, game):
    return ' = '.join(re.sub(r'\.\w+$', '', g) for g in game) or (Path(pic).stem if pic else 'no picture recorded')


def cmd_pictures(a):
    """The clips grouped by the picture they animate, with each picture's game art files and your verdicts.
    Prints a table (or, given NAME, every clip of the matching pictures) and writes <library>/pictures.json."""
    found = clips()
    review = read_json(LIBRARY / 'review.json', {})
    groups = {}
    for c in found:
        groups.setdefault(c['picture'], []).append(c)
    matches = match_game_art(sorted(groups), say=print)
    rows = []
    for pic, cs in groups.items():
        verdicts = [review.get(c['path'], {}) for c in cs]
        rows.append({
            'name': picture_name(pic, matches[pic]), 'picture': pic, 'game_art': matches[pic],
            'originals': sorted({c['source'] for c in cs if c.get('source') and c.get('source_file') == pic}),
            'keys': sorted({c['key'] for c in cs}),
            'clips': len(cs), 'kept': sum(v.get('verdict') == 'keep' for v in verdicts),
            'production': sum(v.get('production') is True for v in verdicts),
            'clip_list': [{'path': c['path'], 'verdict': v.get('verdict', ''), 'production': v.get('production') is True,
                           'note': v.get('note', '')} for c, v in zip(cs, verdicts)]})
    rows.sort(key=lambda r: r['name'])
    write_json(LIBRARY / 'pictures.json', {
        'made_at': time.strftime('%Y-%m-%d %H:%M:%S'),
        'about': 'made by h3.py pictures from clips/*.json, review.json and data/background_lists; '
                 'run it again to bring it up to date',
        'pictures': rows})
    if a.name:
        q = a.name.lower()
        for r in rows:
            if q in r['name'].lower() or q in r['picture'].lower() or any(q in k.lower() for k in r['keys']):
                print(f"\n{r['name']}  ({r['clips']} clips, {r['kept']} kept, {r['production']} production)")
                for c in r['clip_list']:
                    mark = 'P' if c['production'] else {'keep': 'K', 'reject': 'x'}.get(c['verdict'], '.')
                    print(f"  {mark} {Path(c['path']).stem:44s} {c['note'][:70]}")
        return
    print(f"{len(found)} clips of {len(rows)} pictures: {sum(1 for r in rows if r['kept'])} with a kept clip, "
          f"{sum(1 for r in rows if r['production'])} with a production clip, "
          f"{sum(1 for r in rows if not r['game_art'])} not found in the game art")
    print(f"{'prod':>4} {'kept':>4} {'clips':>5}  picture")
    for r in rows:
        print(f"{r['production']:4d} {r['kept']:4d} {r['clips']:5d}  {r['name']}   {', '.join(r['keys'])}")
    print(f'\nwritten to {LIBRARY / "pictures.json"}')


def cmd_plan(_):
    """Prints the plan made on the /plan page (<library>/plan.json): per decision, each picture's clips and note."""
    plan = read_json(LIBRARY / 'plan.json', {})
    pictures = sorted({c['picture'] for c in clips()})
    matches = match_game_art(pictures)
    names = {p: picture_name(p, matches[p]) for p in pictures}
    for decision, title in PLAN_DECISIONS.items():
        rows = sorted((names[p], plan.get(p, {})) for p in pictures if plan.get(p, {}).get('decision', '') == decision)
        if not decision:
            print(f'{len(pictures) - len(rows)} of {len(pictures)} pictures decided')
            continue
        if not rows:
            continue
        print(f'\n{title} ({len(rows)})')
        for name, entry in rows:
            picks = ' + '.join(Path(c).stem for c in entry.get('clips', []))
            print(f'  {name}' + (f': {picks}' if picks else '') + (f'\n      {entry["note"]}' if entry.get('note') else ''))


def cmd_final(_):
    """The plan as files, ready to encode: each picture's picked clips copied to <library>/final/<game art path>.mp4
    (several picks: _1, _2 ... in the order first picked; a pick keeps its name when the order changes), and
    final/manifest.json listing every game slot with its files in pick order (the game plays the first), how long
    they are, whether they loop seamlessly, and its status. A picture with a /redo note that has no verdict yet
    keeps its current picks, marked "review". Rerun after changing the plan: only changed files are copied, and files
    no longer picked are removed."""
    import shutil
    plan = read_json(LIBRARY / 'plan.json', {})
    reworked = {e['picture'] for e in read_json(LIBRARY / 'redo.json', {}).get('pictures', [])}
    by_path = {c['path']: c for c in clips()}
    pictures = sorted({c['picture'] for c in by_path.values()})
    matches = match_game_art(pictures)
    out_dir = LIBRARY / 'final'
    # A pick keeps the file name it already has, so reordering a picture's picks on /plan changes only which plays
    # first: finish.py files each upscale and Theora under the pick's name (WIN_S1_TOP/03_2 stays that clip).
    named = {(s['picture'], f['clip']): f['file']
             for s in read_json(out_dir / 'manifest.json', {}).get('slots', []) for f in s['files']}
    slots, wanted, size = [], set(), 0
    for pic in pictures:
        entry, game = plan.get(pic, {}), matches.get(pic) or []
        decision = entry.get('decision', '')
        picks = [p for p in entry.get('clips', []) if p in by_path]
        if decision == 'none':
            status = 'still'
        elif not picks:
            status = 'nothing picked'
        elif not decision:
            status = 'no decision'
        elif pic in reworked and not entry.get('redo_verdict'):
            status = 'review'
        else:
            status = 'ready'
        slot = {'game_art': game, 'picture': pic, 'decision': decision, 'status': status, 'note': entry.get('note', ''),
                'files': []}
        if status != 'still' and picks and game:
            stem = Path(game[0]).with_suffix('').as_posix()
            mine = re.compile(re.escape(stem) + r'(_\d+)?\.mp4')
            names = {rel: named.get((pic, rel)) for rel in picks}
            names = {rel: n if n and mine.fullmatch(n) else None for rel, n in names.items()}
            for i, rel in enumerate(picks, 1):
                if names[rel]:
                    continue
                taken = set(names.values())
                name = f'{stem}.mp4' if len(picks) == 1 else f'{stem}_{i}.mp4'
                k = len(picks)
                while name in taken:
                    k += 1
                    name = f'{stem}_{k}.mp4'
                names[rel] = name
            for rel in picks:
                c, src = by_path[rel], LIBRARY / rel
                name = names[rel]
                dest = out_dir / name
                wanted.add(dest.resolve())
                if not dest.exists() or dest.stat().st_size != src.stat().st_size or dest.stat().st_mtime < src.stat().st_mtime:
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dest)
                size += src.stat().st_size
                extra = c.get('extra') or {}
                slot['files'].append({
                    'file': name, 'clip': rel, 'frames': c.get('frames'), 'seconds': round(c['frames'] / c['fps'], 2)
                    if c.get('frames') and c.get('fps') else None,
                    # a seam loop, or a clip that ends close enough to its start to loop as it is (plan "loop_as_is")
                    'seamless_loop': c['key'].startswith('LOOP_') or rel in entry.get('loop_as_is', []),
                    # a seam loop starts at its base clip's frame `roll`: play base frames 0..roll-1 first to run into it
                    **({'base_clip': extra['base_clip'], 'roll': extra['roll']} if 'roll' in extra else {})})
        slots.append(slot)
    for f in out_dir.rglob('*.mp4') if out_dir.exists() else []:
        if f.resolve() not in wanted:
            f.unlink()
    write_json(out_dir / 'manifest.json', {
        'made_at': time.strftime('%Y-%m-%d %H:%M:%S'),
        'about': 'One entry per picture: its game art slot(s), the plan decision and status (ready / review = a /redo '
                 'note without a verdict yet / no decision / nothing picked / still) and the picked clips copied here, '
                 'named after the first game art slot (_1, _2 ...; listed in pick order, the first plays in the game). Made by `h3.py final` from plan.json.',
        'slots': slots})
    by_status = {}
    for s in slots:
        by_status.setdefault(s['status'], []).append(s)
    files = sum(len(s['files']) for s in slots)
    print(f'{out_dir}: {files} files from {sum(1 for s in slots if s["files"])} pictures, {size / 1e6:.0f} MB')
    for status in ('ready', 'review', 'no decision', 'nothing picked', 'still'):
        rows = by_status.get(status, [])
        if rows:
            print(f'  {status}: {len(rows)}' + ('' if status in ('ready', 'still') else ': ' + ', '.join(
                sorted(picture_name(s['picture'], matches.get(s['picture'])) for s in rows))))


# ---------------------------------------------------------------- review page

def clips():
    found = []
    for meta in sorted((LIBRARY / 'clips').glob('*/*.json')):
        data = read_json(meta, {})
        data['path'] = f'clips/{meta.parent.name}/{data.get("file", meta.stem + ".mp4")}'
        found.append(data)
    by_name = {Path(c['path']).stem: c for c in found}
    for c in found:
        c['picture'] = picture_of(c, by_name)
    return found


class Review(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(LIBRARY), **kwargs)

    def log_message(self, *args):
        pass

    def send_json(self, data, code=200):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_page(self, name):
        body = (TOOL_DIR / name).read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ('/', '/index.html'):
            self.send_page('review.html')
        elif self.path == '/plan':
            self.send_page('plan.html')
        elif self.path == '/redo':
            self.send_page('redo.html')
        elif self.path == '/api/plan':
            with REVIEW_LOCK:
                plan = read_json(LIBRARY / 'plan.json', {})
            self.send_json(plan)
        elif self.path == '/api/redo':
            self.send_json(read_json(LIBRARY / 'redo.json', {'pictures': []}))
        elif self.path == '/finish':
            self.send_page('finish.html')
        elif self.path == '/api/finish':
            self.send_json(finish_data())
        elif self.path == '/api/clips':
            found = clips()
            name_pictures_soon(c['picture'] for c in found)
            with REVIEW_LOCK:  # a save's os.replace fails on Windows while the file is open here
                review = read_json(LIBRARY / 'review.json', {})
            self.send_json({'clips': found, 'review': review, 'pending': read_json(LIBRARY / 'pending.json', []),
                            'pictures': dict(GAME_MATCHES)})
        elif self.path.startswith('/thumbs/'):
            make_thumb(urllib.parse.unquote(self.path.split('?')[0])[len('/thumbs/'):])
            super().do_GET()
        elif not self.send_range():
            super().do_GET()

    def translate_path(self, path):
        """/fin/... is finish.py's work folder (the /finish page's after videos); everything else is the library."""
        rel = urllib.parse.unquote(path.split('?', 1)[0].split('#', 1)[0])
        if rel.startswith('/fin/'):
            parts = [p for p in rel[len('/fin/'):].split('/') if p]
            if any(p in ('.', '..') or ':' in p or '\\' in p for p in parts):
                return str(FIN_WORK / 'missing')
            return str(FIN_WORK.joinpath(*parts))
        return super().translate_path(path)

    def send_range(self):
        """Answers a video's byte-range request with 206. A plain 200 makes Chrome keep every <video>'s
        connection open, and once its six connections to this host are used, the rest of the page stalls."""
        m = re.fullmatch(r'bytes=(\d*)-(\d*)', self.headers.get('Range', '').strip())
        path = Path(self.translate_path(self.path))
        if not m or not (m[1] or m[2]) or not path.is_file():
            return False
        size = path.stat().st_size
        if m[1]:
            start, end = int(m[1]), min(int(m[2]) if m[2] else size - 1, size - 1)
        else:  # bytes=-N is the last N bytes
            start, end = max(0, size - int(m[2])), size - 1
        if start > end:
            self.send_response(416)
            self.send_header('Content-Range', f'bytes */{size}')
            self.send_header('Content-Length', '0')
            self.end_headers()
            return True
        self.send_response(206)
        self.send_header('Content-Type', self.guess_type(str(path)))
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
        self.send_header('Content-Length', str(end - start + 1))
        self.end_headers()
        try:
            with open(path, 'rb') as f:
                f.seek(start)
                left = end - start + 1
                while left > 0:
                    chunk = f.read(min(left, 1 << 20))
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    left -= len(chunk)
        except ConnectionError:
            pass  # the browser had enough and hung up, which is normal for video
        return True

    def do_POST(self):
        if self.path not in ('/api/review', '/api/plan', '/api/finish') or self.headers.get('Origin', '').rstrip('/') not in (
                f'http://127.0.0.1:{SERVE_PORT}', f'http://localhost:{SERVE_PORT}'):
            return self.send_json({'error': 'not allowed'}, 403)
        item = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))))
        if self.path == '/api/plan':
            return self.save_plan(item)
        if self.path == '/api/finish':
            return self.save_finish(item)
        with REVIEW_LOCK:  # a note saved on blur and a Keep click arrive together
            review = read_json(LIBRARY / 'review.json', {})
            entry = review.get(item['path'], {})
            for field in ('verdict', 'note'):
                if field in item:
                    entry[field] = item[field]
            if 'production' in item:  # starred: good enough to ship as is, a step above keep
                entry['production'] = item['production'] is True
            entry['at'] = time.strftime('%Y-%m-%d %H:%M:%S')
            review[item['path']] = entry
            write_json(LIBRARY / 'review.json', review)
        self.send_json({'ok': True})

    def save_plan(self, item):
        """One picture's entry from the /plan page: what becomes of it, the clips it uses (in order) and a note."""
        if (not isinstance(item.get('picture'), str) or item.get('decision', '') not in PLAN_DECISIONS
                or not all(isinstance(c, str) for c in item.get('clips', []))
                or item.get('redo_verdict', '') not in REDO_VERDICTS or not isinstance(item.get('redo_note', ''), str)):
            return self.send_json({'error': 'bad plan entry'}, 400)
        with REVIEW_LOCK:  # the same lock as review.json: one save at a time, and no read during os.replace
            plan = read_json(LIBRARY / 'plan.json', {})
            entry = plan.get(item['picture'], {})
            for field in ('decision', 'clips', 'note', 'redo_verdict', 'redo_note'):
                if field in item:
                    entry[field] = item[field]
            entry['game_art'] = GAME_MATCHES.get(item['picture']) or entry.get('game_art', [])
            entry['at'] = time.strftime('%Y-%m-%d %H:%M:%S')
            plan[item['picture']] = entry
            write_json(LIBRARY / 'plan.json', plan)
        self.send_json({'ok': True})

    def save_finish(self, item):
        """One game file's verdict from the /finish page: is the upscaled version better than the clip it came from?"""
        if (not isinstance(item.get('file'), str) or item.get('verdict', '') not in FINISH_VERDICTS
                or not isinstance(item.get('note', ''), str)):
            return self.send_json({'error': 'bad verdict'}, 400)
        with REVIEW_LOCK:
            review = read_json(LIBRARY / 'finish_review.json', {})
            entry = review.get(item['file'], {})
            for field in ('verdict', 'note'):
                if field in item:
                    entry[field] = item[field]
            entry['at'] = time.strftime('%Y-%m-%d %H:%M:%S')
            review[item['file']] = entry
            write_json(LIBRARY / 'finish_review.json', review)
        self.send_json({'ok': True})


FINISH_VERDICTS = ('', 'better', 'same', 'worse')


def finish_data():
    """The /finish page: per game slot (final/manifest.json), each file's clip before and the game's version after
    (finish.py's browser copy, once it's made), and the verdicts so far."""
    manifest = read_json(LIBRARY / 'final' / 'manifest.json', {'slots': []})
    encoded = read_json(FIN_WORK / 'encoded.json', {})
    slots = []
    for slot in manifest['slots']:
        files = []
        for f in slot['files']:
            target = f['file'][:-len('.mp4')]
            after = FIN_WORK / 'preview' / f'{target}.mp4'
            files.append({'file': f['file'], 'clip': Path(f['clip']).stem, 'seconds': f.get('seconds'),
                          'loop': f.get('seamless_loop', False), 'before': f'final/{f["file"]}',
                          'thumb': 'thumbs/' + str(Path(f['clip']).with_suffix('.jpg').as_posix()),
                          'after': f'fin/preview/{target}.mp4' if after.is_file() else None,
                          'game': encoded.get(target, {}).get('file'), 'lift': encoded.get(target, {}).get('lift'),
                          'mb': encoded.get(target, {}).get('mb'), 'intro': f'{target}_intro' in encoded})
        if files:
            slots.append({'game_art': slot['game_art'], 'decision': slot['decision'], 'files': files})
    with REVIEW_LOCK:
        review = read_json(LIBRARY / 'finish_review.json', {})
    return {'slots': slots, 'review': review}


REVIEW_LOCK = threading.Lock()
# What becomes of a picture on the /plan page ('' = not decided yet); the clips are listed in the order picked.
PLAN_DECISIONS = {
    '': 'Not decided',
    'use': 'Use as is',               # a picked clip goes into the game as it is
    'combine': 'Combine',             # the picked clips become one longer clip or seamless loop, in pick order
    'loop': 'Make a loop',            # the picked clip becomes a seamless loop
    'redo': 'New renders',            # nothing works yet; the note says what to try
    'none': 'No video',               # the picture stays a still
}
# The /redo page's verdict on a reworked picture: did the new tries fix what its note asked for?
REDO_VERDICTS = ('', 'fixed', 'better', 'no')
FFMPEG_SLOTS = threading.Semaphore(2)  # the page asks for many stills at once


def make_thumb(rel):
    """The review page's small still for clips/<KEY>/<NAME>.jpg (the clip's middle frame) or sources/<NAME>.jpg
    (the picture), made once and kept in <library>/thumbs/. The page shows these instead of a loaded <video>
    per card, which ran the browser out of memory. Returns False when there's nothing to make it from."""
    if '..' in rel or not re.fullmatch(r'(clips/[\w-]+|sources)/[\w.-]+\.jpg', rel):
        return False
    clip = rel.startswith('clips/')
    src = LIBRARY / Path(rel).with_suffix('.mp4' if clip else '.png')
    out = LIBRARY / 'thumbs' / rel
    fresh = lambda: out.is_file() and out.stat().st_mtime >= src.stat().st_mtime
    if not src.is_file():
        return False
    if fresh():
        return True
    with FFMPEG_SLOTS:
        if fresh():  # another request made it meanwhile
            return True
        seek = []
        if clip:
            meta = read_json(src.with_suffix('.json'), {})
            seek = ['-ss', f'{meta.get("frames", 48) / meta.get("fps", 24) / 2:.2f}']
        out.parent.mkdir(parents=True, exist_ok=True)
        tmp = out.with_name(f'{out.stem}.{threading.get_ident()}.jpg')
        made = subprocess.run(['ffmpeg', '-v', 'error', '-y', *seek, '-i', str(src), '-frames:v', '1',
                               '-vf', f'scale={432 if clip else 160}:-2', '-q:v', '4', str(tmp)],
                              capture_output=True).returncode == 0 and tmp.is_file()
        try:
            if made:
                os.replace(tmp, out)
        except OSError:  # Windows: the old still is being sent right now; the next request remakes it
            made = False
        tmp.unlink(missing_ok=True)
        return made


def warm_thumbs():
    """Makes the missing stills in the background, so scrolling the page rarely waits for one."""
    found = clips()
    name_pictures_soon(c['picture'] for c in found)
    for c in found:
        for path in (c['path'], c.get('source_file')):
            if path:
                make_thumb(re.sub(r'\.\w+$', '.jpg', path))


def cmd_serve(_):
    server = http.server.ThreadingHTTPServer(('127.0.0.1', SERVE_PORT), Review)
    threading.Thread(target=warm_thumbs, daemon=True).start()
    print(f'review page: http://127.0.0.1:{SERVE_PORT}  (library {LIBRARY})', flush=True)
    server.serve_forever()


def main():
    global POD
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--pod', default=POD, help='which pod in pods.json (default: $H3_POD or "main")')
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('tunnel')
    sub.add_parser('check')
    s = sub.add_parser('submit')
    s.add_argument('batch')
    s.add_argument('--only', help='comma-separated keys or key prefixes to queue (default: every job)')
    s.add_argument('--front', action='store_true', help='run these next, ahead of what is already queued')
    f = sub.add_parser('fetch')
    f.add_argument('--wait', action='store_true', help='keep going until nothing is pending')
    f.add_argument('--forever', action='store_true', help='keep going, picking up new submits (run it in the background)')
    sub.add_parser('serve')
    sub.add_parser('wipe')
    sub.add_parser('setup')
    w = sub.add_parser('watch')
    w.add_argument('--pods', help='comma-separated pod names (default: all in pods.json)')
    w.add_argument('--idle', type=float, default=15, help='minutes of nothing to do before it exits')
    j = sub.add_parser('join')
    j.add_argument('name', help='the joined clip goes in clips/JOIN_<NAME>/')
    j.add_argument('clips', nargs='+', help='clip files, or library names like SQUEEZE_UNDER_TOP_001')
    j.add_argument('--fade', type=float, default=0.0, help='crossfade seconds between separate shots')
    j.add_argument('--transition', default='fade', help="ffmpeg xfade transition (fade, dissolve, ...)")
    j.add_argument('--keep-shared', action='store_true', help="don't drop the first frame of each later clip")
    j.add_argument('--note', default='')
    p = sub.add_parser('pictures')
    p.add_argument('name', nargs='?', help='list every clip of the pictures matching this (game art name, or a key)')
    sub.add_parser('plan')
    sub.add_parser('final')
    a = ap.parse_args()
    POD = a.pod
    if a.cmd in ('tunnel', 'check', 'submit', 'wipe', 'setup'):
        use_pod(POD)
    {'tunnel': cmd_tunnel, 'check': cmd_check, 'submit': cmd_submit, 'fetch': cmd_fetch, 'serve': cmd_serve,
     'wipe': cmd_wipe, 'setup': cmd_setup, 'watch': cmd_watch, 'join': cmd_join, 'pictures': cmd_pictures,
     'plan': cmd_plan, 'final': cmd_final}[a.cmd](a)


if __name__ == '__main__':
    main()
