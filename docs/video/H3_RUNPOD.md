# Video clips with MiniMax H3 on Runpod

Research from 2026-10-20, for short, looping, mostly static-camera clips in Ashely II (the
"live wallpaper" kind: one gentle motion, looped as a background). Six researchers plus a critic
went through the model, Civitai, Runpod, looping, Theora and this game's video code. Claude then
checked the claims that could be checked locally. Each fact below says whether it was **checked**
(measured or read at the source) or is an **estimate**. None of this is legal advice.

## The short version

- **H3 is the right model.** It is where the NSFW video community is building (872 H3 LoRAs on
  Civitai since August, against a handful of new Wan 2.2 ones), it runs at 24 fps, and it has a
  first-and-last-frame mode, which is what loops need.
- **Your two good clips used the plain base model.** Civitai model 2821932 is Civitai's own mirror
  of the open H3 weights, not an NSFW finetune. The same files are free on Hugging Face, with no
  token, so a Runpod setup can reproduce them exactly.
- **Two things to settle before spending money**, neither of them technical: H3's licence
  excludes the US, the EU, the UK and South Korea, and Runpod's terms list adult content as not
  allowed. Both are below.
- **On Runpod, use a pod, not serverless**: an RTX PRO 6000 (96 GB) at $2.49/hr, with ComfyUI.
  Queue a batch of tries, look at them, queue the next. An estimated $0.06–0.15 per 5-second try.
- **Loops**: first try giving H3 the same still as its first *and* last frame. Nobody has measured
  whether that loops cleanly or stalls at the ends, so test it first. There are fallbacks below,
  including your two-clip splice with tested commands.
- **Your local ffmpeg makes broken Theora files** (checked: Godot shows garbage frames). A newer
  ffmpeg fixes it (checked in Godot 4.4.1). Your converter site works, so this only matters if you
  want to convert locally.
- **The game can't loop a clip yet.** Its video code plays a clip once for 5.5 s and fades it out,
  and it finds clips through a hard-coded list of picture names. Looping backgrounds need a small
  code change.

## Settle these first

### H3's licence

Read from the licence file (huggingface.co/MiniMaxAI/MiniMax-H3, `LICENSE`, dated 2026-08-02):
- The grant is "Solely within the Applicable Territory", which excludes the **US, EU, UK and South
  Korea**.
- Section V.4 also bars using or displaying the **Outputs** outside that territory. Clips in a game
  sold to US or EU players would be outputs displayed there.
- Commercial products must show "MiniMax H3" in their interface.
- Disputes go under Hong Kong law.

It has no clause against adult content. The licence doesn't say whether "territory" means where
you live, where the GPU is, or where the clip is shown.

**Civitai is different.** Civitai has its own agreement with MiniMax. Its site notice (Civitai
GitHub PR #5010, merged 2026-09-21) says "Generation, training and LoRA distribution on Civitai are
covered by Civitai's own license agreement with MiniMax. If you download these weights and run them
yourself, your use is instead governed by the MiniMax H3 Community License". That agreement isn't
public, so whether it covers selling a game with the clips in it is unknown.

Other routes, if you need them:
- MiniMax takes applications from organizations in the excluded regions (platform.minimax.io/h3-license).
- Comfy sells a licence from $5,000/month.
- Wan 2.2 is Apache 2.0, with no territory limit (see Alternatives).

**This is the decision that matters most.** If you or your players are in those four regions,
self-hosting H3 isn't covered by the free licence, whichever data center runs it.

### Runpod's terms

Runpod's Terms of Service (updated 2026-03-24), section 6, list "pornography or graphic adult
content, images, or other adult products" as unauthorized Content: "Postings of any unauthorized
products or content may result in immediate termination of your account and a lifetime ban."

What cuts the other way:
- The wording is about content posted on or made available through the service.
- Section 7 says Runpod "will not actively monitor Content".
- Runpod's own Hub lists uncensored H3 workers.
- No report of a ban for private generation turned up.

So there is a real but unmeasured risk of losing the account. Runpod support can give a written
answer if you want certainty.

## What your two clips tell us

Read from the ComfyUI workflow saved inside each file:

| | `P49XGK…` (the generation) | `6CYC6J…` (a second pass) |
|---|---|---|
| Made with | Civitai's generator, the H3 base weights (`minimaxh3/civitai/2821932/3216500`, the full 66.28 GB bf16 file, matched by size) | VFIMamba 2× frame interpolation |
| Node | `MiniMaxH3ImageToVideo` with a first **and** a last frame | |
| Text encoder | `qwen3vl_32b_minimax_h3_nvfp4_awq` | |
| Size and length | 960×704, 243 frames (10.1 s), 24 fps, with audio | 485 frames at 48 fps |
| Sampling | `res_multistep`, `simple`, 30 steps, no CFG (the model is CFG-distilled) | |

- **No flicker (checked):** ComfyUI has an open bug (#15426) where H3 clips pulse in brightness
  every 17 frames. Both of your clips are clean: no 17-frame window is more than 0.1 brightness
  levels (out of 255) off its neighbours.
- **Wrong shape for this scene:** 960×704 is landscape. Ashely II is portrait, so render 3:4:
  **768×1024**, or 864×1152 for finals. Both are multiples of 32, and both are the 1152×1536
  stills scaled down.
- **Prompt:** your prompt used the guide's I2VA (first frame only) instruction line, but the
  workflow also gave a last frame. The FL2VA line (below) is the one meant for that.
- **Steps:** 30 steps is more than the official default. ComfyUI's template uses 20 and says 12–16
  is often enough for simple shots.

## Where to run it

Live Runpod reads on 2026-10-20. Every per-clip cost is an **estimate**: nobody has measured H3 at
these settings on these cards, so the first session should measure it.

| Option | Price | Per 5 s try (estimate) | Good for |
|---|---|---|---|
| **Runpod pod, RTX PRO 6000 96 GB** | $2.49/hr secure (stock: medium); $1.69/hr community (none free at the time) | about $0.15 at 20 steps, $0.06 with the 8-step turbo LoRA, while the card is kept busy | Many tries, reviewed in batches. **Recommended.** |
| Runpod pod, H100 SXM 80 GB | $3.99/hr secure | probably faster per step, but 60% dearer | Only if the PRO 6000 turns out slow |
| Runpod serverless, same card | $3.49/hr while running | the same, plus several billed minutes loading about 90 GB of weights on each cold start | Scripted batches later |
| Civitai's generator | 35 Buzz/s standard, 12 turbo, **half price until Fri 2026-10-23**; about double after (estimate) | about $0.18 / $0.06 now; $0.35 / $0.12 after (if 1,000 Buzz ≈ $1) | A cheap first test, and it's what you already use |

- **Civitai payment:** NSFW on Civitai needs Yellow Buzz, bought on civitai.red with crypto. Its
  exchange rate wasn't readable, so treat Civitai's dollar figures as rough.
- **What a pod costs in practice:** you pay for review time and boot time too. A 2-hour session is
  about $5. That beats Civitai only if you keep the card busy by queuing batches.
- **Not an option:** Runpod's pay-per-use video endpoints (Wan, Seedance, Kling, Sora, Veo) are
  managed APIs, and none of them is H3.

## The Runpod pod recipe

1. **Template.** Two public pod templates, both checked:
   - `dunz9ocpnc` "One Click - ComfyUI MiniMax H3" (image `hearmeman/comfyui-minimax-template:v10`).
     It downloads H3 when it boots (`download_minimax_h3=true`). Put Civitai LoRA IDs in
     `CIVITAI_LORAS`, with a `civitai_token`. It has 250 GB of container disk plus a 250 GB volume.
     This is the easy start.
   - `wgd3p4n4o6` "ComfyUI - CUDA 13.0", Runpod's official one (image
     `runpod/comfyui:1.3.3-comfyuiv0.30.0-cuda13.0`). Its ComfyUI 0.30.0 is the first with H3, so
     update to 0.42.x. Then download the files yourself (step 3).
2. **Card:** RTX PRO 6000, secure cloud, on a CUDA 13 host. Before deploying, check the pod's
   system RAM on the deploy page. Plan on at least 64 GB for the int8 files and 96–128 GB for the
   bf16 one. RAM, not VRAM, is the usual limit, because ComfyUI streams weights.
3. **Files** (Hugging Face `Comfy-Org/MiniMax-H3`; free, no token):

   | File | Size | Note |
   |---|---|---|
   | `diffusion_models/minimax_h3_fl2va_bf16.safetensors` | 66.28 GB | What your Civitai clips used |
   | `diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors` | 20.97 GB | What ComfyUI's own template uses; faster, needs PyTorch cu130 |
   | `text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` | 15.69 GB | Works on any NVIDIA card |
   | `vae/minimax_h3_video_vae_fp16.safetensors` | 5.21 GB | |
   | `vae/minimax_h3_audio_vae_fp32.safetensors` | 0.61 GB | |
   | the FL2V 8-step turbo LoRA (`loras/`) | 1.96 GB | Drafts only: people report a plastic look and weaker anatomy |

   Command: `HF_XET_HIGH_PERFORMANCE=1 hf download Comfy-Org/MiniMax-H3 <files> --local-dir <ComfyUI>/models`.
   Start with bf16 so the first clips match what you already know works, then try int8 for speed.
   One caveat: LoRAs trained on the full model may lose part of their effect on the pruned files.
4. **Workflow:** ComfyUI's built-in template `video_minimax_h3_i2v`.
   - Set the canvas to 768×1024 and the length to 124 frames (5.2 s) or 243 (10.1 s).
   - Use 20 steps; the sampler and scheduler are already right.
   - Give it the game still, scaled to the canvas, as the first frame (and the last, for loops).
5. **Run in batches:** queue several seeds or prompt variations, look at them, queue the next.
   The models stay loaded between runs.
6. **Privacy:** anyone with the pod's proxy link (port 8188) can use ComfyUI, with no login. Don't
   share it. Download results through the file browser on 8888, or with `runpodctl receive`.
7. **Terminate the pod when you're done.** A stopped pod still bills its volume disk.
   - Re-downloading 40–90 GB each session takes minutes.
   - A network volume keeps the files for about $7 a month per 100 GB, but ties you to one data
     center, and PRO 6000 stock moves around.
   - Start without one, and add one if sessions become routine.

**Later, for unattended batches:** the serverless worker `huchukato/runpod-minimax-h3` (v1.1.3,
released 2026-10-20). It needs a 96 GB card and a network volume of at least 160 GB, and downloads
about 100 GB on its first boot. It includes first-and-last-frame video, turbo LoRAs and RIFE
interpolation.

## Making loops

Make the canvas exactly the still's shape (768×1024 for 3:4). The H3 node stretches the first frame
but centre-crops the last, so a mismatched shape gives two different anchors and a visible jump at
the seam.

Try these in order:

1. **One clip, the same still at both ends** (FL2VA). Cheapest: one generation per try.
   - One community workflow (Civitai 2843813) says it loops cleanly.
   - A node pack says these clips "almost always end in a locked, barely-moving tail".
   - So test 5–10 seeds. Cut any frozen tail, and drop the last frame (it repeats the first).
2. **Two clips through a middle pose:** still I → pose J, then J → I. Make J in InvokeAI from the
   same still (for example, the hand mid-squeeze), so both seams land on stills you control and
   nothing plays in reverse. Join them, dropping the second clip's duplicate first and last frames
   (N2 = the second clip's frame count):
   ```
   ffmpeg -i IJ.mp4 -i JI.mp4 -filter_complex "[0:v]settb=AVTB,fps=24,format=yuv420p[c1];[1:v]settb=AVTB,fps=24,format=yuv420p,trim=start_frame=1:end_frame=<N2-1>,setpts=PTS-STARTPTS[c2];[c1][c2]concat=n=2:v=1:a=0[v]" -map "[v]" -an -c:v ffv1 loop.mkv
   ```
3. **Your current splice, A → B → A**, with a 0.5 s crossfade at both joins and no raw cut at the
   loop point. LA and LB are the clip lengths in seconds:
   ```
   ffmpeg -i A.mp4 -i B.mp4 -filter_complex "[0:v]settb=AVTB,fps=24,format=yuv420p,split[a1][a2];[1:v]settb=AVTB,fps=24,format=yuv420p[b];[a1]trim=start_frame=12,setpts=PTS-STARTPTS[abody];[a2]trim=end_frame=12,setpts=PTS-STARTPTS[ahead];[abody][b]xfade=transition=fade:duration=0.5:offset=<LA-1.0>[ab];[ab][ahead]xfade=transition=fade:duration=0.5:offset=<LA+LB-1.5>[v]" -map "[v]" -an -c:v ffv1 loop.mkv
   ```
   Put the crossfades where the motion is slow; a crossfade between two different motions looks
   like a double exposure.
4. **One clip, rotated and crossfaded into itself.** For a clip that almost loops. Output length is
   L − 0.5 s:
   ```
   ffmpeg -i clip.mp4 -filter_complex "[0:v]settb=AVTB,fps=24,format=yuv420p,split[m][h];[h]trim=end_frame=12,setpts=PTS-STARTPTS[head];[m]trim=start_frame=12,setpts=PTS-STARTPTS[body];[body][head]xfade=transition=fade:duration=0.5:offset=<L-1.0>[v]" -map "[v]" -an -c:v ffv1 loop.mkv
   ```
5. **Ping-pong** (forward then backward). Only for symmetric motion like a squeeze and release, or
   breathing. N is the frame count:
   ```
   ffmpeg -i clip.mp4 -filter_complex "[0:v]format=yuv420p,split[f][r];[r]reverse,trim=start_frame=1:end_frame=<N-1>,setpts=PTS-STARTPTS[rv];[f][rv]concat=n=2:v=1:a=0[v]" -map "[v]" -an -c:v ffv1 loop.mkv
   ```

A researcher tested these commands for exact frame counts. They only filter, so your current
ffmpeg runs them fine. Only its Theora encoding is broken. An untested idea for later: H3's
`MiniMaxH3AddGuide` node can pin a short run of frames anywhere in a clip, so a bridge clip could
carry the motion itself across the seam.

**LoRAs worth trying for the squeeze shot** (on Civitai, usable on its generator too):
- "Breast Play & Jiggle for MiniMax H3": v2 is first-and-last-frame; use strength 0.7–0.8, since
  higher adds finger artifacts.
- "Boob Physics": its author says base H3 is "severely lacking in touching and squeezing physics".
- "Live Wallpaper Style" (H3 Ref2VA version): a locked-off camera and subtle motion.

## Prompts

The guide's structure (`docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md`). For a loop, Picture 2 is the
same still as Picture 1. The time is the clip length to two decimals: 124 frames ÷ 24 = 5.17,
243 ÷ 24 = 10.13.

```text
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 1) aligns with the 5.17-second mark of the target video.

integrated_multimodal_description: [Shot 1] <style, taken from the still>, a static shot. The shot begins in the position and framing established by Picture 1. <The one motion: what moves, how far, how slowly, and that it eases back.> Everything else holds still: her pose, the background and the light. By the end of the shot everything settles back into the pose, spacing and composition established by Picture 2.

overall_soundscape: <one or two sentences of quiet ambient sound, or the soundscape you want>

non_diegetic_music: N/A
```

- **Describe the path, not the two pictures:** the guide says the body of an FL2VA prompt should
  describe how the clip gets from one picture to the other.
- **Camera:** "static shot" is the guide's term for a fixed camera; "POV" is also a camera type.
- **Style:** the guide says to take the style from the reference image. Your prompt said
  "Live-action, cinematic" over drawn art, so compare it against "2D-animated" in the first test.
- **Your still prompts' rule applies here too:** name only what should be in frame. See
  invoke-remote-tool's `specs/story/ashely-poker2/DIRECTION.md`.

## Into Godot

**The encoder (checked).** Your `C:\Users\samwo\Videos\ffmpeg.exe` (a gyan.dev build from
2025-05-15) writes broken Theora:
- Its files decode with "error in unpack_block_qpis".
- Godot 4.4.1 shows garbage frames at quality 7, 8 and in bitrate mode. Even at quality 10, 1 of
  19 sampled frames was wrong, and the file was 24.7 MB for 10 s.
- The cause is an FFmpeg regression on 64-bit Windows (FFmpeg issue #20185).

The newer BtbN ffmpeg n9.0.2 (2026-10-20) is clean. Godot 4.4.1 played every sampled frame of your
clip within 32–34 dB of the source, with no errors:

| Quality | Size per second of video (your 960×704 clip) |
|---|---|
| q6 | 123 KiB |
| q7 | 182 KiB (1.9 MB for 10 s) |
| q8 | 247 KiB |

```
ffmpeg -i loop.mkv -vf format=yuv420p -c:v libtheora -q:v 7 -g:v 240 -an loop.ogv
ffmpeg -v error -i loop.ogv -f null -      (prints nothing on a good file)
```

- `format=yuv420p` matters: without it an RGB source becomes 4:4:4, 2.6× bigger.
- A long keyframe gap (`-g 240`) keeps subtle loops small.
- Leave the audio out (`-an`): the background video player ignores the game's volume setting.
- Keep both sides a multiple of 16, because Godot 4.4.1 shifts colours on some other sizes (#106311).
- Plain upscaling before encoding adds no detail. An AI restore does: the production clips get SeedVR2 7B at
  1152×1536, and stay at 24 fps (decided 2026-10-23, `ENHANCE.md`).
- Godot 4.4 decodes Theora as BT.601 whatever the file says, so convert BT.709 sources (`ENHANCE.md`).

A copy of that ffmpeg is in this session's scratchpad, which is temporary. Install a current BtbN
or gyan.dev build for real, and run the check line on its output once before trusting it.

**The game (read from the code).**
- **How video plays today:** one `VideoStreamPlayer` in `src/vn/Background.tscn`. `checkForVideo()`
  (`Background.gd:200`) maps hard-coded picture names to `.ogv` files. It runs only at the black
  point of a `fade_next`, plays the clip for 5.5 s (`fadeVideo`, `Background.gd:179`), fades it
  out, and never loops. `video_pause` hides the dialogue box for 6 s (`Main.gd:568`).
- **A looping background needs code.** A proposal: a clip sits beside its picture with the same
  name (`WIN_X2_BREAST__TOP_OFF/05.ogv` beside `05.webp`) and plays on a loop whenever that
  picture shows, stopping when the picture changes. The art packager leaves `.ogv` files alone and
  keeps slot paths, so that's sturdier than picture names.
- **Godot 4.4.1 loops by reopening the file:** about an 11 ms hitch at each restart (measured
  headless). Godot 4.5 loops by seeking to the start instead, which is smoother. Put a loop's seam
  where motion is slow.
- **Quick skip** passes a clip's line without starting it, so the clip won't be playing when
  skipping stops.

## Alternatives

- **Wan 2.2 I2V** (Apache 2.0) is the clean fallback if the H3 licence rules it out.
  - It has a mature NSFW LoRA scene and a first-and-last-frame mode in ComfyUI.
  - It is much faster: seconds per clip with its 4-step builds.
  - It is native 16 fps and about 5 s, so it needs frame interpolation, and its motion is less
    natural than H3's.
  - It runs in the same ComfyUI pod, so one session can compare both on the same still.
- **Not suited to this job:**
  - LTX-2.5: few NSFW LoRAs.
  - HunyuanVideo 1.5 and Kandinsky 6: no first-and-last-frame mode.
  - Wan 2.5 and later: API-only.

## What the first session should measure

1. Minutes per clip at 768×1024, 124 and 243 frames, 20 steps and turbo 8, bf16 and int8. These
   numbers turn every estimate above into a cost.
2. The same still at both ends: does it loop, or stall? Use 5–10 seeds, and check the
   frame-to-frame difference near the end.
3. How many tries a usable clip takes. No source publishes a success rate, so the cost per
   *usable* clip is still unknown.
4. Whether a squeeze LoRA helps, at a fixed seed.
5. One finished loop in the game at 24 fps (and 48, interpolated), to see the seam and the 4.4.1
   restart hitch.

## Sources

Every researcher's facts, each with its source and confidence, plus the critic's notes:
`research_2026-10-20.json` beside this file. The main sources:
- huggingface.co/MiniMaxAI/MiniMax-H3: model card, `LICENSE`, `docs/QA-about-License.md`, and
  `docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md`.
- huggingface.co/Comfy-Org/MiniMax-H3: file sizes from the API tree.
- ComfyUI PR #15224 (native H3, v0.30.0) and issue #15426 (the 17-frame pulse).
- github.com/Comfy-Org/workflow_templates: `video_minimax_h3_i2v.json`.
- Civitai: API for model 2821932; article 35315 (the half-price offer); civitai/civitai PRs #5010 and #6023.
- runpod.io/legal/terms-of-service; the Runpod MCP reads of GPU prices, stock, templates and Hub repos (2026-10-20).
- FFmpeg issue #20185; Godot PR #102360 and issue #106311.
