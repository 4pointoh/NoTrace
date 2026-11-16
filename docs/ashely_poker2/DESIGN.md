# Ashely Poker II — "Rematch: Stakes" (working title)

Chained-match wager scene: design notes, engine investigation, and required changes.
Written 2026-08-05. Status: **design phase** — scene model is a strawman, events not yet locked, no art produced.
**Status 2026-10-19:** in the game and fully wired: 345 pictures in 40 sequences, every scene's dialogue a
placeholder chain. `dialogue_guide.html` (next to this file) maps every dialogue start to its file and pictures.

Interactive possibility map (state lattice + auto-computed shot list):
**`possibility_map.html`** next to this file — open it directly in a browser. It is fully
self-contained and offline: no network, no CDN, no build step. This is the authoritative copy.

Route explorer (2026-10-14): **`route_explorer.html`** next to this file, to click through races
the way the game plays them: stake menus, punishments, endings, the game's own pictures, what you
have seen so far, and how often races reach each scene. Its rules are a copy of
`data/scripts/ashely_poker2/ashely2_race.gd`; keep the two in step. Open it where it is, since it
reads the pictures from `data/background_lists/ashely_poker2/`.

`scene_model.json` and `possibility_map.html` predate rows 37–42 and the new sexy ladder (2026-10-14):
for those, `ashely2_race.gd` and the route explorer are current.

The canonical scene model lives in `scene_model.json` next to this file, and is inlined into
the map as its baseline (the two are kept byte-identical). To recompute after editing the
model, use *Load a .json from disk…* at the bottom of the page — `file://` blocks `fetch()`,
so the map cannot read the sibling JSON on its own. *Download as scene_model.json* writes
in-page edits back out.

A hosted mirror exists at
<https://claude.ai/code/artifact/62cb1513-1fe7-4c3d-9fa3-5e3413114158> — convenient for
sharing, but nothing here depends on it. If the two ever disagree, the local file wins.

---

## 1. Concept (v3 — forfeit race)

A step up from `ashely_bar_poker` (pure stripping). Premise: **"whoever forfeits first,
loses."** Short poker matches repeat until one side has lost 4 stakes (4–7 matches total;
optionally forfeit the player at her 3rd win instead — see §7):

- **Player wins a match** → picks the **next rung of one themed ladder** (his win #k is his
  k-th pick; 4 total picks ends the scene — she forfeits rather than give up a 5th):
  - **Strip ladder** (the core 4 scenes; NO BRA — she isn't wearing one):
    top off → **walk around the park topless** (Janet & Ted elderly-couple gag) → shorts off
    → panties off. Fixed order; the walk keeps the route at exactly 4 picks and, since it
    changes no state, it *tightens* the pyramid for every other ladder.
  - **Sexy ladder**: butt touch → breast touch → BJ → sex, fixed order (changed 2026-10-14: butt →
    breasts → under your clothes → the blowjob finale, with sex and the topless blowjob unlocking
    across races; see §8). Early rungs vary
    visually by how stripped she is when they fire.
  - **Love ladder**: truth → (rung 2 TBD) → (rung 3 TBD) → a real kiss where she melts —
    you never asked for anything uncomfortable even while her punishments hit you all scene.
    (2026-10-12: and she takes it further herself, into sex in the grass; see §9 rows 16 and 21.)
    The truth's QUESTION varies by context in dialogue only (benign on the pure path; "what's
    your bra size" when she's topless — which feeds mini-route 1).
  - **Mini-routes (~4 total)**: highly specific railroaded pick-combos that surface special
    events. MR1 (locked): top → truth(bra-size) → kiss → heavy kiss + fingers in her shorts
    (4th win, only reachable topless-with-shorts-on). MR2–MR4 TBD. Railroading = each
    mini-route scene has exactly ONE reachable state = 1 render set each.
  - Tone rule: **Ashely is never diminished.** No taming/submission framing anywhere — she
    pays her bets loud, defiant, and gives as good as she gets.
- **Ashely wins a match** → her **predetermined punishment #k** fires (k = her win count).
  No player choice, no player state: money, dares, photo leverage — pooled art, framed on
  you / her face. Her win #4 = you forfeit = the losing ending. Losing a match never retries;
  the loss track just advances.

**Key structural fact**: her wins *interleave anywhere* between the player's win-slots without
changing the player's ladder position or her appearance. The whole loss dimension adds match
count and dialogue, not art states. This also dissolves v2's "sweep problem" — losses no
longer burn win-slots, so every run eventually reaches a real ending, and the love narrative
("she was devious to you the whole time, you never fired back") now works literally: most
players WILL eat punishments on the way to 4 wins.

**Endings**: your 4th win = her forfeit — themed ending if your 4 picks completed one ladder,
mixed-forfeit wrap otherwise (per appearance state). Her final win = your forfeit ending
(pooled by default).

**The pyramid rule** (why this structure is art-cheap): exactly 4 win-slots, and the strip
ladder needs 3 picks just to reach shorts-off (top, walk, shorts). So outfit variants shrink
hard as content escalates: butt touch ×3 (dressed / topless / panties-only), breast ×2,
BJ ×2, sex ×1 (fully dressed) — the most explicit art is the cheapest to keep consistent.
Strip scenes never multiply (deterministic entering state). Table/ambient art is per *state*,
shared across all matches (3 sets: dressed, topless, panties-only — naked never sits at the
table, the scene ends there). Punishments can fire at any of the 3 table states — keep them
pooled or they multiply ×3. Setting: a deserted public park, which gives the walk gag and any
exhibition flavor for free.

## 2. Why the art doesn't explode: dims vs flags vs pools

The art budget depends on **states, not paths**:

- **Appearance dims** (her top off, her pants off, your shirt off) must stay consistent in all
  later art. Only these multiply renders. Unlock chains keep the count down (2 chained her-dims
  = 3 reachable states, not 4).
- **Narrative flags** (truth told, photo taken, kiss happened) gate later options and change
  dialogue, but never show in her ambient art → cost writing, not renders.
- **Pooled events** framed so outfit doesn't show (close-ups, money) need exactly one render
  set — the `shirt_irrelevant` pattern from boa.
- **Mechanical stakes** (extra cheat next match, a life handicap) cost *zero* art and pad the
  menus.

The artifact computes reachable states per win-slot, dedupes ladder-rung art across matches
(`sharedId`), flags dead options, and emits the full shot list with suggested dialogue keys
(`WIN_X1_BUTT__TOP_OFF`) and an estimated image total.
**v7 tally (all ladders + MR1 + full punishment track + P4 art): 32 render sets, ~117 images,
4 end appearance states** (dressed / topless / panties-only / naked).
Breakdown: win rungs 18 sets (strip 4, sexy 3+2+2+1, love 4, MR1 2) / punishments 5
(ass-kiss ×2, dick pic, P3a walk-mirror, P3b bench girl) / P4 forfeit ×2 (dressed+topless,
seated) / table 3 / her-forfeit endings 4. Plus bench-girl phone spin-off ≈ 4 images and
MR2–MR4 (TBD) ≈ +12–15. Match count (4–7) does not appear anywhere in that math.

## 3. Engine investigation (what exists, with receipts)

### Precedents this scene is assembled from

| Pattern | Where proven | What it gives us |
|---|---|---|
| Chained small matches with VN stages between | `lisa_sp_poker_poker1/2/3` + `*_after` stages, linked by `guaranteedNextGameStage` | The stage spine |
| Choice menus driven by global state | `LisaPokerChoices.gd` (gates options on `lisaMassagePoints`), `AnnaClassChoices.gd` | The "pick your stake" screens |
| Silent state-based routing | `choice_display.gd:17-19` — a `GUARANTEED` key in the choices dict auto-selects a start key with no UI | State-dependent entry into a stage |
| Parallel art tracks per appearance state | boa: `bgs.tres = [no_shirt, with_shirt, shirt_irrelevant, home]`, dialogue nodes carry `backgroundList` index | Outfit-consistent CGs |
| Write dialogue once, fork only visuals | boa `SHIRT`/`STRIP_LEVEL` Set/Condition nodes (`d_boa_poker_new_poker.tres:3409-3513`) — the only graph in the project using dialogue variables | Halves authoring cost on shared lines |
| State-suffixed dialogue keys from game code | `boa_poker_new_script.gd:57-70` appends `_WITH_SHIRT` to every start key after the player strips | Mid-match ambient art per state |
| Event matrix → keys | `ashely_bar_poker` CSV (event × opponent-state → `Dialogue_Key`, cells collapsed for art reuse) + `tooling/poker_generator.gd` | Optional, if matches ever get mid-match events |

### Key mechanics verified in code

- **VN stages always enter at `START`** — `Main.gd:538-544` (`beginDialogue()` no-arg). The
  `GameStage.dialogueStartKey` field is *not* consulted for VN stages. State-dependent entry
  must go through the `GUARANTEED` router (see §4).
- **Choice loop** — `Main.gd:555-560`: when a segment ends and the current key isn't in
  `endingDialogueKeys` (with `endOnlyOnSpecificDialogueKey = true`), `choicesScript
  .getChoicesForDialogueKey(currentKey)` is called; result renders as buttons, or auto-routes
  via `GUARANTEED`.
- **Dialogue variables are sandboxed** — no bridge between `GlobalGameStage` and
  `DialogueBox.variables`. A Condition node can never read a save flag. Gate with start keys
  from code; use Set/Condition only for within-run convergence (boa pattern).
- **Losing always restarts the match** — `Main.gd:612-617` `_on_poker_game_five_game_lost()`
  rebuilds the same poker scene unconditionally. There is no lose-and-advance path in the
  engine today. **This is the one real engine change this scene needs** (§5).
- **Win path** — `Main.gd:619-627`: stamps `markStagesCompleteOnPokerWin` into
  `completedStages`, then `advanceGameStage()`.
- **Poker stage opening background is static** — `Main.gd:319` (`startNewPoker`) sets the
  stage's inline `startingBackground`. Mitigation in §5.
- **Persistent flags** — `completedStages : Array[String]` on the `GlobalGameStage` autoload
  is the idiomatic per-save flag store (`markStageComplete` / `hasCompletedStage`,
  `GlobalGameStage.gd:778-783` / `:416`). Sentinel strings need **no save-version bump**
  (unlike new typed vars, which require `saveSaveData`/`loadSaveData` edits + `VERSION` bump,
  currently 017).
- **Art indices are fragile** — dialogue nodes store raw `backgroundList`/`background` array
  indices into `bgs.tres`. Freeze list order before authoring the graph; never re-save lists
  through `ResourceSaver` (see warning in `tooling/repopulate_wallpaper_ids.gd:12-15`).
- Spelling: paths/keys use **"ashely"**; `CHARACTERS.ASHLEY` enum is spelled correctly.
  Don't normalize.

## 4. Proposed architecture

> **As built (skeleton, 2026-10-02)** — this section and §5 are the original proposal; the code
> differs. Source of truth: `data/scripts/ashely_poker2/ashely2_race.gd` (all race rules).
> - A portrait scene throughout (decided 2026-10-11; Amy's meetup is what turns the game landscape).
> - Stages: Ashely's text `ashely2_phone` (phone message, unlocks the event) … `ashely2_intro` (VN) → `ashely2_intro_poker` (the first hand) → `ashely2_intro_forfeit`
>   (VN, start key `INTRO_FORFEIT`) → `ashely2_match` (poker)
>   → won: `ashely2_win` (stake menu) / lost: `ashely2_lose` (punishment) → back to the match, or
>   → `ashely2_ending` → phone. The way back to the match is set in code (a .tres link would be
>   cyclic); the result stages' `guaranteedNextGameStage` is the ending.
> - **The first hand (2026-10-25):** a scripted hand before the race. It sets up "whoever loses
>   does what the winner says". Ashely sets the stakes herself, so that asking her for something
>   spicy later doesn't feel out of nowhere. One life each, no cheats, and she always wins: the deck
>   is stacked (`PokerScript.stackedDeck()`, `Deck.stack`). You get kings full of queens and she gets
>   four aces. No card you can draw makes a straight flush, the only hand that beats hers. Her
>   forfeit for you is `INTRO_FORFEIT`, still to be written. It isn't one of her four wins, since
>   the race starts at the end of the intro.
> - Flags: `ashely2_race_pick_<option>` / `ashely2_race_punishment_<id>` /
>   `ashely2_race_bra_size_truth`, cleared when a new race starts (the intro), so a replay starts
>   clean. Kept after the race: `ashely2_won` (won it at least once), `ashely2_bench_girl_unlocked`,
>   and the unlock progress `ashely2_unlock_park_truth` / `_warm_sex` / `_dressed_blowjob` /
>   `_topless_truth` (2026-10-19).
>   Picks and punishments are written as their stage ends, after the autosave
>   (`GlobalGameStage.setFlagAtStageEnd`), so reloading that autosave can't count one twice.
> - Engine: `GameStage.pokerLossGameStage` (lose-and-advance, §5 A), `PokerScript.startingBackground()`
>   (state-variant match picture, §5 B), `GameStage.skipsOnlySeenDialogue` (quick skip in the
>   result stages passes only lines already read).
> - Dialogue start keys and pictures use the §8 row names; a picture is the Background named
>   `ashely2_` + row (placeholders in `data/background_lists/ashely_poker2/placeholders/`).

### Stage spine (v3: a two-stage LOOP, not a chain)

```
gs_ashely2_intro (VN)                          phone-gated like other events
  └─ gs_ashely2_match  (poker, 2-3 lives, isCompletable = false)
       └─ guaranteedNext → gs_ashely2_result (VN + choicesScript, isCompletable = false)
            └─ guaranteedNext → gs_ashely2_ending (VN)   ← the DEFAULT exit
                 └─ gs_phone

LOOP-BACK (runtime only, no circular .tres refs):
  gs_ashely2_result's choicesScript, while routing, checks the score:
    if player wins < 4 AND her wins < forfeit count:
        GlobalGameStage.setNextGameStage(Flags.ASHELY2_MATCH)   # GlobalGameStage.gd:204
    else: leave nextStage alone → falls through to gs_ashely2_ending
```

This is the same runtime-redirect trick the date minigame already uses for retries
(`Main._on_date_complete` → `setNextGameStage(currentStage)`). `advanceGameStage()` re-derives
`nextStage` from the *new* current stage each hop (`GlobalGameStage.gd:181-184`), so the loop
closes cleanly and exits the moment the script stops overriding.

**Loop stages must be `isCompletable = false`** — `advanceGameStage()` appends
`currentStage.name` to per-save `completedStages` *without* a dupe guard
(`GlobalGameStage.gd:158-159`); a 7-iteration loop would append 14 junk entries.
Mark the real scene completion on `gs_ashely2_ending` via `markStagesCompleteOnSceneEnd`.

**Score tracking (all derivable from sentinels, no save-format change):**
- player wins = count of pick sentinels (`ashely2_top_off`, `ashely2_butt`, …)
- her wins = count of punishment sentinels (`ashely2_p1` … `ashely2_p3`)
- last-match result: match stage stamps `ashely2_last_won` (via `markStagesCompleteOnPokerWin`)
  or `ashely2_last_lost` (via the new `markStagesCompleteOnPokerLoss`, §5). The result stage's
  script consumes it and erases it from `completedStages`/`completedStagesGLOBAL` after
  routing — erase-after-consume survives the autosave-on-advance, so quit/reload at the
  result stage replays correctly.

### State: `completedStages` sentinels, prefix `ashely2_`

- Appearance dims: `ashely2_top_off`, `ashely2_pants_off`, `ashely2_your_shirt_off`, …
- Match results: `ashely2_m1_won` / `ashely2_m1_lost` (stamped by the match stage; the result
  stage reads them to decide who picks).
- Narrative flags: `ashely2_truth1`, `ashely2_photo`, `ashely2_kiss1`, …
- ~~**Replay hygiene**: the intro stage's script erases all `ashely2_*` entries from
  `completedStages` on entry so a replay starts clean.~~ Superseded: only the `ashely2_race_*`
  flags are cleared; `ashely2_*` would also erase stage completion and the kept outcomes.

### Result-stage routing (zero engine changes)

1. `START` subtree = one state-neutral beat (pooled framing: she gathers the cards). Ends on a
   non-terminal key.
2. `choicesScript` fires: reads sentinels → returns `{'GUARANTEED': '<state-specific key>'}`
   to enter the right subtree (won vs lost × appearance state).
3. The win subtree ends non-terminally again → `choicesScript` returns the actual **stake menu**
   (options filtered by state/unlocks). The lose subtree routes to the event *she* picked
   (script chooses — random or personality-driven, TBD).
4. Each stake's subtree plays its render set, stamps its sentinel, ends on a terminal key
   (`endingDialogueKeys`) → `advanceGameStage()` → next match.

### Art organization (per result stage / match stage)

- `bgs.tres` per stage, list order frozen up front:
  `[ ashely2_dressed, ashely2_top_off, ashely2_toppants_off, ashely2_irrelevant, home_bgl ]`
- Shared dialogue lines converge with boa's Set/Condition trick; fork only nodes whose art
  differs.
- Dialogue start keys follow the artifact's generated convention:
  `M{n}_{WIN|LOSE}_{OPTION}__{STATE}` (these map 1:1 to shot-list rows).
- Folders under `data/background_lists/ashely_poker2/` mirroring list names; generate `.tres`
  with `tooling/bg_loader.gd`.

### Matches

- Small `playerLives`/`cpuLives` (4–5). **No clothing stack / no CSV needed** — nothing strips
  mid-match; win/lose is the only outcome. `life_tracker` caps at 20 lives — no issue here.
- Ambient banter via a small `pokerScript` whose ambient keys get a state suffix read from
  `GlobalGameStage` (boa's `_WITH_SHIRT` mechanism).
- Opening background: use a **pooled state-irrelevant table shot** (deal-in framing) so the
  static `startingBackground` is never wrong. Optional later: a script hook for state-variant
  table art (§5, optional change B).

## 5. Required engine changes

**A. Lose-and-advance (required, ~10 lines + 2 exported fields).**
- `GameStage.gd`: add `@export var advanceOnPokerLoss : bool` and
  `@export var markStagesCompleteOnPokerLoss : Array[String]`.
- `Main.gd:612` `_on_poker_game_five_game_lost()`: if `advanceOnPokerLoss` → stamp the loss
  sentinels, `queue_free()` the match, `advanceGameStage()`; else current retry behavior.
  Backward compatible — every existing poker stage leaves the flag off.
- Consider whether `pokerStageHistory` loss counting should still apply (it should — leave
  `addLossToPokerStageHistory()` in `poker_game.gd:433-446` untouched).

**B. (Optional) state-variant match opening background.**
Only if a pooled deal-in shot ever feels wrong: let `startNewPoker()` (`Main.gd:311-319`) ask
the stage's `pokerScript` for an override background before falling back to
`startingBackground`. Skip until proven needed.

**C. Replay cleanup helper.**
`GlobalGameStage` has no "unset flag" API; the intro script can `completedStages.erase(...)`
directly, or add a small `clearStagePrefix(prefix)` helper. Note `completedStagesGLOBAL` should
NOT be cleared (it drives cross-save gallery/skip).

## 6. Production workflow (when art starts)

1. Lock events in `scene_model.json` → artifact recomputes the shot list (= full render
   checklist with keys and estimated image counts). Copy CSV from the artifact if useful.
2. Produce renders per shot-list row → drop into `data/background_lists/ashely_poker2/<list>/`.
3. Run `tooling/bg_loader.gd` per folder → `BackgroundList` .tres files; assemble frozen-order
   `bgs.tres` per stage.
4. Author dialogue graphs, one `d_*.tres` per stage, start keys named per the shot list.
5. Create `gs_*.tres` chain, register in `Flags.gd` + `getAvailableSelectableEvents()`
   (gate TBD — where in Ashely's arc this sits).
6. Engine change A, then playtest all routes with the debug scene-select.

## 7. Open gaps (the remaining brainstorm agenda)

1. ~~**Love rungs 2–3**~~ **LOCKED**: L2 = "Say two nice things about me" (she tries 'you're
   hot' — refused, she trashes your looks weekly; grits her teeth, lands two surprisingly real
   ones). L3 = "Show me a real smile" (smug goading smile → refused, 'drop the tough-girl
   bullshit' → protests → the real one). Same emotional mechanic both rungs: reject the
   performance, get the real thing — sets up the kiss.
2. ~~**Punishment track**~~ **LOCKED (all four)**:
   - P1 = **"Kiss my ass." Literally.** Two art variants by shorts on/off. Framing contract:
     from behind / below mid-back, so top-on vs topless doesn't split it into 3 variants.
   - P2 = **The dick pic.** You agree planning a dead number → "hold up... I pick the person"
     → she scrolls your contacts, comically vetoing love interests ("Hmm... this Lisa girl?
     ...no.") → lands on your old female physics professor. Pooled art (phone/faces).
     **Future-update hook**: professor phone chat after the date (phone_message stage).
   - P3 = **conditional on her walk having happened**:
     - P3a (walk done) = **your walk** — underwear, same path, Janet & Ted encore
       ("I remember when you used to look like that, Ted." / "No you don't, Janet.").
       Frame Ashely out or face-only.
     - P3b (no walk) = **the bench girl**. She dares you to ask a stranger for her number
       then say "just kidding" — pure asshole move. You refuse to be cruel, take the number
       for real; the girl skips off giggling. Ashely knew you wouldn't do it — *watching you
       struggle was the punishment*. Then, nonchalant-but-not: "you actually going to text
       her?" — "Maybe." — frown — "Whatever. Next match." **New side character: bench girl.**
       **Future hook: her number becomes a contact.**
   - P4 (her 4th win) = **the naked run** — the forfeit mechanism, see #3.
   - **Bench-girl phone unlock (stretch challenge)**: seeing P3b AND then winning the scene
     (her forfeit) unlocks a sexy bench-girl phone conversation afterwards — i.e. lose exactly
     3 matches, then still take your 4th win. Sentinels: `ashely2_p3b` + `ashely2_scene_won`
     gate a phone_message stage. (Note: P3b + full strip CAN coexist — her 3 wins just have to
     land before your walk pick.)
3. ~~**You-forfeit ending**~~ **LOCKED**: P4 — she demands you strip fully naked and run the
   park. "That's illegal." (If she's topless: "I'm topless, aren't I?" → "that's legal for
   women here.") You sigh — impossible — and forfeit, ending the poker cycle. Forfeit
   threshold confirmed at her **4th** win. **Art (2 sets)**: expressive, devious Ashely
   daring you — no nude player art. She is SEATED so shorts state never shows: exactly a
   dressed + topless pair.
4. **Mini-routes** — MR1–MR3 LOCKED, MR4 open:
   - **MR1**: top → bra-size truth → kiss → heavy kiss + fingers in her shorts (4th win;
     topless, shorts on; her-forfeit finale variant).
   - **MR2**: lives inside the TOPLESS breast-touch render — you reach, she stops you: "only
     my hands get to touch me." Close-range self-touch tease (breasts/upper body, grazing her
     own waistline), then she stops cold. An interception, not a show she volunteers.
     Rung still counts (rung 3 opens). Zero extra sets — redefines `WIN_X2_BREAST__TOP_OFF`.
   - **MR3**: the inspection. Fires ONCE, hijacking your first touch pick after the dick-pic
     punishment. "Fair's fair — the professor got a preview." Hand in your shorts; annoyed
     verdict: "Fuck... you're huge." Plays with it a bit, withdraws: "That was your prize.
     Deal with it." **Consumes the pick — no rung progress** (that run tops out at 3 ladder
     rungs → mixed wrap). 1 pooled set.
   - ~~MR4~~ **RESOLVED: three mini-routes is the final count.** (Unused candidates kept for
     future scenes: "One-handed", "3–3" stare-down, "The jacket", "Double or nothing".)
5. ~~**Walk variant question**~~ **RESOLVED**: her walk is in her shorts (topless, shorts on,
   strip rung 2) — exactly as modeled.
6. ~~**Janet & Ted on-screen or off?**~~ **RESOLVED: rendered.** Two side-character designs
   needed; they appear in her walk + your P3a walk.
7. ~~**Truth-while-topless art**~~ **RESOLVED: split into two renders** (benign/dressed and
   bra-size/topless). General rule: every scene gets at least a minimal render; reuse with
   expression changes is fine.
8. ~~**Mixed 4th-win wrap**~~ **RESOLVED: keep per-state (max renders)** — reduce during
   rendering only if it feels affordable.
9. **Intro / wager-setup beat** — content TBD (owner will figure it out as writing happens),
   but renders ARE required: `INTRO_WAGER` row in §8. (2026-10-25: the intro now leads into a
   scripted first hand that she always wins, then her forfeit for you, `INTRO_FORFEIT`, which
   sets the stakes; see §4. What she makes you do is still to be decided, and it may need a
   render set of its own.)
10. ~~**Arc placement/gating**~~ **RESOLVED**: ~~unlocked after the new `amy_meetup` scene
    (separate content in this same update).~~ Changed 2026-10-02: unlocked after `anna_night`;
    Ashely II comes first, Amy's scene follows it. (2026-10-11: Ashely II stays portrait;
    Amy's meetup intro is what turns the game landscape.) (2026-10-25: Anna's night now offers
    Ashely's text, `ashely2_phone`, and reading that unlocks the event, as most events do.)
11. **Match length** — tentatively **5/5 lives**; tune during implementation (scene is long,
    may reduce).

## 8. THE PRODUCTION LIST (final — design locked 2026-08-06)

**42 render sets, ~159 images** (row 21 grew to 12 on 2026-10-12; rows 37–42 added on 2026-10-14). One row = one render set (a short CG sequence). Work top to
bottom: side-character designs first (they block rows 6, 29, 30, 36), then foundations, then
ladders. "State" = what Ashely must look like in EVERY image of that set.

**Prerequisite designs**: Janet & Ted (rows 6, 29) · bench girl + her name (rows 30, 36).

| # | Scene | Her state | Context | Est |
|---|---|---|---|---|
| **Table / ambient** — behind every match |||||
| 1 | `TABLE__DRESSED` | dressed | Park table idle, dealing, reactions | 2 |
| 2 | `TABLE__TOP_OFF` | topless, shorts on | Same framing | 2 |
| 3 | `TABLE__PANTIES` | panties only | Same framing | 2 |
| **Intro** |||||
| 4 | `INTRO_WAGER` | dressed | The "whoever forfeits first" pitch; her motivation (write as you go) | 3 |
| **Strip ladder** — fixed order, each fires from exactly one state |||||
| 5 | `WIN_S1_TOP` | dressed → topless | Top comes off at the table (no bra), defiant | 4 |
| 6 | `WIN_S2_WALK` | topless, shorts on | The park walk; Janet & Ted rendered ("...used to look like Ryan Gosling, Ted") | 5 |
| 7 | `WIN_S3_SHORTS` | topless → panties only | Always after the walk | 4 |
| 8 | `WIN_S4_PANTIES` | panties → naked | Always your 4th win; flows into the strip ending (see row 35) | 6 |
| **Sexy ladder** — pyramid 3/2/2/1 |||||
| 9 | `WIN_X1_BUTT__DRESSED` | dressed | Butt touch | 3 |
| 10 | `WIN_X1_BUTT__TOP_OFF` | topless, shorts on | Butt touch | 3 |
| 11 | `WIN_X1_BUTT__PANTIES` | panties only | Butt touch | 3 |
| 12 | `WIN_X2_BREAST__DRESSED` | dressed | The actual hands-on breast touch (over/under top) | 4 |
| 13 | `WIN_X2_BREAST__TOP_OFF` | topless, shorts on | **MR2**: reach blocked — "only my hands get to touch me" — close-range self-touch tease, stops cold | 4 |
| 14 | `WIN_X3_BJ__DRESSED` | dressed | BJ at the park table | 5 |
| 15 | `WIN_X3_BJ__TOP_OFF` | topless | BJ | 5 |
| 16 | `WIN_X4_SEX__DRESSED` | dressed (dishevelment in-scene OK) | Sexy finale — doubles as her forfeit. The playful one (2026-11-15; was the cold one): she strips in-scene, not loving | 8 |
| **Love ladder** — close-up framing |||||
| 17 | `WIN_L1_TRUTH__DRESSED` | dressed, close | Benign truth — why she really needs the money | 2 |
| 18 | `WIN_L1_TRUTH__TOP_OFF` | topless | The "what's your bra size" taunt (feeds MR1) | 2 |
| 19 | `WIN_L2_NICE` | any, close | Two nice things — fakes refused, real ones land | 3 |
| 20 | `WIN_L3_SMILE` | any, close | Smug smile refused → the real one | 3 |
| 21 | `WIN_L4_KISS` | dressed | The melt kiss — love finale, doubles as her forfeit. Continues into sex in the grass (2026-10-12): the long, warm one | 12 |
| **Mini-routes** — railroaded, one state each (MR2 = row 13) |||||
| 22 | `WIN_MR1_KISS` | topless, shorts on | Kiss after the bra-size truth | 3 |
| 23 | `WIN_MR1_FINGER` | topless, shorts on | Heavy kiss + fingers in her shorts — 4th-win finale | 5 |
| 24 | `WIN_MR3_INSPECT` | any (hands/faces framing) | Post-dick-pic hijack — "Fuck... you're huge." → "That was your prize. Deal with it." Consumes the pick | 4 |
| **Her punishments** — fire after any match she wins, fixed order |||||
| 25 | `LOSE_P1_ASS_KISS__SHORTS_ON` | shorts on, framed below mid-back | "Kiss my ass." — her 1st win | 3 |
| 26 | `LOSE_P1_ASS_KISS__SHORTS_OFF` | panties only | Same event, shorts gone | 3 |
| 27 | `LOSE_P2_DICK_PIC` (+ `__TOP_OFF`) | dressed / topless (panties too) | Her scrolling YOUR contacts, delighted → the professor, Poppy Winslow | 3 |
| 28 | `LOSE_P3A_YOUR_WALK` | you in underwear; her out of frame | Walk mirror; Janet & Ted encore (fires only if her walk happened) | 4 |
| 29 | `LOSE_P3B_BENCH_GIRL` | any; bench girl on-screen | Asshole-dare subverted → jealousy beat (fires only if no walk yet) | 5 |
| **Endings** |||||
| 30 | `FORFEIT_NAKED_RUN__DRESSED` | dressed, SEATED (shorts never show) | P4: devious dare — the naked run → you forfeit | 4 |
| 31 | `FORFEIT_NAKED_RUN__TOP_OFF` | topless, SEATED | Same + "I'm topless, aren't I?" legality exchange | 4 |
| 32 | `FINAL__DRESSED` | dressed | Mixed-picks her-forfeit wrap | 3 |
| 33 | `FINAL__TOP_OFF` | topless, shorts on | Mixed-picks wrap | 3 |
| 34 | `FINAL__PANTIES` | panties only | Mixed-picks wrap | 3 |
| 35 | `FINAL__NAKED` | naked | Strip-route wrap — may fold into row 8 | 3 |
| **Post-scene** |||||
| 36 | `PHONE_BENCH_GIRL` | phone selfies/chat | Sweet → mutual solo touching over the phone. Unlock: row 29 seen + scene won (lose 3, win 4) | 5 |
| **Added 2026-10-14** — the new sexy ladder, and scenes whose art showed the wrong outfit |||||
| 37 | `WIN_X3_UNDER__DRESSED` | dressed | Sexy rung 3, "Let me touch you under your clothes", in place of the blowjob | 4 |
| 38 | `WIN_X3_UNDER__TOP_OFF` | topless, shorts on | The same rung once her top is off (always your 4th stake), until the topless blowjob is unlocked | 4 |
| 39 | `WIN_L1_TRUTH__PANTIES` | panties only | Her truth in her panties (your 4th stake, after top, walk, shorts): "have you ever had sex in a park?" Row 18 plays here today, and its pictures 01–02 show her shorts | 2 |
| 40 | `WIN_L2_NICE__TOP_OFF` | topless, shorts on, close | Two nice things while topless; row 19's art is dressed (about 1 race in 6 plays it topless) | 3 |
| 41 | `WIN_L3_SMILE__TOP_OFF` | topless, shorts on, close | The real smile while topless (always your 4th stake); row 20's art is dressed | 3 |
| 42 | `LOSE_P1_ASS_KISS__DRESSED` | dressed | Her 1st win while still dressed, about 7 races in 10; row 25's pictures show her topless | 3 |

**The new sexy ladder (2026-10-14), with finales unlocked across races.** Butt → breasts →
under your clothes (rows 37/38) → the blowjob (row 14), which is now the sexy finale. Two more
finales unlock across races. Until then, each shows on the menu as a locked row, "? ? ?" with a
padlock (2026-11-10; it was a plain [?] before): it can't be picked, and gives no hint.
- **The sex scene** (row 16), beside the blowjob at the top. Needs both the park truth (row 39)
  and the love ladder's sex in the grass, finished.
- **The topless blowjob** (row 15), at rung 3 once her top is off. Needs both the dressed blowjob
  ending, finished, and a truth asked while she's topless.

Also: "Say two nice things" isn't offered beside an MR1 kiss, which keeps every menu at three
choices. Row 24 (the inspection) plays in any outfit, so frame it on hands and faces. Try all of
this in `route_explorer.html`; `docs/TODO.md` has what's still open.

**In the game since 2026-10-19** (`data/scripts/ashely_poker2/ashely2_race.gd`): this ladder with
its unlocks, the outfit versions of rows 39–42, and the nice-things rule. Three things to know:
- The blowjob finale plays the dressed blowjob's scene (`WIN_X3_BJ__DRESSED`) and ends on
  `THE_END__X4_BJ`. The topless blowjob ends on `THE_END__X3_BJ__TOP_OFF`.
- The unlock progress is kept between races in `ashely2_unlock_*` flags.
- A locked finale is a menu choice keyed `LOCKED_…`, which `src/vn/choice_display.gd` shows as a
  locked row that can't be picked.

**The stake menu's marks (2026-11-10).** Each stake on the menu says how much of it you have seen:
- **New**: none of its scenes seen. **Seen 1 of 3**: some of them, with "New" in front when the
  one it plays now is still unseen. **Seen all** (or just **Seen** for a stake with one scene).
  **Locked**: a finale not unlocked yet.
- A stake's scenes are every scene its choice can play, over all your races: her outfit changes
  the touches, the truth, the nice things and the smile, and her inspection (MR3) is one of each
  touch's scenes. The list is `STAKE_SCENES` in `ashely2_race.gd`; `ashely2_test` checks it
  against every race the rules allow.
- "Seen" means read to its end (the same record quick skip goes by), so it is kept per save.
- A scene with a sign-off written (below) plays differently as your last round and as an earlier
  one, so it counts as two versions, seen separately (2026-11-15): seeing her top come off as an
  earlier round leaves the last-round version new. The version a pick plays now is the last-round
  one if it would be your 4th win. A version with no sign-off written is seen once its scene is
  read in that place.
- One wrinkle: once the topless blowjob is unlocked it takes "under your clothes" whenever her
  top is off, so that scene's topless version stops counting if it wasn't seen by then.

**Sign-offs (2026-11-10).** A stake scene plays the same whichever of your four stakes it is, so
a line like "You know I'm going to get you back for this, right?" would be wrong when the scene
is your last. Such lines go in a sign-off: a start of its own, played right after the scene,
over the picture it ended on.
- `<scene>__NEXT` plays when the race goes on, `<scene>__LAST` when that was your 4th stake
  (then the ending follows). Eg: `WIN_S1_TOP__NEXT`, `WIN_X1_BUTT__DRESSED__LAST`.
- Both are optional. One left unwritten never plays: no start, no lines, or only empty or
  "(Placeholder)" lines. So the scene itself should read right in both places.
- The 14 scenes that can be your last stake or an earlier one each have both in
  `d_ashely2_win.tres`, as one placeholder line to write over (or delete). The other 11 have
  none: 10 always end the race (the finales, and the scenes only reached at your 4th stake), and
  the MR1 kiss is always your 3rd. Their closing lines go in the scene.
- No branch inside a scene: every start stays a plain chain, which is what the dialogue editor
  edits.
- The rule is `signOff()` in `ashely2_race.gd`, called by `ashely2_win_choices.gd`.
  `ashely2_test` checks every sign-off in the dialogue is one its scene can be followed by.
- Her punishments need none: her 4th win skips the punishment and goes to your forfeit.

`docs/ashely_poker2/dialogue_guide.html` lists every dialogue start: where it plays, its file and
start node, and its pictures line by line. Put in the game rewrites it.

Deferred to future updates: `PHONE_PROFESSOR` (needs no art now).

Production decisions locked: 3 mini-routes final (no MR4); every scene gets at least a
minimal render (reuse with expression changes fine); mixed wraps stay per-state, reduce while
rendering only if affordable; matches tentatively 5/5 lives; no money exists in this game —
never money stakes or dares.
Gating: ~~unlocked after **`amy_meetup`**~~ unlocked after **`anna_night`**
(`completedStages.has('anna_night')`, changed 2026-10-02: Ashely II comes before Amy).
Since 2026-10-25, `anna_night` offers Ashely's text (phone message `ashely2_phone`, its chat a
placeholder for now), and finishing that unlocks the event (`completedStages.has('ashely2_phone')`).
The Rematch With Ashely checkpoint lands on the phone with that text waiting.

## 9. Scene beat bible (full detail, keyed to §8 row numbers)

Everything discussed in depth during design — so dialogue writing can start from here, not
from memory. Tone rule everywhere: **Ashely is never diminished** — she pays her bets loud
and defiant, and gives as good as she gets.

**Row 6 — Her walk (topless, shorts on).** Deserted public park; she does a lap. An elderly
couple wanders through. Ted: "I remember when you used to look like that, Janet." Janet:
"And I remember when you used to look like Ryan Gosling, Ted... now fix your dentures,
you're drooling." Both rendered characters.

**Rows 16 and 21 — the two sex scenes are opposites** (decided 2026-10-12). A race reaches at
most one of them: each needs all four of your picks on its own ladder.
- Row 16, the sexy finale, is the playful one (written 2026-11-15; it was "the cold one" until the
  user relaxed it). You skip all the undressing; she'd obviously say no, but she's never done it in a
  park, so she agrees, says you owe her big time, and strips on the way (pictures borrowed from the
  strip rounds), then leads you into the hedges. Banter, a kiss neither of you planned, a hint it was
  her first time at all. Not loving: the ending (THE_END__X4_SEX) has her keep it at "this wasn't
  I-love-you sex".
- Row 21, the love finale, is the long, warm one: see L4 below.

**Rows 17–21 — Love ladder.**
- L1 truth (dressed): the benign one — why she really needs the money.
- L1 truth (topless, row 18): the question changes with context — "what's your bra size?"
  She's topless answering it. Feeds MR1.
- Truths will vary (2026-10-14): which truth she tells depends on her outfit and on the stakes
  you've picked before, so the player learns about her by exploring choices.
- L2 "two nice things": she goes cheap first — calls you hot; you refuse it, pointing out
  she insults your appearance weekly. Maybe a second refused fake. Then she grits her teeth
  and lands two *surprisingly real* compliments.
- L3 "a real smile": she deploys the usual smug, goading smile. You refuse it — she needs to
  drop the tough-girl bullshit and give a real one. She protests. Then finally does.
- L4 the kiss (dressed, always): she melts into your arms — because through the whole game,
  while she was making you send dick pics and kiss her ass, you never once fired back or
  asked for anything that made her uncomfortable. It made her see you as a good partner.
  Same emotional mechanic across L2→L3→L4: reject the performance, get the real thing.
  Then she takes it further (2026-10-12): she pulls you down into the grass, and it becomes
  sex, the long, warm one, with foreheads together after. You asked for a kiss; she's the one
  who goes further. The menu still says "A real kiss".

**Row 13 — MR2, the interception (topless breast touch).** You reach for her; she stops
your hand. Only HER hands get to touch her. She gives a close-range show — touching herself,
mostly breasts and upper body, teasing her own waistline, close enough to feel her breath.
NOT a dance, not a show she volunteers: a blue-balls tease, control assertion. Then she just
stops. Rung still counts (rung 3 opens after).

**Rows 22–23 — MR1 (top → bra-size truth → kiss → finale).** The kiss escalates on the 4th
win: heavy kiss, fingers slip into her shorts. Only initiable if you stripped nothing beyond
her top — topless with shorts on, always.

**Row 24 — MR3, the inspection.** Fires once, hijacking your first touch pick after P2. Since 2026-10-19
"touch" means her butt, her breasts, or under her clothes (the new rung 3).
"Fair's fair — the professor got a preview. I didn't." Hand into your shorts. Annoyed:
"Fuck... you're huge." Plays with it a little. Withdraws. "That was your prize. Deal with
it." Consumes the pick — no rung progress; that run ends in a mixed wrap.

**Rows 25–26 — P1, "Kiss my ass. Literally."** Her 1st win. Frame from behind / below
mid-back (that's what keeps it at 2 variants).

**Row 27 — P2, the dick pic.** She orders you to send one to a phone contact. You agree,
privately planning a known dead number. "Hold up... *I* pick the person." You get very
nervous. She scrolls casually, narrating past love interests: "Hmm... how about this Lisa
girl? ...no." Lands on your female physics professor from college. Art: Ashely going
through your phone, delighted. Future update: sexy professor phone chat after the date.
Written 2026-11-15, two sets (`LOSE_P2_DICK_PIC` dressed, `LOSE_P2_DICK_PIC__TOP_OFF` topless,
which also plays in her panties since its pictures stop at the table): scrolling → "this one" →
waiting, chin on her hands. The professor is **Poppy Winslow**: "Oh, she sounds *cute*..." /
"That's my physics professor." / "...Oh, well. Still funny. Do it." Ashely watches you send it
but never sees the picture (`WIN_MR3_INSPECT`: "Your professor got a preview. I didn't.").

**Row 28 — P3a, your walk (only if her walk happened).** You, underwear, same path. Janet &
Ted encore — e.g. "I remember when you used to look like that, Ted." / "No you don't,
Janet." Keep Ashely out of frame (or face-only) so her state doesn't split the set.

**Row 29 — P3b, the bench girl (only if no walk yet).** She spots a girl on a park bench:
go ask for her number, then say "just kidding" and walk away — be a total asshole. You:
"That's actually kind of fucked up." Shrug: "Do it, or forfeit." You sit next to the girl.
Talk. She's nice. You ask; she blushes and agrees. You wrestle with the "just kidding" —
fuck it — you take the number for real and refuse to be cruel. Back at the table: "So, did
you do it?" "Yes." Skeptical stare. "...Then why did she just go skipping off giggling into
the sunset?" Silence. She laughs — she KNEW you wouldn't. She liked watching you struggle;
the struggle was the punishment. (Relief beat: Ashely isn't a sociopath.) Then, aggressively
casual: "You actually going to text her?" "Maybe." Frown. "Whatever. Next match."

**Rows 30–31 — P4, the naked run (your forfeit).** Her 4th win: strip fully naked and run
through the park. "That would be illegal." If she's topless: "I'm topless, aren't I?" —
"It's legal for women to be topless here." You sigh — impossible — and forfeit. Art:
devious, expressive Ashely daring you to be that bold; she's SEATED (shorts state never
shows), dressed + topless variants only. No nude player art.

**Row 36 — Bench-girl phone convo.** Unlock: row 29 seen AND the scene won (lose exactly 3,
then take your 4th win — the stretch challenge). Starts sweet; progresses until both of you
are touching yourselves independently on either end of the call. She needs a design + name.

## 10. Replays (2026-11-16)

Picking Ashely Poker II on the phone once it has been played (Continue app, `gs_ashely2_intro.tres`
`replayGameStage`) opens a menu stage, `data/game_stages/vn/ashely2_replay`, in place of the poker
timeline the older matches use. A frosted choice menu over the park, Ashely asking how you want to
play it:
- **No cheats**, **2 cheats each match**, **5 cheats each match** (locked, "see the true ending
  first", until `THE_END__L4_KISS` has played: `Race.WARM_SEX`). A pick is a flag,
  `ashely2_replay_cheats_<n>`, that the match reads (`gs_ashely2_match.tres` `cheatCountByFlag`,
  `GameStage.currentCheatCount()`); it stays until the next replay is picked. A first play has none,
  so its matches keep their 1. The scripted first hand is its own stage and always has none.
- **A hint for the true ending** ("ever think about asking for something nice instead? And sticking
  with it."), after which the menu also offers **Just tell me how**: every win, the sweet one, a truth,
  two nice things, a real smile, a real kiss, nothing in between, before she wins too many hands.
- Picking a replay plays her one-line reaction, then the race's intro.
- **The locked finales** (the stake menu's "? ? ?": the sex scene beside the blowjob, the topless blowjob once
  her top is off): once one has been on your menu (`Race.noteLockedSeen`, flags `ashely2_seen_locked_sex` /
  `ashely2_seen_locked_topless_blowjob`, kept between races) and while it is still locked, the menu offers **a hint**
  for it and **how to open it**, the latter locked until the true ending. Both go once the finale is open.
- All of it is in Ashely's voice (the user: it keeps the immersion), and always as your first game with her: no
  "rematch", "again" or "this time".
