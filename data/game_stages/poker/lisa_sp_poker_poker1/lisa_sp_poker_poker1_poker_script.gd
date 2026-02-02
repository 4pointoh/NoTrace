extends PokerScript

static var alreadyActivatedDialogues = []

static var shouldRestoreImageOnCompletion = false

static var PLAYER_LOST_SHIRT = false
static var PLAYER_LOST_PANTS = false
static var PLAYER_LOST_UNDERWEAR = false
static var PLAYER_LOST_EVERYTHING = false

static var CPU_LOST_HAIRBAND = false
static var CPU_LOST_JACKET = false
static var CPU_LOST_SHIRT = false
static var CPU_LOST_PANTS = false
static var CPU_LOST_BRA = false
static var CPU_LOST_EVERYTHING = false

static var PANTS_OFF_ALT = false

# Num of losses in a row
static var playerLossesInARow = 0
static var cpuLossesInARow = 0

# Total losses
static var playerTotalLosses = 0
static var cpuTotalLosses = 0

# Total wins
static var playerTotalWins = 0
static var cpuTotalWins = 0

# Total Life Advantage
static var playerLifeAdvantage = 0
static var cpuLifeAdvantage = 0

# Highest historical life advantage
static var highestCpuLifeAdvantage = 0
static var highestPlayerLifeAdvantage = 0

# Most recent loss streak
static var playerMostRecentLossStreak = 0
static var cpuMostRecentLossStreak = 0

# Current Win Streak
static var playerCurrentWinStreak = 0
static var cpuCurrentWinStreak = 0

# Highest Win Streak
static var playerHighestWinStreak = 0
static var cpuHighestWinStreak = 0

# Most recent lost item
static var playerMostRecentlyLostItem = 'NOTHING'
static var cpuMostRecentlyLostItem = 'NOTHING'

# Total rounds played
static var totalRounds = 0

static func reset_tracking_vars():
	alreadyActivatedDialogues = []
	shouldRestoreImageOnCompletion = false
	PLAYER_LOST_SHIRT = false
	PLAYER_LOST_PANTS = false
	PLAYER_LOST_UNDERWEAR = false
	PLAYER_LOST_EVERYTHING = false
	CPU_LOST_HAIRBAND = false
	CPU_LOST_JACKET = false
	CPU_LOST_SHIRT = false
	CPU_LOST_PANTS = false
	CPU_LOST_BRA = false
	CPU_LOST_EVERYTHING = false
	playerLossesInARow = 0
	cpuLossesInARow = 0
	playerTotalLosses = 0
	cpuTotalLosses = 0
	playerTotalWins = 0
	cpuTotalWins = 0
	playerLifeAdvantage = 0
	cpuLifeAdvantage = 0
	highestCpuLifeAdvantage = 0
	highestPlayerLifeAdvantage = 0
	playerMostRecentLossStreak = 0
	cpuMostRecentLossStreak = 0
	playerCurrentWinStreak = 0
	cpuCurrentWinStreak = 0
	playerHighestWinStreak = 0
	cpuHighestWinStreak = 0
	playerMostRecentlyLostItem = 'NOTHING'
	cpuMostRecentlyLostItem = 'NOTHING'
	totalRounds = 0

static func evaluate_poker_game(_pokerInfo : PokerInfo) :
	var updateResult = PokerUpdateActionResult.new()

	shouldRestoreImageOnCompletion = false

	totalRounds += 1

	if _pokerInfo.playerLost:
		playerLossesInARow += 1
		cpuLossesInARow = 0
		playerTotalLosses += 1
		cpuTotalWins += 1
		playerCurrentWinStreak = 0
		cpuCurrentWinStreak += 1
	else:
		playerLossesInARow = 0
		cpuLossesInARow += 1
		playerTotalWins += 1
		cpuTotalLosses += 1
		playerCurrentWinStreak += 1
		cpuCurrentWinStreak = 0

	playerLifeAdvantage = _pokerInfo.playerLives - _pokerInfo.cpuLives
	cpuLifeAdvantage = _pokerInfo.cpuLives - _pokerInfo.playerLives

	if playerLifeAdvantage > highestPlayerLifeAdvantage:
		highestPlayerLifeAdvantage = playerLifeAdvantage
	elif cpuLifeAdvantage > highestCpuLifeAdvantage:
		highestCpuLifeAdvantage = cpuLifeAdvantage

	if playerLossesInARow > 2:
		playerMostRecentLossStreak = playerLossesInARow
	elif cpuLossesInARow > 2:
		cpuMostRecentLossStreak = cpuLossesInARow

	if playerCurrentWinStreak > playerHighestWinStreak:
		playerHighestWinStreak = playerCurrentWinStreak
	elif cpuCurrentWinStreak > cpuHighestWinStreak:
		cpuHighestWinStreak = cpuCurrentWinStreak

	# CORE EVENTS

	if _pokerInfo.cpuLives == 8:
		# Lisa First Loss
		if _pokerInfo.playerLives <= 3:
			updateResult = getResultForDialogue('LISA_FIRST_LOSS_FAR_AHEAD', 'lisa_first_loss')
		elif _pokerInfo.playerLives <= 7:
			updateResult = getResultForDialogue('LISA_FIRST_LOSS_AHEAD', 'lisa_first_loss')
		elif _pokerInfo.playerLives == 10:
			updateResult = getResultForDialogue('LISA_FIRST_LOSS_BEHIND', 'lisa_first_loss')
		else:
			updateResult = getResultForDialogue('LISA_FIRST_LOSS_CLOSE', 'lisa_first_loss')
		
	elif _pokerInfo.cpuLives == 5:
		if _pokerInfo.playerLives <= 3:
			updateResult = getResultForDialogue('LISA_SEC_LOSS_FAR_AHEAD', 'lisa_sec_loss')
		elif _pokerInfo.playerLives <= 6:
			updateResult = getResultForDialogue('LISA_SEC_LOSS_CLOSE', 'lisa_sec_loss')
		else:
			updateResult = getResultForDialogue('LISA_SEC_LOSS_BEHIND', 'lisa_sec_loss')

	elif _pokerInfo.cpuLives == 3:
		if _pokerInfo.playerLives <= 6:
			updateResult = getResultForDialogue('LISA_THIRD_LOSS_CLOSE', 'lisa_third_loss')
		else:
			updateResult = getResultForDialogue('LISA_THIRD_LOSS_BEHIND', 'lisa_third_loss')
	
	if updateResult.dialogueStartKey:
		return updateResult
	
	#shouldRestoreImageOnCompletion = true

	if _pokerInfo.playerLives == 8:

		if _pokerInfo.cpuLives <= 4:
			updateResult = getResultForDialogue('PLAYER_FIRST_LOSS_FAR_AHEAD', 'player_first_loss')
		elif _pokerInfo.cpuLives <= 8:
			updateResult = getResultForDialogue('PLAYER_FIRST_LOSS_CLOSE', 'player_first_loss')
		else:
			updateResult = getResultForDialogue('PLAYER_FIRST_LOSS_BEHIND', 'player_first_loss')

	elif _pokerInfo.playerLives == 5:
		if _pokerInfo.cpuLives <= 2:
			updateResult = getResultForDialogue('PLAYER_SEC_LOSS_AHEAD', 'player_sec_loss')
		elif _pokerInfo.cpuLives <= 5:
			updateResult = getResultForDialogue('PLAYER_SEC_LOSS_CLOSE', 'player_sec_loss')
		else:
			updateResult = getResultForDialogue('PLAYER_SEC_LOSS_BEHIND', 'player_sec_loss')

		
	elif _pokerInfo.playerLives == 2:
		if _pokerInfo.cpuLives <= 2:
			updateResult = getResultForDialogue('PLAYER_THIRD_LOSS_CLOSE', 'player_third_loss')
		elif _pokerInfo.cpuLives <= 5:
			updateResult = getResultForDialogue('PLAYER_THIRD_LOSS_BEHIND', 'player_third_loss')
		else:
			updateResult = getResultForDialogue('PLAYER_THIRD_LOSS_FAR_BEHIND', 'player_third_loss')

		
	elif _pokerInfo.playerLives == 0:
			updateResult = getResultForDialogue('PLAYER_LOST', 'player_lost')

	if updateResult.dialogueStartKey:
		return updateResult

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

	if shouldRestoreImageOnCompletion:
		updateResult.restoreImageOnCompletion = true

	alreadyActivatedDialogues.append(dialogueKey)
	
	if altKey != '':
		alreadyActivatedDialogues.append(altKey)
	
	return updateResult

static func hasSeen(dialogueKey : String) -> bool:
	return alreadyActivatedDialogues.has(dialogueKey)
