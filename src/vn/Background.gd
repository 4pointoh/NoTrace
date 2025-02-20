extends Control

signal is_fading
@export var background : Background
var shouldFade = false
@onready var zoompan = load("res://src/phone/zoompan.gdshader")

func setBackground(newBackground):
	if background && (newBackground.name == background.name) && !shouldFade:
		return 
	
	background = newBackground
	
	if shouldFade:
		is_fading.emit()
		shouldFade = false
		fadeTransition()
		$FadeTimer.start(.4)
	else:
		$BackgroundImage.texture = background.images

func enableZoomPan():
	var mat = ShaderMaterial.new()
	mat.shader = zoompan
	$BackgroundImage.material = mat
	$BackgroundImage.material.set_shader_parameter("zoom_speed", 0.1)
	$BackgroundImage.material.set_shader_parameter("zoom_amount", 0.07)
	$BackgroundImage.material.set_shader_parameter("pan_speed", 0.3)
	$BackgroundImage.material.set_shader_parameter("pan_amount", 0.025)
	$BackgroundImage.scale = Vector2(1.1,1.1)
	$BackgroundImage.position = Vector2(-50.0,-50.0)

func disableZoomPan():
	$BackgroundImage.material = null
	$BackgroundImage.scale = Vector2(1.0,1.0)
	$BackgroundImage.position = Vector2(0,0)

# Plys for 3 seconds
func fadeVideo():
	$VideoStreamPlayer.visible = true
	$VideoStreamPlayer.play()
	await get_tree().create_timer(5.5).timeout
	var tween = get_tree().create_tween()
	tween.tween_property($VideoStreamPlayer, "modulate", Color.TRANSPARENT, 1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(resetVideoPlayer)

func resetVideoPlayer():
	$VideoStreamPlayer.visible = false
	$VideoStreamPlayer.modulate = Color.WHITE
	$VideoStreamPlayer.stream = null

func checkForVideo():
	pass
	# literally just the name of the background in the resource
	#if background.name == 'intro10':
	#	$VideoStreamPlayer.stream = load("res://data/background_lists/chads_party/video/intro_bg10_vid.ogv")
	#	fadeVideo()
	if background.name == 'boa_strip_vid2':
		$VideoStreamPlayer.stream = load("res://data/background_lists/boa_poker_new/video/boa2.ogv")
		fadeVideo()
	#if background.name == 'boa_strip_vid1':
	#	$VideoStreamPlayer.stream = load("res://data/background_lists/boa_poker_new/video/boa1.ogv")
	#	fadeVideo()

func _on_fade_timer_timeout():
	if(!$BackgroundImage.texture == background.images):
		$BackgroundImage.texture = background.images
		checkForVideo()

func fadeTransition():
	$AnimationPlayer.play('fade_quick')

func fadeTransitionQuick():
	$AnimationPlayer.play('fade_quick')

func clearBackground():
	background = null
