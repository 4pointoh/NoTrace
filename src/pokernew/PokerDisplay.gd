extends Node2D

signal stageComplete
signal discardPressed(playerIndexes : Array[int])
signal startPressed
signal gameComplete

@export var cardScene : PackedScene

var playerCards = []
var cpuCards = []
var playerUICards = []
var cpuUICards = []

var playerLives
var cpuLives
var playerLivesWithEvents = []
var cpuLivesWithEvents = []

var cpuIndexesToDiscard = []

var currentPlayerLifeIndex = 0
var currentCPULifeIndex = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	%IntroLabel.text = 'Poker With ' + GlobalGameStage.currentStage.opponentName
	%AnimationPlayer.play("intro_label_in")
	%IntroBg.show()
	%IntroLabel.show()

func _on_animation_player_animation_finished(anim_name):
	pass # Replace with function body.

func processPreGameStart():
	playerLives = GlobalGameStage.currentStage.playerLives
	cpuLives = GlobalGameStage.currentStage.cpuLives

	currentPlayerLifeIndex = 0
	currentCPULifeIndex = 0

	playerLivesWithEvents = GlobalGameStage.currentStage.playerLivesWithEvents
	cpuLivesWithEvents = GlobalGameStage.currentStage.cpuLivesWithEvents

	for i in range(playerLives):
		var textureRect = TextureRect.new()
		textureRect.custom_minimum_size = Vector2(80, 10)
		textureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL

		if(playerLivesWithEvents.has(i)):
			textureRect.texture = load("res://data/assets/poker/art/life_star.png")
		else:
			textureRect.texture = load("res://data/assets/poker/art/life.png")
			

		%YourLivesContainer.add_child(textureRect)

	for i in range(cpuLives):
		var textureRect = TextureRect.new()
		textureRect.custom_minimum_size = Vector2(80, 10)
		textureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL

		if(cpuLivesWithEvents.has(i)):
			textureRect.texture = load("res://data/assets/poker/art/life_star.png")
		else:
			textureRect.texture = load("res://data/assets/poker/art/life.png")

		%TheirLivesContainer.add_child(textureRect)

	preGameStartAnimationComplete()

func processPreRoundStart():
	%Discard.text = 'Redraw 0 Cards'
	%PlayerResultBg.hide()
	%CPUResultBg.hide()
	%VsLabel.hide()
	%YourLives.show()
	%TheirLives.show()
	%YourLivesBg.show()
	%TheirLivesBg.show()
	%YourLivesContainer.show()
	%TheirLivesContainer.show()
	preRoundStartAnimationComplete()

func processClearBoard():
	var MOVE_DURATION = 0.4
	var PLAYER_MOVE_OFF_POSITION = Vector2(1200, 850)	# Right side
	var CPU_MOVE_OFF_POSITION = Vector2(1200, 100)	# Right side but at CPU height
	
	# Animate player cards off screen
	for card in playerUICards:
		var tween = create_tween()
		tween.tween_property(card, "position", 
			PLAYER_MOVE_OFF_POSITION, 
			MOVE_DURATION)
		tween.tween_callback(card.queue_free)
	
	# Animate CPU cards off screen
	for card in cpuUICards:
		var tween = create_tween()
		tween.tween_property(card, "position", 
			CPU_MOVE_OFF_POSITION, 
			MOVE_DURATION)
		tween.tween_callback(card.queue_free)
	
	# Wait for animations to complete
	await get_tree().create_timer(MOVE_DURATION).timeout
	
	# Clear the arrays
	playerUICards.clear()
	cpuUICards.clear()
	playerCards.clear()
	cpuCards.clear()
	
	clearBoardAnimationComplete()

func processDeal(playerCards2, cpuCards2):
	var PLAYER_CARD_Y_POS = 850
	var PLAYER_CARD_X_START_POS = 1000
	var CPU_CARD_Y_POS = 200
	var CPU_CARD_X_START_POS = -100
	var FIRST_CARD_X_POS = 100
	var CARD_SPACING = 167  # Space between each card
	var ANIMATION_DURATION = 0.3  # Duration for each card movement
	var DELAY_BETWEEN_CARDS = 0.1  # Delay before next card starts moving
	
	playerCards = playerCards2
	cpuCards = cpuCards2

	%AudioStreamPlayer2D.stream = load("res://data/assets/poker/sounds/cards_being_shuffled.mp3")
	%AudioStreamPlayer2D.play()
	
	# Create player cards
	for i in range(playerCards.size()):
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = playerCards[i]
		nextCard.position = Vector2(PLAYER_CARD_X_START_POS, PLAYER_CARD_Y_POS)
		nextCard.index = i
		nextCard.cardClicked.connect(cardSelected)
		nextCard.selectable = true
		add_child(nextCard)
		playerUICards.append(nextCard)
		
		var tween = create_tween()
		var final_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		
		# Chain the delay and movement
		tween.tween_interval(i * DELAY_BETWEEN_CARDS)  # First add delay based on card position
		tween.tween_property(nextCard, "position",
			Vector2(final_x, PLAYER_CARD_Y_POS),
			ANIMATION_DURATION)
	
	# Create CPU cards with similar animation
	for i in range(cpuCards.size()):
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = cpuCards[i]
		nextCard.position = Vector2(CPU_CARD_X_START_POS, CPU_CARD_Y_POS)
		nextCard.index = i
		add_child(nextCard)
		cpuUICards.append(nextCard)
		
		var tween = create_tween()
		var final_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		
		# Add delay for CPU cards (after player cards)
		tween.tween_interval((playerCards.size() + i) * DELAY_BETWEEN_CARDS)
		tween.tween_property(nextCard, "position",
			Vector2(final_x, CPU_CARD_Y_POS),
			ANIMATION_DURATION)
	
	# Calculate total animation time and delay dealAnimationComplete
	var total_animation_time = (playerCards.size() + cpuCards.size()) * DELAY_BETWEEN_CARDS + ANIMATION_DURATION
	await get_tree().create_timer(total_animation_time).timeout

	for playerUICards in playerUICards:
		playerUICards.flip()

	dealAnimationComplete()

func processPostDeal():
	stageComplete.emit()

func processDiscard(cpuIndexesToDiscard2):
	cpuIndexesToDiscard = cpuIndexesToDiscard2.duplicate()
	%InfoTextBg.show()
	%Discard.show()

func processPostDiscard(playerCards2, cpuCards2):
	playerCards = playerCards2.duplicate()
	cpuCards = cpuCards2.duplicate()
	%InfoTextBg.hide()
	stageComplete.emit()

func processRedraw(playerCards2, cpuCards2):
	var PLAYER_CARD_Y_POS = 850
	var PLAYER_CARD_X_START_POS = 1000
	var CPU_CARD_Y_POS = 200
	var CPU_CARD_X_START_POS = -100
	var FIRST_CARD_X_POS = 100
	var CARD_SPACING = 167
	var ANIMATION_DURATION = 0.3
	var DELAY_BETWEEN_CARDS = 0.1
	
	var playerCardsAdded = playerCards2.size() - playerCards.size()
	var cpuCardsAdded = cpuCards2.size() - cpuCards.size()
	
	# Get starting index for new cards
	var playerStartIndex = playerCards.size()
	var cpuStartIndex = cpuCards.size()
	
	# Update the card arrays
	playerCards = playerCards2
	cpuCards = cpuCards2

	%AudioStreamPlayer2D.stream = load("res://data/assets/poker/sounds/cards_being_shuffled.mp3")
	%AudioStreamPlayer2D.play()
	
	# Create and animate new player cards
	for i in range(playerCardsAdded):
		var cardIndex = playerStartIndex + i
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = playerCards[cardIndex]
		nextCard.position = Vector2(PLAYER_CARD_X_START_POS, PLAYER_CARD_Y_POS)
		add_child(nextCard)
		playerUICards.append(nextCard)
		
		var tween = create_tween()
		var final_x = FIRST_CARD_X_POS + (cardIndex * CARD_SPACING)
		
		tween.tween_interval(i * DELAY_BETWEEN_CARDS)
		tween.tween_property(nextCard, "position",
			Vector2(final_x, PLAYER_CARD_Y_POS),
			ANIMATION_DURATION)
	
	# Create and animate new CPU cards
	for i in range(cpuCardsAdded):
		var cardIndex = cpuStartIndex + i
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = cpuCards[cardIndex]
		nextCard.position = Vector2(CPU_CARD_X_START_POS, CPU_CARD_Y_POS)
		add_child(nextCard)
		cpuUICards.append(nextCard)
		
		var tween = create_tween()
		var final_x = FIRST_CARD_X_POS + (cardIndex * CARD_SPACING)
		
		tween.tween_interval((cpuCardsAdded + i) * DELAY_BETWEEN_CARDS)
		tween.tween_property(nextCard, "position",
			Vector2(final_x, CPU_CARD_Y_POS),
			ANIMATION_DURATION)
	
	print('Redrew ' + str(playerCardsAdded) + ' cards')
	
	# Wait for all animations to complete
	var total_animation_time = (playerCardsAdded + cpuCardsAdded) * DELAY_BETWEEN_CARDS + ANIMATION_DURATION
	await get_tree().create_timer(total_animation_time).timeout

	for playerUICard in playerUICards:
		if(playerUICard.flipped):
			playerUICard.flip()

	redrawAnimationComplete()

func processPostRedraw():
	stageComplete.emit()

func processReveal():
	%Reveal.show()

func processPostReveal():
	stageComplete.emit()

func processEvaluateWinner(playerWins : bool, playerHandResult : String, cpuHandResult : String):
	%PlayerResultBg/PlayerResult.text = playerHandResult
	%CPUResultBg/CPUResult.text = cpuHandResult

	if(playerWins):
		%TheirLivesContainer.get_child(currentCPULifeIndex).texture = load("res://data/assets/poker/art/life_lost.png")
		%Win.text = 'You Win'
		currentCPULifeIndex += 1
		%AudioStreamPlayer2D.stream = load("res://data/assets/poker/sounds/win_sound,_cute,_pia.mp3")
		%AudioStreamPlayer2D.play()
	else:
		%YourLivesContainer.get_child(currentPlayerLifeIndex).texture = load("res://data/assets/poker/art/life_lost.png")
		%Win.text = 'You Lose'
		currentPlayerLifeIndex += 1
		%AudioStreamPlayer2D.stream = load("res://data/assets/poker/sounds/loss_sound,_cute,_pi.mp3")
		%AudioStreamPlayer2D.play()
	
	%Win.show()
	%PlayerResultBg.show()
	%CPUResultBg.show()
	%VsLabel.show()
	evaluateWinnerAnimationComplete()

func processRoundComplete():
	%Continue.show()

func processGameComplete():
	gameCompleteAnimationComplete()

func preGameStartAnimationComplete():
	stageComplete.emit()

func preRoundStartAnimationComplete():
	stageComplete.emit()

func clearBoardAnimationComplete():
	stageComplete.emit()

func dealAnimationComplete():
	stageComplete.emit()
	
func discardAnimationComplete():
	stageComplete.emit()

func redrawAnimationComplete():
	stageComplete.emit()

func revealAnimationComplete():
	stageComplete.emit()

func evaluateWinnerAnimationComplete():
	stageComplete.emit()

func roundCompleteAnimationComplete():
	stageComplete.emit()

func gameCompleteAnimationComplete():
	gameComplete.emit()

func _on_discard_pressed():
	%Discard.hide()
	var selectedIndexes = []
	var MOVE_DURATION = 0.4
	var FLIP_DURATION = 0.3
	var REPOSITION_DURATION = 0.3
	var PLAYER_MOVE_OFF_POSITION = Vector2(1200, 850)  # Right side
	var CPU_MOVE_OFF_POSITION = Vector2(1200, 100)     # Right side but at CPU height
	var FIRST_CARD_X_POS = 100
	var CARD_SPACING = 167

	%AudioStreamPlayer2D.stream = load("res://data/assets/poker/sounds/discard_sound.mp3")
	%AudioStreamPlayer2D.play()
	
	# Handle player cards
	var selectedPlayerCards = []
	var remainingPlayerCards = []
	for uiCard in playerUICards:
		if uiCard.selected:
			selectedPlayerCards.append(uiCard)
			selectedIndexes.append(uiCard.index)
		else:
			remainingPlayerCards.append(uiCard)
		uiCard.disableSelection()
	
	# Handle CPU cards
	var selectedCpuCards = []
	var remainingCpuCards = []
	for uiCard in cpuUICards:
		if uiCard.index in cpuIndexesToDiscard:
			selectedCpuCards.append(uiCard)
		else:
			remainingCpuCards.append(uiCard)
	
	# Update the arrays
	playerUICards = remainingPlayerCards
	cpuUICards = remainingCpuCards
	
	# Animate player cards
	for i in selectedPlayerCards.size():
		var card = selectedPlayerCards[i]
		var tween = create_tween()
		
		# Player cards flip first
		tween.tween_callback(card.flip)
		tween.tween_interval(FLIP_DURATION)
		
		# Then move off screen
		tween.tween_property(card, "position", 
			PLAYER_MOVE_OFF_POSITION, 
			MOVE_DURATION)
		
		tween.tween_callback(card.queue_free)
	
	# Animate CPU cards
	for i in selectedCpuCards.size():
		var card = selectedCpuCards[i]
		var tween = create_tween()
		
		# CPU cards just move off screen (no flip)
		tween.tween_property(card, "position", 
			CPU_MOVE_OFF_POSITION, 
			MOVE_DURATION)
		
		tween.tween_callback(card.queue_free)
	
	# Wait for discard animations before repositioning
	await get_tree().create_timer(FLIP_DURATION + MOVE_DURATION).timeout
	
	# Reposition remaining player cards
	for i in remainingPlayerCards.size():
		var card = remainingPlayerCards[i]
		var tween = create_tween()
		var new_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		tween.tween_property(card, "position",
			Vector2(new_x, card.position.y),
			REPOSITION_DURATION)
	
	# Reposition remaining CPU cards
	for i in remainingCpuCards.size():
		var card = remainingCpuCards[i]
		var tween = create_tween()
		var new_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		tween.tween_property(card, "position",
			Vector2(new_x, card.position.y),
			REPOSITION_DURATION)
	
	# Wait for repositioning before completing
	await get_tree().create_timer(REPOSITION_DURATION).timeout
	
	discardPressed.emit(selectedIndexes)
	discardAnimationComplete()

func _on_reveal_pressed():
	%Reveal.hide()

	# Flip all cards
	for playerUICard in playerUICards:
		if(playerUICard.flipped):
			playerUICard.flip()
	
	for cpuUICard in cpuUICards:
		if(cpuUICard.flipped):
			cpuUICard.flip()

	revealAnimationComplete()

func _on_start_pressed():
	%Start.hide()
	%IntroBg.hide()
	%IntroLabel.hide()
	startPressed.emit()

func cardSelected(index, selected):
	var selectedCount = 0
	for uiCard in playerUICards:
		if uiCard.selected:
			selectedCount += 1

	%Discard.text = 'Redraw ' + str(selectedCount) + ' Cards'

func _on_continue_pressed():
	%Win.hide()
	%Continue.hide()
	stageComplete.emit()
