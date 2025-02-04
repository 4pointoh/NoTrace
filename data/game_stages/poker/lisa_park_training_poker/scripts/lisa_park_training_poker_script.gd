extends PokerScript

static var dialogueIndex = 0


static func reset_tracking_vars():
	dialogueIndex = 0


# could do cumulative values w/ static variables (eg "you bet more than my car this match")

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()

	#if _pokerInfo.cpuLives == 0:
	#	GlobalGameStage.unlockWallpaper('BOA_POK3')
	#	GlobalGameStage.unlockWallpaper('BOA_POK2')
	#	GlobalGameStage.unlockWallpaper('BOA_POK1')
	if _pokerInfo.stage == PokerEnums.PokerStage.POST_DEAL and dialogueIndex == 0:
		dialogueIndex += 1
	elif _pokerInfo.stage == PokerEnums.PokerStage.POST_DEAL and dialogueIndex == 1:
		updateResult.dialogueStartKey = 'START1'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
		dialogueIndex += 1
	elif _pokerInfo.stage == PokerEnums.PokerStage.POST_DEAL and dialogueIndex == 2:
		updateResult.dialogueStartKey = 'START2'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
		dialogueIndex += 1
	elif _pokerInfo.stage == PokerEnums.PokerStage.POST_DEAL and dialogueIndex == 3 and _pokerInfo.cpuMoney < 100:
		updateResult.dialogueStartKey = 'START3'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
		dialogueIndex += 1

	
	return updateResult
	
