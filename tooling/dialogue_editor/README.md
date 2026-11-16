# dialogue_editor: the game's dialogue as scripts in the browser

A page for writing the game's dialogue. It reads and saves the game's `DialogueData` files
(`data/game_stages/**/d_*.tres`) directly, the same files Godot's dialogue_nodes graph edits.
Each start key is shown as a script: its lines and signals from top to bottom, each line with its
picture beside it. Save, and Godot plays it. There is no export step, and the graph keeps working
on saved files.

It edits plain chains: start → line or signal → … → END, with no choices, conditions or variables.
Anything else is shown read-only, with a lock and the reason (see Read-only starts).

## First five minutes

1. Double-click `Open dialogue editor.cmd`. The page opens at http://127.0.0.1:8766/. Godot can
   stay open.
2. Press Ctrl+P, type a few letters of a start key ("x3 under top"), then Enter. An unwritten line
   arrives selected, so just type.
3. Enter starts the next line, with the same picture and the speaker from two lines up. Alt+1 and
   Alt+2 pick the speaker, Alt+0 narration. Alt+← and Alt+→ step the picture, or click one on the
   right. / in an empty line inserts a signal.
4. F5 plays from the line (Shift+F5 from the top). Esc comes back.
5. Ctrl+S saves every edited file. ? lists every key.

If the page says the server isn't answering, double-click the .cmd again. Unsaved edits stay in
the browser meanwhile.

## Starting it

`Open dialogue editor.cmd` starts the editor and opens the browser; keep its window open while
writing, close it to stop. If the editor is already running, it just opens the browser at it. Or,
from the project folder:

```
python -P -E tooling/dialogue_editor/dialogue_editor.py [--port 8766] [--no-open]
```

`--port 0` takes any free port. `--project PATH` opens another Godot project, and `--image-root
PATH` reads its pictures from another copy. `--backups`, `--cache` (thumbnails) and `--config`
move this folder's `backups/`, `cache/` and `config.json`. It needs Python 3 with Pillow, and the
art sorter's `package.py` (in `../art_sort`). The server answers this machine only (127.0.0.1), and
the page asks nothing of anywhere else. F5 is Play on this page: reload it with Ctrl+R.

## Writing

Each line of the script is one box of dialogue in the game. Every shortcut is in the page: press ?.

- **A new line** takes the picture and the speaker of the line it follows, since a speaker usually
  says two or three short lines in a row (Alt+1…9 or Alt+0 switches). A new start (Alt+N) goes
  after the open one. Its first line uses the scene's list named after the key if there is one
  (Ashely II), otherwise it keeps the picture from before, with the panel on the previous start's list.
- **Unwritten lines** start with "(Placeholder)" and show amber. Arriving in one selects all of
  it, so typing replaces it. A line that keeps the prefix with words written after it still counts
  as unwritten, and the art packager may write over a start whose only line is a placeholder. The
  row warns.
- **↑ ↓** stop on a signal's row, not in its value. Enter (or F2) changes the value, Backspace
  removes it, and typing a letter carries on in the next line. ↓ puts the caret at the end of the
  next line, so Enter then adds below.
- **Speakers**: click a line's speaker and type to find one. A character's name picks that
  character. The game shows a character's colour, portrait and states, which it doesn't for the
  same name typed as text. A name nobody has yet is the last entry, "Use … as a new name".
  Changing a speaker sets the character state to -1.
- **Undo** (Ctrl+Z) is one history for the page. It stops at the edge of the open start first,
  and says "Ctrl+Z again undoes in …". It says so too when it undoes something already saved.
- **Markup**: `[b]`, `[i]`, `[u]`, `[s]`, `[color=…]`, `[wait …]`, `[br]`, `[name]` (the player's
  name) and `{{VAR}}`. Tags are lower case, as in the game. A tag left open, a stray closing
  tag or `[B]` is warned about: the game shows it as text, and a tag left open shows "[/wait]" at
  the end of the line.
- **Pictures** are numbered from 1, as their names and files are (`WIN_S1_TOP_07` is `07.webp`).
  **Keep previous** is picture -1: the game keeps whatever is on screen. A line showing the same
  picture as the line before gets a slim "same picture" mark instead of the thumbnail, so the
  picture changes stand out. The thumbnails button in the top bar shows them on every line.
- **Changing a picture** changes only the selected line. Each line holds its own picture (a new line
  copies the one above), so the lines after it keep the old one, and its thumbnail now shows on the
  next line: the toast names them. Turn on **Replace** (beside Keep previous; amber while on, and
  remembered) to change it on those lines too, up to the first line that showed a different picture.
  It covers every picture change: the picker, Keep previous, ◀ ▶ and Alt+← →. **Shift+click** does
  the other of the two for one click.
- **Fade** (beside Replace, blue while on, and on unless you turn it off): a picture change puts a
  `fade_next` signal just before the line where the picture now changes. That's the line you set, and
  also the next line if it now changes away from the run you ended. It's skipped when a fade already
  waits there (the game keeps a fade, quick fade or slow fade until the next real change), and on a
  start's first line, since what shows before that comes from elsewhere. It's part of the same undo
  step, so Ctrl+Z takes back the picture and its fade together. To skip a fade, delete its row. A fade
  added this way is taken out again if its line stops changing picture (eg you pick Keep previous
  instead). Fades you put in yourself always stay, and so do changes you didn't touch.
- **Signals**: the picker lists every signal the game's code reacts to, with the code's own comment
  as its description, this file's most used first. `play_sfx_<n>` and `play_music_<n>` take a
  number from the stage's sound or music list. Unknown values are flagged but can be saved.
- **Warnings** show on the line and don't stop a save. They cover unknown signals, picture, list,
  speaker or state numbers out of range, empty lines, markup the game shows as text, and `{` `}`
  in a typed name (Godot's editor takes them out when it saves).

## Play

Play (F5 from the selected line, Shift+F5 or the start's Play button from the top) opens the start
in **the play tab**, a tab of its own, so the script stays open here. It runs the start as the game
would: the picture, the box where the game puts it, fades through black at the game's speeds, and
`landscape_next` / `portrait_next` switching the frame. Space, → or Enter go on. ← or Backspace go
back. Signals flash their names, and those after the last line flash on the END card.

- **Edits show there as you type**, unsaved ones too, and it keeps the line it is on. At the END
  card, a line added after the last one plays next, so you can write a line, look, and write on.
- **Every Play uses the same tab**: press it again to send that tab to another start or line.
  Drag the tab out into a window of its own to keep it beside the script.
- It follows the editor tab that opened it. If that tab is gone, it plays the start as saved and
  says so. It saves nothing and keeps no drafts, so close it whenever you like. The browser asks
  to allow pop-ups only if it blocks the first one.

What Play can't know: the game keeps the box where the dialogue before left it, and a fade still
waiting from before. The panel and Play say so when the scene moves the box. A read-only start with
choices or conditions plays one way through (the first choice, the "true" side). Sound, music and
characters' movements aren't played.

## Finding things

**Ctrl+F finds in the open start.** The browser's own find can't see into the line boxes, so
the page has its own bar, above the script. Every match is marked where it is, and the current one
is orange. Its line is selected, so the panel shows its picture.

- **Enter**, ↓ or F3 goes to the next match, and **Shift+Enter**, ↑ or Shift+F3 to the one before.
  After you click another line, the next match is the one from there.
- **Only matching lines** hides the rest, and a thin rule marks each gap. Each line then shows
  its own picture. Lines you add, or change so they no longer match, stay in view. ↑ and ↓ skip
  the hidden lines. The page remembers the button. While nothing matches, nothing is hidden.
- The start list shows each start's count, and dims the starts without one. Click a start, or
  press Alt+PgDn, and the bar jumps to that start's first match.
- **Esc** closes the bar and puts the caret on the match, with its words selected.
- Ctrl+F with words selected in a line finds those words.
- Case doesn't matter, and nor do curly against straight quotes. Line text, signal values and
  read-only summaries are searched; speakers' names and pictures aren't (Ctrl+K has those).

Ctrl+P finds any start key in any file, loosely: "x3undertop" finds `WIN_X3_UNDER__TOP_OFF`.
Ctrl+K searches start keys, line text, speakers, picture names and signal values everywhere. **This
file only** and **Placeholder lines** narrow it. The page's address (`#file=…&key=…`) opens that
start, so starts can be bookmarked.

## Done or not

**Mark done** (beside Play on a start) marks the open start done, and it turns green. Click it again
to mark the start not done, as work in progress again. A done start shows a ✓ in the start list, in
Ctrl+P and in the file list (Ctrl+O). The file list also gives "3 done" per file, or "done" when every
start is. The start list's count says how many are done. Its menu lists **All**, **Not done** or
**Done**, and the page remembers which.

A mark isn't an edit. It takes effect at once, needs no save and has no undo. It's kept in `done.json`
beside the editor, never in the dialogue files, so the game knows nothing of it. Read-only and unsaved
new starts can be marked too. Other open tabs show a mark at once. A mark stays when you edit the start
afterwards; unmark it if the start needs work again.

## Gallery

**Gallery** in the top bar (Alt+G) shows every picture the open file can use, all its lists on one
page. The picker beside the script shows one list at a time. The eight Ashely II files name the same
lists, so from any of them the gallery is the whole scene's art. It opens on the picture the
selected line shows.

- The list names are down the left with "used / pictures" for each. Click one to go to it.
- **Filter** takes words of a list or picture name, such as "top off" or "x3 bj" (Ctrl+F or /).
  The menu beside it shows **All pictures**, **Not used yet** or **Used**. **Size** makes the
  pictures bigger or smaller, and the page remembers it.
- A blue **×3** on a picture is the number of lines set to it. Lines are counted in every file
  that names the same lists, and unsaved edits count. A line that keeps the picture before it
  isn't counted. An amber **match** means only a poker match opens on it (Match pictures).
- A purple **▶ loop** or **▶ once** beside a picture's number means the game has a video for it,
  which plays over the still while the picture shows. A loop keeps going; "once" plays and goes
  back to the still. **With a video** in the menu lists only those. The big view names the video
  file, and any other videos picked for the picture, which the game doesn't play. The marks come
  from the lists `src/vn/Background.gd` names in `PICTURE_VIDEO_LISTS`. The page can't play the
  videos: they're Theora, which browsers no longer play.
- Click a picture to see it big. The side says where it shows, by file and start; click a start to
  go to that line. ← → go through the pictures, and Esc goes back.
- In the big view, **Show in folder** opens the picture's folder in File Explorer with the picture
  selected. Each video of the picture has **Play video**, which opens it in the program this
  computer plays videos with, and its own **Show in folder**. A loop's lead-in (`…_intro.ogv`)
  sits beside it in that folder. The editor server does the opening, so the window can come up
  behind the browser.
- **Use** on a picture (it appears when the mouse is over it), or **Use on line N** or Enter in the
  big view, puts the picture on the selected line and closes the gallery. It's an edit like a
  picker click: Replace, Fade and Ctrl+Z work the same, and Shift does the other of Replace.
- **Open in a tab** gives the gallery a tab of its own to keep beside the editor
  (`/?gallery=1#file=…`). That tab only shows. It reads the files as saved, and again when they
  change, so unsaved edits don't count there.
- **★ Wallpapers** picks the pictures that will be wallpapers (added 2026-11-16).
  - Turn it on and every picture gets a star at its bottom left. Click the star, or press W on a
    picture, to pick or unpick it. Picked pictures have a gold frame.
  - The big view has **Pick as wallpaper** / **★ A wallpaper**, and W there too.
  - **Wallpapers** in the menu lists only the picked ones. The top line and each list say how many
    are picked.
  - The first time it's turned on for a file's picture lists, every picture there with a video is
    picked, to start from.
  - Picks are saved at once, by picture file, in `wallpaper_picks.json` beside `done.json`. The game
    doesn't read that file: the picks go into the game from it when they're ready. The tab of its
    own can pick them too.

The use counts across files, the video marks, Show in folder and Wallpapers need the editor server
started since they were added. With an older one still running, the gallery says what it can't do.

## Match pictures (Ashely II)

**Match pictures** in the top bar lists every situation an Ashely II poker match can start in, as
`ashely2_race.gd` works it out. Each gets one picture:

- **The first hand**, before the race.
- **Dressed**: rows are the matches you've won so far (0–3), columns the matches she's won (0–3). The
  race ends at 4 either way.
- **Topless, shorts on**: only once you've won at least 1, since her top comes off with a stake of yours.
- **In her panties**: you've won 3 (top, walk, shorts).

Click a match (Shift+click for more), then a picture on the right. The pick saves at once. The
picture list follows the match's outfit, and its menu offers any other list. A cell outlined amber
uses a picture from another outfit's list. ← → move between matches, Delete clears, Esc closes.

The picks go in `match_pictures.json` beside the editor. The game doesn't read that file: the picks are
copied into the game (`ashely2_race.gd`) by hand once they're set. Until then, each match picks one of
its outfit's table pictures at random.

## Saving

Edits stay in the page until Ctrl+S, which saves every file with edits. Switching starts or files
never loses them. They are also kept in this browser, each tab its own, and after a crash or a
reload the page offers them back. A draft that can't go back where it was is never dropped: if its
start was deleted, its key taken, or the start edited again since, it comes back as a new start
next to it. If its file moved, its text is shown to copy.

What a save does to the file:
- Only the starts you changed are rewritten. Everything else stays byte for byte, so changes made
  elsewhere to other starts (Godot, the art packager) stay too. A save that changes nothing writes
  nothing.
- A line or signal you kept keeps its node and id. New ones get the next free id, and removed ones
  are deleted.
- In Godot's graph a start with the same nodes in the same order moves nothing. A chain laid out in
  a row (as the packager lays them) is laid out in a row again, when the row is clear of other
  nodes. Otherwise kept nodes stay where they are and new ones go to the nearest free place right of
  the one before. A new start goes below every node.
- Before writing, the old file is copied to `backups/<the file's path>/<date-time>.tres.bak`. The
  newest 50 are kept, plus the first of each day for 60 days. To undo a save, copy one back over the
  file: Godot reloads it.
- If another program writes the file while a save is under way, the save starts again from what is
  on disk. The file is read back and checked after writing. If the check fails, the old file goes
  back, but only over this save's own write: another program's version stays, and the page says so.

## Godot open or closed

Unpatched, the dialogue_nodes addon writes every dialogue file it has open, from its own copy,
whenever Godot saves, and that includes pressing Run (F5). It would write over what you saved here.
This project's copy of the addon is patched (`addons/dialogue_nodes/editor/files.gd`, marked
`EXTERNAL_EDIT_SAFE`, and a few lines in `editor.gd`):
- **Godot writes only the files you edited in its graph.** A file you only opened there is left
  alone.
- **Not edited in Godot**: a file open in Godot that changed on disk is reloaded from disk when
  Godot saves or when you come back to Godot's window. Nodes you only dragged around in the graph
  don't count: they go back to where the file has them.
- **Edited in Godot too**: Godot asks what to keep.
  - **Use the file on disk**: loads the saved version and drops the graph edits to that file.
  - **Overwrite it with Godot's graph**: saves the graph's version now. The disk version is first
    copied to `backups/<the file's path>/<date-time>-outside-godot.tres.bak` in this folder. The
    editor never deletes those.
  - **Decide later** (or Esc, or closing the dialog): nothing is written. Godot won't save that
    file until you choose, and asks again each time it tries. Run (F5) plays the file on disk.
- **So**: don't edit the same file in both at once. If you have unsaved graph edits to a file, save
  them in Godot before editing that file here.
- **The graph rebuilds**: when the file shown in Godot's graph changes, Godot rebuilds the graph.
  That takes a few seconds for a big file (about 3 s for `d_ashely2_win.tres`, 10 s for
  `d_anna_night.tres`, 30 s for `d_anna_class.tres`). On another Godot screen (2D, Script, …) it
  waits until you open the dialogue screen. To skip it, close the file in Godot's dialogue tab
  while you write it here.
- **Not in the Inspector**: don't edit a dialogue file in Godot's Inspector. Godot saves that copy
  itself, past the addon, over your edits here and without a backup.
- After the addon is first patched or updated, restart Godot once: lines already in an open graph
  keep their old wiring until the file is opened again.

The **Godot** pill says **Godot closed**, **Godot open · safe** (patched) or **Godot open ·
unpatched**; unpatched, the page asks before each save while Godot runs.

## Changes made elsewhere

Every 10 seconds, and when you come back to the browser, the page looks for files changed on disk.
- A start you haven't edited here reloads quietly. Other starts of the same file changing is no
  conflict.
- A start you edited that changed there too gets a red **!** and is refused at the next save, until
  you choose: **Compare** (the disk version next to yours), **Reload it from disk (drop my
  edits)**, **Save mine over it**, or **Keep editing**. If a new start's key turns up in the file,
  **Save mine as KEY_MINE** keeps both.
- A start you edited that can't be edited here any more keeps your edits, shown read-only and not
  saved, with **Copy my lines** and **Drop my edits**. This happens when another start's line now
  runs into it, or the file isn't laid out the way Godot writes it. The edits save again once it is
  editable with the same version.
- A file that can't be read for the moment gets a notice, and the other files carry on.

## Read-only starts

A start can be edited here when it is start → line or signal → … → END, every node reached from
that one place only, every line with its single empty option. Anything else (shared lines,
choices, variables) is left to Godot's graph. The page shows its lines, signals, choices and
variable steps in the order they are reached, and they can be searched and played.

Two things Godot's editor does to a file when it saves one you edited in its graph. A start with no lines
(start → END) drops out of its start list. Its start node stays in the file as a stray, and the
page warns on such a start. If you add the key again here, it gets a second start node; the game
doesn't mind. Godot also takes `{` and `}` out of typed speaker names.

## Scene notes

`config.json` names art-sorter workspaces' `scene.json` files
(`{"notes": ["~/invoke-remote-data/sorted/ashely2/scene.json"]}`). For the stages a scene.json
names, each start shows the dialogue guide's words above its lines: title, when it plays, what
follows, the beat, her state. Click the title to fold them away. A missing file just means no notes.
Changed notes show after Ctrl+R.

## The tests

```
python -P -E tooling/dialogue_editor/tests/test_dialogues.py -v
node tooling/dialogue_editor/tests/browser_test.mjs [--shots DIR] [--keep]
sh tooling/dialogue_editor/tests/godot/run.sh
```

Neither writes to the real project. Both work on a copy of its text files in the temp folder and
read the pictures from the real project. The files they look into line by line are a frozen
snapshot in `tests/fixtures/`, so writing with the editor doesn't make them fail. Refresh it on
purpose with `python -P -E tooling/dialogue_editor/tests/make_fixtures.py`. The live project is
checked only for what holds whatever it says, for example that every start saves back byte for
byte and Godot reads it. Its numbers are printed.

- `test_dialogues.py` (about 90 seconds) covers saving, layout, conflicts, backups, locks, failed
  checks and the HTTP API, and has Godot 4.4.1 load the saved files headless and walk every start
  (`GODOT_BIN` says where Godot is; `DE_SKIP_GODOT=1` skips this). It fails if the real project's
  dialogue files changed during the run.
- `browser_test.mjs` (about 45 seconds, Node 22 and Chrome) drives the page in headless Chrome and
  checks the saved files on disk. It takes screenshots only with `--shots DIR`; they show the
  game's pictures, so keep them on this machine. `--copy DIR` must not be the real project.
- `godot/run.sh` (about 3 minutes, Git Bash) tests the patched Godot addon in a headless Godot
  editor: Godot's saves, reloads, the "Changed outside Godot" dialog, closing files, Save As, and
  opening the biggest file without a crash. It builds a throwaway project in the temp folder from
  `godot/project/` plus a copy of the real `addons/dialogue_nodes`. Run it after any change to the
  addon. `--run-dn-test` runs the first patch's suite.

## When the game changes

- The signal list is read from `src/vn/Main.gd`, `src/vn/DialogueManager.gd` and
  `src/cinematic/cinematic_layer.gd` (atmospheres from `CinematicLayer.tscn`), so it follows the
  code by itself.
- Some things in `editor.html` are copied by hand. `FRAMES` (box positions and fonts) comes from
  `DialogueManager.tscn`'s Layouts, `REPOSITION` from `DialogueManager.gd`, and `FADES` from
  `Background.gd`. Test7 in `test_dialogues.py` says when they no longer match. The markup tags
  the warnings know (`PAIRED_TAGS`) are there too.
- `dialogues.py` reads and writes the files with `../art_sort/package.py` (`Reader`, `write`,
  `fingerprint`…). Run these tests after changing that file.

## Files

- `dialogue_editor.py`: the server and its command line.
- `dialogues.py`: reading a file into starts, what is editable, and saving.
- `editor.html`: the page (one file, no outside requests; its line warnings live here only).
- `config.json`: the scene notes. `done.json`: the starts marked done (made at the first mark).
  `match_pictures.json`: the Ashely II match pictures picked.
  `Open dialogue editor.cmd`: double-click to start.
- `tests/`: the two suites, `helpers.py` (the copy, the fixtures, Godot headless), `godot_walk.gd`,
  `make_fixtures.py` and `fixtures/`.
- `backups/` and `cache/` (thumbnails) are made when needed. Godot and git ignore them, and the
  cache can be deleted any time.
