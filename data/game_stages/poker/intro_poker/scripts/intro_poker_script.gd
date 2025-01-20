extends PokerScript

static var alreadyDisplayed = false
static var alreadyDisplayed2 = false
static var alreadyDisplayed3 = false
static var alreadyDisplayed4 = false


# could do cumulative values w/ static variables (eg "you bet more than my car this match")

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()

	if _pokerInfo.playerMoney > 200 && !alreadyDisplayed3:
		alreadyDisplayed3 = true
		updateResult.dialogueStartKey = 'FIRST_LOSS'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	elif _pokerInfo.playerMoney > 260 && !alreadyDisplayed4:
		alreadyDisplayed4 = true
		updateResult.dialogueStartKey = 'HALF_GONE'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	elif _pokerInfo.playerMoney >= 310 && !alreadyDisplayed:
		alreadyDisplayed = true
		updateResult.dialogueStartKey = 'ALMOST_OVER'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true

	
	return updateResult
	
