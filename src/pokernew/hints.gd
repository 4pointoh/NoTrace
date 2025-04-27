extends Node2D

@export var singleHint : PackedScene

func _ready():
	var oneStarHints = GlobalGameStage.currentStage.oneStarHints
	var twoStarHints = GlobalGameStage.currentStage.twoStarHints
	var threeStarHints = GlobalGameStage.currentStage.threeStarHints
	
	for i in range(threeStarHints.size()):
		var hint = singleHint.instantiate()
		hint.setup(3, threeStarHints[i])
		%HintContainer.add_child(hint)
	
	for i in range(twoStarHints.size()):
		var hint = singleHint.instantiate()
		hint.setup(2, twoStarHints[i])
		%HintContainer.add_child(hint)
	
	for i in range(oneStarHints.size()):
		var hint = singleHint.instantiate()
		hint.setup(1, oneStarHints[i])
		%HintContainer.add_child(hint)


func _on_button_pressed() -> void:
	%HintDesc.visible = !%HintDesc.visible
