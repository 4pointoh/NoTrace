extends ChoiceScript

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == 'START':
		return {
			'TITLE': 'What do you want me to do?', 
			'ROUTE_1': 'Drop your hands', #drop your hands
			'ROUTE_2': 'Not In The Beta!', #let me touch you - massage
			'ROUTE_3': 'Not In The Beta!', #kiss me - kiss
			'ROUTE_4': 'Not In The Beta!', #touch me - massage me
			'ROUTE_5': 'Not In The Beta!', #nothing, you did great
		}
	else:
		return {}
