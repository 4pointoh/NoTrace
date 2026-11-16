extends ChoiceScript

# The race is over: whichever ending it earned plays, and its outcome is kept.
# The rules are in ashely2_race.gd.
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")

static func getChoicesForDialogueKey(_dialogueKey: String) -> Dictionary[String, String]:
	Race.keepOutcome()
	return { "GUARANTEED": Race.endingKey() }
