# Video clips with MiniMax H3

Makes short video clips from the game's art with MiniMax H3 on a Runpod pod, and keeps every try
in a local library with a review page. Research and background: `docs/video/H3_RUNPOD.md`.

**Privacy (agreed with Runpod):** clips stay between the pod and this machine. The pod exposes
only SSH (port 22). ComfyUI is reached through an SSH tunnel, never through a public Runpod proxy
link. Terminate the pod when a session ends, which deletes its disks, and run `wipe` before that.

## The library

`~/invoke-remote-data/video/`, outside the game repo, because the export ships everything under
res://. Set `H3_LIBRARY` to use another folder.

| Path | What |
|---|---|
| `pod.json` | the current pod: `{"host", "port", "key", "pod_id"}` |
| `batches/*.json` | what to make (format in `h3.py`'s docstring) |
| `clips/<KEY>/<KEY>_<NNN>.mp4` + `.json` | each try, with its prompt, seed and settings |
| `sources/` | the pictures as uploaded, scaled to the canvas |
| `pending.json` | tries queued on the pod and not downloaded yet |
| `review.json` | your verdicts (keep / reject), the production star and notes |
| `pictures.json` | every picture with its game art file(s), clip names and clips with your verdicts; made by `h3.py pictures` |
| `plan.json` | per picture: what becomes of it, the clips picked (in order) and a note; made on the `/plan` page |
| `redo.json` | per picture reworked from its plan note: the note, the clips it was about, and what was tried (keys); read by the `/redo` page |
| `final/` | the picked clips copied under their game art names (`final/ashely_poker2/WIN_S1_TOP/03.mp4`) and `manifest.json`; made by `h3.py final` |
| `thumbs/` | the review page's small stills, made by `serve` with ffmpeg, and `game_art.npz`, the game art's fingerprints (all safe to delete) |

### Pictures

Every clip animates one picture, the batch job's `source`. A clip that starts on another clip's last
frame, a source named `<CLIP>_NNN_last.png` (extensions, continuations), counts as that clip's
picture. Loops, stitches and joins carry their base clip's picture.

Each picture is matched to its file(s) under `data/background_lists` by content. A picture staged
from a Downloads PNG is still found as, say, `ashely_poker2/WIN_X2_BREAST__DRESSED/06`. When the game
uses the same art in two slots, both are listed (`... = ...`). Look-alikes with only the expression
or a hand changed are separate pictures. The first match reads all the game art (about 90 s) and keeps
its fingerprints in `thumbs/game_art.npz`; later runs take seconds.

- `h3.py pictures` prints one line per picture: production, kept and clip counts, the game art name
  and the clip names. It also writes `pictures.json`.
- `h3.py pictures WIN_X2_BREAST__DRESSED/06` (or part of a clip name, like `M37`) lists every clip of
  the matching pictures with its verdict (`P` production, `K` keep, `x` reject) and your note.

### The plan: which clips go into the game

http://127.0.0.1:8771/plan (on `h3.py serve`) shows one section per picture: the original, its
★ production clips, then its kept clips (rejects are left out). For each picture, choose what becomes
of it:

| Decision | Meaning |
|---|---|
| Use as is | a picked clip goes into the game as it is |
| Combine | the picked clips, in pick order, become one longer clip or seamless loop |
| Make a loop | the picked clip becomes a seamless loop |
| New renders | nothing works yet; the note says what to try |
| No video | the picture stays a still |

Pick clips with **Pick** (or P while hovering); the order you pick in is the order they're used. The
note says how, e.g. "stitch #1 and #2 into one seamless loop". Stars and verdicts can be changed there
too. Everything saves to `plan.json` in the library; `h3.py plan` prints it by decision.

### Reworking from the notes: before / after

When plan notes ask for changes (a better loop, an extension, more tries), the new tries go into a round, and
`redo.json` in the library lists, per picture: your note, the clips it was about, and each thing tried with the clip
keys it made. http://127.0.0.1:8771/redo shows only those pictures: your note, **Before** (the original and the old
picks), then each try with its clips (made since the round started; placeholders for ones still rendering). Loops
show their biggest frame-to-frame step against the motion around it: "no jump" under 2.5x, red at 4x or more. Mark
each picture **Fixed / Better, not fixed / Not fixed** with a note, and Pick the clip(s) the game should use; both
save into the picture's `plan.json` entry (`redo_verdict`, `redo_note`, `clips`).

### The final cut

`h3.py final` copies every picture's picked clips to `<library>/final/<game art path>.mp4` (with several picks,
`_1`, `_2` ... in the order first picked; a pick keeps its name if you reorder, because the upscale and Theora are filed
under it) and writes `final/manifest.json`: per picture, its game art slot(s), decision, status
and files (frames, seconds, whether it's a seamless loop, and for a seam loop the base clip and `roll`, where the
loop starts in it). Status is `ready`, `review` (a `/redo` note without a verdict yet: its current picks are used),
`no decision`, `nothing picked` or `still`. Run it again after changing the plan; it copies only what changed and
removes files that are no longer picked. Encoding (SeedVR2 at art size, then Theora, see `docs/video/ENHANCE.md`)
starts from this folder.

## A session

1. **Create the pod.** Runpod template `dunz9ocpnc` ("One Click - ComfyUI MiniMax H3", image
   `hearmeman/comfyui-minimax-template:v10`, ComfyUI 0.42.1, torch 2.11 cu130) on an RTX PRO 6000
   (96 GB), secure cloud, $2.49/hr. Use:
   - `ports: ["22/tcp"]` only, and `startSsh: true`;
   - env `download_minimax_h3=false`;
   - a minimum of 96 GB RAM;
   - this start command, because the image doesn't start an SSH server itself:
     ```
     bash -c "(command -v sshd >/dev/null || (apt-get update -qq && apt-get install -y -qq --no-install-recommends openssh-server >/dev/null)); mkdir -p /run/sshd /root/.ssh && chmod 700 /root/.ssh && printf '%s\n' \"$PUBLIC_KEY\" > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && ssh-keygen -A && /usr/sbin/sshd -o PasswordAuthentication=no -o PermitRootLogin=prohibit-password; exec /start_script.sh"
     ```
   Your `~/.ssh/id_ed25519` is registered on the Runpod account.
2. **Add the pod to `pods.json`** in the library, under a name:
   `{"main": {"host": ..., "port": ..., "key": "~/.ssh/id_ed25519", "local_port": 18188, "pod_id": ...}}`.
   Use the pod's `ssh.direct` host and port, which change whenever the container restarts. Give each
   pod its own `local_port`. Every command takes `--pod NAME`; the default is `main`.
3. **`python -P -E h3.py --pod NAME setup`** takes about a minute:
   - It makes ComfyUI's `input` and `output` local folders. They're links into `/workspace`, which
     is network storage.
   - It downloads the models: about 85 GB in about 30 s.
4. **Run** (`-P -E` stops Python importing from the current folder):
   - `h3.py --pod NAME tunnel`: keep one running per pod.
   - `h3.py --pod NAME check`: the GPU, ComfyUI's version, the model files, and the H3 node's inputs.
   - `h3.py --pod NAME submit <batch.json> [--only KEY,PREFIX] [--front]`: queues the tries on that pod.
     Split a big batch across pods with `--only`. `--front` runs them next, ahead of the waiting queue
     (use it for redos from review notes).
   - `h3.py fetch --wait`: downloads finished tries from every pod. It stops once nothing is
     pending, so start it again after the next submit.
   - `h3.py join NAME clip clip ... [--fade 0.4]`: plays tries back to back into
     `clips/JOIN_NAME/`. For a chain, each clip's first frame is the last one's final frame, so it's
     dropped once. With `--fade`, separate shots crossfade.
   - `h3.py serve`: the review page at http://127.0.0.1:8771. Each card shows a still (the clip's
     middle frame), and only the last three clips you hovered load their video, which keeps the
     browser's memory down with hundreds of clips. Hover a clip to play it; press K to
     keep, R to reject; notes save as you type. The star (S) marks a clip production-ready: usable
     as is, a step above keep. Starring also keeps the clip, and un-keeping or rejecting it removes
     the star. In review.json a starred clip has `"production": true`.
     **By picture** puts every clip made from one picture in one section, under its game art name,
     to choose between them. By name, each section's blue link jumps there. **No ★ yet** shows only
     the sections without a production clip.
5. **End**: run `h3.py --pod NAME wipe`, then terminate the pod.

## Loops

The loop tools live in the library, in `looptest/scripts` (method and measurements:
`looptest/REPORT.md`). `LT_PORT` picks the pod's tunnel, and `LT_FRONT=1` queues the jobs first.

- `loops.py submit|publish <list.json>`: one seamless loop per kept clip. The clip's seam is
  regenerated with the turbo LoRA (about 95 s per 5 s clip), and the clip's own frames are kept
  everywhere else. The result is `clips/LOOP_<KEY>/`. A loop starts at the base clip's frame `roll`
  (in its json). To play the clip into its loop, play frames 0 to roll−1 first.
- `junctions.py submit|publish <spec.json>`: several clips of one still played as one long loop.
  Each junction (the end of one clip into the start of the next) is regenerated the same way.

What round 4 (2026-10-23) learned about loops:
- **Jumps come from the end of the regenerated window.** Inside it the model drifts away from the original frames, then
  snaps back to them in one or two frames where the window ends. Handing back over four latents (1 → 0.75 → 0.5 →
  0.25 → 0) instead of one helped some clips (the stroke loop went from 10x to 2.3x) and not others (M08 #2 still 14x).
  A longer window helps when the clip's end pose differs a lot from its start.
- `ana.jump_check(clip)` measures a loop's biggest frame-to-frame step against the motion around it (1-2x smooth,
  4x or more a visible jump). Round 4's loops record it in their json as `jump_check`.
- `repair.py LOOP_KEY_NNN ...` makes a copy of a loop that jumped, with the model's frames cross-fading into the
  original ones over the 12 frames before the snap; `repair.repair_stitch(spec, clip)` does it for a stitched loop.
  There's no jump, but two poses blend for half a second, so these are marked `"crossfade": true`: a fallback.
- When a clip ends far from where it starts, a **return segment** works better than a seam loop: an FL2VA render from
  the clip's last frame to its first, played after the clip. FL2VA lands near its anchor frames, not exactly on them,
  and came out about 2 levels darker, so `retfix.fitted()` colour-matches it and eases its ends into the clip.
- **Colour:** `compose.write` writes tagged BT.709, like ComfyUI's clips. When it wrote untagged BT.601, parts joined
  with original clips were tinted. `ana.frames` decodes with `accurate_rnd+full_chroma_int`, because swscale's default
  4:2:0 decode reads about 1.2 levels dark, which darkened every re-encoded part.

## Finishing for the game

Decided 2026-10-23; the reasons are in `docs/video/ENHANCE.md`. `finish.py` takes every clip `h3.py final` put in
`final/` into the game:
1. **On the pods:** upscaled 2× with SeedVR2 7B, then scaled to the art size (1152×1536). Clips over 250 frames go in
   parts. Every part sees 8 real frames on each side, so loop seams and part joins stay seamless: from the loop's
   other end, the neighbouring part, or the clip's first or last frame repeated.
2. **Intros:** every loop that starts partway into a clip also gets an intro, so it can start from the still. That's
   a seam loop (it starts at its base clip's frame `roll`) or a stitched loop (where its first segment starts). The
   intro is that clip's frames up to the loop's start.
3. **Here:** encoded to Theora q9 at 24 fps, converting BT.709 to BT.601. Godot 4.4 decodes Theora as BT.601.
   - There's one keyframe per file (`-g 512`). ffmpeg's default of one every 12 frames made calm shots pulse
     faintly twice a second.
   - The brightness is also corrected. SeedVR2's colour correction follows the frames VHS's loader decoded, which
     read about 1.4 levels dark. So each clip's luma is lifted back to its source's, a whole step measured per
     clip (+1 so far).
   - An intro is matched to its loop instead: its last frame to the loop's first.
   - An intro's last 8 frames also cross-fade into the loop file's own last 8 frames. Both show the same
     moments (just before the loop starts), but SeedVR2 draws fine detail a little differently in every job, so
     a cut from the intro's job to the loop's ticked. The intro now ends on the loop's own frame and hands over
     the way the loop wraps.
4. **Into the game:** written to `data/background_lists/<scene>/video/<slot>.ogv` (plus `<slot>_intro.ogv`), with
   `video/videos.gd` listing each picture's videos in pick order. The game plays a picture's first video; the others
   only come up with V in the editor. To change which plays, reorder the picks on `/plan`, then run `h3.py final` and
   `finish.py gamelist` (nothing is re-encoded).
   - `src/vn/Background.gd` plays a picture's first video over its still while it shows. A loop runs its intro,
     then loops until the picture changes. Any other video plays once and fades back to the still.
   - In a debug build, V cycles through a picture's videos, to compare them in game.
   - The test is `video_test` in `godot2/landscape-test`.
5. **Before / after:** `finish.py preview --wait` makes a browser copy of each game file. Browsers don't play
   Theora, so it's H.264, tagged with the BT.601 matrix Godot uses, so it looks as it will in game.
   - `h3.py serve`'s http://127.0.0.1:8771/finish compares each clip with its upscaled version: side by side, wipe
     (the mouse moves the line) or flip (F). Z zooms in where the mouse is, and `,` `.` step a frame.
   - Better / About the same / Worse save to `<library>/finish_review.json`. A clip marked worse can go into the
     game un-upscaled instead.

```
python -P -E finish.py plan fin1 fin2 fin3 fin4    # split the parts across the pods in pods.json
python -P -E finish.py upload fin1                 # then: finish.py submit fin1
python -P -E finish.py fetch --wait                # downloads to ~/Videos/ashely2_finish (FIN_WORK)
python -P -E finish.py encode --wait               # Theora into the game, as parts arrive (--again: redo all)
python -P -E finish.py status | sync               # progress; sync rebuilds the records from the pods' queues
```

The pods only need the SeedVR2 models, not H3's. Make `input`/`output` local folders as `h3.py setup` does, then
`hf download Comfy-Org/SeedVR2 diffusion_models/seedvr2_7b_fp16.safetensors vae/seedvr2_ema_vae_fp16.safetensors`.
On 2026-10-23 the cut was 105 clips plus 42 intros, 154 parts, 23,900 frames: about 1.9 s a frame, on 4 pods.

There's no interpolation.

## Settings that work

- **Canvas** 864×1152: the 1152×1536 art scaled by 0.75, which is under H3's size cap.
- **Length**: in steps of 17 frames, 5+17k: 124 = 5.2 s, 158 = 6.6 s, 243 = 10.1 s, at 24 fps.
- **Sampling**: `res_multistep`, `simple` schedule, 30 steps, no CFG (the model is CFG-distilled).
- **Speed** on the RTX PRO 6000: 7.5 s per step at 864×1152×124, so about 4.3 min per try,
  about $0.18.
- **Prompts** follow MiniMax's guide: the I2VA instruction line, then
  `integrated_multimodal_description`, `overall_soundscape` and `non_diegetic_music: N/A`. See
  `batches/b001_first_four.json` in the library. Keep the camera completely still, and use one slow
  motion. The man's head stays out of frame. Never mention her feet.
