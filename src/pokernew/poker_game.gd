extends Node2D


var deck : Deck = Deck.new()
var isPlayerTurn : bool = true
var playerCards = []
var cpuCards = []
var cpuIndexesToDiscard
var playerLives
var cpuLives
var opponentName = GlobalGameStage.currentStage.opponentName
var opponentNamePlural = GlobalGameStage.currentStage.opponentName
var currentStage : PokerEnums.PokerStageFiveCardDraw
var nextPokerAction
var dialoguePause = false

signal gamePaused
signal gameWon
signal gameLost

func _ready():
	deck = Deck.new()
	isPlayerTurn = true
	dialoguePause = false
	opponentName = GlobalGameStage.currentStage.opponentName
	opponentNamePlural = GlobalGameStage.currentStage.opponentName
	playerLives = GlobalGameStage.currentStage.playerLives
	cpuLives = GlobalGameStage.currentStage.cpuLives

	GlobalGameStage.currentStage.pokerScript.reset_tracking_vars()

	currentStage = PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START
	%PokerDisplay.stageComplete.connect(processStageComplete)
	%PokerDisplay.discardPressed.connect(processDiscardPressed)
	%PokerDisplay.startPressed.connect(processStartPressed)
	%PokerDisplay.gameComplete.connect(endMatch)


func setup():
	deck = Deck.new()
	isPlayerTurn = true
	dialoguePause = false
	opponentName = GlobalGameStage.currentStage.opponentName
	opponentNamePlural = GlobalGameStage.currentStage.opponentName
	playerLives = GlobalGameStage.currentStage.playerLives
	cpuLives = GlobalGameStage.currentStage.cpuLives

func processStageComplete():
	var shouldEnd = false

	if(currentStage == PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START):
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

	if(currentStage == PokerEnums.PokerStageFiveCardDraw.PRE_GAME_START):
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

func processStartPressed():
	processCurrentStage()

func processPreGameStart():
	%PokerDisplay.processPreGameStart()

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
	%PokerDisplay.processReveal()

func processPostReveal():
	%PokerDisplay.processPostReveal()

func processEvaluateWinner():
	var playerWins = true

	var winner = PokerEval.getWinnersFromCardLists(playerCards, cpuCards, [])
	var winningHand = str(winner[1])
	var losingHand = str(winner[2])

	if winner[0] == "Hand 1 wins":
		playerWins = true
		cpuLives -= 1
		print('Player Wins with ' + winningHand)
	else:
		playerWins = false
		playerLives -= 1
		print('CPU Wins with ' + winningHand)
	
	print('Other player had ' + losingHand)

	var playerHandResult
	var cpuHandResult
	if(playerWins):
		playerHandResult = winningHand
		cpuHandResult = losingHand
	else:
		playerHandResult = losingHand
		cpuHandResult = winningHand

	%PokerDisplay.processEvaluateWinner(playerWins, playerHandResult, cpuHandResult)

func processRoundComplete():
	%PokerDisplay.processRoundComplete()

func processGameComplete():
	%PokerDisplay.processGameComplete()

func endMatch():
	if(playerLives <= 0):
		gameLost.emit()
	else:
		gameWon.emit()

func eventIsStartDialogue(actionResult):
	if(actionResult.actionResult == PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE):
		return true
	else:
		return false

func getCurrentEvent():
	var pokerInfo = PokerInfo.new()
	pokerInfo.playerLives = playerLives
	pokerInfo.cpuLives = cpuLives

	var updateResult = GlobalGameStage.currentStage.pokerScript.evaluate_poker_game(pokerInfo)

	return updateResult

func startDialogue():
	dialoguePause = true
	gamePaused.emit()

func removeDialoguePause():
	dialoguePause = false
	processStageComplete()
