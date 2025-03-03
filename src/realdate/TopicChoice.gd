extends Control

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

signal clicked(id: int)

func setColors(colors: Array, labelText: String, newId: int):
	%Title.text = labelText

	id = newId

	for i in range(colors.size()):
		var color = colors[i]
		var trect = TextureRect.new()
		trect.texture = getColorTexture(color)
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var icon = TextureRect.new()
		icon.texture = getIconTexture(color)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		icon.size.y = 38
		icon.position.y = -41
		trect.add_child(icon)
		%Colors.add_child(trect)



func getColorTexture(color: RealDate.TopicColors):
	match color:
		RealDate.TopicColors.TOPIC_RED:
			return redColorTexture
		RealDate.TopicColors.TOPIC_GREEN:
			return greenColorTexture
		RealDate.TopicColors.TOPIC_BLUE:
			return blueColorTexture
		RealDate.TopicColors.TOPIC_YELLOW:
			return yellowColorTexture
		RealDate.TopicColors.TOPIC_PURPLE:
			return purpleColorTexture
		RealDate.TopicColors.TOPIC_ORANGE:
			return orangeColorTexture
		RealDate.TopicColors.TOPIC_PINK:
			return pinkColorTexture
		RealDate.TopicColors.TOPIC_TEAL:
			return tealColorTexture
		_:
			return redColorTexture

func getIconTexture(color: RealDate.TopicColors):
	match color:
		RealDate.TopicColors.TOPIC_RED:
			return redColorIconTexture
		RealDate.TopicColors.TOPIC_GREEN:
			return greenColorIconTexture
		RealDate.TopicColors.TOPIC_BLUE:
			return blueColorIconTexture
		RealDate.TopicColors.TOPIC_YELLOW:
			return yellowColorIconTexture
		RealDate.TopicColors.TOPIC_PURPLE:
			return purpleColorIconTexture
		RealDate.TopicColors.TOPIC_ORANGE:
			return orangeColorIconTexture
		RealDate.TopicColors.TOPIC_PINK:
			return pinkColorIconTexture
		RealDate.TopicColors.TOPIC_TEAL:
			return tealColorIconTexture
		_:
			return redColorIconTexture


func _on_button_pressed():
	clicked.emit(id)
