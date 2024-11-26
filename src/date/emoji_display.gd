extends Node2D

@onready var heart = load("res://data/assets/date/art/heart.png")
@onready var happy = load("res://data/assets/date/art/happy.png")
@onready var concerned = load("res://data/assets/date/art/concerned.png")
@onready var confused = load("res://data/assets/date/art/confused.png")
@onready var annoyed = load("res://data/assets/date/art/annoyed.png")
@onready var pissed = load("res://data/assets/date/art/pissed.png")
@onready var horny = load("res://data/assets/date/art/horny.png")
@onready var surprised = load("res://data/assets/date/art/surprised.png")
@onready var laugh = load("res://data/assets/date/art/laugh.png")
@onready var innocent = load("res://data/assets/date/art/surprised.png")
@onready var blush = load("res://data/assets/date/art/blush.png")

@onready var heartSound = load("res://data/assets/general/sounds/tone4.wav")
@onready var happySound = load("res://data/assets/general/sounds/success2.wav")
@onready var concernedSound = load("res://data/assets/general/sounds/doubt.wav")
@onready var confusedSound = load("res://data/assets/general/sounds/doubt.wav")
@onready var annoyedSound = load("res://data/assets/general/sounds/doubt.wav")
@onready var pissedSound = load("res://data/assets/general/sounds/huh.wav")
@onready var hornySound = load("res://data/assets/general/sounds/mmmm.wav")
@onready var surprisedSound = load("res://data/assets/general/sounds/doubt.wav")
@onready var laughSound = load("res://data/assets/general/sounds/laugh2.wav")
@onready var innocentSound = load("res://data/assets/general/sounds/mmmm.wav")
@onready var blushSound = load("res://data/assets/general/sounds/huh.wav")

@onready var audioPlayer = $AudioStreamPlayer2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func display(emoji : Heartsplosion.TYPES):
	match emoji:
		Heartsplosion.TYPES.HEARTS:
			$EmojiDisplay.texture = heart
			audioPlayer.stream = heartSound
		Heartsplosion.TYPES.HAPPY:
			$EmojiDisplay.texture = happy
			audioPlayer.stream = happySound
		Heartsplosion.TYPES.CONCERNED:
			$EmojiDisplay.texture = concerned
			audioPlayer.stream = concernedSound
		Heartsplosion.TYPES.CONFUSED:
			$EmojiDisplay.texture = confused
			audioPlayer.stream = confusedSound
		Heartsplosion.TYPES.ANNOYED:
			$EmojiDisplay.texture = annoyed
			audioPlayer.stream = annoyedSound
		Heartsplosion.TYPES.PISSED:
			$EmojiDisplay.texture = pissed
			audioPlayer.stream = pissedSound
		Heartsplosion.TYPES.HORNY:
			$EmojiDisplay.texture = horny
			audioPlayer.stream = hornySound
		Heartsplosion.TYPES.SURPRISED:
			$EmojiDisplay.texture = surprised
			audioPlayer.stream = surprisedSound
		Heartsplosion.TYPES.LAUGH:
			$EmojiDisplay.texture = laugh
			audioPlayer.stream = laughSound
		Heartsplosion.TYPES.INNOCENT:
			$EmojiDisplay.texture = innocent
			audioPlayer.stream = innocentSound
		Heartsplosion.TYPES.BLUSH:
			$EmojiDisplay.texture = blush
			audioPlayer.stream = blushSound
	
	audioPlayer.play()
	show()

	var tween = get_tree().create_tween()
	tween.tween_property($EmojiDisplay, "rotation_degrees", 10, 4)
	tween.tween_property($EmojiDisplay, "modulate:a", 0, 0.5)
	tween.tween_callback(reset)

func reset():
	hide()
	$EmojiDisplay.modulate.a = 1
	$EmojiDisplay.rotation_degrees = -20
