extends Node2D

signal continued

func setup(character : GlobalGameStage.CHARACTERS):
	%Clipper.hide()
	%Clipper2.hide()
	if character == GlobalGameStage.CHARACTERS.LISA:
		%Message.text = 'That crazy orange girl kinda likes you!'
		%Face.texture = load("res://data/characters/lisa/phone_icons/default.png")
		%CharName2.set("theme_override_colors/font_color",Color(.91,.44,0))
		%CharName2.text = "Lisa"
	elif character == GlobalGameStage.CHARACTERS.AMY:
		%Message.text = 'You caught the eye of the richest girl in town!'
		%Face.texture = load("res://data/characters/amy/phone_icons/default.png")
		%CharName2.set("theme_override_colors/font_color",Color(.48,0,.81))
		%CharName2.text = "Amy"
	elif character == GlobalGameStage.CHARACTERS.ANA:
		%Message.text = "She might be hiding a secret but she can't hide her feelings!"
		%Face.texture = load("res://data/characters/anna/phone_icons/default.png")
		%CharName2.set("theme_override_colors/font_color",Color(1,0,1))
		%CharName2.text = "Anna"
	elif character == GlobalGameStage.CHARACTERS.ASHLEY:
		%Message.text = "Wow, she actually smiled! ... she's not just playing you, right?"
		%Face.texture = load("res://data/characters/ashely/phone_icons/default.png")
		%CharName2.set("theme_override_colors/font_color",Color(1,0,0.17))
		%CharName2.text = "Ashely"

func animate():
	%Clipper.hide()
	%Clipper2.hide()
	var currentPosition = position
	var newPosition = position
	newPosition.y += 500
	position = newPosition
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", currentPosition, 0.3)
	tween.tween_callback(playAnim)
	%AudioStreamPlayer2.play()

func playAnim():
	%AnimationPlayer.play("animate")

func _on_unlock_button_pressed():
	continued.emit()
