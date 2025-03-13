extends Control
class_name TopicChoice

var redColorTexture = load("res://data/assets/realdate/red_sq_two.png")
var greenColorTexture = load("res://data/assets/realdate/green_sq_two.png")
var blueColorTexture = load("res://data/assets/realdate/blue_sq_two.png")
var yellowColorTexture = load("res://data/assets/realdate/yellow_sq_two.png")
var purpleColorTexture = load("res://data/assets/realdate/purple_sq_two.png")
var orangeColorTexture = load("res://data/assets/realdate/orange_sq_two.png")
var pinkColorTexture = load("res://data/assets/realdate/pink_sq_two.png")
var tealColorTexture = load("res://data/assets/realdate/teal_sq_two.png")

var redColorIconTexture = load("res://data/assets/realdate/flame.png")
var greenColorIconTexture = load("res://data/assets/realdate/cup.png")
var yellowColorIconTexture = load("res://data/assets/realdate/smile.png")
var blueColorIconTexture = load("res://data/assets/realdate/feather.png")
var purpleColorIconTexture = load("res://data/assets/realdate/rings.png")
var orangeColorIconTexture = load("res://data/assets/realdate/star.png")
var pinkColorIconTexture = load("res://data/assets/realdate/heart.png")
var tealColorIconTexture = load("res://data/assets/realdate/compass.png")

var id
var colors

signal clicked(id: int)

func setColors(colorsNew: Array, labelText: String, newId: int):
	%Title.text = labelText

	colors = colorsNew
	id = newId

	for i in range(colors.size()):
		var color = colors[i]
		var trect = TextureRect.new()
		trect.texture = RealDateColorHelper.getColorTexture(color)
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var icon = TextureRect.new()
		icon.texture = RealDateColorHelper.getIconTexture(color)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size.y = 38
		icon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		icon.position.y = -41
		trect.add_child(icon)
		%Colors.add_child(trect)

func _on_button_pressed():
	clicked.emit(id)
