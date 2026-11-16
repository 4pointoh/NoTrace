# Finishing the clips: upscaling, frame rate, colour

Decided 2026-10-23, after a test on 5 production loops and your blind test of the results. The method, every
measurement and the viewer are in the library: `~/invoke-remote-data/video/enhance/` (`REPORT.md`; `judge.bat`
runs the blind test again, `browse.bat` shows every version with its name).

## The decision

- **Upscale every clip in the production cut with SeedVR2 7B, at the art size (1152×1536).**
  - In the blind test SeedVR2 won all 5 sharpness sets, against both the original and a plain sharpen filter.
  - The art size won 4 of them; SeedVR2 kept at 864×1152 won 1.
  - It gives crisper line work, eyes and hair, closer to the art. Expressions stay the same, and loops stay seamless.
- **Stay at 24 fps.** In the blind test you couldn't tell 24 from 48 or 60 fps (FILM interpolation) on any of
  the 5 clips, and interpolation costs 1.7–2× the file size.
- **Convert BT.709 clips to BT.601 when encoding Theora.** Godot 4.4 decodes Theora with the BT.601 matrix whatever
  the file says (checked with colour patches). Clips saved by ComfyUI are BT.709, so in game their greens come
  out brighter and their reds deeper. Loops made with plain ffmpeg are BT.601 already.

## What it costs (checked)

Theora q9, Godot 4.4.1 on this laptop (Ryzen AI 9 HX 370). Decode is per video frame, on the main thread.

| Version | File size vs the original | Decode per frame |
|---|---|---|
| Original, 864×1152 | 1× | 2.4 ms |
| SeedVR2, 864×1152 | 1.1–1.25× | 2.6 ms |
| **SeedVR2, 1152×1536 (chosen)** | **1.6–1.8×** | **4.6 ms** |
| SeedVR2, 1728×2304 | 3–3.4× | 10.3 ms, spikes to 28 ms (too heavy) |
| FILM 48 / 60 fps | 1.7× / 1.8–2× | about 2 ms, but 2–2.5× as often |

- A frame at 60 Hz has 16.7 ms, so 4.6 ms leaves room. The 2× version would stutter on slower CPUs.
- On a 1080p screen Godot shows the clip about 1080 px tall, so those players get little more from the art size
  than from SeedVR2 at 864×1152. The gain shows on 1440p and taller screens (you judged on 2560×1600).
- Theora q9 is 45–47 dB from its source (SSIM 0.99), so the encode isn't what limits quality.

Rejected:
- **SeedVR2 7B sharp:** twice the flicker in still areas.
- **SeedVR2 3B:** harsher and less faithful.
- **Real-ESRGAN anime video:** flattens the painted shading.
- **H3's latent upscaler:** soft, and it breaks the loop seam.
- **ffmpeg CAS sharpen:** lost every blind set.
- **RIFE:** FILM beat it by 2.6–4.6 dB on moving pixels.

## The production process

Run this once the production cut is picked on the `/plan` page (`plan.json`). `tooling/video_gen/finish.py`
does steps 2 and 3 for every clip `h3.py final` put in `final/`, and puts them in the game (its README section
"Finishing for the game"). It scales to the art size on the pod, so only art-size files come back.

1. **Finish each clip first** at 864×1152, 24 fps: loops, combines and joins. Upscaling comes last, just before
   encoding.
2. **Upscale 2× (1728×2304) on the pod** with SeedVR2 7B. It runs in ComfyUI's native nodes on the same H3
   template. The graph is the `svr7b` variant in `enhance/scripts/enhance.py`:
   - The models are `seedvr2_7b_fp16` and `vae/seedvr2_ema_vae_fp16`, from Hugging Face `Comfy-Org/SeedVR2`.
   - Load clips with `VHS_LoadVideoFFmpeg`. `VHS_LoadVideo` (OpenCV) darkens them by about 1.2/255. Measured with
     an accurate decode, the ffmpeg loader's output still comes back about 1.4 levels dark (the first test
     compared with the same biased decoder, so it didn't show), and SeedVR2's colour correction follows it:
     `finish.py` lifts each clip's luma back to its source's when it encodes.
   - Use VAE tiles of 1024. The template's 512 is about 1.5× slower.
   - For a loop, SeedVR2 sees 8 frames from the other end on each side; they're cut off afterwards. That keeps the
     seam seamless.
   - **Estimate:** about 2.1 s a frame on an RTX PRO 6000 ($2.49/hr), mostly the VAE decode. A 5 s loop takes
     about 4.5 min ($0.19) and a 10 s one about 8.5 min.
3. **Encode to Theora**, scaling to 1152×1536 in the same pass:
   ```
   ffmpeg -i clip_2x.mp4 -vf "colorspace=space=bt470bg:ispace=bt709:range=tv:irange=tv:primaries=bt709:iprimaries=bt709:trc=bt709:itrc=bt709,scale=1152:1536:flags=lanczos" -an -c:v libtheora -q:v 9 clip.ogv
   ffmpeg -v error -i clip.ogv -f null -      (prints nothing on a good file)
   ```
   - The `colorspace=` part is only for BT.709 sources, which ffprobe's `color_space` reports as `bt709`.
     SeedVR2's output is BT.709, because ComfyUI saves it.
   - The conversion matches a direct BT.601 encode within 1/255.
   - Use the BtbN ffmpeg: the old gyan.dev build writes broken Theora (`H3_RUNPOD.md`).
   - `enhance/scripts/build_compare.py` does this step for the test clips.

## Still open

- **Loop wraps after SeedVR2.** Each loop is upscaled in one job, padded at each end with 8 frames from its other
  end, but the job draws its last and its first frames' fine detail a little differently.
  - On the stillest loops the wrap step (mean change over the frame) went from 0.2-0.6 levels to 0.6-0.8. That's
    about the clip's own biggest natural frame change, or up to 1.4x it (L4_KISS 09 and 49).
  - A fix would upscale just the wrap again, as its own short job with the wrap in the middle (about 80 frames per
    loop), and cross-fade the loop's ends into it: about 4,000 frames, roughly $6 on 4 pods.
  - Not done yet; it waits on whether it shows in game.
- **The library's comparison viewer** (`compare/build.py`) encodes without the colour conversion.

Done on 2026-10-23:
- **Intro hand-overs.** An intro and its loop are upscaled in separate jobs, so the cut from one to the other ticked
  (0.6-1.4 levels, against the source's 0.1). `finish.py` now cross-fades an intro's last 8 frames into the loop
  file's own last 8 (the same moments), so the hand-over is the loop's own wrap step.
- **The keyframe gap.** With ffmpeg's default, Theora puts a keyframe every 12 frames. Each one refreshes the fine
  detail that the frames between hold still, which on calm shots makes a faint pulse twice a second.
  - The step into a keyframe was about 0.4 levels larger than the upscale's own, which is about 6x the median step of
    a very still loop.
  - `finish.py` now encodes with `-g 512`: one keyframe per file. libtheora caps the spacing at the power of two at
    or below `-g`, so `-g 240` still gave keyframes at 240 and 480 in the 486-frame loops.
  - The pulse is gone (the step into a keyframe went from +0.4 to about 0), and calm clips are half the size or less.
    The difference from the upscaled frames grows by only 0.05 levels.
- **The production script:** `tooling/video_gen/finish.py`.
- **Clips that play once:** they get their first and last frames repeated as SeedVR2's padding. Long clips go in
  parts of up to 250 frames, each padded with its neighbours' real frames.
- **The cost of the whole cut:**
  - The cut was 105 clips, plus 42 intros (each loop's run-in from the still), 23,900 frames with padding.
  - It ran at about 1.9 s a frame on 4 RTX PRO 6000s, about 3.5 h and $35.
