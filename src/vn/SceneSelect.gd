extends Node2D

@export var stageButton: PackedScene

signal sceneSelectStageSelected(stage: GameStage)
signal closeSceneSelect

# Called when the node enters the scene tree for the first time.
func _ready():
	var allGameStages = load("res://resources/game_stage_lists/part_one.tres")

	for gameStage in allGameStages.gameStages:
		var button = stageButton.instantiate()
		button.setStage(gameStage)
		button.sceneSelect.connect(sceneSelected)
		%VBoxContainer.add_child(button)

func sceneSelected(stage):
	sceneSelectStageSelected.emit(stage)

func _on_close_pressed():
	closeSceneSelect.emit()
