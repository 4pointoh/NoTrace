extends Control

# Everything laid over the background for effect: for now the near atmosphere (petals) and the
# portrait -> landscape reveal. It is the one place Main sends these dialogue signals to:
#
#   atmosphere_<name>   atmosphere_off   reveal_landscape
#
# It never reshapes the window itself. At the reveal's black point it asks Main (frameChangeDue),
# which changes the frame behind its own cover, exactly as it does for landscape_next.
#
# Main is a Node2D, and a Control under a Node2D gets an empty anchor rect, so this node sizes
# itself to the frame. Its children are ordinary anchored Controls: open this scene, resize the
# root to 1920x1080 or 896x1152, and you are looking at that frame.

signal musicFadeRequested
signal musicRequested(stream : AudioStream)
## The reveal has reached black and wants the frame changed (Main answers, behind its cover).
signal frameChangeDue(mode)
signal revealStarted
signal revealFinished

## The game's Background node. Its camera is what the reveal moves.
@export var background : Control

var revealRequested = false
# From the moment the reveal takes the dialogue until it hands it back, played or skipped.
var revealPlaying = false
var revealBackground : Background
var revealConfig : LandscapeRevealConfig

func _ready():
	DisplayMode.modeChanged.connect(_on_display_mode_changed)
	fitFrame()
	$Atmosphere.camera = camera()

	$Reveal.enteredBlack.connect(turnLandscape)
	$Reveal.cameraRequested.connect(_on_reveal_camera_requested)
	$Reveal.musicFadeRequested.connect(musicFadeRequested.emit)
	$Reveal.musicRequested.connect(musicRequested.emit)
	$Reveal.atmosphereRequested.connect(setAtmosphere)
	$Reveal.finished.connect(finishReveal)

# The frame only ever changes behind black. What drifted in the old frame ends with it.
func _on_display_mode_changed(_mode):
	fitFrame()
	$Atmosphere.clear()

func fitFrame():
	position = Vector2.ZERO
	size = DisplayMode.getBaseSize()

func camera():
	return background.get_node("Camera")

# Returns true when the signal was one of ours, so Main can stop looking.
func handleSignal(value : String) -> bool:
	if value.begins_with("atmosphere_"):
		var which = value.trim_prefix("atmosphere_")
		setAtmosphere("" if which == "off" else which)
		return true
	if value == "reveal_landscape":
		revealRequested = true
		return true
	return false

# Empty lets it die away; a name starts it.
func setAtmosphere(atmosphereName : String):
	if atmosphereName == "":
		$Atmosphere.stop()
	else:
		$Atmosphere.play(atmosphereName)

# Everything a stage may have left on screen, cleared when the next one begins (or a save loads).
func reset():
	$Atmosphere.clear()
	revealRequested = false

# --- The landscape reveal ---------------------------------------------------------------------

# reveal_landscape only asks; the picture to open onto is the background of the dialogue line
# that follows the signal, which Main hands over here.
func takeRevealRequest() -> bool:
	var requested = revealRequested
	revealRequested = false
	return requested

func playReveal(newBackground : Background, instantly : bool):
	revealBackground = newBackground
	revealConfig = GlobalGameStage.currentStage.reveal
	if revealConfig == null:
		revealConfig = LandscapeRevealConfig.new()
	# Loaded while the screen dips to black, so it is ready at the black point.
	if newBackground and newBackground.imagePath != "":
		BackgroundCache.prefetch(newBackground.imagePath)
	revealPlaying = true
	revealStarted.emit()

	# Skipping, or already wide: the same end state without the set-piece.
	if instantly or DisplayMode.isLandscape():
		turnLandscape()
		while !DisplayMode.isLandscape():
			await DisplayMode.modeChanged
		camera().goWide(0.0)
		setAtmosphere(revealConfig.atmosphere)
		if revealConfig.music:
			musicRequested.emit(revealConfig.music)
		else:
			musicFadeRequested.emit()
		finishReveal()
		return

	$Reveal.play(revealConfig)

# The black point (or the skip): the picture goes up at once, and Main changes the frame behind
# its cover.
func turnLandscape():
	if revealBackground:
		background.showNow(revealBackground)
	if !DisplayMode.isLandscape():
		frameChangeDue.emit(DisplayMode.MODES.LANDSCAPE)

func finishReveal():
	revealPlaying = false
	revealFinished.emit()

func _on_reveal_camera_requested(kind : String, duration : float):
	var point = Vector2(0.5, 0.5)
	var zoom = 1.45
	var focus = revealFocus()
	if focus:
		point = focus.point
		zoom = focus.zoom

	match(kind):
		"tight": camera().snapTo(point, zoom)
		"push": camera().focusOn(point, zoom * 1.12, duration)
		"wide": camera().focusOn(Vector2(0.5, 0.5), camera().wideZoom(), duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)

# The point the reveal holds on: the config's focusName, else the picture's first focus point.
# A picture with none is held on its center.
func revealFocus() -> BackgroundFocus:
	if revealBackground == null or revealBackground.focusPoints.is_empty():
		return null
	var named = revealBackground.getFocus(revealConfig.focusName)
	return named if named else revealBackground.focusPoints[0]
