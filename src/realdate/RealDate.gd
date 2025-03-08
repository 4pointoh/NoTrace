extends Node2D
class_name RealDate

@export var topicChoiceScene : PackedScene
@export var selectionResponse : PackedScene

var currentAvailableCombos : Array = []
var cpuSelections : Array = []
const DEFAULT_TURNS = 6
var turns : int = DEFAULT_TURNS #TODO - Take From Gamestage?
var selections : int = 4 #TODO - Take From Gamestage?

var excludedColors = []

func _ready():
	setup()

func setup():
	clearEverything()
	turns = DEFAULT_TURNS
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
	var selected = currentAvailableCombos[id]
	var newSelectionResponse = selectionResponse.instantiate()
	
	var preferred = determinePreferredColor(selected.colors)
	if preferred == -1:
		newSelectionResponse.setNoneVariant(selected.colors)
		%SpeechBubble.show()
		%SpeechBubbleText.text = selected.topicText + '?\n' + getRandomNegativeResponse()
	else:
		var pref = selected.colors[preferred]
		var notPref = []
		for color in selected.colors:
			if color != pref:
				notPref.append(color)
		%SpeechBubble.show()
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
	excludedColors.clear()
	clearChoices()
	var states = %ColorTracker.getStates()
	for color in RealDateColorHelper.allColors:
		if states[color] == 1:
			excludedColors.append(color)

	turns += 3
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
