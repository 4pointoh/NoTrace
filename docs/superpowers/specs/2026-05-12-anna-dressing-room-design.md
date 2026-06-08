# Anna Dressing Room — Design

## Purpose

A VN scene in which the player and Anna exchange text messages over a background image. The conversation is fully scripted (no in-script branching) but the scene will eventually host multiple scripts, with the player picking which script to play next via a choice presented between scripts. This spec covers only the **background + texting interface** components. The between-scripts choice UI is explicitly deferred.

Screen resolution: 896×1152 (portrait).

## Scope

**In scope (this pass):**
- Background image displayed full-screen, swappable mid-script.
- Texting panel occupying one quadrant of the screen, with mid-script repositioning and a hide/show toggle.
- Plain-text script format with directives for messages, image swaps, and panel positioning.
- Pacing loop: click-to-advance for player lines, auto-paced typing rhythm for Anna runs.
- Support for loading and playing multiple scripts (one at a time) from a scripts folder.

**Out of scope (deferred):**
- The between-scripts choice UI and how options are defined.
- Sound effects (will reuse `messages_app.gd`'s wavs when added).
- Crossfade on `img:` swap (instant for v1).
- Per-line custom delays (e.g. `wait: 2.0`).
- What happens after the final script's last line (stays on screen for now).

## Files

| Path | Status | Purpose |
|---|---|---|
| `src/vn/AnnaDressingRoom.tscn` | exists; will be extended | Scene root. Currently has `black` ColorRect and `%bg` TextureRect. Add `TextingPanel` Control. |
| `src/vn/anna_dressing_room.gd` | exists; empty | Becomes the controller (~120 lines). |
| `data/scripts/anna_dressing_room/*.txt` | new folder | One file per script. First script is `intro.txt`. |

## Script File Format

Plain text, one directive per line. Blank lines and `#` comments are ignored. Unknown prefixes log a `push_error` so typos surface in the Godot console.

```
# intro.txt
img: res://data/background_lists/home/backgrounds/intro_bg11.webp
pos: tl
a: hey
a: you there?
p: yeah whats up
a: ok look
a: at this outfit
img: res://data/background_lists/home/backgrounds/intro_bg12.webp
pos: tr
a: thoughts?
p: looks great
```

Directives:

| Prefix | Meaning |
|---|---|
| `a: <text>` | Anna message. Auto-paced within an Anna run. |
| `p: <text>` | Player message. Waits for click, then appears instantly. |
| `img: <res path>` | Set `%bg.texture` to the image at this path. Instant. |
| `pos: tl\|tr\|bl\|br` | Move texting panel to this quadrant. Tweened. |
| `#` (line start) | Comment. Ignored. |

## Scene Additions to `AnnaDressingRoom.tscn`

Add a single `TextingPanel` Control node (sibling of `%bg`):

- **Size:** 448×576 (one quadrant of 896×1152).
- **Position:** set in code from the current `pos:` value. Default `tl` (0, 0).
- **Children:**
  - A semi-transparent `ColorRect` or `Panel` for the panel background (alpha ~0.5).
  - A `ScrollContainer` filling the panel, holding a `VBoxContainer`. Each script line spawns a `MessageText` instance into this VBox. Auto-scroll to bottom on append.
  - A `HideButton` (`Button`) pinned to the panel corner that is closest to screen center for the current quadrant, so the button is never off-screen. Repositioned when `pos:` changes.

## Reused Components

- `src/phone/message_text.tscn` — used directly. Each bubble:
  - `setMessage(isPlayer: bool, text: String, "Anna")` — Anna's bubble texture is already mapped to `bg7_shadow` in `message_text.gd`.
  - `SIZE_SHRINK_BEGIN` for Anna bubbles, `SIZE_SHRINK_END` for player.
- `src/phone/loading_spinner.tscn` — used directly for the "typing…" indicator before an Anna run begins. Confirmed to exist.
- `messages_app.gd` — **not** used. Its pacing pattern (read-receipt → typing dots → bubble) is the inspiration, but no code is shared.

## Controller (`anna_dressing_room.gd`)

### Public API

```gdscript
func play_script(script_name: String) -> void
signal script_finished(script_name: String)
```

`_ready()` calls `play_script("intro")`.

`play_script` behavior:
1. Clear the bubble `VBoxContainer` (previous script's messages don't linger).
2. Load `data/scripts/anna_dressing_room/<script_name>.txt`. If missing, `push_error` and return.
3. Parse the file into an in-memory list of directive entries.
4. Run the pacing loop.
5. Emit `script_finished` after the last directive is consumed.

### Parsing

A single function `parse_script(text: String) -> Array` returns a list of dicts like `{type: "anna", text: "hey"}`, `{type: "img", path: "..."}`, `{type: "pos", quadrant: "tl"}`. Comments and blanks dropped. Unknown prefixes generate a `push_error` and are skipped.

### Pacing loop

State carried across lines:
- `previous_was_anna: bool` — drives the short-vs-long Anna delay.

For each directive:

| Type | Behavior |
|---|---|
| `p:` | `await click_or_keypress`. Append player bubble instantly. Set `previous_was_anna = false`. |
| `a:` | If `previous_was_anna`: wait `ANNA_RUN_DELAY` (~0.4s). Else: show typing-dots loader, wait `ANNA_FIRST_DELAY` (~1.2s), remove loader. Append Anna bubble. Set `previous_was_anna = true`. |
| `img:` | Set `%bg.texture = load(path)`. No effect on `previous_was_anna`. |
| `pos:` | Tween `TextingPanel.position` to the new quadrant over `POS_TWEEN_SEC` (~0.25s). Reposition `HideButton` to the new inner-corner. No effect on `previous_was_anna`. |

Constants (`ANNA_FIRST_DELAY`, `ANNA_RUN_DELAY`, `POS_TWEEN_SEC`) live at the top of the file for easy tuning.

### Hide button

Toggles a fade tween on `TextingPanel.modulate.a` between 1.0 and 0.0 over ~0.2s. Button itself stays at alpha 1.0 and changes its label between "Hide" and "Show". **Hiding does not pause the script** — if the player hides mid-Anna-run, messages continue to be appended behind the curtain. (Easy to flip later if we want pause-on-hide.)

### State carried across scripts

Background image and panel position are **not** reset between scripts. A new script that doesn't repeat `img:` or `pos:` inherits the previous values. The bubble VBox **is** cleared.

## Quadrant Coordinates

For a 896×1152 screen with a 448×576 panel:

| Key | Panel position | Inner corner (for HideButton) |
|---|---|---|
| `tl` | (0, 0) | bottom-right of panel |
| `tr` | (448, 0) | bottom-left of panel |
| `bl` | (0, 576) | top-right of panel |
| `br` | (448, 576) | top-left of panel |

## Error Handling

- Missing script file: `push_error("Script not found: <path>")`, return early.
- Unknown directive prefix: `push_error("Unknown directive: <line>")`, skip line, continue.
- Missing image path on `img:`: `push_error`, skip directive, leave previous background.
- Invalid `pos:` value: `push_error`, skip directive, panel stays where it is.

All errors are non-fatal — the scene tries to keep going.

## Testing Approach

Manual testing in the Godot editor. Create a short `intro.txt` exercising every directive (`a:` runs of 1 and 3+ lines, `p:` lines between them, two `img:` swaps, all four `pos:` values, comments, blank lines, a deliberately-malformed line to verify `push_error`). Verify:
- Player lines wait for click and appear instantly.
- Anna's first-in-run has typing dots + longer delay; subsequent run lines have a short delay.
- Background swaps correctly on `img:`.
- Panel tweens to the right quadrant on `pos:`, and HideButton stays on-screen.
- Hide button fades the panel and doesn't pause Anna's run.
- Calling `play_script("other")` clears the bubbles and starts over without resetting bg/pos.

No automated tests for this scene.
