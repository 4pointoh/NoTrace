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

		if PLAYER_LOST_UNDERWEAR or PLAYER_LOST_PANTS or PLAYER_LOST_SHIRT:
			# She is very far ahead
			updateResult = getResultForDialogue('ASHE_STRIP_SHIRT_EVEN', 'strip_shirt')
		else:
			# She is behind, player still has shirt
			updateResult = getResultForDialogue('ASHE_STRIP_SHIRT_BEHIND', 'strip_shirt')
		
	elif _pokerInfo.cpuLives == 7:
		cpuMostRecentlyLostItem = 'PANTS'

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

		if PLAYER_LOST_UNDERWEAR or PLAYER_LOST_PANTS:
			# She is ahead / not far behind
			updateResult = getResultForDialogue('ASHE_STRIP_BRA_STILL_AHEAD', 'strip_bra')
		else:
			# She is far behind
			updateResult = getResultForDialogue('ASHE_STRIP_BRA_VERY_FAR_BEHIND', 'strip_bra')
		
	elif _pokerInfo.cpuLives == 0:
		if PLAYER_LOST_UNDERWEAR:
			# She barely lost
			updateResult = getResultForDialogue('ASHE_STRIP_ALL_EVEN', 'strip_all')
		elif PLAYER_LOST_SHIRT :
			# She lost by a lot
			updateResult = getResultForDialogue('ASHE_STRIP_ALL_BEHIND', 'strip_all')
		else:
			# Player didnt remove a single thing
			updateResult = getResultForDialogue('ASHE_STRIP_ALL_VERY_FAR_BEHIND', 'strip_all')

	
	if updateResult.dialogueStartKey:
		return updateResult
	
	shouldRestoreImageOnCompletion = true

	if _pokerInfo.playerLives == 14:
		playerMostRecentlyLostItem = 'SHIRT'

		if CPU_LOST_BRA:
			# player is very far ahead
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_VERY_FAR_AHEAD', 'player_strip_shirt')
		elif CPU_LOST_PANTS:
			# player is far ahead
			updateResult = getResultForDialogue('PLAYER_STRIP_SHIRT_FAR_AHEAD', 'player_strip_shirt')
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
		elif CPU_LOST_PANTS:
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_BRA', 'player_strip_pants')
		elif CPU_LOST_SHIRT:
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_PANTS', 'player_strip_pants')
		else:
			# player slips when sitting
			updateResult = getResultForDialogue('PLAYER_STRIP_PANTS_SLIP', 'player_strip_pants')
		
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
		elif CPU_LOST_PANTS or CPU_LOST_SHIRT:
			# player lost by a bit
			updateResult = getResultForDialogue('PLAYER_STRIP_ALL_NO_PANTS', 'player_strip_all')
		else:
			# player lost by a lot
			updateResult = getResultForDialogue('PLAYER_STRIP_ALL_SHIRT_ON', 'player_strip_all')

	if updateResult.dialogueStartKey:
		return updateResult

	var ambientDialogue = getAmbientDialogue(_pokerInfo)

	#if ambientDialogue.size() > 0:
		#updateResult = getResultForDialogue(ambientDialogue[0], ambientDialogue[1])

	return updateResult

static func getAmbientDialogue(_pokerInfo : PokerInfo) -> Array:
	var ambient_talks = []

	# NEED SOME DIALOGUES EARLY GAME THAT CAN trigger without too much long-form criteria

	if !hasSeen('where_is_guy') and !CPU_LOST_SHIRT:
		if totalRounds > 10 and cpuLifeAdvantage > 5 :
			# Player: Nervously -- is that guy going to come back or what?
			ambient_talks.append(['WHERE_IS_GUY_NERVOUS', 'where_is_guy'])
		elif totalRounds > 10:
			# Player: Is that guy going to come back or what?
			ambient_talks.append(['WHERE_IS_GUY', 'where_is_guy'])

	if !hasSeen('you_seem_cold'):
		if PLAYER_LOST_SHIRT and randf() < 0.2:
			# Ashe: You seem cold
			ambient_talks.append(['ASHE_SAYS_YOU_SEEM_COLD', 'you_seem_cold'])

	if !hasSeen('you_seem_cold_back') and hasSeen('you_seem_cold'):
		if CPU_LOST_SHIRT and randf() < 0.5:
			# Player: You thought I was cold? How do you like it?
			ambient_talks.append(['YOU_SAY_YOU_SEEM_COLD_BACK', 'you_seem_cold_back'])

	if !hasSeen('both_players_in_underwear'):
		if PLAYER_LOST_PANTS and CPU_LOST_PANTS:
			# Player: I guess we are both in our underwear now
			# Ashe: Don't act like your underpants are an equal sight to mine
			ambient_talks.append(['BOTH_PLAYERS_IN_UNDERWEAR', 'both_players_in_underwear'])

	if !hasSeen('player_strong_recovery'):
		if highestCpuLifeAdvantage > 10 and playerCurrentWinStreak > 7:
			if PLAYER_LOST_UNDERWEAR:
				# Player: I play best when im naked
				ambient_talks.append(['PLAYER_STRONG_RECOVERY_NAKED', 'player_strong_recovery'])
			else:
				# Player: You thought you had me, huh? 
				ambient_talks.append(['PLAYER_STRONG_RECOVERY', 'player_strong_recovery'])
	
	if !hasSeen('cpu_strong_recovery'):
		if highestPlayerLifeAdvantage > 10 and cpuCurrentWinStreak > 7 and cpuLifeAdvantage > 0:
			# Ashe: You were ahead before... what happened?
			ambient_talks.append(['CPU_STRONG_RECOVERY', 'cpu_strong_recovery'])

	if !hasSeen('player_recovery_shut_down') and hasSeen('player_strong_recovery'):
		if cpuCurrentWinStreak > 5:
			# that comeback you were bragging about earlier? sorry, but it was a fluke.
			ambient_talks.append(['PLAYER_RECOVERY_SHUT_DOWN', 'player_recovery_shut_down'])
	
	if !hasSeen('cpu_compliment'):
		if PLAYER_LOST_SHIRT and randf() < 0.5:
			# Ashe: I have to admit, you don't look half bad without a shirt
			ambient_talks.append(['CPU_COMPLIMENT', 'cpu_compliment'])

	if !hasSeen('cpu_compliment_naked'):
		if PLAYER_LOST_UNDERWEAR and randf() < 0.5:
			# Ashe: I have to admit, you don't look half bad naked
			ambient_talks.append(['CPU_COMPLIMENT_NAKED', 'cpu_compliment_naked'])

	if !hasSeen('player_compliment'):
		if CPU_LOST_SHIRT and randf() < 0.5:
			# Player: that's some fancy underwear... were you planning to show it off tonight?
			ambient_talks.append(['PLAYER_COMPLIMENT', 'player_compliment'])
	
	if !hasSeen('cpu_compliment'):
		if PLAYER_LOST_PANTS and randf() < 0.5:
			# Ashe: Where'd you get those? I need a pair.
			# or: Ashe: Did your mom pick those out or were they on clearance?"
			ambient_talks.append(['CPU_COMPLIMENT_BRA', 'cpu_compliment_bra'])
	
	if !hasSeen('player_compliment_braless'):
		if CPU_LOST_BRA and randf() < 0.5:
			# Player: you're looking a little underdressed there, Ashe
			# or: Player: You don't have to cover up, I promise I wont look
			ambient_talks.append(['PLAYER_COMPLIMENT_BRALESS', 'player_compliment_braless'])

	if !hasSeen('big_player_advantage'):
		if playerLifeAdvantage > 12:
			# Player: You sure you dont want to quit? I'll barely have lost anything at this rate
			ambient_talks.append(['BIG_PLAYER_ADVANTAGE', 'big_player_advantage'])
	
	if !hasSeen('big_cpu_advantage'):
		if cpuLifeAdvantage > 12:
			# Ashe: You sure you dont want to quit? I'll barely have lost anything at this rate
			ambient_talks.append(['BIG_CPU_ADVANTAGE', 'big_cpu_advantage'])
	
	if !hasSeen('both_players_last_life'):
		if _pokerInfo.playerLives == 1 and _pokerInfo.cpuLives == 1:
			# Player: I guess we are both down to our last piece
			ambient_talks.append(['BOTH_PLAYERS_LAST_LIFE', 'both_players_last_life'])

	if !hasSeen('player_staring'):
		if CPU_LOST_SHIRT and randf() < 0.5:
			# Player: I can't help but stare at your underwear
			ambient_talks.append(['PLAYER_STARING', 'player_staring'])
		elif CPU_LOST_BRA and randf() < 0.5:
			# Player: I can't help but stare at your bra
			ambient_talks.append(['PLAYER_STARING_BRA', 'player_staring'])


	if !hasSeen('player_catching_up'):
		if highestCpuLifeAdvantage > 7 and cpuLifeAdvantage < 1:
			# Player: I think I'm catching up to you
			ambient_talks.append(['PLAYER_CATCHING_UP', 'player_catching_up'])

	if !hasSeen('cpu_catching_up'):
		if highestPlayerLifeAdvantage > 7 and playerLifeAdvantage < 1:
			# Ashe: I think I'm catching up to you
			ambient_talks.append(['CPU_CATCHING_UP', 'cpu_catching_up'])

	if !hasSeen('cpu_winning_streak'):
		if cpuCurrentWinStreak > 10:
			# Ashe: I think I'm on a winning streak
			ambient_talks.append(['CPU_WINNING_STREAK', 'cpu_winning_streak'])
	
	if !hasSeen('player_winning_streak'):
		if playerCurrentWinStreak > 10:
			# Player: I think I'm on a winning streak
			ambient_talks.append(['PLAYER_WINNING_STREAK', 'player_winning_streak'])

	if !hasSeen('player_streak_ends'):
		if playerCurrentWinStreak == 0 and playerHighestWinStreak > 7:
			# Player: I think my streak just ended
			ambient_talks.append(['PLAYER_STREAK_ENDS', 'player_streak_ends'])

	if !hasSeen('cpu_streak_ends'):
		if cpuCurrentWinStreak == 0 and cpuHighestWinStreak > 7:
			# Ashe: I think my streak just ended
			ambient_talks.append(['CPU_STREAK_ENDS', 'cpu_streak_ends'])

	if !hasSeen('player_final_life') and !hasSeen('cpu_final_life') and !hasSeen('both_players_last_life'):
		if _pokerInfo.playerLives == 1:
			# Player: I guess this is my last life
			ambient_talks.append(['PLAYER_FINAL_LIFE', 'player_final_life'])
	
	if !hasSeen('cpu_final_life') and !hasSeen('player_final_life') and !hasSeen('both_players_last_life'):
		if _pokerInfo.cpuLives == 1:
			# Ashe: I guess this is my last life
			ambient_talks.append(['CPU_FINAL_LIFE', 'cpu_final_life'])

	if !hasSeen('long_match'):
		if totalRounds > 30 and playerLifeAdvantage < 2 and cpuLifeAdvantage < 2:
			# Player: This is a long match and it's still close -- *** do something special fo this one
			ambient_talks.append(['LONG_MATCH', 'long_match'])
	
	if !hasSeen('guy_knocks'):
		if totalRounds > 20:
			# Player: is that guy knocking on the door?
			ambient_talks.append(['GUY_KNOCKS', 'guy_knocks'])

	if !hasSeen('cpu_accuses_player_of_letting_win'):
		if cpuLifeAdvantage > 15:
			# Ashe: You know, I think you're letting me win because you think you'll get some action when you're naked
			ambient_talks.append(['CPU_ACCUSE_LETTING_WIN', 'cpu_accuses_player_of_letting_win'])

	if !hasSeen('blush_comment'):
		if CPU_LOST_BRA and randf() < 0.5:
			# Player: You don't seem to be blushing
			ambient_talks.append(['BLUSH_COMMENT', 'blush_comment'])

	if !hasSeen('player_excuses'):
		if PLAYER_LOST_UNDERWEAR and randf() < 0.2:
			# Player: I think the cold is affecting certain... dimensions
			ambient_talks.append(['PLAYER_EXCUSES', 'player_excuses'])

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
