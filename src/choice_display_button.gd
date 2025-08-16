extends Button

var dialogueKey = ""

signal selected(key)

func setLabelAndKey(labeltxt, key):
	dialogueKey = key
	text = labeltxt


func _on_pressed() -> void:
	selected.emit(dialogueKey)
