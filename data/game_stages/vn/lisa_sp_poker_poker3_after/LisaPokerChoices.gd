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
	elif dialogueKey == 'ROUTE_1' or dialogueKey == 'ROUTE_5' or dialogueKey == 'ROUTE_3' or dialogueKey == 'ROUTE_4' or dialogueKey == 'POS_5':
		return {
			'GUARANTEED': 'ENDING',
		}
	elif dialogueKey == 'ROUTE_2':
		return {
			'TITLE': 'What do you want me to do?', 
			'POS_1': 'Upper Back',
			'POS_2': 'Mid Back',
		}
	elif dialogueKey.contains('POS_'):
		GlobalGameStage.lisaMassagePoints = GlobalGameStage.lisaMassagePoints + 1

		if GlobalGameStage.lisaMassagePoints == 1:
			return {
				'TITLE': 'What do you want me to do?', 
				'POS_1': 'Upper Back',
				'POS_2': 'Mid Back',
			}
		elif GlobalGameStage.lisaMassagePoints == 2:
			return {
				'TITLE': 'What do you want me to do?', 
				'POS_1': 'Upper Back',
				'POS_2': 'Mid Back',
				'POS_3': 'Very Upper Back',
			}
		elif GlobalGameStage.lisaMassagePoints == 3:
			return {
				'TITLE': 'What do you want me to do?', 
				'POS_1': 'Upper Back',
				'POS_2': 'Mid Back',
				'POS_3': 'Very Upper Back',
			}
		elif GlobalGameStage.lisaMassagePoints == 4:
			return {
				'TITLE': 'What do you want me to do?', 
				'POS_1': 'Upper Back',
				'POS_2': 'Mid Back',
				'POS_3': 'Very Upper Back',
				'POS_4': 'Lower Back',
			}
		elif GlobalGameStage.lisaMassagePoints == 5:
			return {
				'TITLE': 'What do you want me to do?', 
				'POS_1': 'Upper Back',
				'POS_2': 'Mid Back',
				'POS_3': 'Very Upper Back',
				'POS_4': 'Lower Back',
			}
		elif GlobalGameStage.lisaMassagePoints == 6:
			return {
				'TITLE': 'What do you want me to do?', 
				'POS_1': 'Upper Back',
				'POS_2': 'Mid Back',
				'POS_3': 'Very Upper Back',
				'POS_4': 'Lower Back',
				'POS_5': 'Peek'
			}
	return {}
