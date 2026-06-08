extends PokerScript
## Poker Script Template for CSV-Migrated Scenes
##
## This script handles AMBIENT DIALOGUES only. Core strip events are handled by the CSV system.
## 
## Available PokerInfo properties for ambient dialogue conditions:
##   - _pokerInfo.totalRounds: int - Total rounds played
##   - _pokerInfo.playerLives / cpuLives: int - Current lives
##   - _pokerInfo.maxPlayerLives / maxCpuLives: int - Starting lives
##   - _pokerInfo.playerLifeAdvantage / cpuLifeAdvantage: int - Current life difference
##   - _pokerInfo.highestPlayerLifeAdvantage / highestCpuLifeAdvantage: int - Historical max
##   - _pokerInfo.playerTotalWins / cpuTotalWins: int - Total wins this game
##   - _pokerInfo.playerTotalLosses / cpuTotalLosses: int - Total losses this game
##   - _pokerInfo.playerCurrentWinStreak / cpuCurrentWinStreak: int - Current streak
##   - _pokerInfo.playerHighestWinStreak / cpuHighestWinStreak: int - Best streak this game
##   - _pokerInfo.playerLossesInARow / cpuLossesInARow: int - Current loss streak
##   - _pokerInfo.playerHasLost("ITEM"): bool - Check if player lost specific item (e.g., "SHIRT", "PANTS")
##   - _pokerInfo.cpuHasLost("ITEM"): bool - Check if CPU lost specific item
##   - _pokerInfo.playerItemsLost: Array[String] - List of items player has lost
##   - _pokerInfo.cpuItemsLost: Array[String] - List of items CPU has lost


# Tracks which ambient dialogues have already been shown this game
static var alreadyActivatedDialogues = []

# Add any scene-specific narrative flags here (flags that can't be derived from clothing state)
# Example: static var SPECIAL_DIALOGUE_BRANCH = false


static func reset_tracking_vars():
	alreadyActivatedDialogues = []
	# Reset any scene-specific flags here


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


static func getResultForDialogue(dialogueKey: String, altKey: String = '') -> PokerUpdateActionResult:
	## Creates a PokerUpdateActionResult for a dialogue trigger.
	## dialogueKey: The dialogue node key to start
	## altKey: Alternative key to track (prevents both from triggering)
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
	## Check if a dialogue has already been triggered this game.
	return alreadyActivatedDialogues.has(dialogueKey)
