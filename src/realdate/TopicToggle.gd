extends Control

var topicIndex
@export var id : int
var currentColor = RealDateColorHelper.TopicColors.TOPIC_RED

var clickSound = load("res://data/assets/realdate/sounds/click.mp3")

func setId(newId: int):
	id = newId
	$Label.text = str(id)

func _ready():
	# Assign random color
	topicIndex = randi() % 8
	currentColor = RealDateColorHelper.getColorForIndex(topicIndex)
	$TextureRect.texture = RealDateColorHelper.getColorTexture(currentColor)
	%Icon.texture = RealDateColorHelper.getIconTexture(currentColor)
	$Label.text = str(id)

func _on_button_pressed():
	%AudioStreamPlayer.stream = clickSound
	%AudioStreamPlayer.play()
	topicIndex = (topicIndex + 1) % 8
	var color = RealDateColorHelper.getColorForIndex(topicIndex)
	currentColor = color
	$TextureRect.texture = RealDateColorHelper.getColorTexture(color)
	%Icon.texture = RealDateColorHelper.getIconTexture(currentColor)
