extends ChoiceScript

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
	if dialogueKey == 'START':
		GlobalGameStage.annaCorrectChoices = 0
		return {
			'TITLE': 'What do you want to do?',
			'ROUTE_1': 'Stay Here',
			'ROUTE_2': 'Explore'
		}
	elif dialogueKey == 'ROUTE_1':
		return {
			'TITLE': 'How many cats does Anna have?',
			'ROUTE_1_Q1_A1': 'Six',
			'ROUTE_1_Q1_A2': 'One',
			'ROUTE_1_Q1_A3': 'Zero'
		}
	elif dialogueKey == 'ROUTE_1_Q1_A1' or dialogueKey == 'ROUTE_1_Q1_A2' or dialogueKey == 'ROUTE_1_Q1_A3':
		if dialogueKey == 'ROUTE_1_Q1_A1':
			GlobalGameStage.annaCorrectChoices += 1

		return {
			'TITLE': 'What is Anna\'s favorite cat?',
			'ROUTE_1_Q2_A1': 'Melody',
			'ROUTE_1_Q2_A2': 'Lyric',
			'ROUTE_1_Q2_A3': 'Steve'
		}
	elif dialogueKey == 'ROUTE_1_Q2_A1' or dialogueKey == 'ROUTE_1_Q2_A2' or dialogueKey == 'ROUTE_1_Q2_A3':
		if dialogueKey == 'ROUTE_1_Q2_A2':
			GlobalGameStage.annaCorrectChoices += 1

		return {
			'TITLE': 'What is Anna\'s favorite ice cream flavor?',
			'ROUTE_1_Q3_A1': 'Mint Chocolate Chip',
			'ROUTE_1_Q3_A2': 'Vanilla',
			'ROUTE_1_Q3_A3': 'She\'s never had ice cream'
		}
	elif dialogueKey == 'ROUTE_1_Q3_A1' or dialogueKey == 'ROUTE_1_Q3_A2' or dialogueKey == 'ROUTE_1_Q3_A3':
		if dialogueKey == 'ROUTE_1_Q3_A3':
			GlobalGameStage.annaCorrectChoices += 1

		if GlobalGameStage.annaCorrectChoices == 3:
			GlobalGameStage.annaCorrectChoices = 0
			return {
				'GUARANTEED': 'ROUTE_1_ALL_CORRECT',
			}
		elif GlobalGameStage.annaCorrectChoices == 0:
			return {
				'GUARANTEED': 'ROUTE_1_ALL_INCORRECT',
			}
		else:
			GlobalGameStage.annaCorrectChoices = 0
			return {
				'GUARANTEED': 'ROUTE_1_SOME_INCORRECT',
			}
	elif dialogueKey == 'ROUTE_1_ALL_CORRECT' or dialogueKey == 'ROUTE_1_ALL_INCORRECT' or dialogueKey == 'ROUTE_1_SOME_INCORRECT':
			return {
				'TITLE': 'Investigate the footsteps?',
				'ROUTE_3': 'Wait it out',
				'ROUTE_4': 'See what it is'
			}
	elif dialogueKey == 'ROUTE_4':
		return {
			'TITLE': 'Anna asks: What should we do?',
			'ROUTE_5': 'I don\'t know',
			'ROUTE_6_TRANSITION': 'Exit the room quickly'
		}
	elif dialogueKey == 'ROUTE_6_TRANSITION':
		return {
			'TITLE': 'Where to?',
			'ROUTE_6': 'The Music Wing',
			'ROUTE_7': 'The Sports Wing'
		}
	elif dialogueKey == 'ROUTE_6':
		return {
			'TITLE': 'Where to?',
			'ROUTE_9': 'Steal Snacks From The Cafeteria',
			'ROUTE_13': 'The Sports Wing'
		}
	else:
		return {}
