extends Node2D
var allActions : Array[DateAction]
var currentActionIndex : int = 0

@onready var intensityAnimation = $AnimContainer/IntensityAnimation
@onready var intensityAnimationText = $Intensity
@onready var intensitybg = $intensitybg
@onready var luckAnimation = $CloverAnim
@onready var luckAnimationText = $Luck
@onready var luckbg = $luckbg
@onready var typeBg = $Type
@onready var typeBgText = $Type/TypeText
@onready var bonusesTextIcon = $BonusEmoji
@onready var bonusesTextTitle = $BonusesTitle
@onready var bonusesTextValue = $BonusesText
@onready var bonusbg = $bonusbg

@onready var mainText = $Container/MainText
@onready var mainButton = $Container/MainButton

@onready var topText = $TopBanner/TopText
@onready var dateProgress = $DateProgress
@onready var overlayClipper = $OverlayClipper

@onready var particleContainer = $Container/ParticleContainer

@onready var lisaBg = load("res://data/assets/date/art/datebg2.png")
@onready var asheBg = load("res://data/assets/date/art/datebg3.png")
@onready var amyBg = load("res://data/assets/date/art/datebg4png.png")

@onready var successSound = load("res://data/assets/date/sounds/success.wav")
@onready var failSound = load("res://data/assets/date/sounds/fail.wav")
@onready var arrowClick = load("res://data/assets/phone/sounds/back.wav")

var blackbg = preload("res://data/assets/date/art/transparent_black_rounded_rect_8px9patch.png")
var orangebg = preload("res://data/assets/date/art/transparent_orange_hard_rounded_rect_8px9patch.png")
var bluebg = preload("res://data/assets/date/art/transparent_blue_hard_rounded_rect_8px9patch.png")
var pinkbg = preload("res://data/assets/date/art/transparent_pink_hard_rounded_rect_8px9patch.png")
var greenbg = preload("res://data/assets/date/art/transparent_green_hard_rounded_rect_8px9patch.png")
var purplebg = preload("res://data/assets/date/art/transparent_purple_hard_rounded_rect_8px9patch.png")
var lightgreenbg = preload("res://data/assets/date/art/transparent_light_green_hard_rounded_rect_8px9patch.png")

signal optionSelected(index : int)

var screen_width = 400  # Adjust this to your screen width

func _ready():
	mainText.set_meta("original_x", mainText.position.x)
	particleContainer.start_rain()

func setActions(actions: Array[DateAction]):
	currentActionIndex = 0
	allActions = actions
	setUi(allActions[currentActionIndex])

func firstLoad():
	$IntroText.text = GlobalGameStage.currentStage.dateTitle
	$IntroTextTopBox/IntroTextTop.text = GlobalGameStage.currentStage.dateTitle
	$AnimationPlayer.play("intro_in")

func setUi(action : DateAction):
	var intensityTextArray = ['', '?????', 'Low', 'Mild', 'Medium', 'High', 'Very High']
	var luckTextArray = ['', '?????', 'Low', 'Mild', 'Medium', 'High', 'Very High']
	
	if GlobalGameStage.currentStage.dateCharacter == 'LISA':
		$Container.texture = lisaBg
	elif GlobalGameStage.currentStage.dateCharacter == 'ASHELY':
		$Container.texture =  asheBg
	elif GlobalGameStage.currentStage.dateCharacter == 'AMY':
		$Container.texture = amyBg
	else:
		$Container.texture = lisaBg
	
	if !action.intensity or action.intensity < 0:
		intensityAnimation.hide()
		intensityAnimationText.hide()
		intensitybg.hide()
	else:
		intensityAnimation.show()  
		intensityAnimationText.show()
		intensitybg.show()
		intensityAnimation.play("burning")
		intensityAnimationText.text = intensityTextArray[action.intensity]
		intensityAnimation.scale = Vector2((action.intensity / 10.0) + 0.4, (action.intensity / 10.0) + 0.4)
	
	if !action.luck or action.luck < 0:
		luckAnimation.hide()
		luckAnimationText.hide()
		luckbg.hide()
	else:
		luckAnimation.show()
		luckAnimationText.show()
		luckbg.show()
		luckAnimation.play("breeze")
		luckAnimationText.text = luckTextArray[action.luck]
	
	if !action.category:
		typeBg.hide()
	else:
		typeBg.show()
		
	if action.category == DateAction.CATEGORIES.SMALL_TALK:
		typeBgText.text = 'Small Talk'
		typeBg.texture = blackbg;
		typeBg.material.set_shader_parameter("glow_strength", 2) 
	elif action.category == DateAction.CATEGORIES.PERSONAL:
		typeBgText.text = 'Personal'
		typeBg.texture = bluebg;
		typeBg.material.set_shader_parameter("glow_strength", 3) 
	elif action.category == DateAction.CATEGORIES.FRIENDLY:
		typeBgText.text = 'Friendly Talk'
		typeBg.texture = greenbg;
		typeBg.material.set_shader_parameter("glow_strength", 0.5) 
	elif action.category == DateAction.CATEGORIES.FLIRTY:
		typeBgText.text = 'Flirty'
		typeBg.texture = pinkbg;
		typeBg.material.set_shader_parameter("glow_strength", 0.2) 
	elif action.category == DateAction.CATEGORIES.DEEP:
		typeBgText.text = 'Deep'
		typeBg.texture = purplebg;
		typeBg.material.set_shader_parameter("glow_strength", 1) 
	else:
		typeBgText.text = 'enum mismatch, update DateMinigameDisplay'
		
	var bonuses = getBonuses(action)
	if !bonuses or bonuses.size() < 1:
		bonusesTextIcon.hide()
		bonusesTextTitle.hide()
		bonusesTextValue.hide()
		bonusbg.hide()
	else:
		bonusesTextValue.text = getBonusesText(bonuses)
		bonusesTextIcon.show()
		bonusesTextTitle.show()
		bonusesTextValue.show()
		bonusbg.show()
	
	mainText.text = action.text
	
	match action.type:
		DateAction.TYPES.QUIZ:
			setUiForQuiz()
		DateAction.TYPES.PLAYER_QUESTION:
			setUiForPlayerQuestion()
		DateAction.TYPES.PARTNER_QUESTION:
			setUiForPartnerQuestion()
		DateAction.TYPES.CHOICE:
			setUiForPartnerQuestion()
		DateAction.TYPES.TOPIC:
			setUiForTopic()

func getBonuses(action : DateAction):
	var bonuses = []
	var questionRepeats = GlobalGameStage.getCompleteDateAskFailureCount(action.id)
	if(action.category != DateAction.CATEGORIES.SMALL_TALK and questionRepeats > 0):
		var bonusText = 'Fail Bonus (' + str(questionRepeats) + 'x)'
		bonuses.append(bonusText)
	return bonuses
	
func getBonusesText(bonuses):
	var text = ''
	for bonus in bonuses:
		text += bonus + '\n'
	
	return text

func setProgress(progress, maxProgress):
	var increment = 0;
	
	if(maxProgress == 100):
		increment = 4.5;
	
	if(maxProgress == 120):
		increment = 4;
		
	if(maxProgress == 200):
		increment = 2.25;
	
	dateProgress.value = progress * (100.0/maxProgress)
	overlayClipper.size.x = increment * progress

func setUiForTopic():
	mainButton.text = 'Ask It!'
	topText.text = 'New Topic!'
	mainText.set("theme_override_font_sizes/font_size", 34)

func setUiForPartnerQuestion():
	mainButton.text = 'Answer!'
	topText.text = "Answer Her!"
	mainText.set("theme_override_font_sizes/font_size", 24)
	
func setUiForPlayerQuestion():
	mainButton.text = 'Ask It!'
	topText.text = "Ask Her!"
	mainText.set("theme_override_font_sizes/font_size", 24)

func setUiForQuiz():
	mainButton.text = 'Answer!'
	topText.text = "Quiz!"
	mainText.set("theme_override_font_sizes/font_size", 24)

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

func showSuccess():
	GlobalGameStage.showTopImg(load("res://data/assets/date/art/success_art.png"))
	$Container.visible = false
	$Type.visible = false
	$TopBanner.visible = false
	$Intensity.visible = false
	$BonusEmoji.visible = false
	$BonusesTitle.visible = false
	$BonusesText.visible = false
	$Luck.visible = false
	$CloverAnim.visible = false;
	$AnimContainer.visible = false
	$AudioStreamPlayer2D.stream = load("res://data/assets/general/sounds/victory2.wav")
	$AudioStreamPlayer2D.play()


func _on_button_left_pressed():
	playArrowClick()
	animate_text_transition(1)

func _on_button_right_pressed():
	playArrowClick()
	animate_text_transition(-1)

func animate_text_transition(direction: int):
	var original_x = mainText.get_meta("original_x")
	var tween = create_tween()
	
	# First tween: slide current text off screen
	var off_screen_x = -screen_width if direction > 0 else screen_width
	tween.tween_property(mainText, "position:x", off_screen_x, 0.1)
	
	# After first tween completes, update text and reset position
	tween.tween_callback(func():
		# Update the text content
		currentActionIndex = (currentActionIndex + direction) % allActions.size()
		setUi(allActions[currentActionIndex])
		# Move text to starting position for entrance
		mainText.position.x = -off_screen_x
	)
	
	# Final tween: slide new text in from opposite side
	tween.tween_property(mainText, "position:x", original_x, 0.1)

func set_particle_count(amount):
	particleContainer.set_particle_count(amount)
	
func add_particle(particleName):
	particleContainer.addParticle(particleName)
