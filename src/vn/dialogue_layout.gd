extends ReferenceRect

# One frame's worth of dialogue box placements. The rectangle itself is the frame; every child
# is a marker showing where the box goes. Drag and resize them in the 2D editor: nothing here
# is drawn in the game, and no position lives in code.
#
# Marker names are what DialogueManager asks for, and most match a reposition_* dialogue signal:
#   Default        where the box sits when nothing has moved it (its size is the box size)
#   MaxUpper, Upper, UpperMid, Mid, Bottom, BottomLeft, BottomRight, MaxLower
#   HiddenUi       where the box parks while the player hides the UI (only x is used)
#   TweenYouFrom, TweenLisaFrom   where the tween_you / tween_lisa slide-ins start
#
# Where this node sits in the scene does not matter, only where the markers are inside it,
# so the landscape frame is parked beside the portrait one to keep the editor readable.

## Dialogue text size for this frame.
@export var fontSize := 20
## Speaker name size for this frame. 0 keeps the theme's own size.
@export var speakerFontSize := 0

func placementOf(placement : String) -> Vector2:
	if !has_node(placement):
		push_warning("Dialogue layout '%s' has no marker named '%s', using Default" % [name, placement])
		return $Default.position
	return get_node(placement).position

func boxSize() -> Vector2:
	return $Default.size

func applyFonts(box : DialogueBox):
	box.dialogue.add_theme_font_size_override("normal_font_size", fontSize)
	box.dialogue.add_theme_font_size_override("italics_font_size", fontSize)
	if speakerFontSize > 0:
		box.speaker.add_theme_font_size_override("font_size", speakerFontSize)
	else:
		box.speaker.remove_theme_font_size_override("font_size")
