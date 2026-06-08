extends PokerScript

static var alreadyActivatedDialogues = []

static var shouldRestoreImageOnCompletion = false

static var PLAYER_LOST_SHIRT = false
static var PLAYER_LOST_PANTS = false
static var PLAYER_LOST_UNDERWEAR = false

static var CPU_LOST_PRACTICE = false
static var CPU_LOST_TOP = false
static var CPU_LOST_SHORTS = false
static var CPU_LOST_BRA = false

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
	CPU_LOST_TOP = false
	CPU_LOST_SHORTS = false
	CPU_LOST_BRA = false
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

	if _pokerInfo.cpuLives < 6:
		CPU_LOST_BRA = true
	elif _pokerInfo.cpuLives < 11:
		CPU_LOST_SHORTS = true
	elif _pokerInfo.cpuLives < 16:
		CPU_LOST_TOP = true

	if _pokerInfo.playerLives == 0:
		PLAYER_LOST_UNDERWEAR = true
	elif _pokerInfo.playerLives < 9:
		PLAYER_LOST_PANTS = true
	elif _pokerInfo.playerLives < 14:
		PLAYER_LOST_SHIRT = true

	# CORE EVENTS

	if _pokerInfo.cpuLives == 15:
		cpuMostRecentlyLostItem = 'TOP'

		# GlobalGameStage.unlockWallpaper('ASHELY_POKER1','',true)

		if PLAYER_LOST_SHIRT or PLAYER_LOST_PANTS:
			# She is about even
			updateResult = getResultForDialogue('LISA_STRIP_TOP2', 'strip_top') # done
		else:
			# She is behind
			updateResult = getResultForDialogue('LISA_STRIP_TOP3', 'strip_top') # done
		
	elif _pokerInfo.cpuLives == 10:
		cpuMostRecentlyLostItem = 'SHORTS'

		GlobalGameStage.unlockWallpaper('LISA_SP_69','',true)

		if PLAYER_LOST_PANTS:
			# She is very far ahead
			updateResult = getResultForDialogue('LISA_STRIP_SHORTS1', 'strip_shorts') #done
		else: # includes player lost shirt
			# She is behind
			updateResult = getResultForDialogue('LISA_STRIP_SHORTS3', 'strip_shorts') #done

	elif _pokerInfo.cpuLives == 5:
		cpuMostRecentlyLostItem = 'BRA'

		GlobalGameStage.unlockWallpaper('LISA_SP_85','',true)

		if PLAYER_LOST_PANTS:
			# She is very far ahead
			updateResult = getResultForDialogue('LISA_STRIP_BRA1', 'strip_bra') 
		else:
			# She is behind
			updateResult = getResultForDialogue('LISA_STRIP_BRA3', 'strip_bra') 
	
	if updateResult.dialogueStartKey:
		return updateResult
	
	#shouldRestoreImageOnCompletion = true

	# if _pokerInfo.playerLives == 13:
	# 	playerMostRecentlyLostItem = 'SHIRT'

	# 	if CPU_LOST_BRA:
	# 		# player is behind
	# 		updateResult = getResultForDialogue('P_STRIP_SHIRT3', 'player_strip_shirt') 
	# 	elif CPU_LOST_SHORTS:
	# 		# player is about even
	# 		updateResult = getResultForDialogue('P_STRIP_SHIRT2', 'player_strip_shirt') 
	# 	elif CPU_LOST_TOP:
	# 		# player is very far ahead
	# 		updateResult = getResultForDialogue('P_STRIP_SHIRT1', 'player_strip_shirt') 
	# 	else:
	# 		# player is way behind
	# 		updateResult = getResultForDialogue('P_STRIP_SHIRT4', 'player_strip_shirt') 

	# elif _pokerInfo.playerLives == 8:
	# 	playerMostRecentlyLostItem = 'PANTS'

	# 	if CPU_LOST_BRA:
	# 		# player is behind
	# 		updateResult = getResultForDialogue('P_STRIP_PANTS3', 'player_strip_pants') 
	# 	elif CPU_LOST_SHORTS:
	# 		# player is about even
	# 		updateResult = getResultForDialogue('P_STRIP_PANTS2', 'player_strip_pants') 
	# 	elif CPU_LOST_TOP:
	# 		# player is very far ahead
	# 		updateResult = getResultForDialogue('P_STRIP_PANTS1', 'player_strip_pants') 
	# 	else:
	# 		# player is way behind
	# 		updateResult = getResultForDialogue('P_STRIP_PANTS4', 'player_strip_pants') 

	# elif _pokerInfo.playerLives == 0:
	# 	if CPU_LOST_BRA:
	# 		# player is behind
	# 		updateResult = getResultForDialogue('P_STRIP_ALL3', 'player_strip_all') 
	# 	elif CPU_LOST_SHORTS:
	# 		# player is about even
	# 		updateResult = getResultForDialogue('P_STRIP_ALL2', 'player_strip_all') 
	# 	elif CPU_LOST_TOP:
	# 		# player is very far ahead
	# 		updateResult = getResultForDialogue('P_STRIP_ALL1', 'player_strip_all') 
	# 	else:
	# 		# player is way behind
	# 		updateResult = getResultForDialogue('P_STRIP_ALL4', 'player_strip_all') 

	if updateResult.dialogueStartKey:
		return updateResult

	#var ambientDialogue = getAmbientDialogue(_pokerInfo)

	#if ambientDialogue.size() > 0:
	#	updateResult = getResultForDialogue(ambientDialogue[0], ambientDialogue[1])

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



	
		# where is that guy?
		# you seem cold (to / from)		if 
		# both players at last piece
		# both players in underwear
		# player strong recovery while naked
		# cpu strong recovery while almost naked - 
		# cpu compliments player's body
		# cpu compliments player's body while naked -
		# player is significantly ahead
		# cpu is significantly ahead -
		# player comments on cpu covering herself -
		# both one life left -
		# player is staring -
		# player comments on cpu's underwear -
		# cpu comments on player's underwear - : "Interesting choice. Did your mom pick those out or were they on clearance?"
		# player catching back up -
		# cpu catching back up -
		# cpu on a winning streak
		# player on a winning streak -
		# player streak ends
		# cpu streak ends -
		# cpu takes the lead after a long loss streak -
		# player takes the lead after a long loss streak -
		# player at final life
		# cpu at final life
		# long match (> 30 rounds) and still close (stretch break?)
		# guy knocks at the door after certain number of rounds
		# she accuses him of letting her win because he thinks he'll get some action when hes naked
		# player comments on her lack of blush
		# Player trying to sit "coolly" after losing pants but awkwardly slipping on the chair -
		# Player making excuse about the cold affecting certain... dimensions; -
		# Player trying to explain poker strategy to seem intellectual -- despite being very far behind
		# Player blaming the lighting for making him look pale; she responds: "Yes, it's definitely the lighting making you look like uncooked pizza dough."
