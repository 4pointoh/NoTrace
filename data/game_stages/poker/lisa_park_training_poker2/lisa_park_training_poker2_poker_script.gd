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
	elif _pokerInfo.cpuLives == 3:
		updateResult = getResultForDialogue('FOURTH_LISA_LOSS')
	elif _pokerInfo.cpuLives == 0:
		updateResult = getResultForDialogue('LAST_LISA_LOSS')
	
	if updateResult.dialogueStartKey:
		return updateResult
	
	if _pokerInfo.playerLives == 1:
		updateResult = getResultForDialogue('PLAYER_LOST_ONE')
	if _pokerInfo.playerLives == 0:
		updateResult = getResultForDialogue('PLAYER_LOST_TWO')


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


static func evaluate_ambient_dialogue(_pokerInfo: PokerInfo) -> PokerUpdateActionResult:
	## Main entry point for ambient dialogue evaluation.
	## Called by poker_game.gd when the CSV system returns no event.
	var updateResult = PokerUpdateActionResult.new()
	
	var ambientDialogue = getAmbientDialogue(_pokerInfo)
	
	if ambientDialogue.size() > 0:
		updateResult = getResultForDialogue(ambientDialogue[0], ambientDialogue[1])
	
	return updateResult


static func getAmbientDialogue(_pokerInfo: PokerInfo) -> Array:
	## Define ambient dialogue triggers here.
	## Each dialogue is an array: ['DIALOGUE_KEY', 'tracking_key']
	## Use hasSeen('tracking_key') to prevent repeat triggers.
	## Use randf() < 0.2 for random chance triggers.
	##
	## Example:
	##   if !hasSeen('early_taunt') and _pokerInfo.totalRounds < 5 and _pokerInfo.cpuLifeAdvantage > 2:
	##       ambient_talks.append(['EARLY_TAUNT_DIALOGUE', 'early_taunt'])
	
	var ambient_talks = []
	
	# Add ambient dialogue conditions here
	# Example:
	# if !hasSeen('close_game'):
	#     if _pokerInfo.totalRounds > 10 and abs(_pokerInfo.playerLifeAdvantage) < 2:
	#         ambient_talks.append(['CLOSE_GAME_COMMENT', 'close_game'])
	
	ambient_talks.shuffle()
	if ambient_talks.size() > 0:
		return ambient_talks[0]
	else:
		return []
