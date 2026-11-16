# TODO

Started 2026-10-11. Row names are DESIGN.md §8's (`docs/ashely_poker2/DESIGN.md`); "the board" is the
art sorter (`tooling/art_sort`, workspace `~/invoke-remote-data/sorted/ashely2`).

## Ashely Poker II: now

The full rendering state (the look you settled on, likes and dislikes, each scene's rounds and
candidates) is in invoke-remote-tool `docs/ASHELY2_RENDER_HANDOFF.md`. Hand that to the
rendering agent.

**All wired, 2026-10-19.** Everything in DESIGN.md §8 is in the game except June's phone scene
(Later, below).
- 345 pictures in 40 sequences, as lossless WebP. Every scene is a "(Placeholder)" chain, one line
  per picture.
- The new sexy ladder (under your clothes, then the blowjob finale) with its two unlockable
  finales, the outfit versions (rows 37–42), and no "nice things" beside an MR1 kiss.

`docs/ashely_poker2/dialogue_guide.html` gives every dialogue start: when it plays, its file and
start node, and its pictures line by line. landscape-test's `ashely2_test` plays every race the
rules allow, and checks each scene's start, ending and pictures.

When new art lands, add it to the board, close Godot, and press **Put in the game**. That also
refreshes the guide.

- [ ] **Write the dialogue.** Start from the dialogue guide. Every scene is a "(Placeholder)" chain.
      You can write on the board (the preview's text box), and Put in the game carries it over while
      the scene is still untouched in Godot. Or write in Godot's dialogue editor: the scene is then
      yours, and the packager leaves it alone.
      - **Sign-offs** (added 2026-11-10): the 14 stake scenes that can be your last stake or an
        earlier one each have a `…__NEXT` (the race goes on) and a `…__LAST` (it was your 4th
        stake) start right after them in the won-match file. They are optional: write over the
        placeholder line of the ones you want, and leave or delete the rest (an unwritten one
        never plays). The notes above each start say when it plays and what follows. DESIGN.md
        §8, "Sign-offs".
- [ ] **Ashely's text (`ashely2_phone`)**, added 2026-10-25: rewrite its placeholder chat in
      `data/game_stages/phone_message/ashely2_phone/ashely2_phone_script.gd`. Anna's night offers
      it, and reading it unlocks Ashely Poker II. The Rematch With Ashely checkpoint lands on the
      phone with it waiting. The intro picks up right after it ("Ashely insists she has another
      target...").
- [ ] **The first forfeit (`INTRO_FORFEIT`)**, added 2026-10-25. The intro now leads into a
      scripted first hand: one life each, no cheats, your kings full of queens against her four
      aces. Then her forfeit for you plays, before the race's first match. The idea: she sets the
      stakes, so the player knows the race gets spicy and that she's fine with it.
      - Write it: `d_ashely2_intro_forfeit.tres`, start `INTRO_FORFEIT` (Ctrl+P "intro forfeit" in
        the dialogue editor). It has one placeholder line over the dressed table.
      - Decide what she makes you do. Her punishments (ass kiss, dick pic, walk/bench girl, naked
        run) are taken, and so are the ladders' kiss and touches.
      - Art: it may want a render set of its own. Add an `INTRO_FORFEIT` sequence to the board under
        stage `ashely2_intro_forfeit`. Put in the game then makes its picture list. While the scene is
        still its one placeholder line, it also gives the scene a placeholder line per picture.
        After you've written it, it only lists the pictures no line shows yet.
      - The intro's last two lines are still placeholders: "(Placeholder) The first match starts."
        and "Deal."
- [x] **`LOSE_P2_DICK_PIC`** has its own art (2026-11-15): a dressed set and a topless one
      (`LOSE_P2_DICK_PIC__TOP_OFF`, lists 44 and 45), picked by `Race.punishmentKey()`, both written.
- [x] **Music.** Done: the intro plays "Tuesday at Ten" (`play_music_0`), then every stage rotates
      the six tracks in `bg_music/ashely2/` (`randomMusic`; a stage change keeps the current track,
      a new one starts when it ends). The true ending has its own: "Park Stakes" (2026-11-15),
      imported with loop on, track 0 of `gs_ashely2_win.tres` `musicList`, started by the
      `play_music_0` signal in `WIN_L4_KISS`: since 2026-11-16 at the first fade to black after the sex
      ("And then you're left just looking at each other."; the song was too soft to play through it).
      Looping, it never ends, so it carries on through `THE_END__L4_KISS` until the phone's own music takes over.
- [ ] **Questions from the wiring review (2026-10-19):**
      - Wallpapers: done 2026-11-16 (134, see the Wallpapers item).
      - `WIN_L1_TRUTH__PANTIES` 02 and 03 are the same pictures as `WIN_L3_SMILE__TOP_OFF` 07 and
        02, which is the shorts-on scene. Check that they don't show her shorts.
      - `WIN_MR3_INSPECT` (7 pictures, any outfit) and `LOSE_P3B_BENCH_GIRL` (dressed or topless)
        each have one list. Check that their pictures don't show what she's wearing.
- [x] **`LOSE_P3A_YOUR_WALK`** written 2026-11-15 over the picture already up and `INTRO_PARK`'s empty
      paths (told in the story), so its 1920×1080 stand-in isn't shown any more.
- [ ] **Pictures no line shows**: `INTRO_WAGER` 01 (the intro shows 02). Place it when you write
      the intro. The TABLE lists are fine: a match opens on a random one.
- [ ] **The board's tray** holds 15 images, 13 of them 1920 wide. Place or reject them.
- [x] **`WIN_X4_SEX__DRESSED`** written 2026-11-15 as the playful one (no longer cold; DESIGN.md §9):
      she undresses in-scene over borrowed strip pictures, then the scene's 1, 8, 7, 6, 3, 2, 10.
      The park truth `WIN_L1_TRUTH__PANTIES` written the same day: she answers "never... in a park".
- [ ] Minor: loading a save made during a won match, a lost match or the ending flashes the
      dressed table for a frame. Their `gs_*.tres` startingBackground is `TABLE__DRESSED/06`.
- [ ] **Videos** (short static-camera loops, MiniMax H3). Research done 2026-10-20:
      `docs/video/H3_RUNPOD.md`. Open:
      - Where you live and sell the game: H3's free licence excludes the US, EU, UK and South
        Korea, outputs included. Civitai generation has its own licence from MiniMax.
      - Runpod's terms list adult content as unauthorized; decide whether to ask their support.
      - A first test batch: does the same still as first and last frame loop? Minutes per clip,
        tries per usable clip.
      - Finishing (decided 2026-10-23, `docs/video/ENHANCE.md`): the production cut upscaled with
        SeedVR2 7B to 1152×1536, 24 fps, BT.709 converted to BT.601 for Theora. Done 2026-10-23 by
        `tooling/video_gen/finish.py`.
        - Ashely II's videos are in `data/background_lists/ashely_poker2/video/`, listed in `videos.gd`.
        - `Background.gd` plays them over their stills: loops after their intro, other videos once.
        - Slots with several picks: V cycles through them in a debug build. Keep one per slot (or
          decide how the extras are used), then drop the rest from the plan and rerun `finish.py`.
        - 2026-10-24: 31 play-once picks became seamless loops, and 3 loop as they are (76 of 105 loop).
          - 8 of them got their regenerated stretch resized locally instead of by SeedVR2 (the Runpod balance had
            run out; the user: "dont need to be perfect, just loop them"):
            X2_BREAST__TOP_OFF/03, /09; X3_BJ__DRESSED/08, /09; X3_BJ__TOP_OFF/01, /02; X4_SEX__DRESSED/02, /08.
            The colour and detail are matched to the SeedVR2 frames around them.
            `<library>/looptest/scripts/r5/` (README, localwin.py) can redo those stretches with SeedVR2 for
            about $2.
          - Left as play-once, the user being happy with them: L4_KISS/48, /57; MR3_INSPECT/02; S4_PANTIES/12;
            X1_BUTT__DRESSED/02. Their loops are made (r5 state.json) if wanted later.
- [ ] **MR1 follow-up menu.** After `WIN_MR1_KISS` (always your 3rd win), your 4th-win menu
      should offer only these three; the walk, the butt touch and the regular nice-things scene
      drop out, since they don't follow a kiss:
      - "Kiss me like you mean it" (`WIN_MR1_FINGER`, the MR1 finale);
      - an MR1 version of "Say two nice things about me", with its own dialogue;
      - "Your shorts come off".

      The change:
      - about 10 lines in `ashely2_race.gd` `stakeMenu()`;
      - a placeholder scene or two in `d_ashely2_win.tres` (Godot closed while editing);
      - placeholder pictures added at the end of the list;
      - DESIGN.md, `scene_model.json` and the possibility map;
      - a board row.

      Open:
      - Shorts off: reuse the regular `WIN_S3_SHORTS` scene, or give MR1 its own dialogue over
        the same pictures? The regular one is written as defiance after the walk.
      - Does the MR1 nice-things scene end on the general topless wrap-up (`FINAL__TOP_OFF`), or
        as its own closing beat like `WIN_MR1_FINGER`?

- [x] **Replays** (2026-11-16): picking Ashely Poker II again on the phone opens its replay menu
      (cheats each match: none, 2, or 5 after the true ending; a hint, then the straight answer). DESIGN.md §10.
- [ ] **Before shipping:** set `GlobalGameStage.skipUnreadInEditor` to false (src/vn/GlobalGameStage.gd).
      It only works in the editor (`OS.has_feature("editor")`), so an exported build can't skip unread
      dialogue either way; turning it off makes editor playtests match what players get.
- [x] **Wallpapers** (2026-11-16): 134 Ashely II pictures, picked in the dialogue editor's Gallery (★ Wallpapers,
      `tooling/dialogue_editor/wallpaper_picks.json`), only ones some line shows (the rest could never unlock).
      - Each is `ASHELY2_<picture>` in `resources/wallpapers/all_wallpapers.tres`, with a hint naming what shows
        it ("Ashely Poker II: “A real kiss” (3)") and the picture's video when it has one (81).
      - A line showing the picture unlocks it (`Background.wallpaperId`, src/vn/Main.gd). The id comes from the
        slot's "wallpaper" in `packaged.json`, which `tooling/art_sort/package.py` writes into the list files.
        So add or change one there, then package.
      - The phone offers `GlobalGameStage.shownWallpapers()`: all but those still on placeholder art (Amy's
        meetup's 3, cut from this update). With real art they show.
      - The phone's app loads 9 a page, so the count doesn't slow it.
- [ ] **June's phone scene (`PHONE_BENCH_GIRL`)**: finish it. It will be 1080p after the screen
      expansion; the board has 1 portrait picture now. The board's frame for Ashely II is
      portrait (1152×1536), so 1080p pictures there get size warnings and are hidden by
      *Hide odd shapes*. Give the sorter a per-sequence frame first.
- [ ] **Amy's dating scene**: finish it. It contains the first 1080p expansion, where the game
      switches from portrait to landscape.
- [x] **A prettier selection menu.** Done 2026-11-10 (`src/vn/ChoiceDisplay.tscn`,
      `src/vn/choice_display.gd`, `src/choice_display_button.gd`, `src/vn/choice_glass.gdshader`).
      - A frosted panel on the frame's bottom edge, with a title rule.
      - The stake menu is a list, a row per stake, each marked New / Seen 1 of 3 / Seen all /
        Locked (DESIGN.md §8, "The stake menu's marks").
      - Anna's class marks its route menus too (same day): each route says how much of what it
        leads to you have found, eg: "Seen 2 of 8" on Stay Here (its 5 endings and the quiz's 3
        results), "Seen 1 of 3" on Explore. The quiz's questions carry no marks, so they stay side
        by side. The route tree is `LEADS_TO` in `AnnaClassChoices.gd`.
      - Lisa's after-poker menu has the new look but keeps its choices side by side, in the room
        the old menu took, with no marks. A scene gets marks by giving its ChoiceScript a
        `getChoiceMarks`; a menu with marks becomes a list.
      - landscape-test `choice_menu_test` saves a picture of each kind of menu
        (`out/choice_menu_*.png`).
