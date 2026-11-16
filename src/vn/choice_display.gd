extends Node2D

# The choice menu: a title over the choices (src/choice_display_button.tscn), on a frosted panel
# that stands on the bottom of the portrait frame and grows upward with what it holds.
#
# A menu that knows what the player has seen of its choices, or has a locked one, is a list: a row
# per choice, each with its mark. Any other menu (the older scenes') keeps its choices side by
# side, the way they always were, so it takes no more of the picture than it used to.
#
# setChoices() takes what a stage's ChoiceScript returns, dialogue key -> label, where
#   "TITLE" is the menu's title,
#   "GUARANTEED" means no menu at all: the story goes straight on to that key,
#   a key starting with LOCKED is a choice shown locked, which can't be picked,
# and, when the script has them (ChoiceScript.getChoiceMarks), how much the player has already
# seen of each choice: the rows show it.

var choices = {}

@export var choiceButton : PackedScene

signal choiceSelected(key: String)

const PANEL_WIDTH = 824.0
# From the frame's bottom edge up to the panel's.
const BOTTOM_MARGIN = 16.0
# A new menu comes up from this far below its place.
const RISE = 16.0

# Where the middle of the panel's bottom edge goes, from this node.
var panelFoot : Vector2
var rise := 0.0
var entrance : Tween

func _ready():
	# Authored for the portrait frame (in landscape, DisplayMode scales this node as a whole):
	# wherever this node was put in that frame, the panel is centered on the frame's bottom edge.
	var frame := Vector2(DisplayMode.portraitSize)
	panelFoot = Vector2(frame.x / 2, frame.y - BOTTOM_MARGIN) - position
	%Panel.minimum_size_changed.connect(placePanel)
	placePanel()

func setChoices(new_choices: Dictionary, marks: Dictionary = {}):
	choices = new_choices

	# The rows a menu still coming in was fading in are about to go.
	if entrance:
		entrance.kill()
	for child in %ChoiceContainer.get_children():
		%ChoiceContainer.remove_child(child)
		child.queue_free()

	%Header.visible = choices.has("TITLE")
	var listed = !marks.is_empty() or choices.keys().any(func(key): return key.begins_with("LOCKED"))
	%ChoiceContainer.vertical = listed
	for key in choices.keys():
		if key == "GUARANTEED":
			_on_choice_button_pressed(choices[key])
			return

		if key == "TITLE":
			%title.text = choices[key]
			continue

		var button = choiceButton.instantiate()
		button.sideBySide = !listed
		button.setLabelAndKey(choices[key], key)
		# A locked choice is there to be seen, not picked: its row never says it was selected.
		if key.begins_with("LOCKED"):
			button.setLocked()
		elif marks.has(key):
			button.setSeen(marks[key]["seen"], marks[key]["total"], marks[key]["new"])
		button.selected.connect(_on_choice_button_pressed)
		%ChoiceContainer.add_child(button)

	playEntrance()

# The panel is as tall as its rows need (a size under its minimum becomes its minimum), standing
# on its foot.
func placePanel():
	%Panel.size = Vector2(PANEL_WIDTH, 0)
	%Panel.position = panelFoot - Vector2(PANEL_WIDTH / 2, %Panel.size.y - rise)

func setRise(value : float):
	rise = value
	placePanel()

# The panel fades in as it comes up into place, its rows one after the other. The rows can be
# picked from the first frame.
func playEntrance():
	%Panel.modulate.a = 0.0
	setRise(RISE)
	entrance = create_tween().set_parallel()
	entrance.tween_property(%Panel, "modulate:a", 1.0, 0.16)
	entrance.tween_method(setRise, RISE, 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var rows = %ChoiceContainer.get_children()
	for i in rows.size():
		rows[i].modulate.a = 0.0
		entrance.tween_property(rows[i], "modulate:a", 1.0, 0.16).set_delay(0.04 + 0.045 * i)

func _on_choice_button_pressed(key: String):
	print("Choice selected: %s" % key)
	choiceSelected.emit(key)
