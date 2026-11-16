extends Node

# Swaps the game's base resolution at runtime between the original portrait frame and the
# landscape frame used by newer chapters. project.godot stays portrait, so anything that never
# asks for landscape behaves exactly as it always has: the project setting only seeds the root
# window's content_scale_size at startup, and that property stays writable while the game runs.
#
# Everything that depends on the frame should react to modeChanged. It is emitted from inside
# setMode(), so handlers run in the same call as the switch and no frame is ever drawn with a
# stale layout. Do not poll the frame size in _process instead: code that changes the mode
# usually runs after _process (from a tween, timer or animation), and the layout would be one
# frame late. That exact mistake once leaked a picture through a fade to black.
#
# The OS window is only ever resized in one step, while the screen is black. Every resize
# rebuilds the swapchain: measured at 100-150 ms on Vulkan (~40 ms D3D12, ~33 ms OpenGL).
# Animating it while anything is visible turns the picture into a slideshow, and spreading it
# over time behind black was tried too: the window's edge just widens in about eight chunky
# steps a second, which looks worse than one clean snap.

signal modeChanged(mode)

enum MODES { PORTRAIT, LANDSCAPE }

const LANDSCAPE_SIZE = Vector2i(1920, 1080)

# Read from project.godot, so the portrait frame has a single source of truth.
var portraitSize : Vector2i
var currentMode = MODES.PORTRAIT

# Windowed size the player last had in each mode, so swapping back restores it.
var windowSizes = {}
# Until the frame first changes, the window is exactly as the original portrait game leaves it,
# whatever shape the player gives it.
var frameHasChanged = false
var portraitAuthored = []

func _ready():
	portraitSize = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))

func setMode(mode : MODES):
	if mode == currentMode:
		return

	rememberWindowSize()
	currentMode = mode
	frameHasChanged = true
	get_window().content_scale_size = getBaseSize()
	refitWindow()
	placePortraitAuthored()
	modeChanged.emit(currentMode)

func setLandscape():
	setMode(MODES.LANDSCAPE)

func setPortrait():
	setMode(MODES.PORTRAIT)

func toggleMode():
	setMode(MODES.PORTRAIT if isLandscape() else MODES.LANDSCAPE)

func isLandscape() -> bool:
	return currentMode == MODES.LANDSCAPE

func getBaseSize() -> Vector2i:
	return getBaseSizeFor(currentMode)

func getBaseSizeFor(mode : MODES) -> Vector2i:
	return LANDSCAPE_SIZE if mode == MODES.LANDSCAPE else portraitSize

# --- UI without a landscape layout ----------------------------------------------------------

# UI that was authored for the portrait frame and has no landscape layout of its own is shown
# scaled to the landscape frame's height and centered: a portrait panel laid over the wide
# scene. Register it once (usually in _ready) and it follows every mode change. This is the
# fallback that keeps menus and overlays usable in landscape without redesigning each one.
func keepPortraitAuthored(node : CanvasItem):
	portraitAuthored.append({ "node": weakref(node), "position": node.position, "scale": node.scale })
	placePortraitAuthored()

func placePortraitAuthored():
	var fit = float(LANDSCAPE_SIZE.y) / portraitSize.y
	var margin = Vector2((LANDSCAPE_SIZE.x - portraitSize.x * fit) / 2, 0)

	for entry in portraitAuthored.duplicate():
		var node = entry["node"].get_ref()
		if node == null:
			portraitAuthored.erase(entry)
		elif isLandscape():
			node.scale = entry["scale"] * fit
			node.position = entry["position"] * fit + margin
		else:
			node.scale = entry["scale"]
			node.position = entry["position"]

# --- The OS window --------------------------------------------------------------------------

# Reshapes a windowed window to match the current mode. Fullscreen and maximized windows are
# left alone; the engine letterboxes the frame inside them.
func refitWindow():
	var win = get_window()
	if win.mode != Window.MODE_WINDOWED or !frameHasChanged:
		return

	# Already the right shape (eg: the player dragged it that way), nothing to do.
	if (win.size.x > win.size.y) == isLandscape():
		return

	placeWindow(getWindowSizeFor(currentMode), win.position + win.size / 2)

# Only a window that still has its own mode's shape counts as "the size the player had".
func rememberWindowSize():
	var win = get_window()
	if win.mode == Window.MODE_WINDOWED and (win.size.x > win.size.y) == isLandscape():
		windowSizes[currentMode] = win.size

# The size the player last had in that mode. Failing that, the same scale they are looking at
# now, so text stays the size they chose (a half-size portrait window becomes a half-size
# landscape one), shrunk further only if it would not fit the screen.
func getWindowSizeFor(mode : MODES) -> Vector2i:
	var win = get_window()
	var usable = DisplayServer.screen_get_usable_rect(win.current_screen)
	var decorations = win.get_size_with_decorations() - win.size
	var available = Vector2(usable.size - decorations)

	var remembered = windowSizes.get(mode)
	if remembered != null and remembered.x <= available.x and remembered.y <= available.y:
		return remembered

	# Measured against the frame whose shape the window has right now, which is not always the
	# current mode: this also runs just after the mode changed, and when the options menu
	# brings a window back from fullscreen in its old shape.
	var shownMode = MODES.LANDSCAPE if win.size.x > win.size.y else MODES.PORTRAIT
	var shown = Vector2(getBaseSizeFor(shownMode))
	var viewedScale = minf(win.size.x / shown.x, win.size.y / shown.y)

	var target = Vector2(getBaseSizeFor(mode))
	var fit = minf(viewedScale, minf(available.x / target.x, available.y / target.y))
	return Vector2i((target * fit).floor())

# Resizes the window around a fixed center, but never lets it hang off the screen.
func placeWindow(newSize : Vector2i, center : Vector2i):
	var win = get_window()
	var usable = DisplayServer.screen_get_usable_rect(win.current_screen)
	var decorations = win.get_size_with_decorations() - win.size
	win.size = newSize

	var newPos = center - newSize / 2
	var maxPos = usable.end - newSize - Vector2i(decorations.x / 2, decorations.x / 2)
	var minPos = usable.position + Vector2i(decorations.x / 2, decorations.y - decorations.x / 2)
	win.position = newPos.clamp(minPos, maxPos.max(minPos))

func _unhandled_key_input(event):
	# Debug hotkey for trying the swap anywhere in the game, only when run from the Godot editor. Never ships.
	if OS.has_feature("editor") and event.pressed and !event.echo and event.keycode == KEY_F9:
		toggleMode()
