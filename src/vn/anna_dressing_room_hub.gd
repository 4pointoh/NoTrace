extends Control

const IMAGE_W := 2096
const VIEW_W := 896
const PAN_MIN := float(VIEW_W - IMAGE_W)  # -1200
const PAN_MAX := 0.0
const PAN_STEP := 400.0
const PAN_TWEEN_SEC := 0.3

const GlowTexture := preload("res://data/background_lists/anna_night/changing_room/glow_texture.webp")

signal outfit_selected(outfit_name: String)
signal skip_to_rewards_requested
signal done_browsing_requested

var glow: TextureRect

func _ready() -> void:
	_build_glow()
	%LeftArrow.pressed.connect(_pan_by.bind(PAN_STEP))
	%RightArrow.pressed.connect(_pan_by.bind(-PAN_STEP))
	%SkipToRewards.pressed.connect(_on_skip_pressed)
	%DoneBrowsing.pressed.connect(_on_done_pressed)
	for child in %Pan.get_children():
		if child is Button:
			child.pressed.connect(_on_hotspot_pressed.bind(child.name))
			child.mouse_entered.connect(_on_hotspot_hover.bind(child))
			child.mouse_exited.connect(_on_hotspot_unhover)
	_update_arrows()

func _build_glow() -> void:
	glow = TextureRect.new()
	glow.texture = GlowTexture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	%Pan.add_child(glow)
	# Render order: HubImage(0), Glow(1), then the hotspot Buttons on top.
	%Pan.move_child(glow, 1)

func _on_hotspot_hover(btn: Button) -> void:
	if btn.disabled:
		return
	glow.position = btn.position
	glow.size = btn.size
	glow.visible = true

func _on_hotspot_unhover() -> void:
	glow.visible = false

func enable_all_outfits() -> void:
	for child in %Pan.get_children():
		if child is Button:
			child.disabled = false

func restrict_to_outfits(names: Array) -> void:
	for child in %Pan.get_children():
		if child is Button:
			child.disabled = not (child.name in names)

func _pan_by(dx: float) -> void:
	var target_x: float = clamp(%Pan.position.x + dx, PAN_MIN, PAN_MAX)
	var tween := create_tween()
	tween.tween_property(%Pan, "position:x", target_x, PAN_TWEEN_SEC)
	tween.tween_callback(_update_arrows)

func _update_arrows() -> void:
	%LeftArrow.disabled = %Pan.position.x >= PAN_MAX - 0.5
	%RightArrow.disabled = %Pan.position.x <= PAN_MIN + 0.5

func _on_hotspot_pressed(outfit_name: String) -> void:
	outfit_selected.emit(outfit_name)

func reset_pan() -> void:
	%Pan.position.x = 0
	_update_arrows()

func _on_skip_pressed() -> void:
	skip_to_rewards_requested.emit()

func set_skip_button_visible(v: bool) -> void:
	%SkipToRewards.visible = v

func _on_done_pressed() -> void:
	done_browsing_requested.emit()

func set_done_button_visible(v: bool) -> void:
	%DoneBrowsing.visible = v
	%DoneBrowsingLabel.visible = v
