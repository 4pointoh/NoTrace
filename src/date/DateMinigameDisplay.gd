extends Node2D
var allActions : Array[DateAction]
var currentActionIndex : int = 0

@onready var intensityAnimation = $AnimContainer/IntensityAnimation
@onready var intensityAnimationText = $Intensity
@onready var luckAnimation = $CloverAnim
@onready var luckAnimationText = $Luck
@onready var typeBg = $Type
@onready var typeBgText = $Type/TypeText
@onready var bonusesTextIcon = $BonusEmoji
@onready var bonusesTextTitle = $BonusesTitle
@onready var bonusesTextValue = $BonusesText

@onready var mainText = $Container/MainText
@onready var mainButton = $Container/MainButton

@onready var topText = $TopBanner/TopText
@onready var dateProgress = $DateProgress
@onready var overlayClipper = $OverlayClipper

@onready var lisaBg = load("res://data/assets/date/art/datebg2.png")
@onready var asheBg = load("res://data/assets/date/art/datebg3.png")
@onready var amyBg = load("res://data/assets/date/art/datebg4png.png")

@onready var successSound = load("res://data/assets/date/sounds/success.wav")
@onready var failSound = load("res://data/assets/date/sounds/fail.wav")
@onready var arrowClick = load("res://data/assets/phone/sounds/back.wav")

signal optionSelected(index : int)

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
	else:
		intensityAnimation.show()  
		intensityAnimationText.show()
		intensityAnimation.play("burning")
		intensityAnimationText.text = intensityTextArray[action.intensity]
		intensityAnimation.scale = Vector2((action.intensity / 10.0) + 0.4, (action.intensity / 10.0) + 0.4)
	
	if !action.luck or action.luck < 0:
		luckAnimation.hide()
		luckAnimationText.hide()
	else:
		luckAnimation.show()
		luckAnimationText.show()
		luckAnimation.play("breeze")
		luckAnimationText.text = luckTextArray[action.luck]
	
	if !action.category:
		typeBg.hide()
	else:
		typeBg.show()
		
	if action.category == DateAction.CATEGORIES.SMALL_TALK:
		typeBgText.text = 'Small Talk'
	elif action.category == DateAction.CATEGORIES.PERSONAL:
		typeBgText.text = 'Personal'
	elif action.category == DateAction.CATEGORIES.FIRENDLY:
		typeBgText.text = 'Friendly Talk'
	else:
		typeBgText.text = 'enum mismatch, update DateMinigameDisplay'
		
	var bonuses = getBonuses(action)
	if !bonuses or bonuses.size() < 1:
		bonusesTextIcon.hide()
		bonusesTextTitle.hide()
		bonusesTextValue.hide()
	else:
		bonusesTextValue.text = getBonusesText(bonuses)
		bonusesTextIcon.show()
		bonusesTextTitle.show()
		bonusesTextValue.show()
	
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

func setProgress(progress):
	dateProgress.value = progress
	overlayClipper.size.x = 4.5 * progress

func setUiForTopic():
	mainButton.text = 'Ask It!'
	topText.text = 'New Topic!'

func setUiForPartnerQuestion():
	mainButton.text = 'Answer!'
	topText.text = "Answer Her!"
	
func setUiForPlayerQuestion():
	mainButton.text = 'Ask It!'
	topText.text = "Ask Her!"

func setUiForQuiz():
	mainButton.text = 'Answer!'
	topText.text = "Quiz!"

func playSuccessSound():
	$AudioStreamPlayer2D.stream = successSound
	$AudioStreamPlayer2D.play()

func playFailSound():
	$AudioStreamPlayer2D.stream = failSound
	$AudioStreamPlayer2D.play()

func playArrowClick():
	$AudioStreamPlayer2D.stream = arrowClick
	$AudioStreamPlayer2D.play()

func _on_arrow_left_pressed():
	playArrowClick()
	currentActionIndex = (currentActionIndex - 1) % allActions.size()
	setUi(allActions[currentActionIndex])

func _on_arrow_right_pressed():
	playArrowClick()
	currentActionIndex = (currentActionIndex + 1) % allActions.size()
	setUi(allActions[currentActionIndex])

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
