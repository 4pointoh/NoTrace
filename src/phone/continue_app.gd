extends Node2D

@export var availableMessage : PackedScene

signal selected(stage: GameStage)

var currentEvents = true

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
