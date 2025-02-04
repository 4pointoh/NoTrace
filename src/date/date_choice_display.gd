extends Node2D

@export var buttonScene : PackedScene

var choices = []

signal choice_selected(index : String)
signal back_button()

func setChoices(choices2):
	#clear the current choices
	for child in %FullBg.get_children():
		child.queue_free()

	self.choices = choices2
	for i in range(choices.size()):
		var button = buttonScene.instantiate()
		button.mainLabel = choices[i]
		button.setIndex(i)
		button.texture = load("res://data/assets/date/art/transparent_black_rounded_rect_8px9patch.png")
		button.position = Vector2((i * 177) + 10, 10)
		button.choice_selected.connect(_on_choice_selected)

		%FullBg.add_child(button)

func _on_choice_selected(choice):
	choice_selected.emit(choice)


func _on_button_pressed():
	back_button.emit()

func hideBackButton():
	$Button.hide()

func showBackButton():
	$Button.show()
