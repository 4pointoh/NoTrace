extends Button

signal sceneSelect(sceneId)

var currentStage
var revealed = false

func setCheckpoint(stage : Checkpoint, index : String):
	currentStage = stage
	text = "Checkpoint " + index + "\n Click To Reveal Spoilers"
	%MainText.text = currentStage.checkpointName
	%Description.text = currentStage.checkpointDescription

	if stage.character == 'Lisa':
		%HeaderColor.color = Color.DARK_ORANGE
	elif stage.character == 'Anna':
		%HeaderColor.color = Color.DEEP_PINK
	elif stage.character == 'Ashely':
		%HeaderColor.color = Color.RED
	elif stage.character == 'Amy':
		%HeaderColor.color = Color.REBECCA_PURPLE

func _on_pressed():
	if !revealed:
		revealed = true
		reveal()
	else:
		sceneSelect.emit(currentStage)

func reveal():
	text = ''
	%MainText.show()
	%Description.show()
	%HeaderColor.hide()
