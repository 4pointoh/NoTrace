extends PokerScript

static var alreadyActivatedDialogues = []

static func reset_tracking_vars():
	alreadyActivatedDialogues = []

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()

	# 9 = play after losing first life
	# 0 = play right before the exit dialogue

	if _pokerInfo.cpuLives == 9:
		updateResult = getResultForDialogue('FIRST_LISA_LOSS')
	elif _pokerInfo.cpuLives == 8:
		updateResult = getResultForDialogue('SECOND_LISA_LOSS')
	elif _pokerInfo.cpuLives == 6:
		updateResult = getResultForDialogue('THIRD_LISA_LOSS')
	elif _pokerInfo.cpuLives == 5:
		updateResult = getResultForDialogue('INTERMISSION')
	elif _pokerInfo.cpuLives == 4:
		updateResult = getResultForDialogue('FOURTH_LISA_LOSS')
	elif _pokerInfo.cpuLives == 2:
		updateResult = getResultForDialogue('FIFTH_LISA_LOSS')
	elif _pokerInfo.cpuLives == 0:
		updateResult = getResultForDialogue('LAST_LISA_LOSS')
	
	if updateResult.dialogueStartKey:
		return updateResult
	
	if _pokerInfo.playerLives == 3 and _pokerInfo.cpuLives >= 9:
		updateResult = getResultForDialogue('PLAYER_LOST_QUICK', 'altkey_playerloss1')
	elif _pokerInfo.playerLives == 3:
		updateResult = getResultForDialogue('PLAYER_LOST_NOT_QUICK', 'altkey_playerloss1')
	elif _pokerInfo.playerLives == 1  and _pokerInfo.cpuLives >= 6:
		updateResult = getResultForDialogue('PLAYER_ABOUT_TO_LOSE_NOT_CLOSE', 'altkey_playerloss2')
	elif _pokerInfo.playerLives == 1:
		updateResult = getResultForDialogue('PLAYER_ABOUT_TO_LOSE_CLOSE', 'altkey_playerloss2')


	return updateResult

# altKey is used for dialogues that have multiple paths
static func getResultForDialogue(dialogueKey : String, altKey : String = ''):
	var updateResult = PokerUpdateActionResult.new()

	if alreadyActivatedDialogues.has(dialogueKey) or alreadyActivatedDialogues.has(altKey):
		return updateResult
	
	updateResult.dialogueStartKey = dialogueKey
	updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
	updateResult.shouldPausePoker = true
	updateResult.shouldHidePoker = true

	alreadyActivatedDialogues.append(dialogueKey)
	
	if altKey != '':
		alreadyActivatedDialogues.append(altKey)
	
	return updateResult
