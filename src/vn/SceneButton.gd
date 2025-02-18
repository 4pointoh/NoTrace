extends Button

signal sceneSelect(sceneId)

var currentStage

func setStage(stage : GameStage):
	currentStage = stage
	text = stage.displayName
	custom_minimum_size.y = 60
	custom_minimum_size.x = 600

func _on_pressed():
	sceneSelect.emit(currentStage)
