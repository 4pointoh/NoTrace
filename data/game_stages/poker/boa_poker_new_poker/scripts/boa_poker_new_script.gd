extends PokerScript

static var alreadyActivatedDialogues = []

static func reset_tracking_vars():
	alreadyActivatedDialogues = []

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()

	# 9 = play after losing first life
	# 0 = play right before the exit dialogue

	if _pokerInfo.cpuLives == 9 and _pokerInfo.playerLives >= 7:
		updateResult = getResultForDialogue('FIRST_BOA_LOSS_QUICK', 'altkey_firstboaloss1')
	elif _pokerInfo.cpuLives == 9:
		updateResult = getResultForDialogue('FIRST_BOA_LOSS_SLOW', 'altkey_firstboaloss1')
	elif _pokerInfo.cpuLives == 6:
		updateResult = getResultForDialogue('BOA_FIRST_STRIP')
	elif _pokerInfo.cpuLives == 3:
		updateResult = getResultForDialogue('BOA_SECOND_STRIP')
	elif _pokerInfo.cpuLives == 0:
		updateResult = getResultForDialogue('BOA_FINAL_STRIP')
	
	if alreadyActivatedDialogues.has('altkey_playerstrip'):
		updateResult.dialogueStartKey += '_WITH_SHIRT'
	
	if updateResult.dialogueStartKey:
		return updateResult
	
	if _pokerInfo.playerLives == 9 and _pokerInfo.cpuLives >= 9:
		updateResult = getResultForDialogue('PLAYER_LOST_QUICK', 'altkey_playerloss1')
	elif _pokerInfo.playerLives == 9:
		updateResult = getResultForDialogue('PLAYER_LOST_NOT_QUICK', 'altkey_playerloss1')
	elif _pokerInfo.playerLives == 6:
		if alreadyActivatedDialogues.has('BOA_SECOND_STRIP'):
			updateResult = getResultForDialogue('PLAYER_STRIP3', 'altkey_playerstrip')
		elif alreadyActivatedDialogues.has('BOA_FIRST_STRIP'):
			updateResult = getResultForDialogue('PLAYER_STRIP2', 'altkey_playerstrip')
		else:
			updateResult = getResultForDialogue('PLAYER_STRIP1', 'altkey_playerstrip')
	elif _pokerInfo.playerLives == 0:
		updateResult = getResultForDialogue('PLAYER_LOST')

	if alreadyActivatedDialogues.has('altkey_playerstrip'):
		updateResult.dialogueStartKey += '_WITH_SHIRT'

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
