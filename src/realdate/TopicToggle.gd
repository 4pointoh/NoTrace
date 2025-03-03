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

var topicIndex
@export var id : int
var currentColor = RealDate.TopicColors.TOPIC_RED

func setId(newId: int):
	id = newId
	$Label.text = str(id)

func _ready():
	# Assign random color
	topicIndex = randi() % 8
	currentColor = getColorForIndex(topicIndex)
	$TextureRect.texture = getColorTexture(currentColor)
	%Icon.texture = getIconTexture(currentColor)
	$Label.text = str(id)


func getColorForIndex(index: int):
	match index:
		0:
			return RealDate.TopicColors.TOPIC_RED
		1:
			return RealDate.TopicColors.TOPIC_GREEN
		2:
			return RealDate.TopicColors.TOPIC_BLUE
		3:
			return RealDate.TopicColors.TOPIC_YELLOW
		4:
			return RealDate.TopicColors.TOPIC_PURPLE
		5:
			return RealDate.TopicColors.TOPIC_ORANGE
		6:
			return RealDate.TopicColors.TOPIC_PINK
		7:
			return RealDate.TopicColors.TOPIC_TEAL

func _on_button_pressed():
	topicIndex = (topicIndex + 1) % 8
	var color = getColorForIndex(topicIndex)
	currentColor = color
	$TextureRect.texture = getColorTexture(color)
	%Icon.texture = getIconTexture(currentColor)


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
