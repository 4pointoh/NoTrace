extends Node2D

signal sceneEnd

## Set this to skip ahead for debugging (e.g. 60.0 to start at 1 minute).
## Set to 0.0 for normal playback.
const DEBUG_START_TIME := 0.0
const END_TIME := 165.0
const SKIP_HIDE_DELAY := 1.5

var elapsed: float = 0.0
var current_index: int = 0
var timeline: Array = []
var use_lyric_a: bool = true
var use_bg1: bool = true
var active_bg_tween: Tween = null
var skip_hide_timer: Timer = null
var ending_started: bool = false
var scene_end_emitted: bool = false

const FADE_DURATION := 0.5

func _ready() -> void:
	timeline = get_timeline()
	timeline.sort_custom(func(a, b): return a["time"] < b["time"])
	%AudioStreamPlayer2D.volume_db = GlobalGameStage.getBgVolume()
	%FadeOverlay.color.a = 0.0
	%Skip.visible = false
	skip_hide_timer = Timer.new()
	skip_hide_timer.one_shot = true
	skip_hide_timer.wait_time = SKIP_HIDE_DELAY
	add_child(skip_hide_timer)
	skip_hide_timer.timeout.connect(_on_skip_hide_timer_timeout)
	
	if DEBUG_START_TIME > 0.0:
		# Skip elapsed time and audio to the debug point
		elapsed = DEBUG_START_TIME
		%AudioStreamPlayer2D.play(DEBUG_START_TIME)
		# Fire all events up to the start time instantly (last bg wins)
		while current_index < timeline.size() and timeline[current_index]["time"] <= DEBUG_START_TIME:
			dispatch_event(timeline[current_index])
			current_index += 1
	else:
		%AudioStreamPlayer2D.play()

func _process(delta: float) -> void:
	if scene_end_emitted:
		return
	elapsed += delta
	while current_index < timeline.size() and elapsed >= timeline[current_index]["time"]:
		dispatch_event(timeline[current_index])
		current_index += 1

func dispatch_event(event: Dictionary) -> void:
	match event["type"]:
		"crossfade":
			handle_crossfade(event)
		"bg_scroll":
			handle_bg_scroll(event)
		"lyric":
			handle_lyric(event)
		"lyric_clear":
			handle_lyric_clear()
		"zoom_in":
			handle_zoom_in(event)
		"zoom_and_pan":
			handle_zoom_and_pan(event)
		"scene_end":
			start_scene_end()

# ————— BG HELPERS —————

func get_active_bg() -> Sprite2D:
	return %bg1 if use_bg1 else %bg2

func get_inactive_bg() -> Sprite2D:
	return %bg2 if use_bg1 else %bg1

func swap_bg() -> void:
	use_bg1 = !use_bg1

func kill_active_tween() -> void:
	if active_bg_tween and active_bg_tween.is_valid():
		active_bg_tween.kill()
		active_bg_tween = null

func reset_bg(bg: Sprite2D) -> void:
	bg.centered = false
	bg.offset = Vector2.ZERO
	bg.scale = Vector2.ONE
	bg.position = Vector2.ZERO

## Fades in the inactive bg with a new image and fades out the active bg.
## Returns the newly-active TextureRect so callers can apply scroll/zoom on it.
func transition_to_new_bg(image_path: String, fade_duration: float = FADE_DURATION) -> Sprite2D:
	var fade_in_bg = get_inactive_bg()
	var fade_out_bg = get_active_bg()

	reset_bg(fade_in_bg)
	fade_in_bg.texture = load(image_path)
	fade_in_bg.modulate.a = 0.0

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_in_bg, "modulate:a", 1.0, fade_duration)
	tween.tween_property(fade_out_bg, "modulate:a", 0.0, fade_duration)

	swap_bg()
	return fade_in_bg

# ————— CROSSFADE —————

func handle_crossfade(event: Dictionary) -> void:
	kill_active_tween()
	var duration = event.get("duration", FADE_DURATION)
	var bg = transition_to_new_bg(event["image"], duration)
	if event.has("scale"):
		bg.scale = Vector2(event["scale"], event["scale"])

# ————— BG SCROLL —————
## Fades to a new (wide) image and scrolls it from start_offset to end_offset.
## Use start_offset to begin at an arbitrary point inside the image.

func handle_bg_scroll(event: Dictionary) -> void:
	kill_active_tween()
	var duration = event.get("duration", 5.0)
	var fade_duration = event.get("fade_duration", FADE_DURATION)
	var start_offset = event.get("start_offset", Vector2.ZERO)
	var end_offset = event.get("end_offset", Vector2(-500, 0))

	var bg: Sprite2D
	if event.has("image") and fade_duration > 0:
		bg = transition_to_new_bg(event["image"], fade_duration)
	else:
		bg = get_active_bg()
		if event.has("image"):
			reset_bg(bg)
			bg.texture = load(event["image"])
	if event.has("scale"):
		bg.scale = Vector2(event["scale"], event["scale"])
	bg.position = start_offset

	active_bg_tween = get_tree().create_tween()
	active_bg_tween.tween_property(bg, "position", end_offset, duration) \
		.set_trans(Tween.TRANS_LINEAR)

# ————— ZOOM IN —————
## Zooms into a point on the image. If "image" is provided, crossfades to it first.
## "center" sets the focal point of the zoom (pivot_offset).

func handle_zoom_in(event: Dictionary) -> void:
	kill_active_tween()
	var duration = event.get("duration", 5.0)
	var fade_duration = event.get("fade_duration", FADE_DURATION)
	var from_scale = event.get("from_scale", 1.0)
	var to_scale = event.get("to_scale", 1.5)
	var center = event.get("center", Vector2(240, 360))

	var bg: Sprite2D
	if event.has("image"):
		bg = transition_to_new_bg(event["image"], fade_duration)
	else:
		bg = get_active_bg()

	bg.offset = -center
	bg.position = center
	bg.scale = Vector2(from_scale, from_scale)

	active_bg_tween = get_tree().create_tween()
	active_bg_tween.tween_property(bg, "scale", Vector2(to_scale, to_scale), duration) \
		.set_trans(Tween.TRANS_LINEAR)

# ————— ZOOM AND PAN —————
## Zooms and pans simultaneously (Ken Burns effect).
## Tweens both scale (around center) and position from start_offset to end_offset.

func handle_zoom_and_pan(event: Dictionary) -> void:
	kill_active_tween()
	var duration = event.get("duration", 5.0)
	var fade_duration = event.get("fade_duration", FADE_DURATION)
	var from_scale = event.get("from_scale", 1.0)
	var to_scale = event.get("to_scale", 1.3)
	var center = event.get("center", Vector2(240, 360))
	var start_offset = event.get("start_offset", Vector2.ZERO)
	var end_offset = event.get("end_offset", Vector2.ZERO)

	var bg: Sprite2D
	if event.has("image"):
		bg = transition_to_new_bg(event["image"], fade_duration)
	else:
		bg = get_active_bg()

	bg.offset = -center
	bg.position = center + start_offset
	bg.scale = Vector2(from_scale, from_scale)

	active_bg_tween = get_tree().create_tween()
	active_bg_tween.set_parallel(true)
	active_bg_tween.tween_property(bg, "scale", Vector2(to_scale, to_scale), duration) \
		.set_trans(Tween.TRANS_LINEAR)
	active_bg_tween.tween_property(bg, "position", center + end_offset, duration) \
		.set_trans(Tween.TRANS_LINEAR)

# ————— LYRICS —————

func handle_lyric(event: Dictionary) -> void:
	var text = event["text"]
	if use_lyric_a:
		%LyricA.text = text
	else:
		%LyricB.text = text
	slide_in_lyric()
	use_lyric_a = !use_lyric_a

func handle_lyric_clear() -> void:
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(%LyricA, "modulate:a", 0.0, 0.3)
	tween.tween_property(%LyricB, "modulate:a", 0.0, 0.3)

func slide_in_lyric() -> void:
	var relevant_lyric: Label
	var other_lyric: Label

	if use_lyric_a:
		relevant_lyric = %LyricA
		other_lyric = %LyricB
	else:
		relevant_lyric = %LyricB
		other_lyric = %LyricA

	relevant_lyric.modulate.a = 1.0
	relevant_lyric.position = %Clipper.position
	relevant_lyric.position.y += %Clipper.size.y

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(relevant_lyric, "position:y", %Clipper.position.y, 0.15)
	tween.tween_property(other_lyric, "position:y", %Clipper.position.y - %Clipper.size.y, 0.15)

# ————— ENDING / SKIP —————

func start_scene_end() -> void:
	if ending_started or scene_end_emitted:
		return
	ending_started = true
	%Skip.visible = false
	if skip_hide_timer:
		skip_hide_timer.stop()
	var tween = get_tree().create_tween()
	tween.tween_property(%FadeOverlay, "color:a", 1.0, FADE_DURATION)
	tween.finished.connect(_emit_scene_end)

func _emit_scene_end() -> void:
	if scene_end_emitted:
		return
	scene_end_emitted = true
	emit_signal("sceneEnd")

func _show_skip_button() -> void:
	if ending_started or scene_end_emitted:
		return
	%Skip.visible = true
	if skip_hide_timer:
		skip_hide_timer.start(SKIP_HIDE_DELAY)

func _on_skip_hide_timer_timeout() -> void:
	if ending_started or scene_end_emitted:
		return
	%Skip.visible = false

# ————— TIMELINE DATA —————

func get_timeline() -> Array:
	var img = "res://data/background_lists/anna_music_video/ana_music_video_"
	return [
		# ——— Scene 1: Standing on stage — crossfade + slow zoom ———
		{"time": 0.0, "type": "bg_scroll", "image": img + "0006.webp",
			"duration": 11.0,
			"start_offset": Vector2(-1200, -0), "end_offset": Vector2(-1000, 0)},

		# Lyric 1
		{"time": 0.0, "type": "lyric",
			"text": "My face is plastered on the sunset strip"},

		# Lyric 2
		{"time": 6.5, "type": "lyric",
			"text": "But I'm sitting here biting my lip"},

		{"time": 11.0, "type": "zoom_in", "image": img + "30.webp",
			"duration": 12.0, "from_scale": 1.0, "to_scale": 1.1,
			"center": Vector2(100, 100)},

		# Lyric 3
		{"time": 12.0, "type": "lyric",
			"text": "One million followers refreshing my feed"},

		# Lyric 4
		{"time": 17.5, "type": "lyric",
			"text": "While I'm looking for the oxygen I actually need"},
		
		{"time": 23.0, "type": "zoom_in", "image": img + "0007.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.02,
			"center": Vector2(100, 100), "fade_duration": 1.0},
		
		{"time": 23.0, "type": "lyric",
			"text": "You're counting change for a soda, in the machine"},
		
		{"time": 28.0, "type": "lyric",
			"text": "While I'm the artist of the year, in a magazine"},

		{"time": 34.5, "type": "lyric",
			"text": "I'm rubbing the stage paint off of my skin"},
		{"time": 37.3, "type": "lyric",
			"text": "Trying to find where the real me begins"},
		{"time": 40.0, "type": "lyric",
			"text": "You didn't ask for a photo or a front row seat"},
		{"time": 43.0, "type": "lyric",
			"text": "You just asked why I'm shivering here on the street"},
		{"time": 48.2, "type": "lyric",
			"text": "Don't google my name"},
		{"time": 50.4, "type": "lyric",
			"text": "Don't scroll through the tags"},
		{"time": 54.2, "type": "lyric",
			"text": "Let me stay here in my thrift store rags"},
		{"time": 59.5, "type": "lyric",
			"text": "I'm a platinum record in a cardboard sleeve"},
		{"time": 65.0, "type": "lyric",
			"text": "Give me one more hour before I gotta' leave"},
		{"time": 71.0, "type": "lyric",
			"text": "See the girl not the ghost of the girl on the screen"},
		{"time": 77.0, "type": "lyric",
			"text": "The quietest person you've ever seen"},
		{"time": 82.0, "type": "lyric",
			"text": "We're sitting on the curb just watching the cars"},
		{"time": 84.6, "type": "lyric",
			"text": "I'm pointing at clouds, you're pointing at stars"},
		{"time": 87.7, "type": "lyric",
			"text": "You notice the glitter on my cheek"},
		{"time": 92.0, "type": "lyric",
			"text": "I laugh it off and scrub it away"},
		{"time": 96.0, "type": "lyric",
			"text": "Just a craft project from earlier today."},
		{"time": 102.0, "type": "lyric",
			"text": "In five minutes my driver will pull to the curb"},
		{"time": 104.9, "type": "lyric",
			"text": "And I'll go back to the world where I'm just a word"},
		{"time": 107.9, "type": "lyric",
			"text": "A brand. A Product. A face on a wall."},
		{"time": 110.4, "type": "lyric",
			"text": "But you're the only one who didn't look at it all."},
		{"time": 113.0, "type": "lyric",
			"text": "Stay oblivious"},
		{"time": 114.4, "type": "lyric",
			"text": "Stay exactly this way"},
		{"time": 118.3, "type": "lyric",
			"text": "Keep the super star version of me at bay"},
		{"time": 123.6, "type": "lyric",
			"text": "Don't google my name"},
		{"time": 125.6, "type": "lyric",
			"text": "Don't scroll through the tags"},
		{"time": 129.4, "type": "lyric",
			"text": "Let me stay here in my thrift store rags"},
		{"time": 134.7, "type": "lyric",
			"text": "I'm a platinum record in a cardboard sleeve"},
		{"time": 140.2, "type": "lyric",
			"text": "Give me one more hour before I gotta' leave"},
		{"time": 145.9, "type": "lyric",
			"text": "See the girl not the ghost of the girl on the screen"},
		{"time": 152.0, "type": "lyric",
			"text": "The quietest person you've ever seen"},
			

		{"time": 28.0, "type": "zoom_in", "image": img + "0008.webp",
			"duration": 8.0, "from_scale": 1.0, "to_scale": 1.2,
			"center": Vector2(1100, 1000), "fade_duration": 1.0},
		
		{"time": 34.0, "type": "zoom_in", "image": img + "0009.webp",
			"duration": 14.0, "from_scale": 1.0, "to_scale": 1.2,
			"center": Vector2(100, 100), "fade_duration": 1.0},
		
		{"time": 48.0, "type": "bg_scroll", "image": img + "0011.webp",
			"duration": 11.5,
			"start_offset": Vector2(-1200, -0), "end_offset": Vector2(-1000, 0)},
		
		{"time": 59.5, "type": "zoom_in", "image": img + "0012.webp",
			"duration": 11.0, "from_scale": 0.85, "to_scale": .9,
			"center": Vector2(0, 0), "fade_duration": 1.0},
		
		{"time": 70.0, "type": "crossfade", "image": img + "0014.webp", "duration": 1.0, "scale": 0.75},

		#{"time": 71.5, "type": "bg_scroll", "image": img + "0014.webp", "fade_duration": 0.0, 
		#	"duration": 5.0, "scale": 0.75,
		#	"start_offset": Vector2(0, 0), "end_offset": Vector2(-1000, 0)},
		
		{"time": 82.0, "type": "zoom_in", "image": img + "0015.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 88.0, "type": "zoom_in", "image": img + "0017.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 92.0, "type": "zoom_in", "image": img + "0018.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 96.0, "type": "zoom_in", "image": img + "0016.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 102.3, "type": "zoom_in", "image": img + "0010.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 104.7, "type": "zoom_in", "image": img + "0019.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 107.6, "type": "zoom_in", "image": img + "0021.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 110.3, "type": "zoom_in", "image": img + "0023.webp",
			"duration": 5.0, "from_scale": .85, "to_scale": .9,
			"center": Vector2(0, 0), "fade_duration": 1.0},
		
		{"time": 113.0, "type": "zoom_in", "image": img + "0024.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 118.3, "type": "zoom_in", "image": img + "0025.webp",
			"duration": 5.0, "from_scale": .75, "to_scale": .755,
			"center": Vector2(0, 0), "fade_duration": 1.0},

		{"time": 123.5, "type": "zoom_in", "image": img + "0028.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 125.0, "type": "zoom_in", "image": img + "30.webp",
			"duration": 5.0, "from_scale": 1.0, "to_scale": 1.05,
			"center": Vector2(600, 800), "fade_duration": 1.0},
		
		{"time": 129.2, "type": "bg_scroll", "image": img + "0011.webp",
			"duration": 11.5, "fade_duration": 2.0,
			"start_offset": Vector2(-1200, -0), "end_offset": Vector2(-1000, 0)},
		
		{"time": 140.2, "type": "zoom_in", "image": img + "0012.webp",
			"duration": 11.0, "from_scale": .85, "to_scale": .9,
			"center": Vector2(0, 0), "fade_duration": 1.0},
		
		{"time": 145.9, "type": "crossfade", "image": img + "0014.webp", "duration": 1.0, "scale": 0.75},

		{"time": 149.0, "type": "bg_scroll", "image": img + "0014.webp", "fade_duration": 0.0, 
			"duration": 8.0, "scale": 0.75,
			"start_offset": Vector2(0, 0), "end_offset": Vector2(-1010, 0)},

		{"time": END_TIME, "type": "scene_end"},

	]


# func get_timeline() -> Array:
# 	var img = "res://data/background_lists/anna_music_video/ana_music_video_"
# 	return [
# 		# ——— Scene 1: Standing on stage — crossfade + slow zoom ———
# 		{"time": 0.0, "type": "bg_scroll", "image": img + "0006.webp",
# 			"duration": 11.0,
# 			"start_offset": Vector2(-1200, -0), "end_offset": Vector2(-1000, 0)},

# 		# Lyric 1
# 		{"time": 0.0, "type": "lyric",
# 			"text": "My face is plastered on the sunset strip"},

# 		# Lyric 2
# 		{"time": 2.5, "type": "lyric",
# 			"text": "But I'm sitting here biting my lip"},

# 		{"time": 11.0, "type": "zoom_in", "image": img + "0005.webp",
# 			"duration": 10.0, "from_scale": 1.0, "to_scale": 1.1,
# 			"center": Vector2(100, 100)},

# 		# Lyric 3
# 		{"time": 8.5, "type": "lyric",
# 			"text": "One million followers refreshing my feed"},

# 		# Lyric 4
# 		{"time": 12.0, "type": "lyric",
# 			"text": "While I'm looking for the oxygen I actually need"},

# 		# ——— Scene 3: Soda machine — bg_scroll (wide panning shot) ———
# 		{"time": 15.5, "type": "bg_scroll", "image": img + "0003.webp",
# 			"duration": 8.0,
# 			"start_offset": Vector2(0, 0), "end_offset": Vector2(-400, 0)},

# 		# Lyric 5
# 		{"time": 16.0, "type": "lyric",
# 			"text": "You're counting change for a soda, in the machine"},

# 		# ——— Scene 4: Magazine — zoom_and_pan (Ken Burns) ———
# 		{"time": 20.0, "type": "zoom_and_pan", "image": img + "0004.webp",
# 			"duration": 6.0, "from_scale": 1.0, "to_scale": 1.4,
# 			"center": Vector2(240, 200),
# 			"start_offset": Vector2(0, 0), "end_offset": Vector2(-80, -30)},

# 		# Lyric 6
# 		{"time": 20.5, "type": "lyric",
# 			"text": "While I'm the artist of the year, in a magazine"},

# 		# ——— Scene 5: Cleaning makeup — crossfade ———
# 		{"time": 26.0, "type": "crossfade", "image": img + "0005.webp", "duration": 1.0},

# 		# Lyric 7
# 		{"time": 26.5, "type": "lyric",
# 			"text": "I'm rubbing the stage paint off of my skin"},

# 		# Lyric 8
# 		{"time": 30.0, "type": "lyric",
# 			"text": "Trying to find where the real me begins"},

# 		# ——— Scene 6: zoom_in on close-up ———
# 		{"time": 33.5, "type": "zoom_in", "image": img + "0006.webp",
# 			"duration": 7.0, "from_scale": 1.0, "to_scale": 1.3,
# 			"center": Vector2(240, 280)},

# 		# Lyric 9
# 		{"time": 34.0, "type": "lyric",
# 			"text": "You didn't ask for a photo or a front row seat"},

# 		# Lyric 10
# 		{"time": 37.5, "type": "lyric",
# 			"text": "You just asked why I'm shivering here on the street"},

# 		# Clear lyrics after last test line
# 		{"time": 41.0, "type": "lyric_clear"},
# 	]

# ————— DEBUG —————

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DebuButton"):
		print(elapsed)
	if event is InputEventMouseMotion:
		_show_skip_button()


func _on_skip_pressed() -> void:
	_emit_scene_end()
