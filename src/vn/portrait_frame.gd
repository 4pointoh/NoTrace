extends Control

# Holds a scene that was authored for the portrait frame (896x1152) and has no landscape layout
# of its own: the phone, the poker timeline, poker and the date minigame, and in time the other
# full-screen scenes Main creates.
#
# In portrait it changes nothing. In landscape it shows the scene as a centered portrait panel,
# fitted to the frame's height (DisplayMode.keepPortraitAuthored, the same fallback the menus
# use), and crops it to that panel the way the window edge crops it in portrait: art authored to
# bleed past the edges stays hidden, and nothing out there can be clicked. The scene itself never
# knows: it keeps its own coordinates and animations. When a scene gets a real landscape layout
# of its own, it simply stops being added inside a PortraitFrame.
#
#   const PortraitFrame = preload("res://src/vn/portrait_frame.gd")
#   $Background.add_sibling(PortraitFrame.new().holding(currentPhone))
#
# The frame goes when the scene does, so free the scene as before. Anything Main does to place
# the scene among its own children (move_child, remove_child) it now does to the frame, which
# holding() returns and around(scene) finds again.

func _init():
	clip_contents = true
	mouse_filter = MOUSE_FILTER_IGNORE

func holding(scene : Node) -> Control:
	name = str(scene.name) + "Frame"
	size = DisplayMode.portraitSize
	# The scene sits under a Node2D, as it did directly under Main, so a scene whose root is a
	# Control still gets no anchor rect to stretch to (see the landscape guide).
	var holder := Node2D.new()
	holder.name = "Holder"
	add_child(holder)
	holder.add_child(scene)
	scene.tree_exited.connect(queue_free, CONNECT_ONE_SHOT)
	return self

func _ready():
	DisplayMode.keepPortraitAuthored(self)

# The frame a scene was added in with holding().
static func around(scene : Node) -> Control:
	return scene.get_parent().get_parent()
