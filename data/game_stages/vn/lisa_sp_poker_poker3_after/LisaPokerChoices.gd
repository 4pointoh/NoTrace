extends ChoiceScript

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == 'START':
		return {
			'TITLE': 'What do you want me to do?', 
			'ROUTE_1': 'Drop your hands', #drop your hands
			'ROUTE_2': 'Not In The Beta!', #let me touch you
			'ROUTE_3': 'Not In The Beta!', #kiss me
			'ROUTE_4': 'Not In The Beta!', #touch me
			'ROUTE_5': 'Not In The Beta!', #nothing, you did great
		}
	elif dialogueKey == 'ROUTE_2':
		return {
			'TITLE': 'Where?', # where?
			'ROUTE_1_Q1_A1': 'Not In The Beta!', #breast
			'ROUTE_1_Q1_A2': 'Not In The Beta!', #butt
			'ROUTE_1_Q1_A3': 'Not In The Beta!' #your...
		}
	elif dialogueKey == 'ROUTE_4':
		return {
			'TITLE': 'Where?',
			'ROUTE_1_Q2_A1': 'Not In The Beta!', #you pick
			'ROUTE_1_Q2_A2': 'Not In The Beta!' #you know where
		}
	else:
		return {}
