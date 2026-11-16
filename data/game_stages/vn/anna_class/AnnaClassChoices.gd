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
		GlobalGameStage.unlockWallpaper('ANNA_CLASS6','',true)
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
		else:
			GlobalGameStage.unlockWallpaper('ANNA_CLASS7','',true)

		return {
			'TITLE': 'What is Anna\'s favorite ice cream flavor?',
			'ROUTE_1_Q3_A1': 'Mint Chocolate Chip',
			'ROUTE_1_Q3_A2': 'Vanilla',
			'ROUTE_1_Q3_A3': 'She\'s never had ice cream'
		}
	elif dialogueKey == 'ROUTE_1_Q3_A1' or dialogueKey == 'ROUTE_1_Q3_A2' or dialogueKey == 'ROUTE_1_Q3_A3':
		if dialogueKey == 'ROUTE_1_Q3_A3':
				GlobalGameStage.annaCorrectChoices += 1
		else:
			GlobalGameStage.unlockWallpaper('ANNA_CLASS8','',true)

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
			'ROUTE_9': 'Steal Snacks From The Food Court',
			'ROUTE_13': 'The Sports Wing'
		}
	elif dialogueKey == 'ROUTE_2':
		GlobalGameStage.unlockWallpaper('ANNA_CLASS9','',true)
		GlobalGameStage.unlockWallpaper('ANNA_CLASS10','',true)
		return {
			'TITLE': 'Where to?',
			'ROUTE_10': 'The Music Wing',
			'ROUTE_8': 'The Sports Wing'
		}
	elif dialogueKey == 'ROUTE_10':
		return {
			'TITLE': 'Where to?',
			'ROUTE_12': 'Stay Dry In Here',
			'ROUTE_11': 'The Pool'
		}
	else:
		return {}

# --- what the route menus say you have seen (ChoiceScript.getChoiceMarks)

# The scene as a tree of routes: the choices each one opens next. A route with none ends the scene.
# "Stay Here" (ROUTE_1) reaches its two through the quiz, whatever you answer.
# The menus above stay the ones that decide what is offered: landscape-test's choice_menu_test
# checks this tree against them.
const LEADS_TO = {
	"START": ["ROUTE_1", "ROUTE_2"],
	"ROUTE_1": ["ROUTE_3", "ROUTE_4"],
	"ROUTE_4": ["ROUTE_5", "ROUTE_6_TRANSITION"],
	"ROUTE_6_TRANSITION": ["ROUTE_6", "ROUTE_7"],
	"ROUTE_6": ["ROUTE_9", "ROUTE_13"],
	"ROUTE_2": ["ROUTE_10", "ROUTE_8"],
	"ROUTE_10": ["ROUTE_12", "ROUTE_11"],
}
# The quiz ends one of three ways, each a scene of its own.
const QUIZ_RESULTS = ["ROUTE_1_ALL_CORRECT", "ROUTE_1_ALL_INCORRECT", "ROUTE_1_SOME_INCORRECT"]
const STAGE = "anna_class"

# A scene counts as seen once it has been read to its end.
static func seen(dialogueKey: String) -> bool:
	return GlobalGameStage.hasCompletedDialogueKey(dialogueKey, STAGE)

# What there is to find by taking a route: every ending it can lead to (itself, if it is one),
# and for "Stay Here" the quiz's three results too.
static func toFind(route: String) -> Array:
	if !LEADS_TO.has(route):
		return [route]
	var finds := QUIZ_RESULTS.duplicate() if route == "ROUTE_1" else []
	for next in LEADS_TO[route]:
		finds.append_array(toFind(next))
	return finds

# The routes on the menu a dialogue ends with. None for the quiz's questions: a mark on an answer
# would only read as a hint.
static func routesAfter(dialogueKey: String) -> Array:
	if dialogueKey in QUIZ_RESULTS:
		return LEADS_TO["ROUTE_1"]
	if dialogueKey == "ROUTE_1":
		return []
	return LEADS_TO.get(dialogueKey, [])

# Each route on the menu: how much of what it leads to you have found, and whether its own scene
# is new to you.
static func getChoiceMarks(dialogueKey: String) -> Dictionary:
	var marks := {}
	for route in routesAfter(dialogueKey):
		var finds := toFind(route)
		var found := finds.filter(func(find): return seen(find))
		marks[route] = { "seen": found.size(), "total": finds.size(), "new": !seen(route) }
	return marks
