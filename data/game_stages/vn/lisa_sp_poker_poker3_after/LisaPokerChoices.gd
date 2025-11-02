extends ChoiceScript

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == 'START':
		return {
			'TITLE': 'What do you want me to do?',
			'ROUTE_1': 'Drop your hands',
			'ROUTE_2': 'Let me touch you',
			'ROUTE_3': 'Kiss me',
			'ROUTE_4': 'Touch me',
			'ROUTE_5': 'Nothing. You did great.',
		}
	elif dialogueKey == 'ROUTE_2':
		return {
			'TITLE': 'Where?',
			'ROUTE_1_Q1_A1': 'Breast',
			'ROUTE_1_Q1_A2': 'Butt',
			'ROUTE_1_Q1_A3': 'Your...'
		}
	elif dialogueKey == 'ROUTE_4':
		return {
			'TITLE': 'Where?',
			'ROUTE_1_Q2_A1': 'You pick.',
			'ROUTE_1_Q2_A2': 'You know where.'
		}
	else:
		return {}
