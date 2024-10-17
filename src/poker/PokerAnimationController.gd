extends Control
class_name PokerAnimationController

signal animation_complete

@export var cardScene : PackedScene

var playerUiCards = []
var cpuUiCards = []
var boardUiCards = []

var cardDrawDelay = .2

func teardown():
	playerUiCards = []
	cpuUiCards = []
	boardUiCards = []

func processAnimations(pokerStage, playerCards = null, cpuCards = null, tableCards = null, message = null):
	match pokerStage:
		PokerEnums.PokerStage.PRE_GAME_START:
			pass
		PokerEnums.PokerStage.CLEAR_BOARD:
			processClearBoardAnimation()
		PokerEnums.PokerStage.ANTE:
			pass
		PokerEnums.PokerStage.DEAL:
			processDealAnimation(playerCards, cpuCards)
		PokerEnums.PokerStage.POST_DEAL:
			pass
		PokerEnums.PokerStage.POST_DEAL_BETTING:
			processDealBetAnimation(message)
		PokerEnums.PokerStage.PRE_FLOP:
			pass
		PokerEnums.PokerStage.FLOP:
			processFlopAnimation(tableCards)
		PokerEnums.PokerStage.POST_FLOP:
			pass
		PokerEnums.PokerStage.FLOP:
			pass
		PokerEnums.PokerStage.FLOP_BETTING:
			processFlopBetAnimation(message)
		PokerEnums.PokerStage.PRE_TURN:
			pass
		PokerEnums.PokerStage.TURN:
			processTurnAnimation(tableCards)
		PokerEnums.PokerStage.POST_TURN:
			pass
		PokerEnums.PokerStage.TURN_BETTING:
			processTurnBetAnimation(message)
		PokerEnums.PokerStage.PRE_RIVER:
			pass
		PokerEnums.PokerStage.RIVER:
			processRiverAnimation(tableCards)
		PokerEnums.PokerStage.POST_RIVER:
			pass
		PokerEnums.PokerStage.EVALUATE_WINNER:
			processEvaluateWinnerAnimation(message)
		PokerEnums.PokerStage.ROUND_COMPLETE:
			pass
		PokerEnums.PokerStage.GAME_COMPLETE:
			pass

func processClearBoardAnimation():
	for card in getAllCards():
		card.free()
	
	playerUiCards = []
	cpuUiCards = []
	boardUiCards = []
	animationsComplete()

func processDealAnimation(playerCards : Array[NonUiCard], cpuCards : Array[NonUiCard]):
	var cardOnePlayer = cardScene.instantiate()
	var cardTwoPlayer = cardScene.instantiate()
	var cardOneCpu = cardScene.instantiate()
	var cardTwoCpu = cardScene.instantiate()
	
	cardOnePlayer.nonUiCard = playerCards[0]
	cardTwoPlayer.nonUiCard = playerCards[1]
	cardOneCpu.nonUiCard = cpuCards[0]
	cardTwoCpu.nonUiCard = cpuCards[1]
	
	playerUiCards.append(cardOnePlayer)
	playerUiCards.append(cardTwoPlayer)
	cpuUiCards.append(cardOneCpu)
	cpuUiCards.append(cardTwoCpu)
	
	$PlayerHand.add_child(cardOnePlayer)
	$PlayerHand.add_child(cardTwoPlayer)
	$CpuHand.add_child(cardOneCpu)
	$CpuHand.add_child(cardTwoCpu)
	
	cardOnePlayer.flip()
	cardTwoPlayer.flip()
	
	animationsComplete()

func processFlopAnimation(tableCards : Array[NonUiCard]):
	var cardOne = cardScene.instantiate()
	var cardTwo = cardScene.instantiate()
	var cardThree = cardScene.instantiate()
	
	cardOne.nonUiCard = tableCards[0]
	cardTwo.nonUiCard = tableCards[1]
	cardThree.nonUiCard = tableCards[2]

	boardUiCards.append(cardOne)
	boardUiCards.append(cardTwo)
	boardUiCards.append(cardThree)
	
	await get_tree().create_timer(cardDrawDelay).timeout
	$DrawContainer.add_child(cardOne)
	await get_tree().create_timer(cardDrawDelay).timeout
	$DrawContainer.add_child(cardTwo)
	await get_tree().create_timer(cardDrawDelay).timeout
	$DrawContainer.add_child(cardThree)
	
	await get_tree().create_timer(cardDrawDelay).timeout
	cardOne.flip()
	await get_tree().create_timer(cardDrawDelay).timeout
	cardTwo.flip()
	await get_tree().create_timer(cardDrawDelay).timeout
	cardThree.flip()
	await get_tree().create_timer(1).timeout
	
	animationsComplete()
	
func processTurnAnimation(tableCards : Array[NonUiCard]):
	var cardFour = cardScene.instantiate()
	cardFour.nonUiCard = tableCards[3]
	
	boardUiCards.append(cardFour)
	
	$DrawContainer.add_child(cardFour)
	await get_tree().create_timer(cardDrawDelay).timeout
	
	#TBD - Probably need to do something more here
	cardFour.flip()
	await get_tree().create_timer(1).timeout
	animationsComplete()
	
func processRiverAnimation(tableCards : Array[NonUiCard]):
	var cardFive = cardScene.instantiate()
	cardFive.nonUiCard = tableCards[4]
	
	boardUiCards.append(cardFive)
	
	$DrawContainer.add_child(cardFive)
	await get_tree().create_timer(cardDrawDelay).timeout
	
	cardFive.flip()
	await get_tree().create_timer(1).timeout
	animationsComplete()

func processDealBetAnimation(message):
	printMessage(message)
	animationsComplete()
	
func processFlopBetAnimation(message):
	printMessage(message)
	animationsComplete()
	
func processTurnBetAnimation(message):
	printMessage(message)
	animationsComplete()
	
func processEvaluateWinnerAnimation(message):
	printMessage(message)
	
	await get_tree().create_timer(.4).timeout
	cpuUiCards[0].flip()
	cpuUiCards[1].flip()
	await get_tree().create_timer(5).timeout
	
	animationsComplete()
	
func printMessage(message):
	if message:
		if $Info/AnimationPlayer.is_playing():
			$Info/AnimationPlayer.stop()
			$Info/AnimationPlayer.clear_queue()
			
		$Info.text = message
		$Info/AnimationPlayer.queue('show')

func animationsComplete():
	animation_complete.emit()

func getAllCards():
	var allCards = []
	allCards.append_array(playerUiCards)
	allCards.append_array(cpuUiCards)
	allCards.append_array(boardUiCards)
	
	return allCards
	
func hideMessage():
	$Info.text = ""
