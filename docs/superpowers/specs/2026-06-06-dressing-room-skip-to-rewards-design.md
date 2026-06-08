# Anna Dressing Room — Skip-to-Rewards Design

**Date:** 2026-06-06
**Status:** Approved for planning

## Problem

To see a reward script in the dressing room minigame, the player must try on 3
outfits (watching 3 intro scripts) before the favorite-pick phase unlocks, and
only **one** reward plays per run. To see other rewards they replay the whole
minigame and re-watch intros they've already seen. Players report this is
tedious.

## Goal

Let a returning player jump straight to the reward (favorite-pick) phase via a
button, restricted to outfits whose **intro they have already seen**. Seen
intros persist in the per-save file so the unlock survives across runs.

Per-run grind is intentionally preserved: skipping still yields **one** reward
then ends the scene (same as the normal ending). To see every reward the player
re-enters the minigame, but no longer re-watches intros.

## Decisions (from brainstorming)

- **Reward loop:** one reward per run, then `goodbye`. No reward-binge loop.
- **Button location:** on the outfit-selection hub (not the phone panel).
- **Storage:** per-save (`saveSaveData`/`loadSaveData`), not global persistent.
- **Skip lead-in:** dedicated new script (`skip_lead_in.txt`), not a reuse of
  `pick_favorite`.
- **Button visibility:** shown on every outfit-selection (trying-phase) hub when
  the player has at least one seen intro; hidden during the favorite-pick hub.
  (Also the simpler implementation.)

## Components & Changes

### A. `GlobalGameStage.gd` — persistence

- New field near `annaDressingRoomTranscript`:
  ```gdscript
  var annaDressingRoomSeenIntros : Array[String] = []
  ```
  This accumulates across runs and is **not** reset between sessions (unlike the
  transcript).
- Helpers:
  ```gdscript
  func recordAnnaDressingRoomIntroSeen(outfitName: String):
      if outfitName not in annaDressingRoomSeenIntros:
          annaDressingRoomSeenIntros.append(outfitName)

  func hasSeenAnnaDressingRoomIntros() -> bool:
      return annaDressingRoomSeenIntros.size() > 0

  func getAnnaDressingRoomSeenIntros() -> Array:
      return annaDressingRoomSeenIntros
  ```
- `saveSaveData`: append `file.store_var(annaDressingRoomSeenIntros)` at the very
  end (after `randomizeWallpaper`).
- `loadSaveData`: read at the end, guarded by the new version, using `.assign`
  for the typed array:
  ```gdscript
  if (saveVersion > 016):
      annaDressingRoomSeenIntros.assign(file.get_var())
  else:
      annaDressingRoomSeenIntros = []
  ```
- Bump `const VERSION = 016` → `017`. (Single global counter shared with
  `persistent.dat`; the existing `> 015` guard for `anaMusicVideoCompleted` still
  holds since `017 > 015`.)

**Save timing — no new plumbing.** Completing the anna_night phone conversation
calls `messages_app.onComplete` → `Main._on_phone_conversation_complete` →
`GlobalGameStage.setPhoneGameStage()` → `advanceGameStage()` →
`saveSaveData("user://autosave.dat")`. Because the minigame writes seen intros
into `GlobalGameStage` memory while it runs, that autosave persists them.
Trade-off: quitting mid-minigame (before the closing texts) loses that run's
unlocks. Acceptable given the "keep a little grind" decision.

### B. `anna_dressing_room.gd` — recording, reward pool, skip handler

1. **Record on intro completion.** In `_on_script_finished`, the existing
   `elif script_name.ends_with("_intro")` branch (which `hub_intro` never reaches,
   since it is matched earlier) records the outfit before its existing logic:
   ```gdscript
   GlobalGameStage.recordAnnaDressingRoomIntroSeen(script_name.trim_suffix("_intro"))
   ```

2. **Shared reward pool.** New field `var reward_outfit_pool: Array[String] = []`.
   - Normal end-game path: before `play_script("pick_favorite")` (in the `_intro`
     branch when `tried_outfits.size() >= MAX_OUTFITS_TO_TRY`), set
     `reward_outfit_pool = tried_outfits.duplicate()`.
   - The `pick_favorite` branch restricts using the pool instead of
     `tried_outfits`: `hub.restrict_to_outfits(reward_outfit_pool)`.
   - Factor the favorite-pick-hub entry into a small helper, e.g.
     `_enter_reward_hub()`, reused by both `pick_favorite` and `skip_lead_in`
     completion branches:
     ```gdscript
     func _enter_reward_hub() -> void:
         picking_favorite = true
         hub.restrict_to_outfits(reward_outfit_pool)
         await _enter_hub()
     ```

3. **Skip handler.** New `_on_skip_to_rewards()` connected to the hub signal:
   ```gdscript
   func _on_skip_to_rewards() -> void:
       reward_outfit_pool = GlobalGameStage.getAnnaDressingRoomSeenIntros().duplicate()
       await _exit_hub()
       play_script("skip_lead_in")
   ```
   New branch in `_on_script_finished`:
   ```gdscript
   elif script_name == "skip_lead_in":
       await _enter_reward_hub()
   ```

4. **Skip button visibility.** Whether the shortcut is offered is snapshotted
   ONCE at `_ready` into a `skip_available` field, *before* this run records any
   of its own intros:
   ```gdscript
   skip_available = GlobalGameStage.hasSeenAnnaDressingRoomIntros()
   ```
   `_enter_hub` then uses the snapshot (not a live re-check), so the button never
   appears partway through a first playthrough:
   ```gdscript
   hub.set_skip_button_visible(not picking_favorite and skip_available)
   ```
   Because seen-intros only persist after a *full* run (saved on Back-press after
   the whole anna_night conversation, which is only reached once the minigame hits
   `goodbye`), this enforces "play through the full thing at least once before you
   can skip." Connect the hub signal in `_build_hub`:
   `hub.skip_to_rewards_requested.connect(_on_skip_to_rewards)`.

### C. `anna_dressing_room_hub.tscn` + `.gd` — the button

- Add a fixed-position `Button` named e.g. `SkipToRewards` as a direct child of
  `Hub` (a sibling of `LeftArrow`/`RightArrow`, so it does not pan with the
  outfits). Top-center placement, text "Skip to Rewards", hidden by default.
- `anna_dressing_room_hub.gd`:
  - `signal skip_to_rewards_requested`
  - In `_ready`, connect `%SkipToRewards.pressed` to emit the signal (Button +
    `pressed` signal, per project convention — no `_input` handling).
  - `func set_skip_button_visible(v: bool) -> void: %SkipToRewards.visible = v`

### D. New script `data/scripts/anna_dressing_room/skip_lead_in.txt`

A short lead-in tailored to jumping straight to rewards, matching Anna's casual
texting voice. Ends with a player line so the next step (entering the gated
reward hub) flows naturally. Draft:
```
# Plays when the player taps "Skip to Rewards" — jumps straight to picking a
# reward outfit from those whose intro the player has already seen.
pos: bl
a: back so soon?
a: ok, which one do you want to see again?
p: let me pick...
```

## Flow

**Normal (unchanged):** `hub_intro` → hub → pick → `{outfit}_intro` (records
seen) → … (×3) → `pick_favorite` → gated hub (pool = tried) → pick → favorite
line → `{outfit}_reward` → `goodbye`.

**Skip:** enter dressing room → `hub_intro` → hub (skip button visible if seen
intros exist) → **Skip to Rewards** → `skip_lead_in` → gated hub (pool = seen
intros) → pick → favorite line → `{outfit}_reward` → `goodbye`.

## Edge cases / notes

- `hub_intro` is matched before the `_intro` suffix branch, so it is never
  recorded as a seen outfit.
- Hidden hub outfits (`workout`, `swim`, `punk` are `visible=false`) can't have
  their intros seen, so they never enter the seen-intros set; even if present
  they'd stay non-interactable. No special handling needed.
- After a skip reward → `goodbye`; no return to the hub, consistent with the
  one-reward-per-run rule.
- `script_name` for the lead-in deliberately avoids the `_reward` and `_intro`
  suffixes so it isn't swallowed by those branches.

## Out of scope

- Reward-binge loop (multiple rewards per run).
- A skip button on the phone texting panel.
- Global (cross-save) persistence / gallery.
