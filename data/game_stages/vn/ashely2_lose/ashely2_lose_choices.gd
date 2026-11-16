extends ChoiceScript

# After a match she won: the table, then her punishment and the next match. Her fourth win is
# your forfeit, which the ending plays. The rules are in ashely2_race.gd.
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == "START":
		return { "GUARANTEED": "LOST__" + Race.appearance() }
	if dialogueKey.begins_with("LOST__"):
		return { "GUARANTEED": Race.lostMatchKey() }
	Race.takePunishment(dialogueKey)
	return { "GUARANTEED": Race.routeOn() }
