extends TextureRect

var girl : GlobalGameStage.CHARACTERS
signal clicked(girl : GlobalGameStage.CHARACTERS)

func setup(girl2, tex):
	texture = tex
	girl = girl2

func _on_button_pressed():
	clicked.emit(girl)
