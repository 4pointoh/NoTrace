extends MarginContainer

signal click(id : int, text : String)

var id
var text

func setup(newId, newText):
	id = newId
	text = newText
	$Label.text = text

func _on_button_pressed():
	click.emit(id, text)
