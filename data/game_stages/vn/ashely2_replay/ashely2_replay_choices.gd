extends ChoiceScript

# Replaying Ashely Poker II from the phone, once it has been played (gs_ashely2_intro.tres
# replayGameStage, in place of the poker timeline): pick how many cheats each match gets, or read a
# hint for the true ending and then, if wanted, just how to get it; and for each locked "? ? ?" the
# stake menu has shown, a hint and (after the true ending) how to open it. Picking a replay starts
# the race's intro. All in Ashely's voice, and always as your first game with her.
#
# The pick is a flag the match reads (gs_ashely2_match.tres cheatCountByFlag, GameStage
# currentCheatCount()); it stays until the next replay is picked. A first play has none of them, so
# its matches keep the match's own cheatCount.
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")
const INTRO = "res://data/game_stages/vn/ashely2_intro/gs_ashely2_intro.tres"

const CHEATS = "ashely2_replay_cheats_"
# The replays, dialogue key -> cheats each match.
const MODES = { "REPLAY_NO_CHEATS": 0, "REPLAY_TWO_CHEATS": 2, "REPLAY_FIVE_CHEATS": 5 }
const LOCKED_FIVE = "LOCKED_FIVE_CHEATS"
# The race's locked finales ("? ? ?" on the stake menu): once one has been seen, and while it is still
# locked, a hint for it (HINT_<id>), and how to open it (ANSWER_<id>), which is locked itself until the
# true ending has been seen. [locked row, finale, id, where the player saw it].
const LOCKED_FINALES = [
	[Race.LOCKED_SEX, Race.SEX, "SEX", "beside the blowjob"],
	[Race.LOCKED_TOPLESS_BLOWJOB, Race.TOPLESS_BLOWJOB, "TOPLESS_BJ", "once her top is off"],
]

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if MODES.has(dialogueKey):
		GlobalGameStage.clearFlagsStartingWith(CHEATS)
		GlobalGameStage.setFlagAtStageEnd(CHEATS + str(MODES[dialogueKey]))
		GlobalGameStage.setNextGameStage(load(INTRO))
		return { "GUARANTEED": "TO_RACE" }
	return menu(dialogueKey)

# The menu: the three replays (the last one locked until the true ending has been seen), the hint,
# and once the hint has been read, the straight answer.
static func menu(dialogueKey: String) -> Dictionary[String, String]:
	var choices : Dictionary[String, String] = { "TITLE": "Replay Ashely Poker II" }
	choices["REPLAY_NO_CHEATS"] = "No cheats"
	choices["REPLAY_TWO_CHEATS"] = "2 cheats each match"
	if trueEndingSeen():
		choices["REPLAY_FIVE_CHEATS"] = "5 cheats each match"
	else:
		choices[LOCKED_FIVE] = "5 cheats each match: see the true ending first"
	choices["HINT"] = "A hint for the true ending"
	if dialogueKey in ["HINT", "ANSWER"]:
		choices["ANSWER"] = "Just tell me how"
	for finale in LOCKED_FINALES:
		if !Race.lockedSeen(finale[0]) or Race.unlocked(finale[1]):
			continue
		choices["HINT_" + finale[2]] = "A hint for the ? ? ? %s" % finale[3]
		if trueEndingSeen():
			choices["ANSWER_" + finale[2]] = "Just tell me how to open the ? ? ? %s" % finale[3]
		else:
			choices["LOCKED_ANSWER_" + finale[2]] = "How to open the ? ? ? %s: see the true ending first" % finale[3]
	return choices

# The true ending: the real kiss and the night in the grass (Race.keepOutcome sets the flag when its
# ending, THE_END__L4_KISS, plays).
static func trueEndingSeen() -> bool:
	return GlobalGameStage.hasFlag(Race.WARM_SEX)
