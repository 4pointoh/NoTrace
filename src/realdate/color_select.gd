extends Control

signal colorSelected(color : int)

func setChoiceNumber(num: int):
	%Label.text = "Select Color For: #" + str(num)

func _on_green_pressed() -> void:
	colorSelected.emit(1)

func _on_red_pressed() -> void:
	colorSelected.emit(0)

func _on_blue_pressed() -> void:
	colorSelected.emit(2)

func _on_orange_pressed() -> void:
	colorSelected.emit(5)

func _on_teal_pressed() -> void:
	colorSelected.emit(7)

func _on_pink_pressed() -> void:
	colorSelected.emit(6)

func _on_purple_pressed() -> void:
	colorSelected.emit(4)

func _on_yellow_pressed() -> void:
	colorSelected.emit(3)
