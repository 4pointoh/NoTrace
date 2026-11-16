# art_sort: from a zip of finished art to ordered folders

Turns a pile of finished images with random names into one folder per picture sequence, numbered
in order, grouped by game stage:

```
export/ashely2_win/WIN_S1_TOP/01.png, 02.png, ...
export/ashely2_win/WIN_S1_TOP/dialogue.txt   its placeholder dialogue, picture by picture (if any)
export/ashely2_match/TABLE__DRESSED/01.png, ...
export/manifest.json        which library image each file is, and its dialogue
```

The export is for looking at, or using elsewhere. To put the sequences into the game, see Into the game
below: each one becomes a `BackgroundList`, with its dialogue.

## Workflow

Everything for one scene lives in a workspace folder, for example
`~/invoke-remote-data/sorted/ashely2/` (it starts with just a `scene.json`):

1. **Add** the images: `python -P -E tooling/art_sort/art_sort.py add <workspace> <zip or folder>...`
   It copies new images into `library/`, makes thumbnails, and guesses each one's sequence. Images
   it is sure or fairly sure about go into their sequence, in a starting order, marked "auto" (a dashed
   outline). The rest wait in the tray. Adding the same zip again skips images already there, so
   add each new board download as it comes. Your earlier decisions are never touched.
2. **Sort** on the board: `python -P -E tooling/art_sort/art_sort.py board <workspace>` (or double-click
   `Open board.cmd` in the workspace). It opens in the browser, and every change saves to
   `board.json` at once.
3. **Export**: the board's *Export folders* button (or `... art_sort.py export <workspace>`). It rewrites
   `export/` from the board. It replaces only files an export wrote, and refuses if anything else is in there.

## The board

- **Tray** (left): images in no sequence yet, each labelled with its guess. The dot shows how sure
  that guess is: green certain, amber likely, red unsure. Filters pick out the unsure ones and the
  odd sizes (not the scene's frame, eg a wide render, or 1153×1536). *Hide odd shapes* takes the
  wrong-shaped ones (the wide renders) out of the tray. Ones only a few pixels off stay.
- **Lanes** (right): one per sequence, under its stage, with the design row, her state, and the count
  against the design's estimate. Drag to place or reorder. **Ctrl-drag copies**, so the same image
  can sit in two sequences. Drag back to the tray to take one placement out.
- **Mark checked** once a lane's order is right. That clears its "auto" outlines.
- **Preview** on a lane (or the tray) opens it large: what the sequence is for (stage, design row,
  her state, the beat description, the design's count), the picture, and the whole sequence as a
  numbered strip below. Clicking any image opens the same view at that image.
- In that view:
  - **← →**, or a click on the right or left of the picture, steps through.
  - **Shift+← →** moves the picture earlier or later in the sequence.
  - **Enter** takes the guess and moves on to the next; **1–3** take one of the alternatives.
  - **L** puts it in *maybe later*, **R** rejects it (out of every sequence), **Del** sends it back
    to the tray, and **Esc** closes.
- **Jump to** (under the header): a button per stage, with how many pictures it holds, and a list
  of every sequence. Each scrolls the board straight there.
- **+ Add a sequence** under a stage, for anything the design didn't plan.
- **Placeholder dialogue**: the preview has a text box for the current picture's lines. Write one
  line per line; `Name: …` gives a line a speaker. The lines show in a dialogue box over the bottom
  of the picture (**H** hides it). **PageUp / PageDown** step pictures without leaving the text box,
  and **Esc** leaves it. Dialogue belongs to the picture's place in that sequence: it moves with
  the picture, and a copy in another sequence can say something else.
- **Play (P)** runs the sequence from the current picture as the game would: full screen, one line
  at a time, then the next picture. Click, → or Space go on, ← goes back, and Esc stops.
- *Later / maybe* and *Rejected* are never exported.

`board.json` keeps its previous version as `board.json.bak`. Each time the board opens it also takes
a dated copy in `backups/`, keeping the newest 30.

## How it guesses (InvokeAI)

Every PNG InvokeAI saves records its prompt and, for canvas work, the images its layers came from.
`scene.json`'s `evidence` points at the campaign renders, which sit in folders named after design
rows (`ash2-shots-05-strip-top/...`). An image's row is then:

- **certain**: its canvas was built on a campaign render, or its prompt is identical to one;
- **likely**: its prompt is at least 60% like a render's (shared words / all words, ignoring words
  most prompts share). On Ashely II's known images, the closest render was in the right row every
  time, even well below that;
- **unsure**: anything weaker. The guess and the next three candidates still show.

The starting order inside a sequence follows the row's beat sheet (`spec.story-*.json`) where it has
one, then render time.

## Into the game

**Put in the game** on the board (or `python -P -E tooling/art_sort/art_sort.py package <workspace>`)
puts every sequence into the Godot project. **Close Godot first.** The editor saves its own open
copies over these files, so the command refuses while Godot runs. Open Godot afterwards, and it
imports the new pictures.

- Each sequence becomes a folder of pictures plus a `BackgroundList` named after it, for example
  `data/background_lists/ashely_poker2/WIN_S1_TOP/` with `01.webp`, `02.webp`… and `WIN_S1_TOP.tres`. In
  the dialogue editor you pick the list `WIN_S1_TOP`, then the picture `WIN_S1_TOP_07`, which is
  `07.webp` in the folder.
  Every picture is named after its sequence because the game treats two pictures with the same
  name as the same picture and keeps the one on screen (`src/vn/Background.gd`). Plain `07`s in two
  lists would leave the wrong picture up whenever one follows the other.
- Pictures go in as **lossless WebP** at the least compression effort: the same pixels as the PNG at
  about 70% of the size. The PNG's
  prompt text stays in the sorter's `library/`, and `export/` stays PNG. A picture put in earlier as a
  PNG becomes `07.webp` on the next run. Every reference to it in the project's text files moves to the
  WebP, and the PNG and its `.import` are deleted. If a binary `.res`/`.scn` names one of them, the run
  stops before changing anything.
- Each sequence's dialogue (the start key named after it) becomes one line per picture, in board
  order. Lines written on the board go in as they are, and `Name: …` picks that character as the
  speaker. Pictures without lines get a "(Placeholder)" line.
- Anything else still showing a placeholder picture switches to the sequence's last picture, for
  example the after-match lines (`WON__…`, `LOST__…`), `THE_END__…`, and the stages' starting pictures.
- A sequence planned on the board before the game has a dialogue for it still gets its pictures
  put in. The report says no dialogue shows them yet. Once a dialogue starts with its key on a
  single "(Placeholder)" line, as the skeleton's do, the next run writes its chain.

Run it again whenever the board changes. **Dialogue points at a picture by position**, its list's
and its own, so nothing ever moves:
- A new picture gets the next number in its sequence, and a new sequence's list goes on the end.
- A picture taken off the board keeps its number, and is renamed `WIN_S1_TOP_07 (off the board)`. Delete it from
  the list by hand once no dialogue uses it.
- A sequence's dialogue is rewritten from the board only while it is still what this command wrote.
  Once you change it in Godot it is yours, and the command only lists the board's new pictures your
  dialogue doesn't show yet.

What has been put in is recorded in the game, in `packaged.json` beside the pictures (which sorter
image is in each slot, and the dialogue chains it wrote). Keep it in git with the rest. Without it the
command can't know the picture numbers, so it stops rather than guess.

The workspace's `scene.json` says where things go, in a `game` block. The fields are listed at the
top of `package.py`.

## The dialogue guide

`python -P -E tooling/art_sort/art_sort.py guide <workspace>` writes one HTML page, and Put in the
game rewrites it after each run. The page has a card for every dialogue start in the scene's stages,
in play order, and each card gives:
- what the scene is, when it plays, and what follows;
- the dialogue file, and the start node's id and position in the editor;
- every line, with its speaker, its text and the picture it shows (list and number);
- the pictures in its list that no line uses yet.

The page reads the game's own files, so a fresh run is never out of date. The words around them
come from the `game` block's `guide` (the fields are listed at the top of `guide.py`). For Ashely II,
the page is `docs/ashely_poker2/dialogue_guide.html`. Open it from there, since its pictures are the
game's own files.

## A new scene

Make a workspace folder with a `scene.json` like `~/invoke-remote-data/sorted/ashely2/scene.json`:

- `stages`, each with its `sequences`: `key`, `designRow`, `campaignRows`, `state`, `estimate` and
  `context`. Optional fields: `kind: "pool"` for an unordered set, and `autoPlace: false` to never
  fill a sequence automatically.
- `frame`, the expected image size.
- `evidence` (the campaign folder, its name prefix, a regex that finds the row code in a run's
  folder name, and the specs folder). Leave `evidence` out to sort by hand with no guesses.
- `game`, where the scene goes in the game, for **Put in the game** (see `package.py`). A sequence's
  key must be its dialogue start key, and its placeholder picture's file name.
