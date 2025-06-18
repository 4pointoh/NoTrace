extends Node2D
var allActions : Array[DateAction]
var currentActionIndex : int = 0
var currentActionType : DateAction.TYPES

@onready var loveBar = $LoveBar
@onready var businessBar = $BusinessBar

@onready var dateProgress = $DateProgress
@onready var overlayClipper = $OverlayClipper

@onready var lisaBg = load("res://data/assets/date/art/datebg2.png")
@onready var asheBg = load("res://data/assets/date/art/datebg3.png")
@onready var amyBg = load("res://data/assets/date/art/datebg4png.png")

@onready var successSound = load("res://data/assets/date/sounds/success.wav")
@onready var failSound = load("res://data/assets/date/sounds/fail.wav")
@onready var arrowClick = load("res://data/assets/phone/sounds/back.wav")

var blackbg = load("res://data/assets/date/art/transparent_black_rounded_rect_8px9patch.png")
var orangebg = load("res://data/assets/date/art/transparent_orange_hard_rounded_rect_8px9patch.png")
var bluebg = load("res://data/assets/date/art/transparent_blue_hard_rounded_rect_8px9patch.png")
var pinkbg = load("res://data/assets/date/art/transparent_pink_hard_rounded_rect_8px9patch.png")
var tealbg = load("res://data/assets/date/art/transparent_teal_hard_rounded_rect_8px9patch.png")
var greenbg = load("res://data/assets/date/art/transparent_green_hard_rounded_rect_8px9patch.png")
var purplebg = load("res://data/assets/date/art/transparent_purple_hard_rounded_rect_8px9patch.png")
var lightgreenbg = load("res://data/assets/date/art/transparent_light_green_hard_rounded_rect_8px9patch.png")

var allowLoveLocked = true

var target_position: Vector2
var spawn_position: Vector2

signal optionSelected(index : int)
signal goBack()
signal proceedFromComplete()
signal dateSkipSelected()
signal playAgain()

var screen_width = 400  # Adjust this to your screen width

func _ready():
	resetAnnoyanceBar()

func setActions(actions: Array[DateAction], allowLoveLockedP: bool):
	allActions = actions
	allowLoveLocked = allowLoveLockedP
	#setUi(allActions[currentActionIndex])
	setUi2(allActions)

func firstLoad():
	$IntroText.text = GlobalGameStage.currentStage.dateTitle
	$IntroTextTopBox/IntroTextTop.text = GlobalGameStage.currentStage.dateTitle
	$AnimationPlayer.play("intro_in")
	%DateSelectDisplay.setBusinessLabel(GlobalGameStage.currentStage.dateBusinessButtonLabel)

func setUi2(actions: Array[DateAction]):
	currentActionType = actions[0].type

	match currentActionType:
		DateAction.TYPES.QUIZ:
			setUiForQuiz()
		DateAction.TYPES.PLAYER_QUESTION:
			setUiForPlayerQuestion()
		DateAction.TYPES.PARTNER_QUESTION:
			setUiForPartnerQuestion()
		DateAction.TYPES.CHOICE:
			setUiForPartnerQuestion()
		DateAction.TYPES.TOPIC:
			setUiForTopicSelection()

func setUi(action : DateAction):
	if GlobalGameStage.currentStage.dateCharacter == 'LISA':
		$Container.texture = lisaBg
	elif GlobalGameStage.currentStage.dateCharacter == 'ASHELY':
		$Container.texture =  asheBg
	elif GlobalGameStage.currentStage.dateCharacter == 'AMY':
		$Container.texture = amyBg
	else:
		$Container.texture = lisaBg
	
	# if action.category == DateAction.CATEGORIES.SMALL_TALK:
	# 	typeBgText.text = 'Small Talk'
	# 	typeBg.texture = blackbg;
	# 	typeBg.material.set_shader_parameter("glow_strength", 2) 
	# elif action.category == DateAction.CATEGORIES.PERSONAL:
	# 	typeBgText.text = 'Personal'
	# 	typeBg.texture = bluebg;
	# 	typeBg.material.set_shader_parameter("glow_strength", 3) 
	# elif action.category == DateAction.CATEGORIES.FRIENDLY:
	# 	typeBgText.text = 'Friendly Talk'
	# 	typeBg.texture = greenbg;
	# 	typeBg.material.set_shader_parameter("glow_strength", 0.5) 
	# elif action.category == DateAction.CATEGORIES.FLIRTY:
	# 	typeBgText.text = 'Flirty'
	# 	typeBg.texture = pinkbg;
	# 	typeBg.material.set_shader_parameter("glow_strength", 0.2) 
	# elif action.category == DateAction.CATEGORIES.CORE:
	# 	typeBgText.text = 'Core'
	# 	typeBg.texture = tealbg;
	# 	typeBg.material.set_shader_parameter("glow_strength", 0.2) 
	# elif action.category == DateAction.CATEGORIES.DEEP:
	# 	typeBgText.text = 'Deep'
	# 	typeBg.texture = purplebg;
	# 	typeBg.material.set_shader_parameter("glow_strength", 1) 
	# else:
	# 	typeBgText.text = 'enum mismatch, update DateMinigameDisplay'
	
	match action.type:
		DateAction.TYPES.QUIZ:
			setUiForQuiz()
		DateAction.TYPES.PLAYER_QUESTION:
			setUiForPlayerQuestion()
		DateAction.TYPES.PARTNER_QUESTION:
			setUiForPartnerQuestion()
		DateAction.TYPES.CHOICE:
			setUiForPartnerQuestion()

func setProgress(progress, maxProgress):
	var increment = 0;
	
	if(maxProgress == 100):
		increment = 4.5;
	
	if(maxProgress == 120):
		increment = 4;
	
	if(maxProgress == 180):
		increment = 2.8;
		
	if(maxProgress == 200):
		increment = 2.25;
	
	dateProgress.value = progress * (100.0/maxProgress)
	overlayClipper.size.x = increment * progress

func setUiForTopicSelection():
	var lockTalk = false;
	var lockFlirt = false;
	var lockBusiness = false;

	for action in allActions:
		if(action.buttonIndex == DateAction.BUTTON_INDEX.TALK):
			lockTalk = (action.loveLocked and !allowLoveLocked)
			lockTalk = lockTalk or action.progressLocked
		elif(action.buttonIndex == DateAction.BUTTON_INDEX.FLIRT):
			lockFlirt = (action.loveLocked and !allowLoveLocked)
			lockFlirt = lockFlirt or action.progressLocked
		elif(action.buttonIndex == DateAction.BUTTON_INDEX.BUSINESS):
			lockBusiness = (action.loveLocked and !allowLoveLocked)
			lockBusiness = lockBusiness or action.progressLocked

	%DateSelectDisplay.setTalkProgressNeeded(lockTalk)
	%DateSelectDisplay.setFlirtProgressNeeded(lockFlirt)
	%DateSelectDisplay.setBusinessProgressNeeded(lockBusiness)

	%DateChoiceDisplay.hide()
	%DateSelectDisplay.showWithAnimation()

func setUiForSubtopicSelection(actionText):
	%DateChoiceDisplay.setChoices(actionText)
	%DateChoiceDisplay.show()
	%DateSelectDisplay.hide()

func setUiForPartnerQuestion():
	%DateChoiceDisplay.setChoices(getAllActionTexts())
	%DateChoiceDisplay.show()
	%DateSelectDisplay.hide()
	
func setUiForPlayerQuestion():
	%DateChoiceDisplay.setChoices(getAllActionTexts())
	%DateChoiceDisplay.show()
	%DateSelectDisplay.hide()

func setUiForQuiz():
	%DateChoiceDisplay.setChoices(getAllActionTexts())
	%DateChoiceDisplay.show()
	%DateSelectDisplay.hide()

func playSuccessSound():
	$AudioStreamPlayer2D.stream = successSound
	$AudioStreamPlayer2D.play()

func playFailSound():
	$AudioStreamPlayer2D.stream = failSound
	$AudioStreamPlayer2D.play()

func playArrowClick():
	$AudioStreamPlayer2D.stream = arrowClick
	$AudioStreamPlayer2D.play()

func _on_main_button_pressed():
	optionSelected.emit(currentActionIndex)

func showSuccess(memories):
	$OverlayClipper.visible = false
	$DateProgress.visible = false
	$LoveBar.visible = false
	$BusinessBar.visible = false
	$BarBg.visible = false
	$BarBg2.visible = false
	$AnnoyanceBar.visible = false
	$AnnoyanceLabel.visible = false
	%DateChoiceDisplay.hide()
	%DateSelectDisplay.hide()
	$AudioStreamPlayer2D.stream = load("res://data/assets/general/sounds/victory2.wav")
	$AudioStreamPlayer2D.play()
	$DateCompleteDisplay.set_memories(memories)
	$DateCompleteDisplay.show()
	$AnimationPlayer2.play("date_success_in")

func setLoveProgress(progress):
	loveBar.set_progress(progress)

func setBusinessProgress(progress):
	businessBar.set_progress(progress)

func hideUi():
	$IntroTextTopBox.visible = false
	$OverlayClipper.visible = false
	$DateProgress.visible = false
	%DateChoiceDisplay.visible = false
	%DateSelectDisplay.visible = false

func showUi():
	$IntroTextTopBox.visible = true
	$OverlayClipper.visible = true
	$DateProgress.visible = true
	%DateChoiceDisplay.visible = true
	%DateSelectDisplay.visible = true

func displayEmoji(emoji : Heartsplosion.TYPES):
	$EmojiDisplay.display(emoji)

func _on_date_complete_display_clicked_continue():
	proceedFromComplete.emit()

func _on_date_complete_display_clicked_play_again() -> void:
	playAgain.emit()

func _on_date_choice_display_choice_selected(text):
	#find the index of the action which matche the text
	var index = 0

	for action in allActions:
		if(action.text == text):
			break
		index += 1

	optionSelected.emit(index)

func _on_date_select_display_choice_selected(index):
	#filter allActions for entries which match the button index
	var actionText = []
	for action in allActions:
		if(action.buttonIndex == index):
			actionText.append(action.text)

	setUiForSubtopicSelection(actionText)
	
func getAllActionTexts():
	var actionText = []
	for action in allActions:
		actionText.append(action.text)
	
	return actionText

func reduceAnnoyanceBar():
	if GlobalGameStage.currentStage.cantLose:
		%AnnoyanceLabel.text = 'Happy 🔒'
		return
		
	%AnnoyanceBar.value = %AnnoyanceBar.value - 34

	if(%AnnoyanceBar.value < 0):
		%AnnoyanceBar.value = 0

	if(%AnnoyanceBar.value < 35):
		%AnnoyanceLabel.text = 'Annoyed'
		$AnnoyanceBar.modulate = Color(5, 0, 0)
	elif(%AnnoyanceBar.value < 70):
		%AnnoyanceLabel.text = 'Neutral'
		$AnnoyanceBar.modulate = Color(5, 5, 0)
	else:
		%AnnoyanceLabel.text = 'Content'
	
func resetAnnoyanceBar():
	if GlobalGameStage.currentStage.cantLose:
		%AnnoyanceLabel.text = 'Happy 🔒'
		%AnnoyanceBar.value = 100
		%AnnoyanceBar.hide()
		return
	
	%AnnoyanceBar.value = 100
	%AnnoyanceLabel.text = 'Content'

func setCgsAvailable(loveCgsAvailable, talkCgsAvailable, businessCgsAvailable):
	%DateSelectDisplay.setTalkCgAvailable(talkCgsAvailable)
	%DateSelectDisplay.setFlirtCgAvailable(loveCgsAvailable)
	%DateSelectDisplay.setBusinessCgAvailable(businessCgsAvailable)

func _on_date_choice_display_back_button():
	goBack.emit()

func isMaximumAnnoyance():
	return %AnnoyanceBar.value == 0

func hideBackButton():
	%DateChoiceDisplay.hideBackButton()

func showBackButton():
	%DateChoiceDisplay.showBackButton()

func _on_date_select_display_skip_date_selected():
	%SkipConfirmBg.show()

func _on_yes_pressed() -> void:
	dateSkipSelected.emit()
	%SkipConfirmBg.hide()

func _on_no_pressed() -> void:
	%SkipConfirmBg.hide()
