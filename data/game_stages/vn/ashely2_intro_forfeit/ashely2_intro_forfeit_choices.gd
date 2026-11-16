extends ChoiceScript

# She won the first hand: her forfeit plays, then the race's first match.
static func getChoicesForDialogueKey(_dialogueKey: String) -> Dictionary[String, String]:
	return { "GUARANTEED": "INTRO_FORFEIT" }
