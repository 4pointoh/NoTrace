extends Node2D


var deck: Deck = Deck.new()
var isPlayerTurn: bool = true
var playerCards = []
var cpuCards = []
var cpuIndexesToDiscard

# Lives state
var playerLives: int
var cpuLives: int
var maxPlayerLives: int
var maxCpuLives: int
var startingPlayerLivesLost: int = 0
var startingCpuLivesLost: int = 0
var isAlternateStart: bool = false
var altStartData : PokerNodeData = null

var opponentName: String
var opponentNamePlural: String
var currentStage: PokerEnums.PokerStageFiveCardDraw
var nextPokerAction
var dialoguePause: bool = false
var cheatsLeft: int

var mostRecentKeyEventRowId: String

var animationsOn : bool = true

# New CSV-based poker system
var _csv_evaluator: PokerCSVEventEvaluator = null
var _lastRoundPlayerLost: bool = false

# State tracking for ambient dialogues
var _totalRounds: int = 0
var _playerTotalLosses: int = 0
var _cpuTotalLosses: int = 0
var _playerTotalWins: int = 0
var _cpuTotalWins: int = 0
var _playerLossesInARow: int = 0
var _cpuLossesInARow: int = 0
var _playerCurrentWinStreak: int = 0
var _cpuCurrentWinStreak: int = 0
var _playerHighestWinStreak: int = 0
var _cpuHighestWinStreak: int = 0
var _playerMostRecentLossStreak: int = 0
var _cpuMostRecentLossStreak: int = 0
var _highestPlayerLifeAdvantage: int = 0
var _highestCpuLifeAdvantage: int = 0
var _playerItemsLost: Array[String] = []
var _cpuItemsLost: Array[String] = []
var _playerMostRecentlyLostItem: String = "NOTHING"
var _cpuMostRecentlyLostItem: String = "NOTHING"

signal gamePaused
signal gameWon
signal gameLost
signal showTimeline(mostRecentKeyEventRowId : String)


func _ready():
	_initializeGameState()
	_initializePokerEventSystem()
	_connectSignals()


func setup():
	_initializeGameState()
	_resetPokerEventSystem()
	setCheats(0)
	_updateSkipVisibility()


func _initializeGameState():
	deck = Deck.new()
	isPlayerTurn = true
	dialoguePause = false
	opponentName = GlobalGameStage.currentStage.opponentName
	opponentNamePlural = GlobalGameStage.currentStage.opponentName
	currentStage = PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START
	
	_initializeLives()
	_resetStateTracking()


func _resetStateTracking():
	_totalRounds = 0
	_playerTotalLosses = 0
	_cpuTotalLosses = 0
	_playerTotalWins = 0
	_cpuTotalWins = 0
	_playerLossesInARow = 0
	_cpuLossesInARow = 0
	_playerCurrentWinStreak = 0
	_cpuCurrentWinStreak = 0
	_playerHighestWinStreak = 0
	_cpuHighestWinStreak = 0
	_playerMostRecentLossStreak = 0
	_cpuMostRecentLossStreak = 0
	_highestPlayerLifeAdvantage = 0
	_highestCpuLifeAdvantage = 0
	_playerItemsLost = []
	_cpuItemsLost = []
	_playerMostRecentlyLostItem = "NOTHING"
	_cpuMostRecentlyLostItem = "NOTHING"
	_lastRoundPlayerLost = false


func _initializeLives():
	maxPlayerLives = GlobalGameStage.currentStage.playerLives
	maxCpuLives = GlobalGameStage.currentStage.cpuLives
	isAlternateStart = GlobalGameStage.isStartingPokerFromNode
	
	if isAlternateStart:
		altStartData = GlobalGameStage.altStartSceneData
		playerLives = GlobalGameStage.altStartPlayerLives
		cpuLives = GlobalGameStage.altStartOppLives
		currentStage = PokerEnums.PokerStageFiveCardDraw.ALTERNATE_START_INITIAL_DIALOGUE
		startingPlayerLivesLost = maxPlayerLives - playerLives
		startingCpuLivesLost = maxCpuLives - cpuLives
		%AltStart.show()
		%Start.hide()
		%StripDesciption.text = getAltStartDescription()
		%AltStartLabel.text = 'Alt Start | Opp Lives: %d/%d | Player Lives: %d/%d' % [cpuLives, maxCpuLives, playerLives, maxPlayerLives]
	else:
		%AltStartInfo.hide()
		%AltStart.hide()
		%Start.show()
		altStartData = null
		playerLives = maxPlayerLives
		cpuLives = maxCpuLives
		startingPlayerLivesLost = 0
		startingCpuLivesLost = 0


func _initializePokerEventSystem():
	if GlobalGameStage.currentStage.useNewPokerSystem:
		_csv_evaluator = PokerCSVEventEvaluator.new()
		_csv_evaluator.initialize(
			GlobalGameStage.currentStage.pokerConfigJsonPath,
			GlobalGameStage.currentStage.pokerCSVPath,
			altStartData
		)
	else:
		GlobalGameStage.currentStage.pokerScript.reset_tracking_vars()


func _resetPokerEventSystem():
	if GlobalGameStage.currentStage.useNewPokerSystem:
		if _csv_evaluator:
			_csv_evaluator.reset()
		else:
			_initializePokerEventSystem()
		# Also reset script tracking vars if a fallback script exists
		if GlobalGameStage.currentStage.pokerScript:
			GlobalGameStage.currentStage.pokerScript.reset_tracking_vars()
	elif GlobalGameStage.currentStage.pokerScript:
		GlobalGameStage.currentStage.pokerScript.reset_tracking_vars()


func _connectSignals():
	%PokerDisplay.stageComplete.connect(processStageComplete)
	%PokerDisplay.discardPressed.connect(processDiscardPressed)
	%PokerDisplay.startPressed.connect(processStartPressed)
	%PokerDisplay.gameComplete.connect(endMatch)
	%PokerDisplay.cheatPressed.connect(cheat)


func _updateSkipVisibility():
	%Skip.visible = GlobalGameStage.hasCompletedCurrentStageGlobally()

func processStageComplete():
	var shouldEnd = false

	if(currentStage == PokerEnums.PokerStageFiveCardDraw.ALTERNATE_START_INITIAL_DIALOGUE):
		currentStage = PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START):
		currentStage = PokerEnums.PokerStageFiveCardDraw.PRE_ROUND_START
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.PRE_ROUND_START):
		currentStage = PokerEnums.PokerStageFiveCardDraw.CLEAR_BOARD
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.CLEAR_BOARD):
		currentStage = PokerEnums.PokerStageFiveCardDraw.DEAL
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.DEAL):
		currentStage = PokerEnums.PokerStageFiveCardDraw.POST_DEAL
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_DEAL):
		currentStage = PokerEnums.PokerStageFiveCardDraw.DISCARD
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.DISCARD):
		currentStage = PokerEnums.PokerStageFiveCardDraw.POST_DISCARD
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_DISCARD):
		currentStage = PokerEnums.PokerStageFiveCardDraw.REDRAW
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.REDRAW):
		currentStage = PokerEnums.PokerStageFiveCardDraw.POST_REDRAW
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_REDRAW):
		currentStage = PokerEnums.PokerStageFiveCardDraw.REVEAL
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.REVEAL):
		currentStage = PokerEnums.PokerStageFiveCardDraw.POST_REVEAL
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_REVEAL):
		currentStage = PokerEnums.PokerStageFiveCardDraw.EVALUATE_WINNER
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.EVALUATE_WINNER):
		currentStage = PokerEnums.PokerStageFiveCardDraw.ROUND_COMPLETE
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.ROUND_COMPLETE):
		nextPokerAction = getCurrentEvent()
		if(eventIsStartDialogue(nextPokerAction)):
			currentStage = PokerEnums.PokerStageFiveCardDraw.DIALOGUE_PAUSE
			startDialogue()
		elif(playerLives <= 0 or cpuLives <= 0):
			currentStage = PokerEnums.PokerStageFiveCardDraw.GAME_COMPLETE
		else:
			currentStage = PokerEnums.PokerStageFiveCardDraw.PRE_ROUND_START
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.DIALOGUE_PAUSE):
		if(playerLives <= 0 or cpuLives <= 0):
			currentStage = PokerEnums.PokerStageFiveCardDraw.GAME_COMPLETE
		else:
			currentStage = PokerEnums.PokerStageFiveCardDraw.PRE_ROUND_START
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.GAME_COMPLETE):
		shouldEnd = true
	
	if(!shouldEnd):
		processCurrentStage()
	else:
		endMatch()


func processCurrentStage():
	print('Processing stage: ' + str(currentStage))
	print('Player Card: ' + str(playerCards.map(func(card): return card.value + ' of ' + card.suit)))
	print('CPU Card: ' + str(cpuCards.map(func(card): return card.value + ' of ' + card.suit)))

	if(currentStage == PokerEnums.PokerStageFiveCardDraw.ALTERNATE_START_INITIAL_DIALOGUE):
		processAltStartInitialDialogue()
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START):
		processPreGameStart();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.PRE_ROUND_START):
		processPreRoundStart();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.CLEAR_BOARD):
		processClearBoard();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.DEAL):
		processDeal();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_DEAL):
		processPostDeal();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.DISCARD):
		processDiscard();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_DISCARD):
		processPostDiscard();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.REDRAW):
		processRedraw();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_REDRAW):
		processPostRedraw();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.REVEAL):
		processReveal();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.POST_REVEAL):
		processPostReveal();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.EVALUATE_WINNER):
		processEvaluateWinner();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.ROUND_COMPLETE):
		processRoundComplete();
	elif(currentStage == PokerEnums.PokerStageFiveCardDraw.GAME_COMPLETE):
		processGameComplete();
		

func _on_alt_start_pressed() -> void:
	%Start.show()
	%AltStartInfo.show()
	%AltStart.hide()

func processStartPressed():
	%Skip.hide()
	%AltStartInfo.hide()
	%DisableAnimButton.show()
	
	if GlobalGameStage.hasCompletedCurrentStage():
		%GraphViewButton.show()
	
	processCurrentStage()

func processAltStartInitialDialogue():
	var dialogueAction = PokerUpdateActionResult.new()
	dialogueAction.dialogueStartKey = altStartData.dialogue_key
	dialogueAction.nodeId = altStartData.row_id
	mostRecentKeyEventRowId = altStartData.row_id
	dialogueAction.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
	dialogueAction.shouldPausePoker = true
	dialogueAction.shouldHidePoker = true
	nextPokerAction = dialogueAction
	startDialogue()

func processPreGameStart():
	%PokerDisplay.processPreGameStart(maxPlayerLives, maxCpuLives, startingPlayerLivesLost, startingCpuLivesLost)

func processPreRoundStart():
	%PokerDisplay.processPreRoundStart()

func processClearBoard():
	playerCards = []
	cpuCards = []
	%PokerDisplay.processClearBoard()

func processDeal():
	playerCards = deck.deal(5)
	cpuCards = deck.deal(5)
	%PokerDisplay.processDeal(playerCards, cpuCards)

func processPostDeal():
	%PokerDisplay.processPostDeal()

func processDiscard():
	cpuIndexesToDiscard = PokerEval.calculate_cpu_discard_indexes(cpuCards, GlobalGameStage.currentStage.cpuRandomDiscardChance)
	%PokerDisplay.processDiscard(cpuIndexesToDiscard)

func processDiscardPressed(cardsToDiscard):
	# Sort indexes in descending order to avoid shifting issues
	cardsToDiscard.sort_custom(func(a, b): return a > b)

	# Discard the selected cards from highest index to lowest
	for cardIndex in cardsToDiscard:
		playerCards.remove_at(cardIndex)

	# Now do CPU discards
	cpuIndexesToDiscard.sort_custom(func(a, b): return a > b)
	for cardIndex in cpuIndexesToDiscard:
		cpuCards.remove_at(cardIndex)

func processPostDiscard():
	%PokerDisplay.processPostDiscard(playerCards, cpuCards)

func processRedraw():
	if(playerCards.size() < 5):
		var cardsNeeded = 5 - playerCards.size()
		playerCards.append_array(deck.deal(cardsNeeded))
	
	if(cpuCards.size() < 5):
		var cardsNeeded = 5 - cpuCards.size()
		cpuCards.append_array(deck.deal(cardsNeeded))

	%PokerDisplay.processRedraw(playerCards, cpuCards)

func processPostRedraw():
	%PokerDisplay.processPostRedraw()

func processReveal():
	%PokerDisplay.processReveal(cheatsLeft > 0, cheatsLeft)

func processPostReveal():
	%PokerDisplay.processPostReveal()

func processEvaluateWinner():
	var playerWins = true

	var winner = PokerEval.getWinnersFromCardLists(playerCards, cpuCards, [])
	var winningHand = str(winner[1])
	var losingHand = str(winner[2])

	var winningHandDescription = winner[3]
	var losingHandDescription = winner[4]

	if winner[0] == "Hand 1 wins":
		playerWins = true
		cpuLives -= 1
		_lastRoundPlayerLost = false
		print('Player Wins with ' + winningHand)
	else:
		playerWins = false
		playerLives -= 1
		_lastRoundPlayerLost = true
		print('CPU Wins with ' + winningHand)
	
	print('Other player had ' + losingHand)
	
	# Update state tracking after the round
	_updateStateTracking(playerWins)

	var playerHandResult
	var cpuHandResult
	if(playerWins):
		playerHandResult = winningHandDescription
		cpuHandResult = losingHandDescription
	else:
		playerHandResult = losingHandDescription
		cpuHandResult = winningHandDescription

	%PokerDisplay.processEvaluateWinner(playerWins, playerHandResult, cpuHandResult)


func _updateStateTracking(playerWins: bool):
	_totalRounds += 1
	
	if playerWins:
		# Player won this round
		_playerTotalWins += 1
		_cpuTotalLosses += 1
		_playerCurrentWinStreak += 1
		_cpuCurrentWinStreak = 0
		_playerLossesInARow = 0
		_cpuLossesInARow += 1
	else:
		# CPU won this round
		_cpuTotalWins += 1
		_playerTotalLosses += 1
		_cpuCurrentWinStreak += 1
		_playerCurrentWinStreak = 0
		_cpuLossesInARow = 0
		_playerLossesInARow += 1
	
	# Update highest win streaks
	if _playerCurrentWinStreak > _playerHighestWinStreak:
		_playerHighestWinStreak = _playerCurrentWinStreak
	if _cpuCurrentWinStreak > _cpuHighestWinStreak:
		_cpuHighestWinStreak = _cpuCurrentWinStreak
	
	# Update most recent loss streaks (when streak > 2)
	if _playerLossesInARow > 2:
		_playerMostRecentLossStreak = _playerLossesInARow
	if _cpuLossesInARow > 2:
		_cpuMostRecentLossStreak = _cpuLossesInARow
	
	# Update life advantage tracking
	var playerLifeAdvantage = playerLives - cpuLives
	var cpuLifeAdvantage = cpuLives - playerLives
	
	if playerLifeAdvantage > _highestPlayerLifeAdvantage:
		_highestPlayerLifeAdvantage = playerLifeAdvantage
	if cpuLifeAdvantage > _highestCpuLifeAdvantage:
		_highestCpuLifeAdvantage = cpuLifeAdvantage

func processRoundComplete():
	%PokerDisplay.processRoundComplete()

func processGameComplete():
	%PokerDisplay.processGameComplete()

func endMatch():
	if(playerLives <= 0):
		GlobalGameStage.addLossToPokerStageHistory()
		gameLost.emit()
	else:
		GlobalGameStage.addWinToPokerStageHistory()
		gameWon.emit()
	
	isAlternateStart = false
	GlobalGameStage.isStartingPokerFromNode = false
	GlobalGameStage.altStartPlayerLives = 0
	GlobalGameStage.altStartOppLives = 0
	
	print(GlobalGameStage.pokerStageHistory)

func eventIsStartDialogue(actionResult):
	if(actionResult.actionResult == PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE):
		return true
	else:
		return false

func getCurrentEvent():
	var pokerInfo = _buildPokerInfo()

	# Use the new CSV system if enabled, otherwise use the old script system
	var updateResult: PokerUpdateActionResult
	if GlobalGameStage.currentStage.useNewPokerSystem and _csv_evaluator:
		updateResult = _csv_evaluator.evaluate(pokerInfo)

		if updateResult.nodeId != null:
			mostRecentKeyEventRowId = updateResult.nodeId
		
		# Fallback to script for ambient dialogues if CSV returned no event
		if _isNoEvent(updateResult) and GlobalGameStage.currentStage.pokerScript:
				updateResult = GlobalGameStage.currentStage.pokerScript.evaluate_ambient_dialogue(pokerInfo)
	else:
		updateResult = GlobalGameStage.currentStage.pokerScript.evaluate_poker_game(pokerInfo)

	return updateResult


func _buildPokerInfo() -> PokerInfo:
	var info = PokerInfo.new()
	
	# Core state
	info.playerLives = playerLives
	info.cpuLives = cpuLives
	info.maxPlayerLives = maxPlayerLives
	info.maxCpuLives = maxCpuLives
	info.playerLost = _lastRoundPlayerLost
	
	# Round tracking
	info.totalRounds = _totalRounds
	
	# Loss/win counts
	info.playerTotalLosses = _playerTotalLosses
	info.cpuTotalLosses = _cpuTotalLosses
	info.playerTotalWins = _playerTotalWins
	info.cpuTotalWins = _cpuTotalWins
	
	# Streak tracking
	info.playerLossesInARow = _playerLossesInARow
	info.cpuLossesInARow = _cpuLossesInARow
	info.playerCurrentWinStreak = _playerCurrentWinStreak
	info.cpuCurrentWinStreak = _cpuCurrentWinStreak
	info.playerHighestWinStreak = _playerHighestWinStreak
	info.cpuHighestWinStreak = _cpuHighestWinStreak
	info.playerMostRecentLossStreak = _playerMostRecentLossStreak
	info.cpuMostRecentLossStreak = _cpuMostRecentLossStreak
	
	# Life advantage tracking
	info.playerLifeAdvantage = playerLives - cpuLives
	info.cpuLifeAdvantage = cpuLives - playerLives
	info.highestPlayerLifeAdvantage = _highestPlayerLifeAdvantage
	info.highestCpuLifeAdvantage = _highestCpuLifeAdvantage
	
	# Clothing state - get from CSV evaluator if available for accurate item names
	if _csv_evaluator:
		info.playerItemsLost = _csv_evaluator.getPlayerItemsLost()
		info.cpuItemsLost = _csv_evaluator.getOpponentItemsLost()
		if info.playerItemsLost.size() > 0:
			info.playerMostRecentlyLostItem = info.playerItemsLost[-1]
		if info.cpuItemsLost.size() > 0:
			info.cpuMostRecentlyLostItem = info.cpuItemsLost[-1]
	else:
		info.playerItemsLost = _playerItemsLost.duplicate()
		info.cpuItemsLost = _cpuItemsLost.duplicate()
		info.playerMostRecentlyLostItem = _playerMostRecentlyLostItem
		info.cpuMostRecentlyLostItem = _cpuMostRecentlyLostItem
	
	return info


func _isNoEvent(result: PokerUpdateActionResult) -> bool:
	if result.actionResult != PokerUpdateActionResult.ACTION_RESULTS.NOTHING:
		return false
	if result.dialogueStartKey != null and not result.dialogueStartKey.is_empty():
		return false
	return true

func startDialogue():
	dialoguePause = true
	gamePaused.emit()

func removeDialoguePause():
	dialoguePause = false
	processStageComplete()

func _on_button_pressed():
	gameWon.emit()

func cheat():
	cheatsLeft -= 1

	playerCards = []

	for i in range(5):
		if i == 0:
			var newAce = NonUiCard.new()
			newAce.value = "A"
			newAce.suit = "spades"
			playerCards.append(newAce)
		
		if i == 1:
			var newAce = NonUiCard.new()
			newAce.value = "A"
			newAce.suit = "hearts"
			playerCards.append(newAce)
		
		if i == 2:
			var newAce = NonUiCard.new()
			newAce.value = "A"
			newAce.suit = "clubs"
			playerCards.append(newAce)
		
		if i == 3:
			var newAce = NonUiCard.new()
			newAce.value = "A"
			newAce.suit = "diamonds"
			playerCards.append(newAce)
		
		if i == 4:
			var newAce = NonUiCard.new()
			newAce.value = "K"
			newAce.suit = "hearts"
			playerCards.append(newAce)
		
	
	#Remove cards at the beginning of the player hand until they have 5 cards
	while playerCards.size() > 5:
		playerCards.remove_at(0)

	%PokerDisplay.displayCheat(playerCards)


func _on_poker_mode_select_selected_mode(mode: int) -> void:
	setCheats(mode)

func setCheats(mode: int):
	if mode == 0:
		cheatsLeft = GlobalGameStage.currentStage.cheatCount
	elif mode == 1:
		cheatsLeft = GlobalGameStage.currentStage.proPlusCheats
	elif mode == 2:
		cheatsLeft = GlobalGameStage.currentStage.proPlusMaxCheats

func getAltStartDescription():
	var target = ""
	var target_pronoun = ""
	var target_item = altStartData.event_item
	var full_text = ""

	if GlobalGameStage.currentStage.isStripPoker:
		if altStartData.is_opponent_strip:
			target = altStartData.stripper_id
			target_pronoun = "her"
		else:
			target = "YOU"
			target_pronoun = "your"
		full_text = target + ' ' + 'will strip' + ' ' + target_pronoun + ' ' + target_item
	else:
		if altStartData.is_opponent_strip:
			target = altStartData.stripper_id
			target_pronoun = "has"
		else:
			target = "YOU"
			target_pronoun = "have"
		full_text = target + ' ' + target_pronoun + ' just lost' + ' ' + target_item
	
	return full_text


func _on_disable_anim_button_mouse_entered() -> void:
	%ButtonDescription.text = 'Toggle Animations'
	%ButtonDescription.show()


func _on_graph_view_button_mouse_entered() -> void:
	%ButtonDescription.text = 'View Timeline'
	%ButtonDescription.show()


func _on_graph_view_button_mouse_exited() -> void:
	%ButtonDescription.hide()


func _on_disable_anim_button_mouse_exited() -> void:
	%ButtonDescription.hide()


func _on_disable_anim_button_pressed() -> void:
	animationsOn = !animationsOn
	if animationsOn:
		%DisableAnimLabel.text = 'Anim.\nOn'
	else:
		%DisableAnimLabel.text = 'Anim.\nOff'

func _on_graph_view_button_pressed() -> void:
	showTimeline.emit(mostRecentKeyEventRowId)
