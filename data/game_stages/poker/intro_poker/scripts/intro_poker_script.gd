extends PokerScript

static var alreadyDisplayed = false
static var alreadyDisplayed2 = false

# could do cumulative values w/ static variables (eg "you bet more than my car this match")

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()
	
	if _pokerInfo.stage == PokerEnums.PokerStage.POST_FLOP && !alreadyDisplayed:
		alreadyDisplayed = true
		updateResult.dialogueStartKey = 'START_TEST'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	elif _pokerInfo.stage == PokerEnums.PokerStage.DEAL && _pokerInfo.cpuMoney < 200 && !alreadyDisplayed2:
		alreadyDisplayed2 = true
		updateResult.dialogueStartKey = 'START_TEST2'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	else:
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.NOTHING
	
	return updateResult
	
