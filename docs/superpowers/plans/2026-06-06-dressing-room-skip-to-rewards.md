# Dressing Room Skip-to-Rewards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Skip to Rewards" button to Anna's dressing-room minigame that jumps straight to the favorite-pick (reward) phase, restricted to outfits whose intro the player has already seen, with seen-intros persisted in the per-save file.

**Architecture:** Persist a per-save `Array[String]` of seen intro outfit names in `GlobalGameStage`. The minigame records an outfit when its `*_intro` script completes. A new hub button emits a signal; the controller funnels both the normal end-game favorite-pick and the skip into one reward-hub entry that restricts the hub to a shared "reward pool" (this run's tried outfits, or the persisted seen-intros for skip). A dedicated `skip_lead_in.txt` script provides the lead-in dialogue.

**Tech Stack:** Godot 4 / GDScript. No unit-test framework in this project, so verification is **GDScript parse/load checks in the Godot editor + a manual playtest**. Git is user-handled — "Checkpoint" steps are points at which to commit if you wish, not commands to run.

**Spec:** `docs/superpowers/specs/2026-06-06-dressing-room-skip-to-rewards-design.md`

---

## File Structure

- **Modify** `src/vn/GlobalGameStage.gd` — new per-save field + helpers; save/load wiring; `VERSION` bump.
- **Modify** `src/vn/anna_dressing_room.gd` — record seen intros; shared reward pool + `_enter_reward_hub()`; skip handler; skip-button visibility; signal hookup.
- **Modify** `src/vn/anna_dressing_room_hub.gd` — `skip_to_rewards_requested` signal; button hookup; `set_skip_button_visible()`.
- **Modify** `src/vn/anna_dressing_room_hub.tscn` — add the `SkipToRewards` button node.
- **Create** `data/scripts/anna_dressing_room/skip_lead_in.txt` — lead-in dialogue.

---

## Task 1: Persist seen intros in GlobalGameStage

**Files:**
- Modify: `src/vn/GlobalGameStage.gd` (field + helpers near `annaDressingRoomTranscript` ~line 924-932; `saveSaveData` ~line 513; `loadSaveData` ~line 626; `VERSION` line 73)

- [ ] **Step 1: Add the field and helper functions**

In `src/vn/GlobalGameStage.gd`, find the transcript helpers:

```gdscript
func resetAnnaDressingRoomTranscript():
	annaDressingRoomTranscript = []

func recordAnnaDressingRoomMessage(entry: Dictionary):
	annaDressingRoomTranscript.append(entry)
```

Add immediately after `recordAnnaDressingRoomMessage`:

```gdscript

# Outfits whose intro the player has finished watching, used to gate the
# "Skip to Rewards" shortcut. Persisted per-save; NOT reset between sessions.
var annaDressingRoomSeenIntros : Array[String] = []

func recordAnnaDressingRoomIntroSeen(outfitName: String):
	if outfitName not in annaDressingRoomSeenIntros:
		annaDressingRoomSeenIntros.append(outfitName)

func hasSeenAnnaDressingRoomIntros() -> bool:
	return annaDressingRoomSeenIntros.size() > 0

func getAnnaDressingRoomSeenIntros() -> Array:
	return annaDressingRoomSeenIntros
```

> Note: `annaDressingRoomSeenIntros` is declared as its own `var` (it must persist across runs), unlike `annaDressingRoomTranscript` which is reset each session.

- [ ] **Step 2: Bump the save version**

Find line 73:

```gdscript
const VERSION = 016
```

Change to:

```gdscript
const VERSION = 017
```

- [ ] **Step 3: Write the field in `saveSaveData`**

Find the end of `saveSaveData` (~line 513):

```gdscript
	file.store_var(randomizeWallpaper)
	
	savePersistentData()
```

Change to:

```gdscript
	file.store_var(randomizeWallpaper)
	file.store_var(annaDressingRoomSeenIntros)
	
	savePersistentData()
```

- [ ] **Step 4: Read the field in `loadSaveData`**

Find this block (~lines 623-628):

```gdscript
		if (saveVersion > 014):
			randomizeWallpaper = file.get_var()
		else:
			randomizeWallpaper = false

		dateStorage.clearCurrentDate()
```

Change to:

```gdscript
		if (saveVersion > 014):
			randomizeWallpaper = file.get_var()
		else:
			randomizeWallpaper = false

		if (saveVersion > 016):
			annaDressingRoomSeenIntros.assign(file.get_var())
		else:
			annaDressingRoomSeenIntros = []

		dateStorage.clearCurrentDate()
```

> `.assign()` is used (not `=`) so the untyped `Variant` from `get_var()` is copied into the typed `Array[String]` without a type-mismatch error — matching the existing `completedStages.assign(...)` pattern.

- [ ] **Step 5: Verify it parses**

Open the project in the Godot editor (or reload the script). Confirm the **Errors/Output** panel shows no parse errors for `GlobalGameStage.gd`.
Expected: no errors; autoload still loads.

- [ ] **Step 6: Checkpoint** (git is user-handled — commit if you wish)

---

## Task 2: Add the SkipToRewards button to the hub scene + script

**Files:**
- Modify: `src/vn/anna_dressing_room_hub.tscn` (append a button node)
- Modify: `src/vn/anna_dressing_room_hub.gd` (signal, hookup, setter)

- [ ] **Step 1: Add the button node to the scene**

In `src/vn/anna_dressing_room_hub.tscn`, the file currently ends with the `RightArrow` node:

```
[node name="RightArrow" type="Button" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 808.0
offset_top = 516.0
offset_right = 888.0
offset_bottom = 636.0
text = ">"
```

Append a new node at the end of the file (direct child of `Hub`, fixed top-center, hidden by default):

```
[node name="SkipToRewards" type="Button" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 328.0
offset_top = 24.0
offset_right = 568.0
offset_bottom = 80.0
text = "Skip to Rewards"
```

> `parent="."` makes it a sibling of `LeftArrow`/`RightArrow` (children of `Hub`, not `Pan`), so it stays fixed on screen instead of scrolling with the outfits. `unique_name_in_owner = true` enables `%SkipToRewards`.

- [ ] **Step 2: Add the signal and setter to the hub script**

In `src/vn/anna_dressing_room_hub.gd`, find:

```gdscript
signal outfit_selected(outfit_name: String)
```

Change to:

```gdscript
signal outfit_selected(outfit_name: String)
signal skip_to_rewards_requested
```

- [ ] **Step 3: Connect the button in `_ready` and add the setter**

In `_ready`, find:

```gdscript
	%LeftArrow.pressed.connect(_pan_by.bind(PAN_STEP))
	%RightArrow.pressed.connect(_pan_by.bind(-PAN_STEP))
```

Add below those two lines:

```gdscript
	%SkipToRewards.pressed.connect(_on_skip_pressed)
```

Then add these two functions at the end of the file (after `reset_pan`):

```gdscript

func _on_skip_pressed() -> void:
	skip_to_rewards_requested.emit()

func set_skip_button_visible(v: bool) -> void:
	%SkipToRewards.visible = v
```

- [ ] **Step 4: Verify it parses**

Open `anna_dressing_room_hub.tscn` in the editor. Confirm the scene opens, the `SkipToRewards` button appears top-center in the scene tree/2D view, and there are no script parse errors.
Expected: scene opens cleanly; button present and hidden in-game by default.

- [ ] **Step 5: Checkpoint** (git is user-handled — commit if you wish)

---

## Task 3: Add the skip lead-in script

**Files:**
- Create: `data/scripts/anna_dressing_room/skip_lead_in.txt`

- [ ] **Step 1: Create the script file**

Create `data/scripts/anna_dressing_room/skip_lead_in.txt` with exactly:

```
# Plays when the player taps "Skip to Rewards" — jumps straight to picking a
# reward outfit from those whose intro the player has already seen.
pos: bl
a: back so soon?
a: ok, which one do you want to see again?
p: let me pick...
```

> The filename intentionally does **not** end in `_reward` or `_intro`, so `_on_script_finished` won't route it through those branches (which would play `goodbye` or try to record/count a fake outfit).

- [ ] **Step 2: Verify the format matches existing scripts**

Compare against `data/scripts/anna_dressing_room/pick_favorite.txt` — same directive style (`pos:`, `a:`, `p:`). Confirm it ends with a `p:` line so the conversation pauses on the player's turn before the reward hub opens.
Expected: directives valid; no `img:` so the existing changing-room backdrop is used.

- [ ] **Step 3: Checkpoint** (git is user-handled — commit if you wish)

---

## Task 4: Wire up recording, reward pool, and skip handling in the controller

**Files:**
- Modify: `src/vn/anna_dressing_room.gd` (`tried_outfits` decl ~line 97; `_build_hub` ~line 110-115; `_on_script_finished` ~line 413-433; `_enter_hub` ~line 455-463; new helpers)

- [ ] **Step 1: Add the reward-pool field**

Find (~lines 97-98):

```gdscript
var tried_outfits: Array[String] = []
var picking_favorite := false
```

Change to:

```gdscript
var tried_outfits: Array[String] = []
var picking_favorite := false

# Outfits the reward (favorite-pick) hub is restricted to. Set to this run's
# tried outfits for the normal ending, or the persisted seen-intros when the
# player taps "Skip to Rewards".
var reward_outfit_pool: Array[String] = []
```

- [ ] **Step 2: Connect the hub's skip signal**

In `_build_hub` (~lines 110-115), find:

```gdscript
	hub = HubScene.instantiate()
	hub.visible = false
	hub.modulate.a = 0.0
	hub.outfit_selected.connect(_on_outfit_selected)
	add_child(hub)
```

Change to:

```gdscript
	hub = HubScene.instantiate()
	hub.visible = false
	hub.modulate.a = 0.0
	hub.outfit_selected.connect(_on_outfit_selected)
	hub.skip_to_rewards_requested.connect(_on_skip_to_rewards)
	add_child(hub)
```

- [ ] **Step 3: Record seen intros and set the reward pool in `_on_script_finished`**

Find the `_on_script_finished` branches for `pick_favorite` and `_intro` (~lines 416-431):

```gdscript
	elif script_name == "pick_favorite":
		picking_favorite = true
		hub.restrict_to_outfits(tried_outfits)
		await _enter_hub()
	elif script_name == "goodbye":
		scene_ended.emit()
		GlobalGameStage.stopBespoke('Anna Dressing Room')
	elif script_name == "already_tried":
		await _enter_hub()
	elif script_name.ends_with("_reward"):
		play_script("goodbye")
	elif script_name.ends_with("_intro"):
		if tried_outfits.size() >= MAX_OUTFITS_TO_TRY:
			play_script("pick_favorite")
		else:
			await _enter_hub()
```

Change to:

```gdscript
	elif script_name == "pick_favorite":
		await _enter_reward_hub()
	elif script_name == "skip_lead_in":
		await _enter_reward_hub()
	elif script_name == "goodbye":
		scene_ended.emit()
		GlobalGameStage.stopBespoke('Anna Dressing Room')
	elif script_name == "already_tried":
		await _enter_hub()
	elif script_name.ends_with("_reward"):
		play_script("goodbye")
	elif script_name.ends_with("_intro"):
		GlobalGameStage.recordAnnaDressingRoomIntroSeen(script_name.trim_suffix("_intro"))
		if tried_outfits.size() >= MAX_OUTFITS_TO_TRY:
			reward_outfit_pool.assign(tried_outfits)
			play_script("pick_favorite")
		else:
			await _enter_hub()
```

> `hub_intro` is still handled by the earlier `if script_name == "hub_intro":` branch, so it never reaches the `_intro` suffix branch and is never recorded as an outfit.

- [ ] **Step 4: Add the reward-hub helper and the skip handler**

Add these two functions after `_on_outfit_selected` (after line ~447, before `_inject_player_line`):

```gdscript

func _enter_reward_hub() -> void:
	picking_favorite = true
	hub.restrict_to_outfits(reward_outfit_pool)
	await _enter_hub()

func _on_skip_to_rewards() -> void:
	reward_outfit_pool.assign(GlobalGameStage.getAnnaDressingRoomSeenIntros())
	await _exit_hub()
	play_script("skip_lead_in")
```

- [ ] **Step 5: Show/hide the skip button on hub entry**

Find `_enter_hub` (~lines 455-463):

```gdscript
func _enter_hub() -> void:
	hub.visible = true
	hub.reset_pan()
	var tween := create_tween().set_parallel(true)
```

Change to:

```gdscript
func _enter_hub() -> void:
	hub.visible = true
	hub.reset_pan()
	hub.set_skip_button_visible(not picking_favorite and GlobalGameStage.hasSeenAnnaDressingRoomIntros())
	var tween := create_tween().set_parallel(true)
```

> During the reward-pick hub `picking_favorite` is `true`, so the skip button is hidden there. On every outfit-selection (trying-phase) hub it shows whenever the player has at least one seen intro.

- [ ] **Step 6: Verify it parses**

Reload `anna_dressing_room.gd` in the editor. Confirm no parse errors and that `_enter_reward_hub`, `_on_skip_to_rewards`, and the new branches reference only defined symbols.
Expected: no errors.

- [ ] **Step 7: Checkpoint** (git is user-handled — commit if you wish)

---

## Task 5: Manual playtest (integration verification)

**Files:** none (verification only)

- [ ] **Step 1: First run — earn unlocks the normal way**

Launch the game and reach the Anna Dressing Room (anna_night phone event → "Anna Dressing Room" special).
- On the first hub after `hub_intro`, confirm the **Skip to Rewards** button is **hidden** (a brand-new save has no seen intros).
- Try on 3 outfits, watching each `*_intro`. Reach `pick_favorite`, choose a favorite, watch its `*_reward`, then `goodbye`.
- Finish the closing phone texts so the conversation completes (this triggers the autosave that persists seen intros).

Expected: normal flow unchanged; reward plays once then scene ends.

- [ ] **Step 2: Confirm persistence**

Without starting a brand-new game, re-enter the Anna Dressing Room (replay the message), OR fully quit and relaunch so `user://autosave.dat` is loaded, then re-enter.
- On the hub after `hub_intro`, confirm the **Skip to Rewards** button is now **visible**.

Expected: button appears because the 3 (or more) intros seen in Step 1 were saved and loaded.

- [ ] **Step 3: Use the skip**

Tap **Skip to Rewards**.
- Confirm `skip_lead_in` dialogue plays ("back so soon? / ok, which one do you want to see again?").
- Confirm the hub reopens with **only** the previously-seen outfits enabled (others disabled) and the skip button now hidden.
- Pick one; confirm the favorite line is injected, the `*_reward` script plays, then `goodbye`.

Expected: one reward then scene ends — the grind-free path to a reward.

- [ ] **Step 4: Edge check — partial trying phase still records**

Start a fresh save, enter the dressing room, try exactly one outfit (watch its intro), then back out at the hub via Skip to Rewards if visible. (With only one seen intro this run, after the closing texts the single intro should be recorded.) Re-enter and confirm that one outfit is selectable via skip.

Expected: any completed intro — even a single one — unlocks its reward via skip on the next run.

- [ ] **Step 5: Checkpoint** (git is user-handled — commit if you wish)

---

## Self-Review Notes

- **Spec coverage:** persistence field + helpers + save/load + VERSION (Task 1) ✓; hub button + signal + setter (Task 2) ✓; dedicated `skip_lead_in.txt` (Task 3) ✓; recording on intro completion, shared `reward_outfit_pool`/`_enter_reward_hub`, skip handler, whole-trying-phase visibility (Task 4) ✓; one-reward-then-goodbye flow preserved (Task 4 reuses existing `_reward`→`goodbye`) ✓; manual verification incl. persistence across runs (Task 5) ✓.
- **Type consistency:** `recordAnnaDressingRoomIntroSeen`, `hasSeenAnnaDressingRoomIntros`, `getAnnaDressingRoomSeenIntros`, `set_skip_button_visible`, `skip_to_rewards_requested`, `_enter_reward_hub`, `_on_skip_to_rewards`, `reward_outfit_pool` are named identically wherever referenced. `reward_outfit_pool.assign(...)` used in both producers to avoid typed-array mismatch.
- **No placeholders:** every code step shows full before/after text.
