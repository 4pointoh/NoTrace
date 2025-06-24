extends Node2D

@export var dateChoiceSelect : PackedScene

signal selectedMode(mode: int)
signal playAgain

var unlockedPerfectDate = false
var currentlySelected = -1

var perfectDateSelection
var midDateSelection

func _ready():
	var perfectDateScene = GlobalGameStage.currentStage.perfectDateGameStage;
	var midDateScene = GlobalGameStage.currentStage.midDateGameStage;
	
	%AnimationPlayer.play("slide_up")

	perfectDateSelection = dateChoiceSelect.instantiate()
	perfectDateSelection.selectionIndex = 0
	midDateSelection = dateChoiceSelect.instantiate()
	midDateSelection.selectionIndex = 1

	perfectDateSelection.selectedMode.connect(handleSelection)
	midDateSelection.selectedMode.connect(handleSelection)

	if unlockedPerfectDate:
		perfectDateSelection.setText(perfectDateScene.stageButtonLabel)
		currentlySelected = 0
		perfectDateSelection.highlightSelection()
	else:
		perfectDateSelection.setLocked()
		currentlySelected = 1
		midDateSelection.highlightSelection()

	midDateSelection.setText(midDateScene.stageButtonLabel)

	%SelectionContainer.add_child(perfectDateSelection)
	%SelectionContainer.add_child(midDateSelection)
	
	%AudioStreamPlayer.play()

	if unlockedPerfectDate:
		perfectDateSelection.playUnlockedAnimation()

func handleSelection(selectionIndex: int) -> void:
	currentlySelected = selectionIndex

	if currentlySelected == 0:
		midDateSelection.unHighlightSelection()
	else:
		perfectDateSelection.unHighlightSelection()

func _on_button_pressed() -> void:
	selectedMode.emit(currentlySelected)
	%AnimationPlayer.play("slide_out")

func _on_button_2_pressed() -> void:
	playAgain.emit()
