extends Node2D

const SCREEN_W := 896
const SCREEN_H := 1152
const PANEL_W := SCREEN_W / 2
const PANEL_H := SCREEN_H / 2

const SCRIPTS_DIR := "res://data/scripts/anna_dressing_room/"
const STARTING_SCRIPT := "hub_intro"
const HUB_FADE_SEC := 0.3
const MAX_OUTFITS_TO_TRY := 3
const POST_PICK_DELAY := 0.6

# Line spoken by the player when picking an outfit during the trying phase.
# Falls back to a generic line if an outfit isn't listed here.
const OUTFIT_PICK_LINES := {
	"lion": "the lion onesie!",
	"clown": "🤡",
	"daisyduke": "I've always thought you were a cowgirl at heart, how about the daisy dukes?",
	"fairy": "What is that one?",
	"formal": "What's that black one?",
	"goth": "The other nurse outfit!",
	"nurse": "The nurse outfit",
	"punk": "how about the punk look",
	"swim": "the swimsuit?",
	"workout": "the workout one",
	"ballet": "Is that a ballet outfit?",
}

# Line spoken by the player when picking their favorite at the end.
const OUTFIT_FAVORITE_LINES := {
	"lion": "the lion onesie was my favorite!",
	"clown": "You know which one.",
	"daisyduke": "The daisy dukes for sure",
	"fairy": "The fairy outfit was so surreal, how about that one?",
	"formal": "the black dress, you looked stunning",
	"goth": "That vampire one... it awoke something in me...",
	"nurse": "The nurse!",
	"punk": "the punk look",
	"swim": "the swimsuit",
	"workout": "the workout fit",
	"ballet": "I think it has to be the color-changing ballet outfit that was my favorite.",
}

const ANNA_FIRST_DELAY := 1.2
const ANNA_RUN_DELAY := 0.8
# Time Anna spends "reading" a player message before her typing starts.
const ANNA_READ_DELAY := 1.2
const POS_TWEEN_SEC := 0.25
const HIDE_FADE_SEC := 0.2
const BG_FADE_SEC := 0.35
const HIDE_BUTTON_SIZE := Vector2(96, 40)
const SEND_BUTTON_SIZE := Vector2(96, 40)
const MENU_BAR_HEIGHT := 48
const BUTTON_PAD := 4

const MessageTextScene := preload("res://src/phone/message_text.tscn")
const TypingScene := preload("res://src/phone/phone_loading.tscn")
const HubScene := preload("res://src/vn/anna_dressing_room_hub.tscn")
const ChangingRoomBg := preload("res://data/background_lists/anna_night/changing_room/studio_4.webp")
const RoundedRectTexture := preload("res://data/assets/date/art/transparent_purple_bright_rounded_rect_8px9patch.png")
const ROUNDED_RECT_MARGIN := 8

const SOUND_TYPING := preload("res://data/assets/phone/sounds/click.wav")
const SOUND_RECEIVED := preload("res://data/assets/phone/sounds/message_sent.wav")
const SOUND_SENT := preload("res://data/assets/phone/sounds/noti1.wav")
const SOUND_CAMERA := preload("res://data/assets/general/sound_effects/camera_click.mp3")

# Camera-shot flash: a soft, slow fade-in from white (not a harsh strobe).
# Beat before a camera shot — Anna lining up and taking the photo.
const CAMERA_SHOT_DELAY := 1.0
const CAMERA_FLASH_PEAK := 0.8
const CAMERA_FLASH_IN_SEC := 0.12
const CAMERA_FLASH_OUT_SEC := 0.85

var panel: Control
var scroll: ScrollContainer
var vbox: VBoxContainer
var hide_button: Button
var send_button: Button
var return_button: Button
var audio: AudioStreamPlayer
var hub: Control
var flash: ColorRect

var current_quadrant := "tl"
var panel_hidden := false
var previous_was_anna := false
var previous_was_player := false
var awaiting_advance := false

signal _advance_requested
signal _return_requested
signal script_finished(script_name: String)
signal scene_ended

var tried_outfits: Array[String] = []
var picking_favorite := false

func _ready() -> void:
	GlobalGameStage.resetAnnaDressingRoomTranscript()
	audio = AudioStreamPlayer.new()
	add_child(audio)
	_build_flash()
	_build_panel()
	_build_hub()
	script_finished.connect(_on_script_finished)
	play_script(STARTING_SCRIPT)

func _build_hub() -> void:
	hub = HubScene.instantiate()
	hub.visible = false
	hub.modulate.a = 0.0
	hub.outfit_selected.connect(_on_outfit_selected)
	add_child(hub)

func _build_flash() -> void:
	# White overlay used for the camera-shot flash. Built before the panel so
	# it covers the photo but never the phone UI on top of it.
	flash = ColorRect.new()
	flash.name = "CameraFlash"
	flash.color = Color(1, 1, 1, 0)
	flash.position = Vector2.ZERO
	flash.size = Vector2(SCREEN_W, SCREEN_H)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

func _play_sound(stream: AudioStream) -> void:
	audio.stream = stream
	audio.play()

func _build_panel() -> void:
	panel = Control.new()
	panel.name = "TextingPanel"
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.position = _quadrant_pos(current_quadrant)
	add_child(panel)

	var panel_bg := _make_rounded_bg(Vector2(PANEL_W, PANEL_H))
	panel.add_child(panel_bg)

	var menu_bg := _make_rounded_bg(Vector2(PANEL_W, MENU_BAR_HEIGHT))
	menu_bg.position = Vector2(0, PANEL_H - MENU_BAR_HEIGHT)
	panel.add_child(menu_bg)

	scroll = ScrollContainer.new()
	scroll.size = Vector2(PANEL_W, PANEL_H - MENU_BAR_HEIGHT)
	scroll.position = Vector2(0, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# Send button lives in the menu bar (bottom-right of panel) and fades with the panel.
	send_button = Button.new()
	send_button.text = "Send"
	send_button.size = SEND_BUTTON_SIZE
	send_button.position = Vector2(
		PANEL_W - SEND_BUTTON_SIZE.x - BUTTON_PAD,
		PANEL_H - MENU_BAR_HEIGHT + BUTTON_PAD
	)
	send_button.disabled = true
	send_button.pressed.connect(_on_send_pressed)
	panel.add_child(send_button)

	# Continue button sits centered in the menu bar between Hide and Send so it
	# can't be hit by rapid Send clicks. Hidden until the script ends.
	return_button = Button.new()
	return_button.text = "Continue"
	return_button.size = SEND_BUTTON_SIZE
	return_button.position = Vector2(
		(PANEL_W - SEND_BUTTON_SIZE.x) / 2.0,
		PANEL_H - MENU_BAR_HEIGHT + BUTTON_PAD
	)
	return_button.visible = false
	return_button.pressed.connect(_on_return_pressed)
	panel.add_child(return_button)

	# Hide button visually sits in the menu bar (bottom-left of panel) but is a sibling
	# of the panel so it stays visible when the panel fades out.
	hide_button = Button.new()
	hide_button.text = "Hide"
	hide_button.size = HIDE_BUTTON_SIZE
	hide_button.pressed.connect(_on_hide_pressed)
	add_child(hide_button)
	hide_button.position = _hide_button_pos_for(current_quadrant)

func _make_rounded_bg(size: Vector2) -> NinePatchRect:
	var rect := NinePatchRect.new()
	rect.texture = RoundedRectTexture
	rect.patch_margin_left = ROUNDED_RECT_MARGIN
	rect.patch_margin_top = ROUNDED_RECT_MARGIN
	rect.patch_margin_right = ROUNDED_RECT_MARGIN
	rect.patch_margin_bottom = ROUNDED_RECT_MARGIN
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _quadrant_pos(q: String) -> Vector2:
	var right_x := SCREEN_W - PANEL_W
	var bottom_y := SCREEN_H - PANEL_H
	match q:
		"tl": return Vector2(0, 0)
		"tr": return Vector2(right_x, 0)
		"bl": return Vector2(0, bottom_y)
		"br": return Vector2(right_x, bottom_y)
	return Vector2(0, 0)

func _hide_button_pos_for(q: String) -> Vector2:
	# Bottom-left of the panel's menu bar, in global coords.
	var p := _quadrant_pos(q)
	return Vector2(p.x + BUTTON_PAD, p.y + PANEL_H - MENU_BAR_HEIGHT + BUTTON_PAD)

func play_script(script_name: String) -> void:
	# Note: vbox is intentionally NOT cleared. The conversation continues across
	# scripts so the player sees one seamless thread.
	_set_awaiting_advance(false)
	panel_hidden = false
	hide_button.text = "Hide"
	panel.modulate.a = 1.0
	return_button.visible = false

	var path := SCRIPTS_DIR + script_name + ".txt"
	if not FileAccess.file_exists(path):
		push_error("Script not found: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var entries := parse_script(text)
	await _run(entries)

	# Script done — show the Continue button and wait for the player to click it
	# before notifying listeners. This lets them read the last messages.
	return_button.visible = true
	await _return_requested
	return_button.visible = false
	script_finished.emit(script_name)

func parse_script(text: String) -> Array:
	var entries: Array = []
	for raw_line in text.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("a:"):
			entries.append({"type": "anna", "text": line.substr(2).strip_edges()})
		elif line.begins_with("p:"):
			entries.append({"type": "player", "text": line.substr(2).strip_edges()})
		elif line.begins_with("delay:"):
			var raw := line.substr(6).strip_edges()
			if raw.is_valid_float():
				entries.append({"type": "delay", "seconds": raw.to_float()})
			else:
				push_error("Invalid delay value: " + line)
		elif line.begins_with("img:"):
			entries.append({"type": "img", "path": line.substr(4).strip_edges()})
		elif line.begins_with("pos:"):
			var q := line.substr(4).strip_edges()
			if q == "tl" or q == "tr" or q == "bl" or q == "br":
				entries.append({"type": "pos", "quadrant": q})
			else:
				push_error("Invalid pos value: " + line)
		else:
			push_error("Unknown directive: " + line)
	return entries

func _run(entries: Array) -> void:
	for entry in entries:
		match entry.type:
			"anna":
				if previous_was_anna:
					await get_tree().create_timer(ANNA_RUN_DELAY).timeout
				else:
					if previous_was_player:
						# Let Anna "read" the player's message before she
						# starts typing back.
						await get_tree().create_timer(ANNA_READ_DELAY).timeout
					var spinner := _show_typing()
					await get_tree().create_timer(ANNA_FIRST_DELAY).timeout
					if is_instance_valid(spinner):
						spinner.queue_free()
				_add_bubble(false, entry.text)
				previous_was_anna = true
				previous_was_player = false
			"player":
				_set_awaiting_advance(true)
				await _advance_requested
				_set_awaiting_advance(false)
				_add_bubble(true, entry.text)
				previous_was_anna = false
				previous_was_player = true
			"img":
				if ResourceLoader.exists(entry.path):
					# studio_3 / studio_4 are framing backdrops, not part of the
					# conversation, so don't mirror them onto the phone.
					if not ("studio_3" in entry.path or "studio_4" in entry.path):
						GlobalGameStage.recordAnnaDressingRoomMessage({
							"type": "image",
							"path": entry.path,
						})
					await _swap_bg(entry.path)
				else:
					push_error("Missing image: " + entry.path)
			"delay":
				await get_tree().create_timer(entry.seconds).timeout
				# Force the next anna message to show the typing animation,
				# the same as the first message in a sequence.
				previous_was_anna = false
				# An explicit delay is authoritative — don't also stack the
				# player-read delay on top of it.
				previous_was_player = false
			"pos":
				_move_panel(entry.quadrant)

func _set_awaiting_advance(value: bool) -> void:
	awaiting_advance = value
	send_button.disabled = not value

func _show_typing() -> Node:
	var spinner := TypingScene.instantiate()
	vbox.add_child(spinner)
	spinner.play()
	_play_sound(SOUND_TYPING)
	_scroll_to_bottom_deferred()
	return spinner

func _substitute_placeholders(text: String) -> String:
	var player_name: String = GlobalGameStage.playerName
	text = text.replace("{player_name_caps}", player_name.to_upper())
	text = text.replace("{player_name}", player_name)
	return text

func _add_bubble(is_player: bool, text: String) -> void:
	text = _substitute_placeholders(text)
	var msg := MessageTextScene.instantiate()
	msg.size_flags_horizontal = Control.SIZE_SHRINK_END if is_player else Control.SIZE_SHRINK_BEGIN
	vbox.add_child(msg)
	msg.setMessage(is_player, text, "Anna")
	GlobalGameStage.recordAnnaDressingRoomMessage({
		"type": "player_text" if is_player else "partner_text",
		"content": text,
	})
	_play_sound(SOUND_SENT if is_player else SOUND_RECEIVED)
	_scroll_to_bottom_deferred()

func _scroll_to_bottom_deferred() -> void:
	# Wait two frames so the new child's size is computed before we scroll.
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(vbox.size.y)

func _swap_bg(path: String) -> void:
	# studio_3 / studio_4 are framing backdrops (plain fade through black).
	# Every other photo is an in-fiction camera shot: click + white flash.
	if "studio_3" in path or "studio_4" in path:
		await _fade_swap_bg(path)
	else:
		await _camera_swap_bg(path)

func _camera_swap_bg(path: String) -> void:
	# Give Anna a beat to actually take the photo instead of it snapping in
	# the instant the player hits send.
	await get_tree().create_timer(CAMERA_SHOT_DELAY).timeout
	_play_sound(SOUND_CAMERA)
	# Soft, quick rise to white, swap behind the white, then a slow-ish
	# fade back in — reads as a gentle flash, not a harsh strobe.
	var up_tween := create_tween()
	up_tween.tween_property(flash, "color:a", CAMERA_FLASH_PEAK, CAMERA_FLASH_IN_SEC)
	await up_tween.finished
	(%bg as TextureRect).texture = load(path)
	var down_tween := create_tween()
	down_tween.tween_property(flash, "color:a", 0.0, CAMERA_FLASH_OUT_SEC)
	await down_tween.finished

func _fade_swap_bg(path: String) -> void:
	# The bg TextureRect sits over a black ColorRect, so fading its modulate
	# alpha reveals black underneath.
	var bg: TextureRect = %bg
	var out_tween := create_tween()
	out_tween.tween_property(bg, "modulate:a", 0.0, BG_FADE_SEC)
	await out_tween.finished
	bg.texture = load(path)
	var in_tween := create_tween()
	in_tween.tween_property(bg, "modulate:a", 1.0, BG_FADE_SEC)
	await in_tween.finished

func _move_panel(q: String) -> void:
	current_quadrant = q
	var tween := create_tween()
	tween.tween_property(panel, "position", _quadrant_pos(q), POS_TWEEN_SEC)
	tween.parallel().tween_property(hide_button, "position", _hide_button_pos_for(q), POS_TWEEN_SEC)

func _on_send_pressed() -> void:
	if awaiting_advance:
		_advance_requested.emit()

func _on_return_pressed() -> void:
	_return_requested.emit()

func _on_hide_pressed() -> void:
	panel_hidden = not panel_hidden
	hide_button.text = "Show" if panel_hidden else "Hide"
	var target_a: float = 0.0 if panel_hidden else 1.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", target_a, HIDE_FADE_SEC)

func _on_script_finished(script_name: String) -> void:
	if script_name == "hub_intro":
		await _enter_hub()
	elif script_name == "pick_favorite":
		picking_favorite = true
		hub.restrict_to_outfits(tried_outfits)
		await _enter_hub()
	elif script_name == "goodbye":
		scene_ended.emit()
		GlobalGameStage.stopBespoke('Anna Dressing Room')
	elif script_name == "already_tried":
		await _enter_hub()
	elif script_name.ends_with("_reward"):
		play_script("goodbye")
	elif script_name.ends_with("_intro"):
		if tried_outfits.size() >= MAX_OUTFITS_TO_TRY:
			play_script("pick_favorite")
		else:
			await _enter_hub()
	else:
		push_error("Unhandled script_finished: " + script_name)

func _on_outfit_selected(outfit_name: String) -> void:
	await _exit_hub()
	if picking_favorite:
		picking_favorite = false
		await _inject_player_line(OUTFIT_FAVORITE_LINES.get(outfit_name, "i liked " + outfit_name + " the best"))
		play_script(outfit_name + "_reward")
	else:
		await _inject_player_line(OUTFIT_PICK_LINES.get(outfit_name, "how about " + outfit_name + "?"))
		if outfit_name in tried_outfits:
			play_script("already_tried")
		else:
			tried_outfits.append(outfit_name)
			play_script(outfit_name + "_intro")

func _inject_player_line(text: String) -> void:
	_add_bubble(true, text)
	previous_was_anna = false
	previous_was_player = true
	await get_tree().create_timer(POST_PICK_DELAY).timeout

func _enter_hub() -> void:
	hub.visible = true
	hub.reset_pan()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hub, "modulate:a", 1.0, HUB_FADE_SEC)
	tween.tween_property(panel, "modulate:a", 0.0, HUB_FADE_SEC)
	tween.tween_property(%bg, "modulate:a", 0.0, HUB_FADE_SEC)
	await tween.finished
	hide_button.visible = false

func _exit_hub() -> void:
	hide_button.visible = true
	# Reset bg to the changing room so scripts can open with transition dialogue
	# (no leading img:) and have a sensible backdrop instead of black or the
	# previous outfit's image. Texture is swapped while bg is still invisible.
	%bg.texture = ChangingRoomBg
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hub, "modulate:a", 0.0, HUB_FADE_SEC)
	tween.tween_property(panel, "modulate:a", 1.0, HUB_FADE_SEC)
	tween.tween_property(%bg, "modulate:a", 1.0, HUB_FADE_SEC)
	await tween.finished
	hub.visible = false
