extends Button
class_name SaveSelect

var save_name : String

signal clicked(save_name : String)

func _on_pressed():
	clicked.emit(save_name)
