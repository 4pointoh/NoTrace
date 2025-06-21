extends Node2D
class_name RealDate

@export var topicChoiceScene : PackedScene
@export var selectionResponse : PackedScene
@export var resultsScreen : PackedScene
@export var nextSceneSelect : PackedScene

var currentAvailableCombos : Array = []
var cpuSelections : Array = []
const DEFAULT_TURNS = 6
var turns : int = DEFAULT_TURNS
var selections : int = 4
var lockInBonus : int = 3
var matchingChoices: int = 0

var excludedColors = []
var results

signal dateComplete(nextSceneIndex: int)

var blockClickSound = load("res://data/assets/realdate/sounds/clunk3.mp3")
var yesSound = load("res://data/assets/realdate/sounds/ooo.mp3")
var woopSound = load("res://data/assets/realdate/sounds/woop.mp3")
var woop2Sound = load("res://data/assets/realdate/sounds/woop2.mp3")
var woop3Sound = load("res://data/assets/realdate/sounds/woop3.mp3")
var slideSound = load("res://data/assets/realdate/sounds/slide.mp3")


func setup():
	GlobalGameStage.setCurrentCharacter(GlobalGameStage.currentStage.character)
	
	clearEverything()
	turns = GlobalGameStage.currentStage.firstRoundGuesses
	selections = GlobalGameStage.currentStage.numberOfSelections
	lockInBonus = GlobalGameStage.currentStage.secondRoundGuesses

	%Character.texture = GlobalGameStage.currentStage.characterArt
	%Character.scale = GlobalGameStage.currentStage.characterArtScale
	%Character.position = GlobalGameStage.currentStage.characterArtPosition

	%LockIn.text = 'Lock In!\n+' + str(lockInBonus) + ' Turns'

	cpuSelections = RealDateColorHelper.getRandomColorsForCPU(selections)

	for i in range(cpuSelections.size()):
		print(RealDateColorHelper.colorIndexToColorName(cpuSelections[i]))
	
	if selections == 5:
		%TopicToggle5.show()
		%PreferenceText.hide()
		%PreferenceText2.show()
	else:
		%TopicToggle5.hide()
		%PreferenceText.show()
		%PreferenceText2.hide()
	
	%LockIn.show()

	nextChoices()

func clearEverything():
	clearChoices()

	for child in %HistoryContainer.get_children():
		%HistoryContainer.remove_child(child)
		child.queue_free()

func clearChoices():
	for child in %ChoiceContainer.get_children():
		%ChoiceContainer.remove_child(child)
		child.queue_free()

func nextChoices():
	%AnimationPlayer.play("choices_fall_in")
	
	currentAvailableCombos = RealDateColorHelper.getRandomColorCombos(10, 0, excludedColors)
	var index = 0
	for combo in currentAvailableCombos:
		var newTopicChoice = topicChoiceScene.instantiate()
		newTopicChoice.setColors(combo.colors, combo.topicText, index)
		newTopicChoice.clicked.connect(_handle_topic_choice_clicked)
		%ChoiceContainer.add_child(newTopicChoice)
		%ChoiceContainer.move_child(newTopicChoice, 0)
		index += 1

func _input(event):
	if event.is_action_pressed('DebuButton'):
		print(%ColorTracker.getStates())

func addToHistory():
	pass

func _handle_topic_choice_clicked(id: int):
	%AudioStreamPlayer2.stream = woop3Sound
	%AudioStreamPlayer2.play()

	var selected = currentAvailableCombos[id]
	var newSelectionResponse = selectionResponse.instantiate()
	
	var preferred = determinePreferredColor(selected.colors)
	if preferred == -1:
		newSelectionResponse.setNoneVariant(selected.colors)
		#%SpeechBubble.show()
		%SpeechBubbleText.text = selected.topicText + '?\n' + getRandomNegativeResponse()
	else:
		var pref = selected.colors[preferred]
		var notPref = []
		for color in selected.colors:
			if color != pref:
				notPref.append(color)
		#%SpeechBubble.show()
		%SpeechBubbleText.text = selected.topicText + '?\n' + getRandomPositiveResponse()
		newSelectionResponse.setPrefersVariant(pref, notPref)

	%SpeechBubbleTimer.start()

	%HistoryContainer.add_child(newSelectionResponse)
	%HistoryContainer.move_child(newSelectionResponse,0)

	reduceTurns()

	if(turns == 0):
		%AnimationPlayer.play("choices_fall_out")
	else:
		nextChoices()

func getRandomPositiveResponse():
	var responses = [
		"Sure, seems interesting.",
		"Sounds fun!",
		"Interesting topic!",
		"Sounds good!",
		"Sure, why not?",
		"Hmmm, okay.",
		"Yes!",
		"Sounds cool!",
		"Okay"
	]

	return responses[randi() % responses.size()]

func getRandomNegativeResponse():
	var responses = [
		"Boring.",
		"Yawn.",
		"Nah.",
		"Boooring.",
		"Sounds lame.",
		"Sounds like a snooze fest.",
		"No Thanks.",
		"Hmmm, nah.",
		"Not really in the mood.",
	]

	return responses[randi() % responses.size()]

func reduceTurns():
	turns -= 1
	%TriesLeft.text = str(turns)


func determinePreferredColor(colors: Array):
	var preferredIndex = -1
	var priority = selections  # Use selections to determine the maximum priority

	var index = 0
	for color in colors:
		for i in range(selections):
			if cpuSelections[i] == color and priority > i:
				priority = i
				preferredIndex = index
		index += 1

	return preferredIndex


func _on_lock_in_pressed():
	%AudioStreamPlayer2.stream = woop2Sound
	%AudioStreamPlayer2.play()

	excludedColors.clear()
	clearChoices()
	var states = %ColorTracker.getStates()
	for color in RealDateColorHelper.allColors:
		if states[color] == 1:
			excludedColors.append(color)

	turns += lockInBonus
	%TriesLeft.text = str(turns)
	%LockIn.hide()
	%ColorTracker.disableIcons()
	nextChoices()


func _on_speech_bubble_timer_timeout():
	%SpeechBubble.hide()


func _on_color_tracker_hovering_color(currentColor):
	for child in %ChoiceContainer.get_children():
		if child is TopicChoice:
			if !child.colors.has(currentColor):
				child.modulate = Color(.25, .25, .25, 0.8)


func _on_color_tracker_not_hovering_tracker():
	for child in %ChoiceContainer.get_children():
		if child is TopicChoice:
			child.modulate = Color(1,1,1,1)


func _on_submit_pressed():
	%AnimationPlayer.play("main_ui_out")
	%Help.hide()
	results = resultsScreen.instantiate()
	var startingPos = results.position
	results.position = Vector2(startingPos.x - 1000, startingPos.y)
	add_child(results)

	var tween2 = get_tree().create_tween()
	tween2.tween_property(results, "position", startingPos, .8)
	%AudioStreamPlayer.stream = slideSound
	%AudioStreamPlayer.play()

	var curRelXp = GlobalGameStage.getRelationshipXp()
	var curLevel = GlobalGameStage.getRelationshipLevel()

	var newRelXp = curRelXp + getRelationshipBonus()
	var newLevel = getNewRelationshipLevel(newRelXp)

	matchingChoices = getNumberMatchingChoices()

	if isPerfectDate():
		GlobalGameStage.addPerfectDate()
	
	GlobalGameStage.increaseRelationshipXp(getRelationshipBonus())

	results.displayResults(getPlayerChoices(), cpuSelections, curRelXp, newRelXp, curLevel, newLevel, isPerfectDate())
	
	%Continue.show()

func getPlayerChoices():
	var pc = []
	pc.append(%TopicToggle.currentColor)
	pc.append(%TopicToggle2.currentColor)
	pc.append(%TopicToggle3.currentColor)
	
	if(selections > 3):
		pc.append(%TopicToggle4.currentColor)
	
	if(selections > 4):
		pc.append(%TopicToggle5.currentColor)
	
	return pc

func getRelationshipBonus():
	var bonus = 0
	for i in range(selections):
		if cpuSelections[i] == getPlayerChoices()[i]:
			bonus += 20

	return bonus

func getNewRelationshipLevel(newRelXp):
	var curLevel = GlobalGameStage.getRelationshipLevel()

	if (curLevel * 100) <= newRelXp:
		return curLevel + 1
	else:
		return curLevel

func getNumberMatchingChoices():
	var numMatches = 0
	for i in range(selections):
		if cpuSelections[i] == getPlayerChoices()[i]:
			numMatches += 1

	return numMatches

func isPerfectDate():
	for i in range(selections):
		if cpuSelections[i] != getPlayerChoices()[i]:
			return false

	return true

func _on_continue_pressed():
	results.queue_free()
	var nextSceneSelect = nextSceneSelect.instantiate()
	nextSceneSelect.selectedMode.connect(_on_next_scene_selected)

	if matchingChoices > 2:
		nextSceneSelect.unlockedPerfectDate = true

	add_child(nextSceneSelect)
	%Continue.hide()

func _on_next_scene_selected(mode: int):
	dateComplete.emit(mode)

func showStart():
	%SubmitSection.hide()
	%SelectionBg.hide()
	%TrackerBg2.hide()
	%Continue.hide()
	%AnimationPlayer.play("start_in")
	%Start.show()
	%TitleText.text = GlobalGameStage.currentStage.stageButtonLabel
	%Title.show()
	%Character.texture = GlobalGameStage.currentStage.characterArt
	%Character.scale = GlobalGameStage.currentStage.characterArtScale
	%Character.position = GlobalGameStage.currentStage.characterArtPosition

func _on_start_pressed():
	%SubmitSection.show()
	%SelectionBg.show()
	%TrackerBg2.show()
	%AnimationPlayer.play("main_ui_in")
	%Start.hide()
	%Title.hide()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == 'main_ui_in':
		setup()

func _on_button_pressed() -> void:
	%HelpScreen.visible = !%HelpScreen.visible