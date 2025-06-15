extends Control

signal selectedMode(mode: int)

var locked = false
var selectionIndex = -1

func highlightSelection():
	modulate = Color(.17, .95, 0, 1.0)

func unHighlightSelection():
	modulate =  Color(1.0, 1.0, 1.0, 1.0)

func setLocked():
	locked = true
	%ProPlusLocked.show()
	%ProPlusUnlockLabel.show()
	%ProPlusPokerLabel.hide()

func setText(txt):
	%ProPlusPokerLabel.text = txt

func _on_pro_plus_button_pressed() -> void:
	if locked:
		return

	selectedMode.emit(selectionIndex)
	highlightSelection()
