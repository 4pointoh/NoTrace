extends ChoiceScript

# The intro has played: a new race starts from nothing, and the first hand (the one she always
# wins) begins.
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")

static func getChoicesForDialogueKey(_dialogueKey: String) -> Dictionary[String, String]:
	Race.startNewRace()
	return { "GUARANTEED": "TO_MATCH" }
