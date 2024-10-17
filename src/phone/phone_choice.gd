extends NinePatchRect

signal choice(id : int, text : String)

@export var expandableButton : PackedScene

func setChoices(choices):
	var id = 0
	for ch in choices:
		var button = expandableButton.instantiate()
		button.setup(id, ch)
		button.click.connect(_on_button_click)
		$VBoxContainer.add_child(button)
		id += 1

func _on_button_click(id, text):
	for child in $VBoxContainer.get_children():
		child.queue_free()
		
	choice.emit(id, text)
