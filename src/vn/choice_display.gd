extends Node2D

var choices = {}

@export var choiceButton : PackedScene

signal choiceSelected(key: String)

func setChoices(new_choices: Dictionary):
	choices = new_choices

	#Iterate and clear existing buttons
	for child in %ChoiceContainer.get_children():
		child.queue_free()

	for key in choices.keys():
		if key == "GUARANTEED":
			_on_choice_button_pressed(choices[key])
			return

		if key == "TITLE":
			%title.text = choices[key]
			continue
		else:
			var button = choiceButton.instantiate()
			button.setLabelAndKey(choices[key], key)
			button.selected.connect(_on_choice_button_pressed)
			%ChoiceContainer.add_child(button)

func _on_choice_button_pressed(key: String):
	print("Choice selected: %s" % key)
	choiceSelected.emit(key)
