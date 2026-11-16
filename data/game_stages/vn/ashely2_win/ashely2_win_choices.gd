extends ChoiceScript

# After a match you won: the table, your stake menu, the stake's scene, its sign-off if it has one
# written (<scene>__NEXT or <scene>__LAST), then the next match or the ending. The rules are in
# ashely2_race.gd.
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == "START":
		return { "GUARANTEED": "WON__" + Race.appearance() }
	if dialogueKey.begins_with("WON__"):
		var menu := Race.stakeMenu()
		# A locked "? ? ?" seen here puts its hint on the replay menu.
		Race.noteLockedSeen(menu)
		return menu
	if !Race.isSignOff(dialogueKey):
		# The stake's scene has played: the stake counts, and its sign-off follows.
		Race.takeStake(dialogueKey)
		var signOff := Race.signOff(dialogueKey, GlobalGameStage.currentStage.dialogue)
		if signOff != "":
			return { "GUARANTEED": signOff }
		# No sign-off for this place: the scene alone was this version of it (for the menu's marks).
		Race.markVersionSeen(dialogueKey)
	return { "GUARANTEED": Race.routeOn() }

# The stake menu marks each stake by how much of it you have seen (each version of a scene that
# plays differently as your last round: Race.stakeMarks).
static func getChoiceMarks(dialogueKey: String) -> Dictionary:
	if dialogueKey.begins_with("WON__"):
		return Race.stakeMarks()
	return {}
