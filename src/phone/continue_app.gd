extends Node2D

@export var availableMessage : PackedScene

signal selected(stage: GameStage)

func setup():
	var availableEvents = GlobalGameStage.getAvailableSelectableEvents()
	reset()
	
	for stage in availableEvents:
		var newMessage = availableMessage.instantiate()
		newMessage.setStage(stage)
		newMessage.pressedButton.connect(handlePressed)
		$AvailableMessagesContainer.add_child(newMessage)

func closeApp():
	hide()

func reset():
	for stages in $AvailableMessagesContainer.get_children():
		$AvailableMessagesContainer.remove_child(stages)
		stages.queue_free()
		
func handlePressed(gameStage):
	selected.emit(gameStage)
