extends RefCounted

# The rules of Ashely Poker II (docs/ashely_poker2/DESIGN.md and scene_model.json): short matches
# until you have taken four stakes (she forfeits) or she has won four (you forfeit, the naked run).
#
#   intro -> match -> won: pick a stake  -> match ... -> ending -> phone
#                  -> lost: a punishment -> match ...
#
# Everything is worked out from story flags, nothing is held in memory, so the race survives
# saving and loading. Picks and punishments are written as their stage ends
# (GlobalGameStage.setFlagAtStageEnd): a save taken as a stage ends replays it from before them.
#
# Dialogue start keys are DESIGN.md section 8's row names. So are the picture lists: a row's
# finished pictures are PICTURES/<row>/<row>.tres (put there by tooling/art_sort), and until it has
# some, its placeholder is the Background called "ashely2_" + row name.

# The won / lost stages lead to the ending (their guaranteedNextGameStage) unless the race goes on.
# The way back to the match is set here: a reference to it in their .tres would be cyclic.
const MATCH = "res://data/game_stages/poker/ashely2_match/gs_ashely2_match.tres"
const PICTURES = "res://data/background_lists/ashely_poker2/"
const PLACEHOLDERS = PICTURES + "placeholders/ashely_poker2_placeholders.tres"

# Flags of the race being played, cleared when a new one starts.
const RACE = "ashely2_race_"
const PICK = RACE + "pick_"
const PUNISHMENT = RACE + "punishment_"
const BRA_SIZE_TRUTH = RACE + "bra_size_truth"
# Flags kept after the race: you have won it at least once, and the bench girl's number.
const WON = "ashely2_won"
const BENCH_GIRL_UNLOCKED = "ashely2_bench_girl_unlocked"

# The sexy ladder's two extra finales unlock across races (DESIGN.md section 8, 2026-10-14). Each
# needs both of its requirements, met in any races; these flags are kept between races.
const UNLOCK = "ashely2_unlock_"
const PARK_TRUTH = UNLOCK + "park_truth"            # heard "have you ever had sex in a park?"
const WARM_SEX = UNLOCK + "warm_sex"                # finished the sex in the grass (the love finale)
const DRESSED_BLOWJOB = UNLOCK + "dressed_blowjob"  # finished the blowjob finale's ending
const TOPLESS_TRUTH = UNLOCK + "topless_truth"      # asked for a truth while she's topless
# Until then each shows on the menu as a locked "? ? ?" that does nothing when picked: a choice whose
# key starts with LOCKED (src/vn/choice_display.gd).
const LOCKED_SEX = "LOCKED_SEX"
const LOCKED_TOPLESS_BLOWJOB = "LOCKED_TOPLESS_BLOWJOB"
const LOCKED_LABEL = "? ? ?"
# Once a locked row has been on your menu, the replay menu offers a hint for it, and how to open it
# (data/game_stages/vn/ashely2_replay): ashely2_seen_locked_sex, ashely2_seen_locked_topless_blowjob.
const SEEN = "ashely2_seen_"

# The race is over when either of you reaches this many: your stakes taken, or her wins.
const STAKES_TO_FINISH = 4

# Each ladder offers only its next rung, in this order: [option, menu label]. The blowjob is the
# sexy finale; its scene is the dressed blowjob's (BLOWJOB_FINALE).
const STRIP = [["S1_TOP", "Your top comes off"], ["S2_WALK", "Walk around the park, topless"], ["S3_SHORTS", "Your shorts come off"], ["S4_PANTIES", "Your panties come off"]]
const SEXY = [["X1_BUTT", "Let me touch your butt"], ["X2_BREAST", "Let me touch your breasts"], ["X3_UNDER", "Let me touch you under your clothes"], ["X4_BJ", "A blowjob"]]
const LOVE = [["L1_TRUTH", "Tell me a truth"], ["L2_NICE", "Say two nice things about me"], ["L3_SMILE", "Show me a real smile"], ["L4_KISS", "A real kiss"]]
const BLOWJOB_FINALE = "WIN_X3_BJ__DRESSED"
const TOPLESS_BLOWJOB = "WIN_X3_BJ__TOP_OFF"
const SEX = "WIN_X4_SEX__DRESSED"

static func startNewRace():
	GlobalGameStage.clearFlagsStartingWith(RACE)

# --- where the race stands

static func picked(option : String) -> bool:
	return GlobalGameStage.hasFlag(PICK + option)

static func punished(punishment : String) -> bool:
	return GlobalGameStage.hasFlag(PUNISHMENT + punishment)

static func yourWins() -> int:
	return GlobalGameStage.countFlagsStartingWith(PICK)

static func herWins() -> int:
	return GlobalGameStage.countFlagsStartingWith(PUNISHMENT)

static func isOver() -> bool:
	return yourWins() >= STAKES_TO_FINISH or herWins() >= STAKES_TO_FINISH

# What she still has on: DRESSED, TOP_OFF (topless, shorts on), PANTIES, or NAKED.
static func appearance() -> String:
	if picked("S4_PANTIES"):
		return "NAKED"
	if picked("S3_SHORTS"):
		return "PANTIES"
	if picked("S1_TOP"):
		return "TOP_OFF"
	return "DRESSED"

# A picture for a section 8 row, eg: "TABLE__DRESSED": one of its finished pictures at random (the
# table rows are sets to pick from), or its placeholder.
static func picture(row : String) -> Background:
	var finished = PICTURES + row + "/" + row + ".tres"
	if ResourceLoader.exists(finished):
		var images = load(finished).images
		if !images.is_empty():
			return images.pick_random()
	for background in load(PLACEHOLDERS).images:
		if background.name == "ashely2_" + row:
			return background
	push_warning("Ashely Poker II has no picture for " + row)
	return null

# --- the picture each match opens on

# BEGIN MATCH_PICTURES, written from tooling/dialogue_editor/match_pictures.json (the dialogue
# editor's Match pictures, 2026-11-03): what she has on, your wins and hers as the match starts
# ("FIRST" is the first hand, before the race) -> [picture list, picture].
const MATCH_PICTURES = {
	"FIRST": ["TABLE__DRESSED", "TABLE__DRESSED_01"],
	"DRESSED_0_0": ["TABLE__DRESSED", "TABLE__DRESSED_03"],
	"DRESSED_0_1": ["TABLE__DRESSED", "TABLE__DRESSED_01"],
	"DRESSED_0_2": ["TABLE__DRESSED", "TABLE__DRESSED_05"],
	"DRESSED_0_3": ["FINAL__DRESSED", "FINAL__DRESSED_04"],
	"DRESSED_1_0": ["TABLE__DRESSED", "TABLE__DRESSED_03"],
	"DRESSED_1_1": ["TABLE__DRESSED", "TABLE__DRESSED_01"],
	"DRESSED_1_2": ["TABLE__DRESSED", "TABLE__DRESSED_05"],
	"DRESSED_1_3": ["FINAL__DRESSED", "FINAL__DRESSED_04"],
	"DRESSED_2_0": ["TABLE__DRESSED", "TABLE__DRESSED_02"],
	"DRESSED_2_1": ["TABLE__DRESSED", "TABLE__DRESSED_02"],
	"DRESSED_2_2": ["TABLE__DRESSED", "TABLE__DRESSED_01"],
	"DRESSED_2_3": ["TABLE__DRESSED", "TABLE__DRESSED_05"],
	"DRESSED_3_0": ["TABLE__DRESSED", "TABLE__DRESSED_02"],
	"DRESSED_3_1": ["TABLE__DRESSED", "TABLE__DRESSED_02"],
	"DRESSED_3_2": ["TABLE__DRESSED", "TABLE__DRESSED_01"],
	"DRESSED_3_3": ["TABLE__DRESSED", "TABLE__DRESSED_05"],
	"TOP_OFF_1_0": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_01"],
	"TOP_OFF_1_1": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_05"],
	"TOP_OFF_1_2": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_06"],
	"TOP_OFF_1_3": ["FINAL__TOP_OFF", "FINAL__TOP_OFF_04"],
	"TOP_OFF_2_0": ["FINAL__TOP_OFF", "FINAL__TOP_OFF_04"],
	"TOP_OFF_2_1": ["FINAL__TOP_OFF", "FINAL__TOP_OFF_05"],
	"TOP_OFF_2_2": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_06"],
	"TOP_OFF_2_3": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_05"],
	"TOP_OFF_3_0": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_06"],
	"TOP_OFF_3_1": ["FINAL__TOP_OFF", "FINAL__TOP_OFF_01"],
	"TOP_OFF_3_2": ["FINAL__TOP_OFF", "FINAL__TOP_OFF_07"],
	"TOP_OFF_3_3": ["TABLE__TOP_OFF", "TABLE__TOP_OFF_01"],
	"PANTIES_3_0": ["TABLE__PANTIES", "TABLE__PANTIES_01"],
	"PANTIES_3_1": ["FINAL__PANTIES", "FINAL__PANTIES_05"],
	"PANTIES_3_2": ["FINAL__PANTIES", "FINAL__PANTIES_06"],
	"PANTIES_3_3": ["TABLE__PANTIES", "TABLE__PANTIES_02"],
}
# END MATCH_PICTURES

# The picture a race match opens on, for the race as it stands.
static func matchPicture() -> Background:
	return pickedPicture("%s_%d_%d" % [appearance(), yourWins(), herWins()], "TABLE__" + appearance())

# The first hand's, before the race.
static func firstHandPicture() -> Background:
	return pickedPicture("FIRST", "TABLE__DRESSED")

# The picture picked for a situation. With none picked, or the picked one gone, one of the row's
# pictures at random.
static func pickedPicture(situation : String, row : String) -> Background:
	var pick = MATCH_PICTURES.get(situation)
	if pick:
		var list = PICTURES + pick[0] + "/" + pick[0] + ".tres"
		if ResourceLoader.exists(list):
			for background in load(list).images:
				if background.name == pick[1]:
					return background
		push_warning("Ashely Poker II: the picture picked for %s, %s, is missing" % [situation, pick[1]])
	return picture(row)

# The race goes on after this result, or it is over and the ending plays. Returns the key that ends
# the result's stage.
static func routeOn() -> String:
	if isOver():
		return "TO_ENDING"
	GlobalGameStage.setNextGameStage(load(MATCH))
	return "NEXT_MATCH"

# --- after a match you won: the stake menu, dialogue key -> label

static func stakeMenu() -> Dictionary[String, String]:
	var menu : Dictionary[String, String] = { "TITLE": "Your stake" }
	for offer in stakeOffers():
		menu[offer[0]] = offer[1]
	return menu

# The stakes on the menu, in its order: [dialogue key, label, option]. The option is the stake's
# name in the race's flags (a rung, eg: "X1_BUTT"); a locked finale has none.
static func stakeOffers() -> Array:
	var offers := []
	# Mini-route 1: topless, shorts still on, after she answered the bra-size truth.
	var win = yourWins() + 1
	var mr1Kiss = win == 3 and picked("S1_TOP") and !picked("S3_SHORTS") and GlobalGameStage.hasFlag(BRA_SIZE_TRUTH)
	var mr1Finale = win == 4 and picked("MR1_KISS") and !picked("S3_SHORTS")
	for ladder in [STRIP, SEXY, LOVE]:
		for rung in ladder:
			var option = rung[0]
			if picked(option):
				continue
			if option == "X3_UNDER" and picked("S1_TOP") and unlocked(TOPLESS_BLOWJOB):
				# Once her top is off, rung 3 is her topless blowjob, which ends the race on itself.
				offers.append([TOPLESS_BLOWJOB, "A blowjob", "X3_BJ"])
			elif option == "L2_NICE" and (mr1Kiss or mr1Finale):
				pass # "Say two nice things" isn't offered beside an MR1 kiss: every menu stays at three
			else:
				var key = stakeKey(option)
				offers.append([key, rung[1], option])
				# The sex scene sits beside the blowjob finale, and the topless blowjob beside the
				# topless rung 3 (even when her inspection takes that rung): locked until unlocked.
				if key == BLOWJOB_FINALE:
					if unlocked(SEX):
						offers.append([SEX, "Sex", "X4_SEX"])
					else:
						offers.append([LOCKED_SEX, LOCKED_LABEL, ""])
				elif option == "X3_UNDER" and picked("S1_TOP"):
					offers.append([LOCKED_TOPLESS_BLOWJOB, LOCKED_LABEL, ""])
			break

	if mr1Kiss:
		offers.append(["WIN_MR1_KISS", "Kiss me", "MR1_KISS"])
	if mr1Finale:
		offers.append(["WIN_MR1_FINGER", "Kiss me like you mean it", "MR1_FINGER"])
	return offers

# --- what the menu says you have seen of each stake (src/choice_display_button.gd)

# The stakes whose choice plays a different scene from race to race: by what she has on, and her
# inspection (mini-route 3) takes the first touch you ask for after the dick pic. Any other stake
# only ever plays the one scene. ashely2_test checks these against every race the rules allow.
const STAKE_SCENES = {
	"X1_BUTT": ["WIN_X1_BUTT__DRESSED", "WIN_X1_BUTT__TOP_OFF", "WIN_X1_BUTT__PANTIES", "WIN_MR3_INSPECT"],
	"X2_BREAST": ["WIN_X2_BREAST__DRESSED", "WIN_X2_BREAST__TOP_OFF", "WIN_MR3_INSPECT"],
	"X3_UNDER": ["WIN_X3_UNDER__DRESSED", "WIN_X3_UNDER__TOP_OFF", "WIN_MR3_INSPECT"],
	"L1_TRUTH": ["WIN_L1_TRUTH__DRESSED", "WIN_L1_TRUTH__TOP_OFF", "WIN_L1_TRUTH__PANTIES"],
	"L2_NICE": ["WIN_L2_NICE", "WIN_L2_NICE__TOP_OFF"],
	"L3_SMILE": ["WIN_L3_SMILE", "WIN_L3_SMILE__TOP_OFF"],
}
# The stage the stake scenes play in: a scene is seen once it has been read to its end there.
const WIN_STAGE = "ashely2_win"

static func seenScene(key : String) -> bool:
	return GlobalGameStage.hasCompletedDialogueKey(key, WIN_STAGE)

# Every scene an offer's choice can play, over all your races: what its mark counts.
static func stakeScenes(offer : Array) -> Array:
	var scenes : Array = STAKE_SCENES.get(offer[2], [offer[0]]).duplicate()
	# Once the topless blowjob is unlocked it has rung 3's place whenever her top is off: if "under
	# your clothes" wasn't seen topless by then, it no longer can be, and isn't counted as missing.
	if unlocked(TOPLESS_BLOWJOB) and !seenScene("WIN_X3_UNDER__TOP_OFF"):
		scenes.erase("WIN_X3_UNDER__TOP_OFF")
	return scenes

# For the menu (ChoiceScript.getChoiceMarks): how much of each stake you have seen, and whether what
# it plays now is new. A locked finale needs no mark: its key says it's locked.
# A scene with written sign-offs plays differently as your last round and as an earlier one, so it
# counts as two versions, seen separately: <scene>__NEXT and <scene>__LAST (seenVersions). The one it
# plays now is the __LAST version if this pick would be your last round.
static func stakeMarks() -> Dictionary:
	var marks := {}
	var dialogue := winDialogue()
	var lastRound := yourWins() + 1 >= STAKES_TO_FINISH
	for offer in stakeOffers():
		if offer[2] == "":
			continue
		var versions := []
		for scene in stakeScenes(offer):
			versions.append_array(seenVersions(scene, dialogue))
		var seen := versions.filter(func(version): return seenScene(version))
		var now : String = offer[0]
		if hasVersions(now, dialogue):
			now += SIGN_OFF_LAST if lastRound else SIGN_OFF_NEXT
		marks[offer[0]] = { "seen": seen.size(), "total": versions.size(), "new": !seenScene(now) }
	return marks

# The won-match dialogue, where the stake scenes and their sign-offs are. Tests can hand in their own.
const WIN_DIALOGUE = "res://data/game_stages/vn/ashely2_win/d_ashely2_win.tres"
static var dialogueOverride : DialogueData = null

static func winDialogue() -> DialogueData:
	return dialogueOverride if dialogueOverride else load(WIN_DIALOGUE)

# Whether a stake scene plays differently as your last round and as an earlier one: it has both
# sign-off starts (the scenes that can be either) and at least one of them is written.
static func hasVersions(scene : String, dialogue : DialogueData) -> bool:
	return dialogue.starts.has(scene + SIGN_OFF_NEXT) and dialogue.starts.has(scene + SIGN_OFF_LAST) \
		and (isWritten(dialogue, scene + SIGN_OFF_NEXT) or isWritten(dialogue, scene + SIGN_OFF_LAST))

# What the marks count for a scene: the scene itself, or its two versions by their sign-off keys.
# A version is seen once its sign-off has been read, or, with no sign-off written for it, once the
# scene has been read in that place (markVersionSeen).
static func seenVersions(scene : String, dialogue : DialogueData) -> Array:
	return [scene + SIGN_OFF_NEXT, scene + SIGN_OFF_LAST] if hasVersions(scene, dialogue) else [scene]

# A stake scene was read through and no sign-off follows it: the version it played is seen. Called
# with the stake already taken (so isOver says which version it was).
static func markVersionSeen(scene : String):
	if !hasVersions(scene, winDialogue()):
		return
	var seen : Array = GlobalGameStage.completedDialogueKeys.get(WIN_STAGE, [])
	if !seen.has(signOffKey(scene)):
		seen.append(signOffKey(scene))
	GlobalGameStage.completedDialogueKeys[WIN_STAGE] = seen

# A stake menu is up: the locked rows on it have now been seen (kept between races).
static func noteLockedSeen(menu : Dictionary):
	for locked in [LOCKED_SEX, LOCKED_TOPLESS_BLOWJOB]:
		if menu.has(locked):
			GlobalGameStage.setFlagAtStageEnd(SEEN + locked.to_lower())

static func lockedSeen(locked : String) -> bool:
	return GlobalGameStage.hasFlag(SEEN + locked.to_lower())

# Whether a finale that unlocks across races (SEX or TOPLESS_BLOWJOB) is open.
static func unlocked(finale : String) -> bool:
	match finale:
		SEX:
			return GlobalGameStage.hasFlag(PARK_TRUTH) and GlobalGameStage.hasFlag(WARM_SEX)
		TOPLESS_BLOWJOB:
			return GlobalGameStage.hasFlag(DRESSED_BLOWJOB) and GlobalGameStage.hasFlag(TOPLESS_TRUTH)
	return true

# The scene a stake plays, for what she has on. Mini-route 2 is simply the topless breast touch.
static func stakeKey(option : String) -> String:
	# Mini-route 3: the first touch you ask for after the dick pic (her butt, her breasts, or under her
	# clothes) is hers instead.
	if option in ["X1_BUTT", "X2_BREAST", "X3_UNDER"] and punished("P2") and !picked("MR3_INSPECT"):
		return "WIN_MR3_INSPECT"
	match option:
		"X1_BUTT":
			return "WIN_X1_BUTT__" + appearance()
		"X2_BREAST", "X3_UNDER":
			return "WIN_%s__%s" % [option, "TOP_OFF" if picked("S1_TOP") else "DRESSED"]
		"X4_BJ":
			# The finale needs all four of your stakes on this ladder, so she's always dressed.
			return BLOWJOB_FINALE
		"L1_TRUTH":
			# In her panties (always your 4th stake) it's "have you ever had sex in a park?".
			if appearance() == "PANTIES":
				return "WIN_L1_TRUTH__PANTIES"
			return "WIN_L1_TRUTH__" + ("TOP_OFF" if picked("S1_TOP") else "DRESSED")
		"L2_NICE", "L3_SMILE":
			if appearance() != "DRESSED":
				return "WIN_%s__TOP_OFF" % option
	return "WIN_" + option

# A stake scene has played: it counts once the stage ends. The sexy finales pick their own options
# (X4_BJ, X4_SEX, and X3_BJ for the topless blowjob), whatever their scenes are called.
static func takeStake(key : String):
	var option = "X4_BJ" if key == BLOWJOB_FINALE else key.trim_prefix("WIN_").get_slice("__", 0)
	GlobalGameStage.setFlagAtStageEnd(PICK + option)
	if option == "L1_TRUTH" and picked("S1_TOP"):
		GlobalGameStage.setFlagAtStageEnd(BRA_SIZE_TRUTH)
		GlobalGameStage.setFlagAtStageEnd(TOPLESS_TRUTH)
	if key == "WIN_L1_TRUTH__PANTIES":
		GlobalGameStage.setFlagAtStageEnd(PARK_TRUTH)

# --- a stake scene's sign-off: closing lines for whether the race goes on or not

# A stake scene plays the same wherever its stake falls in the race, so a line that only fits one
# case goes in a sign-off: a start of its own, named after the scene, that plays right after it,
# over the picture the scene ended on.
#   <scene>__NEXT   the race goes on: another match follows ("I'm going to get you back for this")
#   <scene>__LAST   that was your fourth stake: she has lost, and the ending follows
# Both are optional. One still unwritten is passed over: no start, no lines, or only lines that are
# empty or placeholders (the "(Placeholder)" the dialogue editor marks an unwritten line with).
# ashely2_test checks every sign-off in the dialogue is one some race plays.
const SIGN_OFF_NEXT = "__NEXT"
const SIGN_OFF_LAST = "__LAST"
const UNWRITTEN = "(Placeholder)"

static func isSignOff(key : String) -> bool:
	return key.ends_with(SIGN_OFF_NEXT) or key.ends_with(SIGN_OFF_LAST)

# The sign-off a stake scene has for the race as it stands, its stake taken: the dialogue key.
static func signOffKey(scene : String) -> String:
	return scene + (SIGN_OFF_LAST if isOver() else SIGN_OFF_NEXT)

# The sign-off to play after a stake scene, in the dialogue it played in: "" when it has none written.
static func signOff(scene : String, dialogue : DialogueData) -> String:
	var key := signOffKey(scene)
	return key if isWritten(dialogue, key) else ""

# Whether a start has a line someone wrote: it leads to a line that isn't empty or a placeholder.
static func isWritten(dialogue : DialogueData, key : String) -> bool:
	if !dialogue or !dialogue.starts.has(key):
		return false
	var next = dialogue.nodes.get(dialogue.starts[key], {}).get("link", "END")
	for step in 2000:
		if String(next) == "END" or !dialogue.nodes.has(next):
			break
		var node : Dictionary = dialogue.nodes[next]
		if node.has("dialogue"):
			var words := String(node["dialogue"]).strip_edges()
			if words != "" and !words.begins_with(UNWRITTEN):
				return true
		var options = node.get("options")
		next = options[0].get("link", "END") if options is Dictionary and options.has(0) else node.get("link", "END")
	return false

# --- after a match she won: her punishment, in a fixed order. Her last win is your forfeit, which
# the ending plays.

# What follows the lost match: her punishment, or straight to the ending.
static func lostMatchKey() -> String:
	if herWins() + 1 >= STAKES_TO_FINISH:
		takeForfeit()
		return routeOn()
	return punishmentKey()

static func punishmentKey() -> String:
	match herWins() + 1:
		1:
			if appearance() == "DRESSED":
				return "LOSE_P1_ASS_KISS__DRESSED"
			return "LOSE_P1_ASS_KISS__" + ("SHORTS_OFF" if picked("S3_SHORTS") else "SHORTS_ON")
		2:
			# Its topless pictures stop at the table, so they serve her panties too.
			return "LOSE_P2_DICK_PIC" + ("" if appearance() == "DRESSED" else "__TOP_OFF")
		3:
			return "LOSE_P3A_YOUR_WALK" if picked("S2_WALK") else "LOSE_P3B_BENCH_GIRL"
	push_error("Ashely Poker II has no punishment for her win %d" % (herWins() + 1))
	return ""

static func takePunishment(key : String):
	GlobalGameStage.setFlagAtStageEnd(PUNISHMENT + key.get_slice("_", 1))

static func takeForfeit():
	GlobalGameStage.setFlagAtStageEnd(PUNISHMENT + "P4_FORFEIT")

# --- the ending

static func endingKey() -> String:
	if herWins() >= STAKES_TO_FINISH:
		return "FORFEIT_NAKED_RUN__" + ("TOP_OFF" if picked("S1_TOP") else "DRESSED")
	if picked("S4_PANTIES"):
		return "FINAL__NAKED"
	# A finished ladder's last scene was the finale already: she forfeits over its picture.
	for finale in ["X4_SEX", "X4_BJ", "L4_KISS", "MR1_FINGER"]:
		if picked(finale):
			return "THE_END__" + finale
	# The topless blowjob is always your 4th stake (her top, the butt and the breasts came first).
	if picked("X3_BJ"):
		return "THE_END__X3_BJ__TOP_OFF"
	return "FINAL__" + appearance()

# What the race leaves behind once it is over: that you have won it, the bench girl's number if you
# met her (her third win) and still won, and the finales its ending counts toward unlocking.
static func keepOutcome():
	if yourWins() >= STAKES_TO_FINISH:
		GlobalGameStage.setFlagAtStageEnd(WON)
		if punished("P3B"):
			GlobalGameStage.setFlagAtStageEnd(BENCH_GIRL_UNLOCKED)
	match endingKey():
		"THE_END__L4_KISS":
			GlobalGameStage.setFlagAtStageEnd(WARM_SEX)
		"THE_END__X4_BJ":
			GlobalGameStage.setFlagAtStageEnd(DRESSED_BLOWJOB)
