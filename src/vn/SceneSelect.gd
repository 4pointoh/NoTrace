extends Node2D

@export var stageButton: PackedScene

signal sceneSelectStageSelected(stage: Checkpoint)
signal closeSceneSelect

func _ready():
	var allCheckpoints = load("res://resources/checkpoints/all_checkpoints.tres")
	var i = 0
	for checkpoint in allCheckpoints.checkpoints:
		i = i + 1
		var button = stageButton.instantiate()
		button.setCheckpoint(checkpoint, str(i))
		button.sceneSelect.connect(sceneSelected)
		%VBoxContainer.add_child(button)

# Called when the node enters the scene tree for the first time.
# func _ready():
# 	var allGameStages = load("res://resources/game_stage_lists/part_one.tres")

# 	for gameStage in allGameStages.gameStages:
# 		var button = stageButton.instantiate()
# 		button.setStage(gameStage)
# 		button.sceneSelect.connect(sceneSelected)
# 		%VBoxContainer.add_child(button)

func sceneSelected(checkpoint):
	sceneSelectStageSelected.emit(checkpoint)

func _on_close_pressed():
	closeSceneSelect.emit()
