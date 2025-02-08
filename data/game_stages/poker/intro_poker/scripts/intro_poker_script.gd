extends PokerScript

static var alreadyDisplayed = false
static var alreadyDisplayed2 = false
static var alreadyDisplayed3 = false
static var alreadyDisplayed4 = false
static var alreadyDisplayed5 = false


static func reset_tracking_vars():
	alreadyDisplayed = false
	alreadyDisplayed2 = false
	alreadyDisplayed3 = false
	alreadyDisplayed4 = false
	alreadyDisplayed5 = false


# could do cumulative values w/ static variables (eg "you bet more than my car this match")

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()

	if _pokerInfo.cpuLives == 3 && !alreadyDisplayed:
		alreadyDisplayed = true
		updateResult.dialogueStartKey = 'FIRST_LOSS'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	elif _pokerInfo.cpuLives == 2 && !alreadyDisplayed2:
		alreadyDisplayed2 = true
		updateResult.dialogueStartKey = 'HALF_GONE'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	elif _pokerInfo.cpuLives == 1 && !alreadyDisplayed3:
		alreadyDisplayed3 = true
		updateResult.dialogueStartKey = 'ALMOST_OVER'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	
	elif _pokerInfo.playerLives == 2 && !alreadyDisplayed4 && alreadyDisplayed:
		alreadyDisplayed4 = true
		updateResult.dialogueStartKey = 'PLAYER_LOSS_ALREADY_WON'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true
	elif _pokerInfo.playerLives == 2 && !alreadyDisplayed4:
		alreadyDisplayed4 = true
		updateResult.dialogueStartKey = 'PLAYER_LOSS_NO_WINS'
		updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
		updateResult.shouldPausePoker = true
		updateResult.shouldHidePoker = true

	if _pokerInfo.cpuLives == 0:
		GlobalGameStage.unlockWallpaper('BOA_POK3')
		GlobalGameStage.unlockWallpaper('BOA_POK2')
		GlobalGameStage.unlockWallpaper('BOA_POK1')
		


	# if _pokerInfo.playerMoney > 200 && !alreadyDisplayed3:
	# 	alreadyDisplayed3 = true
	# 	updateResult.dialogueStartKey = 'FIRST_LOSS'
	# 	updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
	# 	updateResult.shouldPausePoker = true
	# 	updateResult.shouldHidePoker = true
	# elif _pokerInfo.playerMoney > 260 && !alreadyDisplayed4:
	# 	alreadyDisplayed4 = true
	# 	updateResult.dialogueStartKey = 'HALF_GONE'
	# 	updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
	# 	updateResult.shouldPausePoker = true
	# 	updateResult.shouldHidePoker = true
	# elif _pokerInfo.playerMoney >= 310 && !alreadyDisplayed:
	# 	alreadyDisplayed = true
	# 	updateResult.dialogueStartKey = 'ALMOST_OVER'
	# 	updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
	# 	updateResult.shouldPausePoker = true
	# 	updateResult.shouldHidePoker = true

	
	return updateResult
	
