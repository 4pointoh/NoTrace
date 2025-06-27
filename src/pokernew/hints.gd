extends Node2D

@export var singleHint : PackedScene

func _ready():
	var oneStarHints = GlobalGameStage.currentStage.oneStarHints
	var twoStarHints = GlobalGameStage.currentStage.twoStarHints
	var threeStarHints = GlobalGameStage.currentStage.threeStarHints
	
	if !GlobalGameStage.currentStage.isPokerMatch:
		%HintsLocked.hide()
		%HintContainer.show()
	elif GlobalGameStage.getCurrentStagePokerWins() > 0 or  GlobalGameStage.getCurrentStagePokerLosses() > 0:
		%HintsLocked.hide()
		%HintContainer.show()
	else:
		%HintsLocked.show()
		%HintContainer.hide()
	
	var currentHintIndex = 0
	for i in range(threeStarHints.size()):
		var hint = singleHint.instantiate()
		hint.setup(3, threeStarHints[i], currentHintIndex)
		%HintContainer.add_child(hint)
		currentHintIndex += 1

	for i in range(twoStarHints.size()):
		var hint = singleHint.instantiate()
		hint.setup(2, twoStarHints[i], currentHintIndex)
		%HintContainer.add_child(hint)
		currentHintIndex += 1

	for i in range(oneStarHints.size()):
		var hint = singleHint.instantiate()
		hint.setup(1, oneStarHints[i], currentHintIndex)
		%HintContainer.add_child(hint)
		currentHintIndex += 1


func _on_button_pressed() -> void:
	%HintDesc.visible = !%HintDesc.visible
