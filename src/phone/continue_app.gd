extends Node2D

@export var availableMessage : PackedScene

signal selected(stage: GameStage)
signal selectedTimeline(stage: GameStage)

var currentEvents = true
var gs : GameStage

func setup():
	var availableEvents = GlobalGameStage.getAvailableSelectableEvents()
	reset()
	
	for stage in availableEvents:
		var newMessage = availableMessage.instantiate()
		newMessage.setStage(stage)
		newMessage.pressedButton.connect(handlePressed)
		%AvailableMessagesContainer.add_child(newMessage)
	
	currentEvents = true
	%PastEventsButton.text = 'Replay Past Activities'

func closeApp():
	hide()

func reset():
	for stages in %AvailableMessagesContainer.get_children():
		%AvailableMessagesContainer.remove_child(stages)
		stages.queue_free()
		
func handlePressed(gameStage):
	gs = gameStage
	if GlobalGameStage.hasCompletedStage(gameStage.name) && gameStage.sceneLeadsToAPokerMatch:
		%PokerSelectionContainer.show()
		%FromTimeline.show()
		%FromBeginning.show()
		%AnimationPlayer.play("slide_up")
	else:
		selected.emit(gameStage)

func _on_past_events_button_pressed() -> void:
	currentEvents = !currentEvents
	var availableEvents = []
	
	if currentEvents:
		availableEvents = GlobalGameStage.getAvailableSelectableEvents()
		%PastEventsButton.text = 'Replay Past Activities'
	else:
		availableEvents = GlobalGameStage.getCompletedSelectableEvents()
		%PastEventsButton.text = 'Current Activities'
		
	reset()
	
	for stage in availableEvents:
		var newMessage = availableMessage.instantiate()
		newMessage.setStage(stage)
		newMessage.pressedButton.connect(handlePressed)
		%AvailableMessagesContainer.add_child(newMessage)


func _on_from_beginning_pressed() -> void:
	selected.emit(gs)

func _on_from_timeline_pressed() -> void:
	if gs.pokerMatchGameStage.size() == 1:
		selectedTimeline.emit(gs.pokerMatchGameStage[0])
	else:
		%MultiSceneContainer.show()
		%FromTimeline.hide()
		%FromBeginning.hide()
		if gs.pokerMatchGameStage.size() > 1:
			%Scene1.show()
			%Scene1.text = gs.pokerMatchGameStage[0].displayName
			%Scene2.show()
			%Scene2.text = gs.pokerMatchGameStage[1].displayName
		if gs.pokerMatchGameStage.size() > 2:
			%Scene3.show()
			%Scene3.text = gs.pokerMatchGameStage[2].displayName
		if gs.pokerMatchGameStage.size() > 3:
			%Scene4.show()
			%Scene4.text = gs.pokerMatchGameStage[3].displayName

func _on_back_pressed() -> void:
	%PokerSelectionContainer.hide()
	%MultiSceneContainer.hide()


func _on_scene_1_pressed() -> void:
	selectedTimeline.emit(gs.pokerMatchGameStage[0])


func _on_scene_2_pressed() -> void:
	selectedTimeline.emit(gs.pokerMatchGameStage[1])

func _on_scene_3_pressed() -> void:
	selectedTimeline.emit(gs.pokerMatchGameStage[2])


func _on_scene_4_pressed() -> void:
	selectedTimeline.emit(gs.pokerMatchGameStage[3])
