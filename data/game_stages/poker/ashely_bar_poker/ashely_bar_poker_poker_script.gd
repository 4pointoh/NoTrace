extends PokerScript

# Tracks which ambient dialogues have already been shown
static var alreadyActivatedDialogues = []

# Scene-specific narrative flag (tracks specific dialogue branch, not derivable from clothing state)
# This gets set when player loses pants while CPU has already lost shirt or more
static var PANTS_OFF_ALT = false


static func reset_tracking_vars():
	alreadyActivatedDialogues = []
	PANTS_OFF_ALT = false


static func evaluate_ambient_dialogue(_pokerInfo: PokerInfo) -> PokerUpdateActionResult:
	var updateResult = PokerUpdateActionResult.new()
	
	var ambientDialogue = getAmbientDialogue(_pokerInfo)
	
	if ambientDialogue.size() > 0:
		updateResult = getResultForDialogue(ambientDialogue[0], ambientDialogue[1])
	
	return updateResult


static func getAmbientDialogue(_pokerInfo: PokerInfo) -> Array:
	var ambient_talks = []

	# Early game dialogues
	if !hasSeen('player_losing_early'):
		if _pokerInfo.totalRounds < 5 and _pokerInfo.cpuLifeAdvantage > 2:
			# Player: I guess I'm losing early
			ambient_talks.append(['PLAYER_LOSING_EARLY', 'player_losing_early'])
	
	if !hasSeen('player_lost_first_hand'):
		if _pokerInfo.playerTotalWins == 0 and _pokerInfo.cpuTotalWins == 1:
			# Player: I guess I lost the first hand
			ambient_talks.append(['PLAYER_LOST_FIRST_HAND', 'player_lost_first_hand'])
	
	if !hasSeen('cpu_early_streak'):
		if _pokerInfo.cpuCurrentWinStreak > 3 and _pokerInfo.totalRounds < 8 and _pokerInfo.cpuLifeAdvantage > 2 and _pokerInfo.cpuTotalLosses < 3:
			# Ashe: I guess I'm on a winning streak
			ambient_talks.append(['CPU_EARLY_STREAK', 'cpu_early_streak'])

	if !hasSeen('early_close_game') and !hasSeen('player_losing_early') and !hasSeen('cpu_early_streak'):
		if _pokerInfo.totalRounds < 10 and _pokerInfo.totalRounds > 4 and _pokerInfo.playerLifeAdvantage < 2 and _pokerInfo.cpuLifeAdvantage < 2:
			# Player: This is a close game
			ambient_talks.append(['EARLY_CLOSE_GAME', 'early_close_game'])

	if !hasSeen('where_is_guy') and not _pokerInfo.cpuHasLost("SHIRT"):
		if _pokerInfo.totalRounds > 10 and _pokerInfo.cpuLifeAdvantage > 3:
			# Player: Nervously -- is that guy going to come back or what?
			ambient_talks.append(['WHERE_IS_GUY_NERVOUS', 'where_is_guy'])

	if !hasSeen('you_seem_cold'):
		if _pokerInfo.playerHasLost("SHIRT") and not _pokerInfo.cpuHasLost("SHIRT") and randf() < 0.2:
			# Ashe: You seem cold
			ambient_talks.append(['ASHE_SAYS_YOU_SEEM_COLD', 'you_seem_cold'])

	if !hasSeen('you_seem_cold_back') and hasSeen('you_seem_cold'):
		if _pokerInfo.cpuHasLost("SHIRT") and randf() < 0.5:
			# Player: You thought I was cold? How do you like it?
			ambient_talks.append(['YOU_SAY_YOU_SEEM_COLD_BACK', 'you_seem_cold_back'])

	if !hasSeen('both_players_in_underwear'):
		if _pokerInfo.playerHasLost("PANTS") and _pokerInfo.cpuHasLost("PANTS") and not _pokerInfo.cpuHasLost("BRA"):
			# Player: I guess we are both in our underwear now
			# Ashe: Don't act like your underpants are an equal sight to mine
			ambient_talks.append(['BOTH_PLAYERS_IN_UNDERWEAR', 'both_players_in_underwear'])
	
	if !hasSeen('cpu_compliment') and !hasSeen('cpu_compliment_naked'):
		if _pokerInfo.playerHasLost("SHIRT") and randf() < 0.2:
			# Ashe: I have to admit, you don't look half bad without a shirt
			ambient_talks.append(['CPU_COMPLIMENT', 'cpu_compliment'])

	if !hasSeen('player_compliment'):
		if _pokerInfo.cpuHasLost("PANTS") and randf() < 0.1:
			# Player: that's some fancy underwear... were you planning to show it off tonight?
			ambient_talks.append(['PLAYER_COMPLIMENT', 'player_compliment'])
	
	if !hasSeen('big_cpu_advantage'):
		if _pokerInfo.cpuLifeAdvantage > 9:
			# Ashe: You sure you dont want to quit? I'll barely have lost anything at this rate
			ambient_talks.append(['BIG_CPU_ADVANTAGE', 'big_cpu_advantage'])
	
	if !hasSeen('both_players_last_life'):
		if _pokerInfo.playerLives == 1 and _pokerInfo.cpuLives == 1:
			# Player: I guess we are both down to our last piece
			ambient_talks.append(['BOTH_PLAYERS_LAST_LIFE', 'both_players_last_life'])

	if !hasSeen('player_staring'):
		if _pokerInfo.cpuHasLost("BRA") and randf() < 0.2:
			# Player: I can't help but stare
			ambient_talks.append(['PLAYER_STARING_BRA', 'player_staring'])

	if !hasSeen('player_final_life') and !hasSeen('cpu_final_life') and !hasSeen('both_players_last_life'):
		if _pokerInfo.playerLives == 1 and not (_pokerInfo.playerLives == 1 and _pokerInfo.cpuLives == 1):
			# Player: I guess this is my last life
			ambient_talks.append(['PLAYER_FINAL_LIFE', 'player_final_life'])

	if !hasSeen('long_match'):
		if _pokerInfo.totalRounds > 30 and _pokerInfo.playerLifeAdvantage < 2 and _pokerInfo.cpuLifeAdvantage < 2:
			# Player: This is a long match and it's still close
			ambient_talks.append(['LONG_MATCH', 'long_match'])
	
	if !hasSeen('guy_knocks'):
		if _pokerInfo.totalRounds > 20 and _pokerInfo.cpuHasLost("SHIRT"):
			# Player: is that guy knocking on the door?
			ambient_talks.append(['GUY_KNOCKS', 'guy_knocks'])

	if !hasSeen('cpu_accuses_player_of_letting_win'):
		if _pokerInfo.cpuLifeAdvantage > 15:
			# Ashe: You know, I think you're letting me win because you think you'll get some action when you're naked
			ambient_talks.append(['CPU_ACCUSE_LETTING_WIN', 'cpu_accuses_player_of_letting_win'])

	if !hasSeen('player_excuses'):
		if PANTS_OFF_ALT and _pokerInfo.playerHasLost("PANTS") and randf() < 0.2:
			# Ashely: So you really werent hard?
			ambient_talks.append(['REALLY_WERENT_HARD', 'player_excuses'])

	if !hasSeen('player_poker_strategy'):
		if _pokerInfo.cpuCurrentWinStreak > 5 and _pokerInfo.cpuLifeAdvantage > 5:
			# Player: You know, on that hand, you should have <something> 
			# Ashe: You're giving me poker advice? you realize im destroying you right?
			ambient_talks.append(['PLAYER_POKER_STRATEGY', 'player_poker_strategy'])

	if !hasSeen('player_blame_lighting'):
		if _pokerInfo.playerHasLost("PANTS") and randf() < 0.5:
			# Player: I think the lighting is making me look pale
			# Ashe: Yes, it's definitely the lighting making you look like uncooked pizza dough
			ambient_talks.append(['PLAYER_BLAME_LIGHTING', 'player_blame_lighting'])

	ambient_talks.shuffle()
	if ambient_talks.size() > 0:
		return ambient_talks[0]
	else:
		return []


static func getResultForDialogue(dialogueKey: String, altKey: String = '') -> PokerUpdateActionResult:
	var updateResult = PokerUpdateActionResult.new()

	if alreadyActivatedDialogues.has(dialogueKey) or alreadyActivatedDialogues.has(altKey):
		return updateResult
	
	updateResult.dialogueStartKey = dialogueKey
	updateResult.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
	updateResult.shouldPausePoker = true
	updateResult.shouldHidePoker = true
	updateResult.restoreImageOnCompletion = true

	alreadyActivatedDialogues.append(dialogueKey)
	
	if altKey != '':
		alreadyActivatedDialogues.append(altKey)
	
	return updateResult


static func hasSeen(dialogueKey: String) -> bool:
	return alreadyActivatedDialogues.has(dialogueKey)
