extends Node2D
class_name RealDate

@export var topicChoiceScene : PackedScene

enum TopicColors {
	TOPIC_RED,
	TOPIC_GREEN,
	TOPIC_BLUE,
	TOPIC_YELLOW,
	TOPIC_PURPLE,
	TOPIC_ORANGE,
	TOPIC_PINK,
	TOPIC_TEAL,
	TOPIC_SPICY,
	TOPIC_SPECIAL
}


# Called when the node enters the scene tree for the first time.
func _ready():
	var testScene1 = topicChoiceScene.instantiate()
	var testScene2 = topicChoiceScene.instantiate()
	var testScene3 = topicChoiceScene.instantiate()
	var testScene4 = topicChoiceScene.instantiate()
	var testScene5 = topicChoiceScene.instantiate()
	var testScene6 = topicChoiceScene.instantiate()
	var testScene7 = topicChoiceScene.instantiate()
	var testScene8 = topicChoiceScene.instantiate()
	var testScene9 = topicChoiceScene.instantiate()
	var testScene10 = topicChoiceScene.instantiate()

	testScene1.setColors([TopicColors.TOPIC_RED, TopicColors.TOPIC_GREEN], "Morning Routine", 1)
	testScene2.setColors([TopicColors.TOPIC_PURPLE, TopicColors.TOPIC_ORANGE], "Fantasy Date", 2)
	testScene3.setColors([TopicColors.TOPIC_PINK, TopicColors.TOPIC_TEAL, TopicColors.TOPIC_RED], "Favorite Books", 3)
	testScene4.setColors([TopicColors.TOPIC_PURPLE, TopicColors.TOPIC_ORANGE], "Fantasy Date", 4)
	testScene5.setColors([TopicColors.TOPIC_RED, TopicColors.TOPIC_YELLOW], "Morning Routine", 5)
	testScene6.setColors([TopicColors.TOPIC_PURPLE, TopicColors.TOPIC_BLUE], "Fantasy Date", 6)
	testScene7.setColors([TopicColors.TOPIC_BLUE, TopicColors.TOPIC_TEAL, TopicColors.TOPIC_RED], "Favorite Books", 7)
	testScene8.setColors([TopicColors.TOPIC_PURPLE, TopicColors.TOPIC_TEAL], "Fantasy Date", 8)
	testScene9.setColors([TopicColors.TOPIC_BLUE, TopicColors.TOPIC_TEAL, TopicColors.TOPIC_RED], "Favorite Books", 7)
	testScene10.setColors([TopicColors.TOPIC_PURPLE, TopicColors.TOPIC_TEAL], "Fantasy Date", 8)

	$ChoiceContainer.add_child(testScene1)
	$ChoiceContainer.add_child(testScene2)
	$ChoiceContainer.add_child(testScene3)
	$ChoiceContainer.add_child(testScene4)
	$ChoiceContainer.add_child(testScene5)
	$ChoiceContainer.add_child(testScene6)
	$ChoiceContainer.add_child(testScene7)
	$ChoiceContainer.add_child(testScene8)
	$ChoiceContainer.add_child(testScene9)
	$ChoiceContainer.add_child(testScene10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
