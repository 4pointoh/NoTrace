extends PokerScript

static var alreadyActivatedDialogues = []

static var shouldRestoreImageOnCompletion = false

static var PLAYER_LOST_SHIRT = false
static var PLAYER_LOST_PANTS = false
static var PLAYER_LOST_UNDERWEAR = false

static var CPU_LOST_PRACTICE = false
static var CPU_LOST_SHIRT = false
static var CPU_LOST_PANTS = false
static var CPU_LOST_FINAL = false

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
	CPU_LOST_SHIRT = false
	CPU_LOST_PANTS = false
	CPU_LOST_PRACTICE = false
	CPU_LOST_FINAL = false
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
		CPU_LOST_FINAL = true
	elif _pokerInfo.cpuLives < 5:
		CPU_LOST_PANTS = true
	elif _pokerInfo.cpuLives < 8:
		CPU_LOST_SHIRT = true
	elif _pokerInfo.cpuLives < 12:
		CPU_LOST_PRACTICE = true

	if _pokerInfo.playerLives == 0:
		PLAYER_LOST_UNDERWEAR = true
	elif _pokerInfo.playerLives < 5:
		PLAYER_LOST_PANTS = true
	elif _pokerInfo.playerLives < 10:
		PLAYER_LOST_SHIRT = true

	# CORE EVENTS

	if _pokerInfo.cpuLives == 11:
		cpuMostRecentlyLostItem = 'PRACTICE'

		# GlobalGameStage.unlockWallpaper('ASHELY_POKER1','',true)

		if PLAYER_LOST_PANTS or PLAYER_LOST_SHIRT:
			# She is very far ahead
			updateResult = getResultForDialogue('LISA_STRIP_PRACTICE1', 'strip_practice') #done
		else:
			# She is behind
			updateResult = getResultForDialogue('LISA_STRIP_PRACTICE3', 'strip_practice') #done
		
	elif _pokerInfo.cpuLives == 7:
		cpuMostRecentlyLostItem = 'SHIRT'

		if PLAYER_LOST_PANTS:
			# She is very far ahead
			updateResult = getResultForDialogue('LISA_STRIP_SHIRT1', 'strip_shirt') #done
		elif PLAYER_LOST_SHIRT:
			# She is about even
			updateResult = getResultForDialogue('LISA_STRIP_SHIRT2', 'strip_shirt') #done shared with 3
		else:
			# She is behind
			updateResult = getResultForDialogue('LISA_STRIP_SHIRT3', 'strip_shirt') #done	shared with 2

	elif _pokerInfo.cpuLives == 4:
		cpuMostRecentlyLostItem = 'PANTS'

		if PLAYER_LOST_PANTS:
			# She is very far ahead
			updateResult = getResultForDialogue('LISA_STRIP_PANTS1', 'strip_pants') # done
		elif PLAYER_LOST_SHIRT:
			# She is about even
			updateResult = getResultForDialogue('LISA_STRIP_PANTS2', 'strip_pants') # done, same as 3
		else:
			# She is behind
			updateResult = getResultForDialogue('LISA_STRIP_PANTS3', 'strip_pants') # done, same as 2

	# Dont thnk this is needed, it should autoplay next scene on 0 
	#elif _pokerInfo.cpuLives == 0:
	#		updateResult = getResultForDialogue('ASHE_STRIP_ALL', 'strip_all')

	
	if updateResult.dialogueStartKey:
		return updateResult
	
	#shouldRestoreImageOnCompletion = true

	if _pokerInfo.playerLives == 9:
		playerMostRecentlyLostItem = 'SHIRT'

		if CPU_LOST_PANTS:
			# player is behind
			updateResult = getResultForDialogue('P_STRIP_SHIRT3', 'player_strip_shirt') #done
		elif CPU_LOST_SHIRT:
			# player is about even
			updateResult = getResultForDialogue('P_STRIP_SHIRT2', 'player_strip_shirt') #done
		elif CPU_LOST_PRACTICE:
			# player is very far ahead
			updateResult = getResultForDialogue('P_STRIP_SHIRT1', 'player_strip_shirt') # done
		else:
			# player is way behind
			updateResult = getResultForDialogue('P_STRIP_SHIRT4', 'player_strip_shirt') # done

	elif _pokerInfo.playerLives == 4:
		playerMostRecentlyLostItem = 'PANTS'

		if CPU_LOST_PANTS:
			# player is behind
			updateResult = getResultForDialogue('P_STRIP_PANTS3', 'player_strip_pants') # done
		elif CPU_LOST_SHIRT:
			# player is about even
			updateResult = getResultForDialogue('P_STRIP_PANTS2', 'player_strip_pants') #done
		elif CPU_LOST_PRACTICE:
			# player is very far ahead
			updateResult = getResultForDialogue('P_STRIP_PANTS1', 'player_strip_pants') # done
		else:
			# player is way behind
			updateResult = getResultForDialogue('P_STRIP_PANTS4', 'player_strip_pants') # done linked to 1

	elif _pokerInfo.playerLives == 0:
		if CPU_LOST_PANTS:
			# player is behind
			updateResult = getResultForDialogue('P_STRIP_ALL3', 'player_strip_all') # done
		elif CPU_LOST_SHIRT:
			# player is about even
			updateResult = getResultForDialogue('P_STRIP_ALL2', 'player_strip_all') # done
		elif CPU_LOST_PRACTICE:
			# player is very far ahead
			updateResult = getResultForDialogue('P_STRIP_ALL1', 'player_strip_all') # Done
		else:
			# player is way behind
			updateResult = getResultForDialogue('P_STRIP_ALL4', 'player_strip_all') # done linked to 1

	if updateResult.dialogueStartKey:
		return updateResult

	#var ambientDialogue = getAmbientDialogue(_pokerInfo)

	#if ambientDialogue.size() > 0:
	#	updateResult = getResultForDialogue(ambientDialogue[0], ambientDialogue[1])

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
