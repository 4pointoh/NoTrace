extends Node2D

signal stageComplete
signal discardPressed(playerIndexes : Array[int])
signal startPressed
signal cheatPressed
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
var animationsOn = true

# Called when the node enters the scene tree for the first time.
func _ready():
	%IntroLabel.text = 'Poker With ' + GlobalGameStage.currentStage.opponentName
	%AnimationPlayer.play("intro_label_in")
	%IntroBg.show()
	%IntroLabel.show()
	%PokerModeSelect.show()
	if GlobalGameStage.stageHasHints():
		%Hints.show()
	else:
		%Hints.hide()

func _on_animation_player_animation_finished(_anim_name):
	pass # Replace with function body.

func processPreGameStart(maxPlayerLives: int = -1, maxCpuLives: int = -1, startingPlayerLivesLost: int = 0, startingCpuLivesLost: int = 0):
	# Use provided max lives or fall back to stage config
	if maxPlayerLives >= 0:
		playerLives = maxPlayerLives
	else:
		playerLives = GlobalGameStage.currentStage.playerLives
	
	if maxCpuLives >= 0:
		cpuLives = maxCpuLives
	else:
		cpuLives = GlobalGameStage.currentStage.cpuLives

	# Set starting indices based on lives already lost
	currentPlayerLifeIndex = startingPlayerLivesLost
	currentCPULifeIndex = startingCpuLivesLost

	playerLivesWithEvents = GlobalGameStage.currentStage.playerLivesWithEvents
	cpuLivesWithEvents = GlobalGameStage.currentStage.cpuLivesWithEvents

	for i in range(playerLives):
		var textureRect = TextureRect.new()
		textureRect.custom_minimum_size = Vector2(80, 10)
		textureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL

		# Mark lives as lost if below the starting index
		if i < startingPlayerLivesLost:
			textureRect.texture = load("res://data/assets/poker/art/life_lost.png")
		elif playerLivesWithEvents.has(i):
			textureRect.texture = load("res://data/assets/poker/art/life_star.png")
		else:
			textureRect.texture = load("res://data/assets/poker/art/life.png")
			

		%YourLivesContainer.add_child(textureRect)

	for i in range(cpuLives):
		var textureRect = TextureRect.new()
		textureRect.custom_minimum_size = Vector2(80, 10)
		textureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL

		# Mark lives as lost if below the starting index
		if i < startingCpuLivesLost:
			textureRect.texture = load("res://data/assets/poker/art/life_lost.png")
		elif cpuLivesWithEvents.has(i):
			textureRect.texture = load("res://data/assets/poker/art/life_star.png")
		else:
			textureRect.texture = load("res://data/assets/poker/art/life.png")

		%TheirLivesContainer.add_child(textureRect)

	# Current lives = max - already lost
	var currentPlayerLives = playerLives - startingPlayerLivesLost
	var currentCpuLives = cpuLives - startingCpuLivesLost
	%YourLivesNew.setLives(playerLives, playerLivesWithEvents, currentPlayerLives)
	%TheirLivesNew.setLives(cpuLives, cpuLivesWithEvents, currentCpuLives)

	preGameStartAnimationComplete()

func processPreRoundStart():
	%Discard.text = 'Redraw 0 Cards'
	%PlayerResultBg.hide()
	%CPUResultBg.hide()
	%VsLabel.hide()
	%YourLivesNew.show()
	%TheirLivesNew.show()
	%YourLives.show()
	%TheirLives.show()

	preRoundStartAnimationComplete()

func processClearBoard():
	var MOVE_DURATION = 0.4 if animationsOn else 0.0
	var PLAYER_MOVE_OFF_POSITION = Vector2(1200, 850)	# Right side
	var CPU_MOVE_OFF_POSITION = Vector2(1200, 100)	# Right side but at CPU height
	
	# Animate player cards off screen
	for card in playerUICards:
		if animationsOn:
			var tween = create_tween()
			tween.tween_property(card, "position", 
				PLAYER_MOVE_OFF_POSITION, 
				MOVE_DURATION)
			tween.tween_callback(card.queue_free)
		else:
			card.queue_free()
	
	# Animate CPU cards off screen
	for card in cpuUICards:
		if animationsOn:
			var tween = create_tween()
			tween.tween_property(card, "position", 
				CPU_MOVE_OFF_POSITION, 
				MOVE_DURATION)
			tween.tween_callback(card.queue_free)
		else:
			card.queue_free()
	
	# Wait for animations to complete
	if animationsOn:
		await get_tree().create_timer(MOVE_DURATION).timeout
	
	# Clear the arrays
	playerUICards.clear()
	cpuUICards.clear()
	playerCards.clear()
	cpuCards.clear()
	
	clearBoardAnimationComplete()

func processDeal(playerCards2, cpuCards2):
	var PLAYER_CARD_Y_POS = 900
	var PLAYER_CARD_X_START_POS = 1000
	var CPU_CARD_Y_POS = 125
	var CPU_CARD_X_START_POS = -100
	var FIRST_CARD_X_POS = 100
	var CARD_SPACING = 175  # Space between each card
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
		var final_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		if animationsOn:
			nextCard.position = Vector2(PLAYER_CARD_X_START_POS, PLAYER_CARD_Y_POS)
		else:
			nextCard.position = Vector2(final_x, PLAYER_CARD_Y_POS)
		nextCard.index = i
		nextCard.cardClicked.connect(cardSelected)
		nextCard.selectable = true
		add_child(nextCard)
		playerUICards.append(nextCard)
		
		if animationsOn:
			var tween = create_tween()
			# Chain the delay and movement
			tween.tween_interval(i * DELAY_BETWEEN_CARDS)  # First add delay based on card position
			tween.tween_property(nextCard, "position",
				Vector2(final_x, PLAYER_CARD_Y_POS),
				ANIMATION_DURATION)
	
	# Create CPU cards with similar animation
	for i in range(cpuCards.size()):
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = cpuCards[i]
		var final_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		if animationsOn:
			nextCard.position = Vector2(CPU_CARD_X_START_POS, CPU_CARD_Y_POS)
		else:
			nextCard.position = Vector2(final_x, CPU_CARD_Y_POS)
		nextCard.index = i
		add_child(nextCard)
		cpuUICards.append(nextCard)
		
		if animationsOn:
			var tween = create_tween()
			# Add delay for CPU cards (after player cards)
			tween.tween_interval((playerCards.size() + i) * DELAY_BETWEEN_CARDS)
			tween.tween_property(nextCard, "position",
				Vector2(final_x, CPU_CARD_Y_POS),
				ANIMATION_DURATION)
	
	# Calculate total animation time and delay dealAnimationComplete
	if animationsOn:
		var total_animation_time = (playerCards.size() + cpuCards.size()) * DELAY_BETWEEN_CARDS + ANIMATION_DURATION
		await get_tree().create_timer(total_animation_time).timeout

	for playerUICard in playerUICards:
		playerUICard.flip()

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
	var PLAYER_CARD_Y_POS = 900
	var PLAYER_CARD_X_START_POS = 1000
	var CPU_CARD_Y_POS = 125
	var CPU_CARD_X_START_POS = -100
	var FIRST_CARD_X_POS = 100

	var CARD_SPACING = 175
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
		var final_x = FIRST_CARD_X_POS + (cardIndex * CARD_SPACING)
		if animationsOn:
			nextCard.position = Vector2(PLAYER_CARD_X_START_POS, PLAYER_CARD_Y_POS)
		else:
			nextCard.position = Vector2(final_x, PLAYER_CARD_Y_POS)
		add_child(nextCard)
		playerUICards.append(nextCard)
		
		if animationsOn:
			var tween = create_tween()
			tween.tween_interval(i * DELAY_BETWEEN_CARDS)
			tween.tween_property(nextCard, "position",
				Vector2(final_x, PLAYER_CARD_Y_POS),
				ANIMATION_DURATION)
	
	# Create and animate new CPU cards
	for i in range(cpuCardsAdded):
		var cardIndex = cpuStartIndex + i
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = cpuCards[cardIndex]
		var final_x = FIRST_CARD_X_POS + (cardIndex * CARD_SPACING)
		if animationsOn:
			nextCard.position = Vector2(CPU_CARD_X_START_POS, CPU_CARD_Y_POS)
		else:
			nextCard.position = Vector2(final_x, CPU_CARD_Y_POS)
		add_child(nextCard)
		cpuUICards.append(nextCard)
		
		if animationsOn:
			var tween = create_tween()
			tween.tween_interval((cpuCardsAdded + i) * DELAY_BETWEEN_CARDS)
			tween.tween_property(nextCard, "position",
				Vector2(final_x, CPU_CARD_Y_POS),
				ANIMATION_DURATION)
	
	print('Redrew ' + str(playerCardsAdded) + ' cards')
	
	# Wait for all animations to complete
	if animationsOn:
		var total_animation_time = (playerCardsAdded + cpuCardsAdded) * DELAY_BETWEEN_CARDS + ANIMATION_DURATION
		await get_tree().create_timer(total_animation_time).timeout

	for playerUICard in playerUICards:
		if(playerUICard.flipped):
			playerUICard.flip()

	redrawAnimationComplete()

func processPostRedraw():
	stageComplete.emit()

func processReveal(canCheat, cheatsLeft):
	if canCheat:
		%Cheat.show()
		%CheatsLeft.text = str(cheatsLeft) + ' Cheats Left'
	else:
		%Cheat.hide()
	
	%Reveal.show()

func processPostReveal():
	%Cheat.hide()
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
	
	%YourLivesNew.setLives(playerLives, playerLivesWithEvents, playerLives - currentPlayerLifeIndex)
	%TheirLivesNew.setLives(cpuLives, cpuLivesWithEvents, cpuLives - currentCPULifeIndex)
	
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
	
func displayCheat(playerCards2):
	var PLAYER_CARD_Y_POS = 900
	var PLAYER_CARD_X_START_POS = 1000
	var FIRST_CARD_X_POS = 100
	var CARD_SPACING = 175
	var ANIMATION_DURATION = 0.3
	var DELAY_BETWEEN_CARDS = 0.1

	playerCards = playerCards2

	# Create player cards
	for i in range(playerCards.size()):
		var nextCard = cardScene.instantiate()
		nextCard.nonUiCard = playerCards[i]
		var final_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		if animationsOn:
			nextCard.position = Vector2(PLAYER_CARD_X_START_POS, PLAYER_CARD_Y_POS)
		else:
			nextCard.position = Vector2(final_x, PLAYER_CARD_Y_POS)
		nextCard.index = i
		add_child(nextCard)
		playerUICards.append(nextCard)
		
		if animationsOn:
			var tween = create_tween()
			# Chain the delay and movement
			tween.tween_interval(i * DELAY_BETWEEN_CARDS)  # First add delay based on card position
			tween.tween_property(nextCard, "position",
				Vector2(final_x, PLAYER_CARD_Y_POS),
				ANIMATION_DURATION)
	
	# Calculate total animation time and delay dealAnimationComplete
	if animationsOn:
		var total_animation_time = playerCards.size() * DELAY_BETWEEN_CARDS + ANIMATION_DURATION
		await get_tree().create_timer(total_animation_time).timeout

	for playerUICard in playerUICards:
		if(playerUICard.flipped):
			playerUICard.flip()
	
	%Cheat.hide()


func _on_discard_pressed():
	%Discard.hide()
	var selectedIndexes = []
	var MOVE_DURATION = 0.4
	var FLIP_DURATION = 0.3
	var REPOSITION_DURATION = 0.3
	var PLAYER_MOVE_OFF_POSITION = Vector2(1200, 850)  # Right side
	var CPU_MOVE_OFF_POSITION = Vector2(1200, 100)     # Right side but at CPU height
	var FIRST_CARD_X_POS = 100
	var CARD_SPACING = 175

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
		if animationsOn:
			var tween = create_tween()
			# Player cards flip first
			tween.tween_callback(card.flip)
			tween.tween_interval(FLIP_DURATION)
			# Then move off screen
			tween.tween_property(card, "position", 
				PLAYER_MOVE_OFF_POSITION, 
				MOVE_DURATION)
			tween.tween_callback(card.queue_free)
		else:
			card.queue_free()
	
	# Animate CPU cards
	for i in selectedCpuCards.size():
		var card = selectedCpuCards[i]
		if animationsOn:
			var tween = create_tween()
			# CPU cards just move off screen (no flip)
			tween.tween_property(card, "position", 
				CPU_MOVE_OFF_POSITION, 
				MOVE_DURATION)
			tween.tween_callback(card.queue_free)
		else:
			card.queue_free()
	
	# Wait for discard animations before repositioning
	if animationsOn:
		await get_tree().create_timer(FLIP_DURATION + MOVE_DURATION).timeout
	
	# Reposition remaining player cards
	for i in remainingPlayerCards.size():
		var card = remainingPlayerCards[i]
		var new_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		if animationsOn:
			var tween = create_tween()
			tween.tween_property(card, "position",
				Vector2(new_x, card.position.y),
				REPOSITION_DURATION)
		else:
			card.position = Vector2(new_x, card.position.y)
	
	# Reposition remaining CPU cards
	for i in remainingCpuCards.size():
		var card = remainingCpuCards[i]
		var new_x = FIRST_CARD_X_POS + (i * CARD_SPACING)
		if animationsOn:
			var tween = create_tween()
			tween.tween_property(card, "position",
				Vector2(new_x, card.position.y),
				REPOSITION_DURATION)
		else:
			card.position = Vector2(new_x, card.position.y)
	
	# Wait for repositioning before completing
	if animationsOn:
		await get_tree().create_timer(REPOSITION_DURATION).timeout

	print('Opponent discarded: ' + str(selectedCpuCards.size()))
	displayOpponentDiscardLabel(selectedCpuCards.size())
	
	discardPressed.emit(selectedIndexes)
	discardAnimationComplete()

func _on_reveal_pressed():
	%Reveal.hide()
	%SheDiscardsCountBg.hide()

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
	%Hints.hide()
	%PokerModeSelect.hide ()
	startPressed.emit()

func cardSelected(_index, selected):
	var selectedCount = 0
	for uiCard in playerUICards:
		if uiCard.selected:
			selectedCount += 1

	%Discard.text = 'Redraw ' + str(selectedCount) + ' Cards'

func _on_continue_pressed():
	%Win.hide()
	%Continue.hide()
	stageComplete.emit()

func _on_cheat_pressed():
	%Cheat.hide()
	cheatPressed.emit()

func displayOpponentDiscardLabel(count : int):
	var txt = ''
	txt += 'She Drew ' + str(count) + ' Cards'
	%SheDiscardsCountLabel.text = txt
	%SheDiscardsCountBg.show()
