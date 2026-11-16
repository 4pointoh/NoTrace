extends Control

signal is_fading
signal is_fading_slow
## The fade carrying a frame change the dialogue asked for (landscape_next / portrait_next) has
## reached its black point, with the new picture under it. Main makes the change behind its own cover.
signal frameChangeDue(mode)
@export var background : Background
var shouldFade = false
var shouldFadeQuick = false
var shouldFadeSlow = false
var isSkipping = false
@onready var zoompan = load("res://src/phone/zoompan.gdshader")
@onready var wavefromtop = load("res://src/vn/wavefromtop.gdshader")

# Portrait layout exactly as authored in the scene, restored when leaving landscape.
var portraitLayout = {}
var zoomPanEnabled = false

# Display mode to flip to when the next background lands (landscape_next / portrait_next
# dialogue signals, which always come with a fade). It lands at that fade's black point, with
# the new picture, so the window reshape is never seen.
var pendingDisplayMode = null

# Videos made for the pictures themselves (tooling/video_gen/finish.py), listed per picture's art
# path in pick order. While a listed picture shows, its video plays over the still: a loop runs
# into itself until the picture changes (after its intro, the frames from the still into the
# loop); any other video plays once and fades back to the still.
const PICTURE_VIDEO_LISTS = ["res://data/background_lists/ashely_poker2/video/videos.gd"]
var pictureVideos = null # art path -> its videos, read from PICTURE_VIDEO_LISTS when first needed
var pictureVideoArt = '' # the picture whose video is up
# Which of a picture's videos plays. Run from the Godot editor, V cycles through them, to compare them in game.
var pictureVideoChoice = {}
var pictureVideoToken = 0 # bumped whenever the picture video changes, so stale waits stand down

func _ready():
	for node in [$BackgroundImage, $VideoStreamPlayer, $Fade, %UnhideUiMessage]:
		portraitLayout[node] = { "position": node.position, "size": node.size, "scale": node.scale }
	portraitLayout[%FullscreenAnim] = { "position": %FullscreenAnim.position }
	portraitLayout["expand_mode"] = $BackgroundImage.expand_mode
	portraitLayout["stretch_mode"] = $BackgroundImage.stretch_mode

	DisplayMode.modeChanged.connect(_handle_display_mode_changed)

func _handle_display_mode_changed(_mode):
	if DisplayMode.isLandscape():
		var base = Vector2(DisplayMode.getBaseSize())
		$BackgroundImage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		$Fade.position = Vector2.ZERO
		$Fade.size = base
		%FullscreenAnim.position = base / 2
		%UnhideUiMessage.position = Vector2(20, base.y - 54)
		refreshPresentation()
	else:
		# Size first: the portrait expand mode derives its minimum height from the
		# current width, so restoring it while still 1920 wide would clamp the size.
		for node in [$BackgroundImage, $VideoStreamPlayer, $Fade, %UnhideUiMessage]:
			node.position = portraitLayout[node]["position"]
			node.scale = portraitLayout[node]["scale"]
			node.size = portraitLayout[node]["size"]
		$BackgroundImage.expand_mode = portraitLayout["expand_mode"]
		$BackgroundImage.stretch_mode = portraitLayout["stretch_mode"]
		%FullscreenAnim.position = portraitLayout[%FullscreenAnim]["position"]
		$Camera.pictureLaidOut(Vector2.ZERO)
		if zoomPanEnabled:
			applyZoomPanTransform()

# How the current picture sits in the landscape frame: it fills it, cover-cropped. Tall art
# loses its top and bottom here until it can be shown as a card over a blurred backdrop.
func refreshPresentation():
	if !DisplayMode.isLandscape():
		return

	var frame = Vector2(DisplayMode.getBaseSize())
	$BackgroundImage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	$BackgroundImage.position = Vector2.ZERO
	$BackgroundImage.scale = Vector2.ONE
	$BackgroundImage.size = frame

	# A video plays over its own still, so it is cropped the same way. It cannot crop itself
	# (it stretches to whatever size it is given), so it is sized to the still's covering rect.
	var picture = $BackgroundImage.texture
	var covering = frame
	if picture != null:
		covering = picture.get_size() * maxf(frame.x / picture.get_width(), frame.y / picture.get_height())
	$VideoStreamPlayer.position = (frame - covering) / 2
	$VideoStreamPlayer.scale = Vector2.ONE
	$VideoStreamPlayer.size = covering

	# The camera moves the picture from here (it stands down while zoom/pan is on).
	$Camera.pictureLaidOut(frame)
	if zoomPanEnabled:
		applyZoomPanTransform()

func applyZoomPanTransform():
	$BackgroundImage.scale = Vector2(1.1,1.1)
	if DisplayMode.isLandscape():
		# Same 10% overscan as portrait, centered on the wider frame.
		$BackgroundImage.position = -Vector2(DisplayMode.getBaseSize()) * 0.05
	else:
		$BackgroundImage.position = Vector2(-50.0,-50.0)

func setBackground(newBackground):
	if background && (newBackground.name == background.name) && (!shouldFade || !shouldFadeQuick):
		return

	background = newBackground

	# Start loading now so fade transitions hide the load time.
	if background.imagePath != '':
		BackgroundCache.prefetch(background.imagePath)

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
		showPicture(background.getTexture())

func showPicture(texture):
	$BackgroundImage.texture = texture
	refreshPresentation()
	updatePictureVideo()

func videosFor(art : String) -> Array:
	if pictureVideos == null:
		pictureVideos = {}
		for path in PICTURE_VIDEO_LISTS:
			if ResourceLoader.exists(path):
				pictureVideos.merge(load(path).VIDEOS)
	return pictureVideos.get(art, [])

func updatePictureVideo():
	var art = background.imagePath if background else ''
	if art == pictureVideoArt:
		return
	stopPictureVideo()
	var videos = videosFor(art)
	if videos.is_empty() or isSkipping:
		return
	pictureVideoArt = art
	playPictureVideo(videos[pictureVideoChoice.get(art, 0) % videos.size()])

# The intro plays in a player of its own over the loop's, which takes over when it ends.
func introPlayer() -> VideoStreamPlayer:
	var intro = $VideoStreamPlayer.get_node_or_null("IntroPlayer")
	if intro == null:
		intro = VideoStreamPlayer.new()
		intro.name = "IntroPlayer"
		intro.expand = true
		intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$VideoStreamPlayer.add_child(intro)
		intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return intro

func playPictureVideo(video : Dictionary):
	pictureVideoToken += 1
	var token = pictureVideoToken
	var player = $VideoStreamPlayer
	player.modulate = Color.WHITE
	player.stream = load(video.video)
	player.loop = video.loop
	player.visible = true
	if video.has("intro"):
		var intro = introPlayer()
		intro.stream = load(video.intro)
		intro.visible = true
		intro.play()
		await intro.finished
		if token != pictureVideoToken:
			return
		# The intro holds its last frame until the loop has drawn its first.
		player.play()
		for i in 2:
			await get_tree().process_frame
		if token != pictureVideoToken:
			return
		intro.visible = false
		intro.stream = null
	else:
		player.play()
	if video.loop:
		return
	await player.finished
	if token != pictureVideoToken:
		return
	var tween = get_tree().create_tween()
	tween.tween_property(player, "modulate", Color.TRANSPARENT, 1).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	if token == pictureVideoToken:
		resetVideoPlayer()

func stopPictureVideo():
	if pictureVideoArt == '':
		return
	pictureVideoArt = ''
	pictureVideoToken += 1
	var intro = $VideoStreamPlayer.get_node_or_null("IntroPlayer")
	if intro:
		intro.stop()
		intro.stream = null
		intro.visible = false
	$VideoStreamPlayer.stop()
	$VideoStreamPlayer.loop = false
	resetVideoPlayer()

func _unhandled_key_input(event):
	if !OS.has_feature("editor") or !(event is InputEventKey) or !event.pressed or event.echo:
		return
	if event.physical_keycode != KEY_V or background == null:
		return
	var art = background.imagePath
	var videos = videosFor(art)
	if videos.size() < 2:
		return
	pictureVideoChoice[art] = (pictureVideoChoice.get(art, 0) + 1) % videos.size()
	stopPictureVideo()
	updatePictureVideo()
	var label = get_node_or_null("VideoChoiceLabel")
	if label == null:
		label = Label.new()
		label.name = "VideoChoiceLabel"
		label.position = Vector2(20, 20)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		add_child(label)
	var choice = pictureVideoChoice[art]
	label.text = "video %d of %d: %s" % [choice + 1, videos.size(), videos[choice].video.get_file()]
	label.visible = true
	var shown = label.text
	await get_tree().create_timer(3).timeout
	if label.text == shown:
		label.visible = false

# A picture put up at once by a set-piece that does its own fading (the reveal). Whatever the
# dialogue had queued for the picture (a fade, a frame change, a fade still on its way to black)
# is dropped: the set-piece replaces it.
func showNow(newBackground : Background):
	shouldFade = false
	shouldFadeQuick = false
	shouldFadeSlow = false
	pendingDisplayMode = null
	$FadeTimer.stop()
	background = newBackground
	showPicture(background.getTexture())

# A frame change the dialogue asked for that has not landed yet, cleared as it is taken.
func takePendingDisplayMode():
	var mode = pendingDisplayMode
	pendingDisplayMode = null
	return mode

func enableZoomPan():
	var mat = ShaderMaterial.new()
	mat.shader = zoompan
	$BackgroundImage.material = mat
	$BackgroundImage.material.set_shader_parameter("zoom_speed", 0.1)
	$BackgroundImage.material.set_shader_parameter("zoom_amount", 0.07)
	$BackgroundImage.material.set_shader_parameter("pan_speed", 0.3)
	$BackgroundImage.material.set_shader_parameter("pan_amount", 0.025)
	zoomPanEnabled = true
	$Camera.setSuspended(true)
	applyZoomPanTransform()

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
	zoomPanEnabled = false
	$BackgroundImage.material = null
	$BackgroundImage.scale = Vector2(1.0,1.0)
	$BackgroundImage.position = Vector2(0,0)
	$Camera.setSuspended(false)

# Plys for 3 seconds
func fadeVideo(playDuration := 5.5):
	$VideoStreamPlayer.visible = true
	$VideoStreamPlayer.play()
	await get_tree().create_timer(playDuration).timeout
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
	if background.name == 'lisa_poker_reward_0056.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/lisa_poker_reward/video/mas_1.ogv")
		fadeVideo()
	if background.name == 'lisa_poker_reward_0060.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/lisa_poker_reward/video/mas_2.ogv")
		fadeVideo()
	if background.name == 'lisa_poker_reward_0067.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/lisa_poker_reward/video/mas_3.ogv")
		fadeVideo()
	if background.name == 'anna_night_love_0017.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_night/video/anna_night_vid_1.ogv")
		fadeVideo(45)  # 46s video: play 45s, then 1s fade-out to line up with video_pause_46
	if background.name == 'anna_night_love_0012.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_night/video/anna_night_love_0012_vid.ogv")
		fadeVideo()
	if background.name == 'anna_night_love_0032.webp':
		$VideoStreamPlayer.stream = load("res://data/background_lists/anna_night/video/anna_night_love_0032_vid.ogv")
		fadeVideo()
	#if background.name == 'boa_strip_vid1':
	#	$VideoStreamPlayer.stream = load("res://data/background_lists/boa_poker_new/video/boa1.ogv")
	#	fadeVideo()

func _on_fade_timer_timeout():
	var newTexture = background.getTexture()
	var changed = $BackgroundImage.texture != newTexture
	# The black point of the fade: the one moment a frame change the dialogue asked for lands.
	# (A picture that arrives while the fade is still darkening shows without one, and waits.)
	var mode = takePendingDisplayMode()
	showPicture(newTexture)
	if mode != null and mode != DisplayMode.currentMode:
		frameChangeDue.emit(mode)
	if changed:
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
