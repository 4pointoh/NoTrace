extends Control

var redColorTexture = load("res://data/assets/realdate/red_icon.png")
var greenColorTexture = load("res://data/assets/realdate/green_icon.png")
var blueColorTexture = load("res://data/assets/realdate/blue_icon.png")
var yellowColorTexture = load("res://data/assets/realdate/yellow_icon.png")
var purpleColorTexture = load("res://data/assets/realdate/purple_icon.png")
var orangeColorTexture = load("res://data/assets/realdate/orange_icon.png")
var pinkColorTexture = load("res://data/assets/realdate/pink_icon.png")
var tealColorTexture = load("res://data/assets/realdate/teal_icon.png")


func _ready():
	# do some debug testing
	setPrefersVariant(RealDate.TopicColors.TOPIC_RED, [RealDate.TopicColors.TOPIC_GREEN, RealDate.TopicColors.TOPIC_BLUE])
	#setNoneVariant([RealDate.TopicColors.TOPIC_GREEN, RealDate.TopicColors.TOPIC_BLUE])


func setPrefersVariant(preferred: RealDate.TopicColors, notPreferred: Array):
	%PrefersVariant.show()
	%NoneVariant.hide()

	%Preferred.texture = getColorTexture(preferred)

	for i in range(notPreferred.size()):
		var color = notPreferred[i]
		var trect = TextureRect.new()
		trect.texture = getColorTexture(color)
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		trect.custom_minimum_size.x = 40
		%PreferredContainer.add_child(trect)

func setNoneVariant(notPreferred: Array):
	%PrefersVariant.hide()
	%NoneVariant.show()

	for i in range(notPreferred.size()):
		var color = notPreferred[i]
		var trect = TextureRect.new()
		trect.texture = getColorTexture(color)
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		trect.custom_minimum_size.x = 40
		%NotPreferredContainer.add_child(trect)

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
			return null
