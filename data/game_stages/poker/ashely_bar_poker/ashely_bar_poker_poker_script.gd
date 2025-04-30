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

	if _pokerInfo.cpuLives == 0:
		CPU_LOST_EVERYTHING = true
	elif _pokerInfo.cpuLives < 5:
		CPU_LOST_BRA = true
	elif _pokerInfo.cpuLives < 8:
		CPU_LOST_PANTS = true
	elif _pokerInfo.cpuLives < 11:
		CPU_LOST_SHIRT = true
	elif _pokerInfo.cpuLives < 14:
		CPU_LOST_JACKET = true
	elif _pokerInfo.cpuLives < 17:
		CPU_LOST_HAIRBAND = true

	if _pokerInfo.playerLives == 0:
		PLAYER_LOST_EVERYTHING = true
	elif _pokerInfo.playerLives < 5:
		PLAYER_LOST_UNDERWEAR = true
	elif _pokerInfo.playerLives < 10:
		PLAYER_LOST_PANTS = true
	elif _pokerInfo.playerLives < 15:
		PLAYER_LOST_SHIRT = true

	# CORE EVENTS

	if _pokerInfo.cpuLives == 16:
		cpuMostRecentlyLostItem = 'HAIRBAND'

		GlobalGameStage.unlockWallpaper('ASHELY_POKER1','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER2','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER3','',true)

		if PLAYER_LOST_PANTS:
			# She is very far ahead
			updateResult = getResultForDialogue('ASHE_STRIP_HAIRBAND_FAR_AHEAD', 'strip_hairband')
		elif PLAYER_LOST_SHIRT:
			# She is about even
			updateResult = getResultForDialogue('ASHE_STRIP_HAIRBAND_EVEN', 'strip_hairband')
		else:
			# She is behind
			updateResult = getResultForDialogue('ASHE_STRIP_HAIRBAND_BEHIND', 'strip_hairband')
		
	elif _pokerInfo.cpuLives == 13:
		cpuMostRecentlyLostItem = 'JACKET'
		GlobalGameStage.unlockWallpaper('ASHELY_POKER6','',true)

		if PLAYER_LOST_UNDERWEAR:
			# She is very far ahead
			updateResult = getResultForDialogue('ASHE_STRIP_JACKET_FAR_AHEAD', 'strip_jacket')
		elif PLAYER_LOST_PANTS or PLAYER_LOST_SHIRT:
			# She is ahead
			updateResult = getResultForDialogue('ASHE_STRIP_JACKET_AHEAD', 'strip_jacket')
		else:
			# She is behind
			updateResult = getResultForDialogue('ASHE_STRIP_JACKET_BEHIND', 'strip_jacket')

	elif _pokerInfo.cpuLives == 10:
		cpuMostRecentlyLostItem = 'SHIRT'
		GlobalGameStage.unlockWallpaper('ASHELY_POKER7','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER8','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER9','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER10','',true)

		if PLAYER_LOST_UNDERWEAR or PLAYER_LOST_PANTS or PLAYER_LOST_SHIRT:
			# She is very far ahead
			updateResult = getResultForDialogue('ASHE_STRIP_SHIRT_EVEN', 'strip_shirt')
		else:
			# She is behind, player still has shirt
			updateResult = getResultForDialogue('ASHE_STRIP_SHIRT_BEHIND', 'strip_shirt')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER11','',true)
		
	elif _pokerInfo.cpuLives == 7:
		cpuMostRecentlyLostItem = 'PANTS'

		GlobalGameStage.unlockWallpaper('ASHELY_POKER12','',true)

		if PLAYER_LOST_UNDERWEAR:
			# She is about even
			updateResult = getResultForDialogue('ASHE_STRIP_PANTS_EVEN_2', 'strip_pants')
		elif PLAYER_LOST_PANTS:
			# She is about even
			updateResult = getResultForDialogue('ASHE_STRIP_PANTS_EVEN', 'strip_pants')
		else:
			# She is behind
			updateResult = getResultForDialogue('ASHE_STRIP_PANTS_FAR_BEHIND', 'strip_pants')
		
	elif _pokerInfo.cpuLives == 4:
		cpuMostRecentlyLostItem = 'BRA'
		GlobalGameStage.unlockWallpaper('ASHELY_POKER4','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER20','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER21','',true)
		GlobalGameStage.unlockWallpaper('ASHELY_POKER22','',true)

		if PLAYER_LOST_UNDERWEAR or PLAYER_LOST_PANTS:
			# She is ahead / not far behind
			updateResult = getResultForDialogue('ASHE_STRIP_BRA_STILL_AHEAD', 'strip_bra')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER14','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER15','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER19','',true)
		else:
			# She is far behind
			updateResult = getResultForDialogue('ASHE_STRIP_BRA_VERY_FAR_BEHIND', 'strip_bra')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER13','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER16','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER17','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER18','',true)
		
	elif _pokerInfo.cpuLives == 0:
			GlobalGameStage.unlockWallpaper('ASHELY_POKER5','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER23','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER24','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER25','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER26','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER27','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER28','',true)
			updateResult = getResultForDialogue('ASHE_STRIP_ALL', 'strip_all')

	
	if updateResult.dialogueStartKey:
		return updateResult
	
	shouldRestoreImageOnCompletion = true

	if _pokerInfo.playerLives == 14:
		playerMostRecentlyLostItem = 'SHIRT'

		if CPU_LOST_BRA:
			# player is very far ahead
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_VERY_FAR_AHEAD', 'player_strip_shirt')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER30','',true)
		elif CPU_LOST_PANTS:
			# player is far ahead
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_FAR_AHEAD', 'player_strip_shirt')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER29','',true)
		elif CPU_LOST_SHIRT :
			# player is ahead
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_AHEAD', 'player_strip_shirt')
		elif CPU_LOST_JACKET or CPU_LOST_HAIRBAND :
			# player is about even
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_EVEN', 'player_strip_shirt')
		else:
			# player is behind
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_BEHIND', 'player_strip_shirt')

	elif _pokerInfo.playerLives == 9:
		playerMostRecentlyLostItem = 'PANTS'

		if CPU_LOST_BRA:
			# player is far ahead
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_NO_BRA', 'player_strip_pants')
			PANTS_OFF_ALT = true
		elif CPU_LOST_PANTS:
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_BRA', 'player_strip_pants')
			PANTS_OFF_ALT = true
		elif CPU_LOST_SHIRT:
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_PANTS', 'player_strip_pants')
			PANTS_OFF_ALT = true
		else:
			# player slips when sitting
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_SLIP', 'player_strip_pants')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER33','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER34','',true)

		if PANTS_OFF_ALT:
			GlobalGameStage.unlockWallpaper('ASHELY_POKER31','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER32','',true)
		
	elif _pokerInfo.playerLives == 4:
		playerMostRecentlyLostItem = 'UNDERWEAR'

		updateResult = getResultForDialogue('PLAYER_STRIP_UNDERWEAR', 'player_strip_underwear')

		# if CPU_LOST_BRA:
		# 	# player is ahead
		# 	updateResult = getResultForDialogue('PLAYER_STRIP_UNDERWEAR_STILL_AHEAD', 'player_strip_underwear')
		# elif CPU_LOST_PANTS:
		# 	# player is behind
		# 	updateResult = getResultForDialogue('PLAYER_STRIP_UNDERWEAR_BEHIND', 'player_strip_underwear')
		# elif CPU_LOST_SHIRT :
		# 	# player is far behind
		# 	updateResult = getResultForDialogue('PLAYER_STRIP_UNDERWEAR_FAR_BEHIND', 'player_strip_underwear')
		# elif CPU_LOST_JACKET or CPU_LOST_HAIRBAND :
		# 	# player is very far behind
		# 	updateResult = getResultForDialogue('PLAYER_STRIP_UNDERWEAR_VERY_FAR_BEHIND', 'player_strip_underwear')
		# else:
		# 	# player is extremely far behind
		# 	updateResult = getResultForDialogue('PLAYER_STRIP_UNDERWEAR_EXTREMELY_FAR_BEHIND', 'player_strip_underwear')
		
	elif _pokerInfo.playerLives == 0:
		if CPU_LOST_BRA:
			# player barely lost
			updateResult = getResultForDialogue('PLAYER_STRIP_ALL_NO_BRA', 'player_strip_all')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER36','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER37','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER38','',true)
			GlobalGameStage.unlockWallpaper('ASHELY_POKER39','',true)
		elif CPU_LOST_PANTS or CPU_LOST_SHIRT:
			# player lost by a bit
			updateResult = getResultForDialogue('PLAYER_STRIP_ALL_NO_PANTS', 'player_strip_all')
		else:
			# player lost by a lot
			updateResult = getResultForDialogue('PLAYER_STRIP_ALL_SHIRT_ON', 'player_strip_all')
			GlobalGameStage.unlockWallpaper('ASHELY_POKER35','',true)

	if updateResult.dialogueStartKey:
		return updateResult

	var ambientDialogue = getAmbientDialogue(_pokerInfo)

	if ambientDialogue.size() > 0:
		updateResult = getResultForDialogue(ambientDialogue[0], ambientDialogue[1])

	return updateResult

static func getAmbientDialogue(_pokerInfo : PokerInfo) -> Array:
	var ambient_talks = []

	# NEED SOME DIALOGUES EARLY GAME THAT CAN trigger without too much long-form criteria
	if !hasSeen('player_losing_early'):
		if totalRounds < 5 and cpuLifeAdvantage > 2:
			# Player: I guess I'm losing early
			ambient_talks.append(['PLAYER_LOSING_EARLY', 'player_losing_early'])
	
	if !hasSeen('player_lost_first_hand'):
		if playerTotalWins == 0 and cpuTotalWins == 1:
			# Player: I guess I lost the first hand
			ambient_talks.append(['PLAYER_LOST_FIRST_HAND', 'player_lost_first_hand'])
	
	if !hasSeen('cpu_early_streak'):
		if cpuCurrentWinStreak > 3 and totalRounds < 8 and cpuLifeAdvantage > 2 and cpuTotalLosses < 3:
			# Ashe: I guess I'm on a winning streak
			ambient_talks.append(['CPU_EARLY_STREAK', 'cpu_early_streak'])

	if !hasSeen('early_close_game') and !hasSeen('player_losing_early') and !hasSeen('cpu_early_streak'):
		if totalRounds < 10 and totalRounds > 4 and playerLifeAdvantage < 2 and cpuLifeAdvantage < 2:
			# Player: This is a close game
			ambient_talks.append(['EARLY_CLOSE_GAME', 'early_close_game'])

	if !hasSeen('where_is_guy') and !CPU_LOST_SHIRT:
		if totalRounds > 10 and cpuLifeAdvantage > 3 :
			# Player: Nervously -- is that guy going to come back or what?
			ambient_talks.append(['WHERE_IS_GUY_NERVOUS', 'where_is_guy'])

	if !hasSeen('you_seem_cold'):
		if PLAYER_LOST_SHIRT and not CPU_LOST_SHIRT and randf() < 0.2:
			# Ashe: You seem cold
			ambient_talks.append(['ASHE_SAYS_YOU_SEEM_COLD', 'you_seem_cold'])

	if !hasSeen('you_seem_cold_back') and hasSeen('you_seem_cold'):
		if CPU_LOST_SHIRT and randf() < 0.5:
			# Player: You thought I was cold? How do you like it?
			ambient_talks.append(['YOU_SAY_YOU_SEEM_COLD_BACK', 'you_seem_cold_back'])

	if !hasSeen('both_players_in_underwear'):
		if PLAYER_LOST_PANTS and CPU_LOST_PANTS and not CPU_LOST_BRA:
			# Player: I guess we are both in our underwear now
			# Ashe: Don't act like your underpants are an equal sight to mine
			ambient_talks.append(['BOTH_PLAYERS_IN_UNDERWEAR', 'both_players_in_underwear'])
	
	if !hasSeen('cpu_compliment') and !hasSeen('cpu_compliment_naked'):
		if PLAYER_LOST_SHIRT and randf() < 0.2:
			# Ashe: I have to admit, you don't look half bad without a shirt
			ambient_talks.append(['CPU_COMPLIMENT', 'cpu_compliment'])

	if !hasSeen('player_compliment'):
		if CPU_LOST_PANTS and randf() < 0.1:
			# Player: that's some fancy underwear... were you planning to show it off tonight?
			ambient_talks.append(['PLAYER_COMPLIMENT', 'player_compliment'])
	
	if !hasSeen('big_cpu_advantage'):
		if cpuLifeAdvantage > 9:
			# Ashe: You sure you dont want to quit? I'll barely have lost anything at this rate
			ambient_talks.append(['BIG_CPU_ADVANTAGE', 'big_cpu_advantage'])
	
	if !hasSeen('both_players_last_life'):
		if _pokerInfo.playerLives == 1 and _pokerInfo.cpuLives == 1:
			# Player: I guess we are both down to our last piece
			ambient_talks.append(['BOTH_PLAYERS_LAST_LIFE', 'both_players_last_life'])

	if !hasSeen('player_staring'):
		if CPU_LOST_BRA and randf() < 0.2:
			# Player: I can't help but stare at your bra
			ambient_talks.append(['PLAYER_STARING_BRA', 'player_staring'])

	if !hasSeen('player_final_life') and !hasSeen('cpu_final_life') and !hasSeen('both_players_last_life'):
		if _pokerInfo.playerLives == 1 and not (_pokerInfo.playerLives == 1 and _pokerInfo.cpuLives == 1):
			# Player: I guess this is my last life
			ambient_talks.append(['PLAYER_FINAL_LIFE', 'player_final_life'])

	if !hasSeen('long_match'):
		if totalRounds > 30 and playerLifeAdvantage < 2 and cpuLifeAdvantage < 2:
			# Player: This is a long match and it's still close -- *** do something special fo this one
			ambient_talks.append(['LONG_MATCH', 'long_match'])
	
	if !hasSeen('guy_knocks'):
		if totalRounds > 20 and CPU_LOST_SHIRT:
			# Player: is that guy knocking on the door?
			ambient_talks.append(['GUY_KNOCKS', 'guy_knocks'])

	if !hasSeen('cpu_accuses_player_of_letting_win'):
		if cpuLifeAdvantage > 15:
			# Ashe: You know, I think you're letting me win because you think you'll get some action when you're naked
			ambient_talks.append(['CPU_ACCUSE_LETTING_WIN', 'cpu_accuses_player_of_letting_win'])

	if !hasSeen('player_excuses'):
		if PANTS_OFF_ALT and PLAYER_LOST_PANTS and randf() < 0.2:
			# Ashely: So you really werent hard?
			ambient_talks.append(['REALLY_WERENT_HARD', 'player_excuses'])

	if !hasSeen('player_poker_strategy'):
		if cpuCurrentWinStreak > 5 and cpuLifeAdvantage > 5:
			# Player: You know, on that hand, you should have <something> 
			# Ashe: You're giving me poker advice? you realize im destroying you right?
			ambient_talks.append(['PLAYER_POKER_STRATEGY', 'player_poker_strategy'])

	if !hasSeen('player_blame_lighting'):
		if PLAYER_LOST_PANTS and randf() < 0.5:
			# Player: I think the lighting is making me look pale
			# Ashe: Yes, it's definitely the lighting making you look like uncooked pizza dough
			ambient_talks.append(['PLAYER_BLAME_LIGHTING', 'player_blame_lighting'])

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
