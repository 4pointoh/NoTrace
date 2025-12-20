extends ChoiceScript

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == 'START':
		return {
			'TITLE': 'What do you want me to do?', 
			'ROUTE_1': 'Drop your hands', #drop your hands
			'ROUTE_2': 'Let me touch you', #let me touch you - massage
			'ROUTE_3': 'Kiss me', #kiss me - kiss
			'ROUTE_4': 'Touch me', #touch me - massage me
			'ROUTE_5': 'Nothing, you did great', #nothing, you did great
		}
	elif dialogueKey == 'ROUTE_1' or dialogueKey == 'ROUTE_2' or dialogueKey == 'ROUTE_3' or dialogueKey == 'ROUTE_4' or dialogueKey == 'ROUTE_5':
		return {
			'GUARANTEED': 'ENDING',
		}
	else:
		return {}
