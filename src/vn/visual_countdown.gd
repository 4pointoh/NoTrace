extends Control

signal countdown_finished

const MINUTE := 1.0
const HOUR := 60.0 * MINUTE
const DAY := 24.0 * HOUR
const WEEK := 7.0 * DAY

@onready var time_label: Label = %Time
@onready var unit_label: Label = %Unit

var _initial_minutes: float = 0.0
var _delay: int = 0
var _remaining_minutes: float = 0.0
var _countdown_duration: float = 0.0
var _countdown_elapsed: float = 0.0
var _is_counting_down := false

func _ready() -> void:
	set_process(false)
	_update_display()

func setTime(numberOfMinutes: int) -> void:
	_initial_minutes = max(numberOfMinutes, 0)
	_remaining_minutes = _initial_minutes
	_is_counting_down = false
	set_process(false)
	_update_display()

func setCountdownLabel(labelText: String) -> void:
	%CountdownLabel.text = labelText

func setButtonLabel(buttonText: String) -> void:
	%StartButton.text = buttonText

func setDelay(del : int):
	_delay = del

func start(delay: int) -> void:
	_countdown_duration = max(delay, 0)
	_countdown_elapsed = 0.0
	_remaining_minutes = _initial_minutes

	if _countdown_duration <= 0.0 or _remaining_minutes <= 0.0:
		_remaining_minutes = 0.0
		_update_display()
		animation_out()
		return

	_is_counting_down = true
	set_process(true)

func _process(delta: float) -> void:
	if not _is_counting_down:
		return

	_countdown_elapsed += delta
	var progress := 0.0

	if _countdown_duration > 0.0:
		progress = clamp(_countdown_elapsed / _countdown_duration, 0.0, 1.0)

	# Scale the visual timer to match the requested real-time delay.
	_remaining_minutes = max(_initial_minutes * (1.0 - progress), 0.0)
	_update_display()

	if is_equal_approx(progress, 1.0) or _remaining_minutes <= 0.0:
		_remaining_minutes = 0.0
		_update_display()
		animation_out()

func _finish_countdown() -> void:
	_is_counting_down = false
	set_process(false)
	emit_signal("countdown_finished")

func _update_display() -> void:
	if not (is_instance_valid(time_label) and is_instance_valid(unit_label)):
		return

	var unit_info := _select_unit(_remaining_minutes)
	time_label.text = _format_time(_remaining_minutes, unit_info["minutes_per_unit"])
	unit_label.text = unit_info["display_name"]

func _select_unit(minutes: float) -> Dictionary:
	var units: Array[Dictionary] = [
		{"minutes_per_unit": MINUTE, "display_name": "Minutes"},
		{"minutes_per_unit": HOUR, "display_name": "Hours"},
		{"minutes_per_unit": DAY, "display_name": "Days"},
		{"minutes_per_unit": WEEK, "display_name": "Weeks"}
	]

	var chosen: Dictionary = units[0]
	for unit in units:
		if minutes >= unit["minutes_per_unit"]:
			chosen = unit

	return chosen

func _format_time(minutes: float, minutes_per_unit: float) -> String:
	if minutes_per_unit == MINUTE:
		var whole_minutes := int(floor(minutes))
		var seconds := int(round((minutes - whole_minutes) * 60.0))
		if seconds == 60:
			whole_minutes += 1
			seconds = 0
		return "%d:%02d" % [max(whole_minutes, 0), max(seconds, 0)]

	var units_left := 0.0
	if minutes_per_unit > 0.0:
		units_left = minutes / minutes_per_unit
	var whole_units := int(floor(units_left))
	var remainder_minutes := minutes - float(whole_units) * minutes_per_unit

	var sub_minutes := MINUTE
	if minutes_per_unit == HOUR:
		sub_minutes = MINUTE
	elif minutes_per_unit == DAY:
		sub_minutes = HOUR
	elif minutes_per_unit == WEEK:
		sub_minutes = DAY

	var sub_value := int(floor(remainder_minutes / sub_minutes))
	return "%d:%02d" % [whole_units, sub_value]

func animation_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "custom_minimum_size:y", 0.0, .2)
	tween.tween_property(self, "size:y", 0.0, .2)
	tween.tween_callback(_finish_countdown)

func _on_button_pressed() -> void:
	start(_delay)

func _on_tree_entered() -> void:
	%NinePatchRect.size.y = 0.0
	var tween := create_tween()
	tween.tween_property(%NinePatchRect, "size:y", 200.0, .2)
	#tween.tween_property(self, "size:y", 257.0, .2)
