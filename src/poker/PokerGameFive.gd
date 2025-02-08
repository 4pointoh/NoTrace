extends Node2D
class_name PokerGameFive

enum Difficulty { EASY, MEDIUM, HARD }
var difficulty_level = Difficulty.EASY

# Game state variables
var currentPokerStage : PokerEnums.PokerStage
var nextPokerStage : PokerEnums.PokerStage
var gameOver
var win
var waitForHuman

# Player and CPU variables
var isPlayerTurn
var playerAction
var cpuAction
var cpuRaiseAmount
var playerFolded
var cpuFolded
var cpuWinPercent
var playerWinPercent
var playerBetComplete
var cpuBetComplete

# Financial variables
var money
var opponentMoney
var ante
var pot
var maxRaise
var pendingCallAmount
var totalTableWorth

# Dialogue and animation variables
var animationPause
var dialoguePause
var message

# Opponent variables
var opponentName
var opponentNamePlural

# Card variables
var deck = Deck.new()
var currentHandValues
var nextPokerAction
var playerCards : Array[NonUiCard] = []
var cpuCards : Array[NonUiCard] = []
var tableCards : Array[NonUiCard] = []

@onready var raiseSound = load("res://data/assets/poker/sounds/more_chips.wav")
@onready var chipsSound = load("res://data/assets/poker/sounds/chips.wav")
@onready var chipSlide = load("res://data/assets/poker/sounds/chip_slide.wav")

# Signals
signal gamePaused
signal gameWon
signal gameLost

func setup():
	isPlayerTurn = true
	waitForHuman = false
	dialoguePause = false
	playerBetComplete = false
	cpuBetComplete = false
	pot = 0
	playerCards = []
	cpuCards = []
	tableCards = []
	GlobalGameStage.currentStage.pokerScript.reset_tracking_vars()
	money = GlobalGameStage.currentStage.playerStartingMoney
	opponentMoney = GlobalGameStage.currentStage.cpuStartingMoney
	ante = GlobalGameStage.currentStage.startingAnte
	maxRaise = GlobalGameStage.currentStage.maxRaise
	opponentName = GlobalGameStage.currentStage.opponentName
	opponentNamePlural = GlobalGameStage.currentStage.opponentNamePlural
	totalTableWorth = money + opponentMoney
	clearCallAmount()
	
	gameOver = false
	win = false
	handleMoneyMovement()
	$StartingInfo.visible = true
	setupStartingInfoText()
	$Start.visible = true
	$Check.disabled = false
	$Call.disabled = true
	
	hidePokerUiElements()
	show()
	
func setupStartingInfoText():
	var text = ""
	$StartingInfo.text = "Poker with " + GlobalGameStage.currentStage.opponentName + "!"

func hidePokerUiElements():
	%YourMoney.hide()
	%TheirMoney.hide()
	%ChipsBg.hide()
	%ChipsText.hide()
	%Ante.hide()
	%Pot.hide()
	%StatsBg.hide()
	$ToCall.hide()
	$MaxRaise.hide()
	$Raise.hide()
	$Check.hide()
	$Fold.hide()
	$Call.hide()
	$PokerAnimationController.hide()
		
func unHidePokerUiElements():
	%YourMoney.show()
	%TheirMoney.show()
	%ChipsBg.show()
	%ChipsText.show()
	%Ante.show()
	%Pot.show()
	%StatsBg.show()
	$ToCall.show()
	$MaxRaise.show()
	$Raise.show()
	$Check.show()
	$Fold.show()
	$Call.show()
	$PokerAnimationController.show()
		
func hidePokerButtons():
	$Raise.hide()
	$Check.hide()
	$Fold.hide()
	$Call.hide()
		
func unHidePokerButtons():
	$Raise.show()
	$Check.show()
	$Fold.show()
	$Call.show()

func hideInitElements():
	$Start.hide()
	$StartingInfo.hide()
		
func unHideInitElements():
	$Start.show()
	$StartingInfo.show()

func pauseForAnimations():
	animationPause = true

func _on_start_pressed():
	unHidePokerUiElements()
	hideInitElements()
	runPoker()

func _on_call_pressed():
	if animationPause:
		pass
	waitForHuman = false
	playerAction = "call"
	runPoker()
	unHidePokerButtons()


func _on_fold_pressed():
	if animationPause:
		pass
	waitForHuman = false
	playerAction = "fold"
	runPoker()


func _on_check_pressed():
	if animationPause:
		pass
	waitForHuman = false
	playerAction = "check"
	runPoker()


func _on_raise_pressed():
	if animationPause:
		pass
	waitForHuman = false
	playerAction = "raise"
	runPoker()

func spawnPokerChips():
	var numOfSprites = round(pot / ante) - 1
	
	if numOfSprites == $ChipBox.get_child_count():
		return
	else:
		for child in $ChipBox.get_children():
			child.queue_free()
	
	for num in range(numOfSprites):
		var spr = Sprite2D.new()
		spr.texture = load("res://data/assets/poker/art/chip.png")
		
		# Apply random rotation
		spr.rotation = randf_range(0, 2 * PI)
		
		# Apply small random position offset
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		spr.position = spr.position + offset
		
		$ChipBox.add_child(spr)
		
	
func _on_poker_animation_controller_animation_complete():
	animationPause = false
	message = null
	enableButtons()
	runPoker()
	
func waitForAnimationComplete():
	pauseForAnimations()
	disableButtons()
	$PokerAnimationController.processAnimations(currentPokerStage, playerCards, cpuCards, tableCards, message)

var buttonStates
func disableButtons():
	buttonStates = {
		'call': $Call.disabled,
		'fold': $Fold.disabled,
		'check': $Check.disabled,
		'raise': $Raise.disabled
	}
	
	$Call.disabled = true
	$Fold.disabled = true
	$Check.disabled = true
	$Raise.disabled = true
	
func enableButtons():
	$Call.disabled = buttonStates['call']
	$Fold.disabled = buttonStates['fold']
	$Check.disabled = buttonStates['check']
	$Raise.disabled = buttonStates['raise']

var initialState = PokerEnums.PokerStage.PRE_GAME_START

func runPoker():	
	while !animationPause && !waitForHuman && !gameOver && !dialoguePause:
		processCurrentStage()
	
func processCurrentStage():
	currentPokerStage = nextPokerStage
	shouldDialoguePause()
	match currentPokerStage:
		PokerEnums.PokerStage.PRE_GAME_START:
			processPreGameStart()
		PokerEnums.PokerStage.CLEAR_BOARD:
			processClearBoard()
		PokerEnums.PokerStage.ANTE:
			processAnte()
		PokerEnums.PokerStage.DEAL:
			processDeal()
		PokerEnums.PokerStage.POST_DEAL:
			processPostDeal()
		PokerEnums.PokerStage.POST_DEAL_BETTING:
			processDealBettingRound()
		PokerEnums.PokerStage.PRE_FLOP:
			processPreFlop()
		PokerEnums.PokerStage.FLOP:
			processFlop()
		PokerEnums.PokerStage.POST_FLOP:
			processPostFlop()
		PokerEnums.PokerStage.FLOP_BETTING:
			processFlopBettingRound()
		PokerEnums.PokerStage.PRE_TURN:
			processPreTurn()
		PokerEnums.PokerStage.TURN:
			processTurn()
		PokerEnums.PokerStage.POST_TURN:
			processPostTurn()
		PokerEnums.PokerStage.TURN_BETTING:
			processTurnBettingRound()
		PokerEnums.PokerStage.PRE_RIVER:
			processPreRiver()
		PokerEnums.PokerStage.RIVER:
			processRiver()
		PokerEnums.PokerStage.POST_RIVER:
			processPostRiver()
		PokerEnums.PokerStage.EVALUATE_WINNER:
			processEvaluateWinner()
		PokerEnums.PokerStage.ROUND_COMPLETE:
			processRoundComplete()
		PokerEnums.PokerStage.GAME_COMPLETE:
			processGameComplete()
	spawnPokerChips()
	
func processPreGameStart():
	nextPokerStage = PokerEnums.PokerStage.CLEAR_BOARD

func processClearBoard():
	nextPokerStage = PokerEnums.PokerStage.ANTE
	$Call.disabled = true
	$Check.disabled = false
	clearCallAmount()
	waitForHuman = false
	playerCards = []
	cpuCards = []
	tableCards = []
	playerAction = 'check'
	cpuWinPercent = null
	playerBetComplete = false
	cpuBetComplete = false
	$PokerAnimationController.hideMessage()
	waitForAnimationComplete()

func processAnte():
	var actualAnte = ante
	if getLowestBalance() < ante:
		actualAnte = getLowestBalance()

	addToPot(true, actualAnte)
	addToPot(false, actualAnte)
	nextPokerStage = PokerEnums.PokerStage.DEAL
	waitForHuman = false

func processDeal():
	playerCards.append(deck.nextCard())
	playerCards.append(deck.nextCard())
	cpuCards.append(deck.nextCard())
	cpuCards.append(deck.nextCard())
	nextPokerStage = PokerEnums.PokerStage.POST_DEAL
	waitForHuman = false
	waitForAnimationComplete()

func processPostDeal():
	if someoneOutOfMoney():
		nextPokerStage = PokerEnums.PokerStage.PRE_FLOP
	else:
		if isPlayerTurn:
			waitForHuman = true
		nextPokerStage = PokerEnums.PokerStage.POST_DEAL_BETTING

func processDealBettingRound():
	var complete = processBettingRound()
	
	if complete:
		if someoneFolded():
			nextPokerStage = PokerEnums.PokerStage.EVALUATE_WINNER
		else:
			nextPokerStage = PokerEnums.PokerStage.PRE_FLOP
		waitForHuman = false
	else:
		if isPlayerTurn:
			waitForHuman = true
		nextPokerStage = PokerEnums.PokerStage.POST_DEAL_BETTING
	waitForAnimationComplete()

func processPreFlop():
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.FLOP

func processFlop():
	tableCards.append(deck.nextCard())
	tableCards.append(deck.nextCard())
	tableCards.append(deck.nextCard())
	waitForHuman = false
	
	evaluateProbabilities()
	
	nextPokerStage = PokerEnums.PokerStage.POST_FLOP
	waitForAnimationComplete()

func processPostFlop():
	if someoneOutOfMoney():
		nextPokerStage = PokerEnums.PokerStage.PRE_TURN
	else:
		if isPlayerTurn:
			waitForHuman = true
		nextPokerStage = PokerEnums.PokerStage.FLOP_BETTING
	
func processFlopBettingRound():
	var complete = processBettingRound()
	
	if complete:
		if someoneFolded():
			nextPokerStage = PokerEnums.PokerStage.EVALUATE_WINNER
		else:
			nextPokerStage = PokerEnums.PokerStage.PRE_TURN
		waitForHuman = false
	else:
		if isPlayerTurn:
			waitForHuman = true
		nextPokerStage = PokerEnums.PokerStage.FLOP_BETTING
	waitForAnimationComplete()

func processPreTurn():
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.TURN

func processTurn():
	tableCards.append(deck.nextCard())
	evaluateProbabilities()
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.POST_TURN
	waitForAnimationComplete()

func processPostTurn():
	if someoneOutOfMoney():
		nextPokerStage = PokerEnums.PokerStage.PRE_RIVER
	else:
		if isPlayerTurn:
			waitForHuman = true
		nextPokerStage = PokerEnums.PokerStage.TURN_BETTING

func processTurnBettingRound():
	var complete = processBettingRound()
	
	if complete:
		if someoneFolded():
			nextPokerStage = PokerEnums.PokerStage.EVALUATE_WINNER
		else:
			nextPokerStage = PokerEnums.PokerStage.PRE_RIVER
		waitForHuman = false
	else:
		if isPlayerTurn:
			waitForHuman = true
		nextPokerStage = PokerEnums.PokerStage.TURN_BETTING
	waitForAnimationComplete()

func processPreRiver():
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.RIVER

func processRiver():
	tableCards.append(deck.nextCard())
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.POST_RIVER
	waitForAnimationComplete()

func processPostRiver():
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.EVALUATE_WINNER

func processEvaluateWinner():
	determineWinner()
	cpuFolded = false
	playerFolded = false
	waitForHuman = false
	nextPokerStage = PokerEnums.PokerStage.ROUND_COMPLETE
	waitForAnimationComplete()

func processRoundComplete():
	message = null
	if opponentMoney == 0 || money == 0:
		nextPokerStage = PokerEnums.PokerStage.GAME_COMPLETE
	else:
		isPlayerTurn = !isPlayerTurn
		deck.shuffle()
		nextPokerStage = PokerEnums.PokerStage.CLEAR_BOARD
	waitForHuman = false

func processGameComplete():
	if opponentMoney == 0:
		nextPokerStage = PokerEnums.PokerStage.PRE_GAME_START
		gameOver = true
		win = true
		isPlayerTurn = true
		gameWon.emit()
		$PokerAnimationController.teardown()
	elif money == 0:
		nextPokerStage = PokerEnums.PokerStage.PRE_GAME_START
		gameOver = true
		win = false
		isPlayerTurn = true
		gameLost.emit()

func processBettingRound():
	var bettingRoundComplete = true
	
	if waitForHuman:
		pass
	
	if isPlayerTurn:
		processPlayerMove()
		playerBetComplete = true
		print("Player Move: " + playerAction)
	else:
		processCpuMove()
		cpuBetComplete = true
		print("CPU Move: " + cpuAction)
		message = getCpuActionMessage()
	
	bettingRoundComplete = playerBetComplete && cpuBetComplete
	
	if isPlayerTurn && playerAction == "raise":
		bettingRoundComplete = false
		cpuBetComplete = false
		waitForHuman = false
	elif !isPlayerTurn && cpuAction == "raise":
		bettingRoundComplete = false
		playerBetComplete = false
		waitForHuman = true
	
	if playerAction == 'call' || cpuAction == 'call':
		clearCallAmount()
	
	#reset for the next betting round
	if bettingRoundComplete:
		playerBetComplete = false
		cpuBetComplete = false
	
	isPlayerTurn = !isPlayerTurn
	
	return bettingRoundComplete
	
func someoneFolded():
	return playerFolded || cpuFolded

func processPlayerMove():
	if playerAction == "raise":
		update_player_aggression("raise")
		$AudioStreamPlayer2D.stream = raiseSound
		$AudioStreamPlayer2D.play()
		setAmountToCall($Raise/RaiseInput.value)
		addToPot(true, pendingCallAmount)
	elif playerAction == "fold":
		update_player_aggression("fold")
		$AudioStreamPlayer2D.stream = chipSlide
		$AudioStreamPlayer2D.play()
		playerFolded = true
	elif playerAction == "call":
		$AudioStreamPlayer2D.stream = chipsSound
		$AudioStreamPlayer2D.play()
		addToPot(true, pendingCallAmount)
		clearCallAmount()
	
	handleMoneyMovement()
	
func processCpuMove():
	determineCpuActionAndRaiseAmount()
	if cpuAction == "raise":
		setAmountToCall(cpuRaiseAmount)
		addToPot(false, pendingCallAmount)
		$Check.disabled = true
		$Call.disabled = false
		$AudioStreamPlayer2D.stream = raiseSound
		$AudioStreamPlayer2D.play()
	elif cpuAction == "fold":
		cpuFolded = true
		$Check.disabled = false
		$Call.disabled = true
		$AudioStreamPlayer2D.stream = chipSlide
		$AudioStreamPlayer2D.play()
	elif cpuAction == "call":
		setAmountToCall($Raise/RaiseInput.value)
		addToPot(false, pendingCallAmount)
		$Check.disabled = false
		$Call.disabled = true
		$AudioStreamPlayer2D.stream = chipsSound
		$AudioStreamPlayer2D.play()
	else:
		$Check.disabled = false
		$Call.disabled = true
	
func determineCpuActionAndRaiseAmount():
	var raiseAmount = 0
	var randomizer = RandomNumberGenerator.new()
	randomizer.randomize()

	if cpuWinPercent == null:
		cpuWinPercent = estimate_pre_flop_win_percent()

	var cpu_win_pct = adjusted_cpu_win_percent()
	var pot_odds = calculate_pot_odds()
	var expected_value = cpu_win_pct - (pot_odds * 100)
	var can_bluff = should_cpu_bluff()
	var aggression_factor = 0

	# Determine aggression based on difficulty and player's aggression
	match difficulty_level:
		Difficulty.EASY:
			aggression_factor = 0.5
		Difficulty.MEDIUM:
			aggression_factor = 1.0
		Difficulty.HARD:
			aggression_factor = 1.5

	aggression_factor += player_aggression * 0.1
	aggression_factor = clamp(aggression_factor, 0.5, 2.0)

	# Decision-making logic
	if playerAction == "raise":
		if expected_value > 0 or can_bluff:
			if randomizer.randf() < (aggression_factor * 0.5) and opponentMoney > 0:
				cpuAction = "raise"
				raiseAmount = calculate_raise_amount(aggression_factor)
			else:
				cpuAction = "call"
		else:
			if randomizer.randf() < (aggression_factor * 0.2):
				cpuAction = "call"
			else:
				# Check if CPU has better than high card before applying 50% call chance
				var has_better_than_high_card = check_better_than_high_card()
				if has_better_than_high_card:
					cpuAction = "call"
				else:
					cpuAction = "fold"
	else:
		if expected_value > 0 or can_bluff:
			if randomizer.randf() < (aggression_factor * 0.5) and opponentMoney > 0:
				cpuAction = "raise"
				raiseAmount = calculate_raise_amount(aggression_factor)
			else:
				cpuAction = "check"
		else:
			cpuAction = "check"

	# Ensure the CPU does not bet more than it has
	raiseAmount = min(raiseAmount, opponentMoney)
	cpuRaiseAmount = raiseAmount

	

func calculate_raise_amount(aggression_factor: float) -> int:
	var base_raise = opponentMoney * randf_range(0.05, 0.15) * aggression_factor
	var raise_amt = round_to_nearest_10(base_raise)
	# Ensure the raise amount is within limits
	raise_amt = clamp(raise_amt, ante, max_raise_amount())
	return raise_amt

func max_raise_amount() -> int:
	return min(maxRaise, opponentMoney, money)

var player_aggression = 0.0  # Ranges from -10 (passive) to +10 (aggressive)

func update_player_aggression(action: String):
	if action == "raise":
		player_aggression += 1.0
	elif action == "fold":
		player_aggression -= 1.0
	# Decay aggression over time
	player_aggression = lerp(player_aggression, 0.0, 0.1)

func getCpuActionMessage():
	if opponentNamePlural:
		match(cpuAction):
				"raise": return opponentName + " Raise " + str(cpuRaiseAmount) 
				"call": return opponentName + " Call " + str(pendingCallAmount)
				"fold": return opponentName + " Fold"
				"check": return opponentName + " Check"
	else:
		match(cpuAction):
			"raise": return opponentName + " Raises " + str(cpuRaiseAmount) 
			"call": return opponentName + " Calls " + str(pendingCallAmount)
			"fold": return opponentName + " Folds"
			"check": return opponentName + " Checks"

func evaluateProbabilities():
	var probs = PokerEval.getProbabilitiesFromCardLists(playerCards, cpuCards, tableCards)
	playerWinPercent = probs[0]
	cpuWinPercent = probs[1]
	
func round_to_nearest_10(number: float) -> int:
	# Divide the number by 10 and round it to the nearest integer
	var rounded_div_10 = round(number / 10.0)
	
	# Multiply the rounded result by 10 to get the nearest multiple of 10
	if rounded_div_10 == 0:
		rounded_div_10 = 1
	
	return rounded_div_10 * 10
	
func determineWinner():
	if cpuFolded:
		print("Player wins")
		money += pot
		message = "You win this hand"
		GlobalGameStage.playParticleEffect(Heartsplosion.TYPES.CHIPS, Heartsplosion.ANIM_TYPE.EXPLODE)
		GlobalGameStage.playParticleEffect(Heartsplosion.TYPES.CHIPS, Heartsplosion.ANIM_TYPE.EXPLODE)
	elif playerFolded:
		print("CPU Wins")
		opponentMoney += pot
		message = "You lost this hand"
	else:
		var winner = PokerEval.getWinnersFromCardLists(playerCards, cpuCards, tableCards)
		if winner[0] == "Hand 1 wins":
			print("Player wins")
			money += pot
			message = "You win this hand \n(" + str(winner[1]) + ")"
			GlobalGameStage.playParticleEffect(Heartsplosion.TYPES.CHIPS, Heartsplosion.ANIM_TYPE.EXPLODE)
			GlobalGameStage.playParticleEffect(Heartsplosion.TYPES.CHIPS, Heartsplosion.ANIM_TYPE.EXPLODE)
		else:
			print("CPU wins")
			opponentMoney += pot
			if opponentNamePlural:
				message = opponentName + " win this hand \n(" + str(winner[1]) + ")"
			else:
				message = opponentName + " wins this hand \n(" + str(winner[1]) + ")"
	pot = 0
	handleMoneyMovement()
	
func addToPot(isPlayer, amount):
	if isPlayer:
		money -= amount
		pot += amount
	else:
		opponentMoney -= amount
		pot += amount
	handleMoneyMovement()

func getLowestBalance():
	var lowerAmount = 0
	if money < opponentMoney:
		lowerAmount = money
	else:
		lowerAmount = opponentMoney
	
	return lowerAmount

func setMaxRaise():
	if maxRaise > getLowestBalance():
		$Raise/RaiseInput.max_value = getLowestBalance()
	else:
		$Raise/RaiseInput.max_value = maxRaise
		
	if $Raise/RaiseInput.value > $Raise/RaiseInput.max_value:
		$Raise/RaiseInput.value = $Raise/RaiseInput.max_value

func setMinRaise():
	if getLowestBalance() < 10:
		$Raise/RaiseInput.value = 0
		$Raise.disabled = true
	else:
		$Raise.disabled = false
		
func updateMoneyText():
	%YourMoney.text = str(money)
	%TheirMoney.text = str(opponentMoney)
	%Ante.text = str(ante)
	%Pot.text = str(pot)
	$MaxRaise.text = "Max Raise: " + str($Raise/RaiseInput.max_value)

func shouldDialoguePause():
	var pokerInfo = PokerInfo.new()
	pokerInfo.cpuMoney = opponentMoney
	pokerInfo.playerMoney = money
	pokerInfo.pot = pot
	pokerInfo.stage = currentPokerStage
	
	nextPokerAction = GlobalGameStage.currentStage.pokerScript.call('evaluate_poker_game', pokerInfo)
	
	if nextPokerAction.shouldPausePoker:
		dialoguePause = true
		gamePaused.emit()

func removeDialoguePause():
	dialoguePause = false
	runPoker()

func someoneOutOfMoney():
	return money <= 0 || opponentMoney <= 0
	
func handleMoneyMovement():
	setMaxRaise()
	setMinRaise()
	updateMoneyText()

func setAmountToCall(amount):
	pendingCallAmount = amount
	$Raise/RaiseInput.min_value = amount
	$ToCall.visible = true
	$ToCall.text = "Call Amount: " + str(amount)

func clearCallAmount():
	pendingCallAmount = 0
	$Raise/RaiseInput.min_value = 10
	$ToCall.visible = true
	$ToCall.text = ""
	handleMoneyMovement()


func _on_win_pressed():
	gameWon.emit()

func adjusted_cpu_win_percent() -> float:
	var adjustment = 0
	match difficulty_level:
		Difficulty.EASY:
			adjustment = -randf_range(5, 15)  # Underestimates its win probability
		Difficulty.MEDIUM:
			adjustment = randf_range(-5, 5)   # Slight randomness
		Difficulty.HARD:
			adjustment = randf_range(0, 5)    # Slightly overestimates

	var win_percent = cpuWinPercent
	if win_percent == null:
		win_percent = estimate_pre_flop_win_percent()

	return clamp(win_percent + adjustment, 0, 100)

func check_better_than_high_card() -> bool:
	var card1 = cpuCards[0]
	var card2 = cpuCards[1]
	
	var rank1 = PokerEval.card_ranks[card1.value]
	var rank2 = PokerEval.card_ranks[card2.value]
	
	# Check for pairs
	if rank1 == rank2:
		return true
		
	# Check for suited cards
	if card1.suit == card2.suit:
		return true
		
	# Check for connected cards (straight potential)
	if abs(rank1 - rank2) == 1:
		return true
		
	# Otherwise it's just a high card hand
	return false

func estimate_pre_flop_win_percent() -> float:
	var card1 = cpuCards[0]
	var card2 = cpuCards[1]

	var rank1 = PokerEval.card_ranks[card1.value]
	var rank2 = PokerEval.card_ranks[card2.value]

	var is_pair = rank1 == rank2
	var high_card = max(rank1, rank2)
	var is_suited = card1.suit == card2.suit

	if is_pair:
		return 65.0  # Strong hand (pair)
	elif high_card >= 11 and is_suited:
		return 60.0  # High suited cards
	elif high_card >= 11:
		return 55.0  # High cards
	elif is_suited:
		return 50.0  # Suited cards
	else:
		return 45.0  # Other hands


func should_cpu_bluff() -> bool:
	var bluff_chance = 0
	match difficulty_level:
		Difficulty.EASY:
			bluff_chance = 0.1  # 10% chance to bluff
		Difficulty.MEDIUM:
			bluff_chance = 0.2  # 20% chance to bluff
		Difficulty.HARD:
			bluff_chance = 0.3  # 30% chance to bluff
	return randf() < bluff_chance


func calculate_pot_odds() -> float:
	if pendingCallAmount == 0:
		return 0
	return float(pendingCallAmount) / (pot + pendingCallAmount)
