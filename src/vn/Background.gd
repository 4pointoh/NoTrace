extends Control

signal is_fading
signal is_fading_slow
@export var background : Background
var shouldFade = false
var shouldFadeQuick = false
var shouldFadeSlow = false
var isSkipping = false
@onready var zoompan = load("res://src/phone/zoompan.gdshader")
@onready var wavefromtop = load("res://src/vn/wavefromtop.gdshader")

func setBackground(newBackground):
	if background && (newBackground.name == background.name) && (!shouldFade || !shouldFadeQuick):
		return 
	
	background = newBackground
	
	if shouldFade:
		is_fading.emit()
		shouldFade = false
		fadeTransition()
		$FadeTimer.start(.4)
	elif shouldFadeQuick:
		shouldFadeQuick = false
		fadeTransitionQuick2()
		$FadeTimer.start(.25)
	elif shouldFadeSlow:
		is_fading_slow.emit()
		shouldFadeSlow = false
		fadeTransitionSlow()
		$FadeTimer.start(2.5)
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

func enableWave():
	var mat = ShaderMaterial.new()
	mat.shader = wavefromtop
	$BackgroundImage.material = mat
	$BackgroundImage.material.set_shader_parameter("wave_amplitude", 10.2)
	$BackgroundImage.material.set_shader_parameter("wave_frequency", 1.0)
	$BackgroundImage.material.set_shader_parameter("wave_speed", 0.9)
	$BackgroundImage.material.set_shader_parameter("vertical_wave_frequency", 0.2)
	$BackgroundImage.material.set_shader_parameter("distortion_strength", 1.0)
	$BackgroundImage.material.set_shader_parameter("fade_start", 0.0)
	$BackgroundImage.material.set_shader_parameter("fade_end", 0.7)
	$BackgroundImage.material.set_shader_parameter("use_sine_wave", true)
	$BackgroundImage.material.set_shader_parameter("apply_to_alpha", false)
	$BackgroundImage.material.set_shader_parameter("wave_direction", Vector2(0, 1))

func disableWave():
	$BackgroundImage.material = null

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

func fadeVideoSlow():
	$VideoStreamPlayer.visible = true
	$VideoStreamPlayer.play()
	await get_tree().create_timer(7).timeout
	var tween = get_tree().create_tween()
	tween.tween_property($VideoStreamPlayer, "modulate", Color.TRANSPARENT, 1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(resetVideoPlayer)

func resetVideoPlayer():
	$VideoStreamPlayer.visible = false
	$VideoStreamPlayer.modulate = Color.WHITE
	$VideoStreamPlayer.stream = null

func checkForVideo():
	if isSkipping:
		return

	# literally just the name of the background in the resource
	#if background.name == 'intro10':
	#	$VideoStreamPlayer.stream = load("res://data/background_lists/chads_party/video/intro_bg10_vid.ogv")
	#	fadeVideo()
	if background.name == 'boa_strip_vid2':
		$VideoStreamPlayer.stream = load("res://data/background_lists/boa_poker_new/video/boa2.ogv")
		fadeVideo()
	if background.name == '402_vid':
		$VideoStreamPlayer.stream = load("res://data/background_lists/lisa_beach_early_departure/video/foot_on_lap.ogv")
		fadeVideo()
	if background.name == '28_vid.png':
		$VideoStreamPlayer.stream = load("res://data/background_lists/ashely_theater/video/hold.ogv")
		fadeVideoSlow()
	if background.name == 'poker_kiss.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/ashely_bar_poker/video/kiss.ogv")
		fadeVideo()
	if background.name == 'beach_shower':
		$VideoStreamPlayer.stream = load("res://data/background_lists/lisa_beach_night/video/shower.ogv")
		fadeVideo()
	if background.name == '036_anna_feet.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/feet.ogv")
		fadeVideo()
	if background.name == '200_lake.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/lake.ogv")
		fadeVideo()
	if background.name == '502_kiss.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/kiss.ogv")
		fadeVideo()
	if background.name == '1107_rain_lay.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/rain_lay.ogv")
		fadeVideo()
	if background.name == '1313_shirt_fall.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/shirt_fall.ogv")
		fadeVideo()
	if background.name == '1320_pool_back.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/pool_back.ogv")
		fadeVideo()
	if background.name == '1321_pool_sit.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_class/videos/pool_sit.ogv")
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

func fadeTransitionQuick2():
	$AnimationPlayer.play('fade_quick_2')

func fadeTransitionSlow():
	$AnimationPlayer.play('fade_slow')

func clearBackground():
	background = null

func playFullscreenAnim(spritesheetPath : String):
	%FullscreenAnim.modulate.a = 0 
	%FullscreenAnim.sprite_frames = load(spritesheetPath)
	
	var tween = get_tree().create_tween()
	tween.tween_property(%FullscreenAnim, "modulate:a", 1, 1)
	
	%FullscreenAnim.play()
	
func stopFullscreenAnim():
	%FullscreenAnim.stop()
	%FullscreenAnim.sprite_frames = null

func flashUnhideMessage():
	%UnhideUiMessage.visible = true
	await get_tree().create_timer(2).timeout
	%UnhideUiMessage.visible = false
