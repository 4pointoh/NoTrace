extends Control

func setup(description, image, noFullscreen = false):
	$Control/Image.setTexture(image, true)
	$Control/Image.noFullscreen = noFullscreen
	$Control/Label.text = description

func scrollInRight():
	$AnimationPlayer.play("scroll_in_right")
	await $AnimationPlayer.animation_finished

func scrollOutRight():
	$AnimationPlayer.play_backwards("scroll_in_right")
	await $AnimationPlayer.animation_finished

func scrollInLeft():
	$AnimationPlayer.play("scroll_in_left")
	await $AnimationPlayer.animation_finished

func scrollOutLeft():
	$AnimationPlayer.play_backwards("scroll_in_left")
	await $AnimationPlayer.animation_finished

func hideText():
	$Control/Label.hide()
