extends Node

# A camera for the background picture in the landscape frame: it holds a point of the picture at
# the center, pushes in or pulls back, and leans a little with the mouse. It moves the picture
# Background laid out, and the video playing over it, and draws nothing itself.
#
# Landscape only. In portrait it is switched off and never touches the picture, so the original
# game renders exactly as it always has. It also stands down while the zoom/pan shader used by
# poker and dates is on, since both want to move the same node.
#
# For now only the reveal moves it (tight, push, wide). Otherwise it rests on the whole picture
# and leans.

## The picture to move. Background places it for the frame; this only moves it from there.
@export var image : TextureRect
## The video playing over the picture, moved with it so the two stay one image.
@export var video : Control
## How many pixels the picture leans toward the mouse. 0 turns the lean off.
@export var parallax := 24.0
## Seconds for an ordinary move between framings.
@export var moveDuration := 1.6

# The point of the picture held at the center of the frame, 0..1 in picture space.
var focus = Vector2(0.5, 0.5)
var zoom = 1.0
# -0.5..0.5, where the mouse is. Other layers read this so the whole scene leans together.
var lean = Vector2.ZERO
var suspended = false
var moveTween : Tween
# The landscape frame Background laid the picture out in (zero in portrait), and where it put
# the video.
var frameSize = Vector2.ZERO
var videoRest = Vector2.ZERO

func _ready():
	refreshActive()

# Background calls this once it has laid the picture out, for a new picture or a new frame, so
# the two never fight over the same node. frame is the landscape frame's size, or zero in
# portrait, which switches the camera off. A new picture starts on the whole of it.
func pictureLaidOut(frame : Vector2):
	frameSize = frame
	if video:
		videoRest = video.position
	refreshActive()
	snapTo(Vector2(0.5, 0.5), 1.0)

func isActive() -> bool:
	return frameSize != Vector2.ZERO and !suspended

func refreshActive():
	set_process(isActive())
	if !is_processing():
		lean = Vector2.ZERO

# The zoom/pan shader holds the picture while it is on. Taken back in the same call it is
# switched off, so no frame is drawn in between.
func setSuspended(value : bool):
	suspended = value
	refreshActive()
	apply()

# The whole picture. Holds back just enough overscan that leaning never shows an edge.
func wideZoom() -> float:
	return 1.05 if parallax > 0.0 else 1.0

func focusOn(point : Vector2, zoomLevel : float, duration := -1.0, transition := Tween.TRANS_SINE, easing := Tween.EASE_IN_OUT):
	if duration < 0.0:
		duration = moveDuration
	if duration == 0.0:
		snapTo(point, zoomLevel)
		return
	if moveTween:
		moveTween.kill()

	moveTween = create_tween().set_parallel().set_trans(transition).set_ease(easing)
	moveTween.tween_property(self, "focus", point, duration)
	moveTween.tween_property(self, "zoom", maxf(zoomLevel, wideZoom()), duration)

func goWide(duration := -1.0):
	focusOn(Vector2(0.5, 0.5), wideZoom(), duration)

func snapTo(point : Vector2, zoomLevel : float):
	if moveTween:
		moveTween.kill()
	focus = point
	zoom = maxf(zoomLevel, wideZoom())
	apply()

func _process(delta):
	var mouse = (image.get_viewport().get_mouse_position() / frameSize).clamp(Vector2.ZERO, Vector2.ONE) - Vector2(0.5, 0.5)
	lean = lean.lerp(mouse, minf(1.0, delta * 4.0))
	apply()

func apply():
	if !isActive() or image == null:
		return

	var sway = lean * Vector2(parallax, parallax * 0.5) * 2.0

	# The picture is cover-fitted inside its rect, so a point in picture space has to be
	# mapped through that crop before it means anything in rect space.
	var focusInRect = focus * frameSize
	if image.texture:
		var pictureSize = image.texture.get_size()
		var cover = maxf(frameSize.x / pictureSize.x, frameSize.y / pictureSize.y)
		focusInRect = (frameSize - pictureSize * cover) / 2 + focus * pictureSize * cover

	# Center the focus, lean with the mouse, then never show past the picture's edge.
	var target = frameSize / 2 - focusInRect * zoom - sway
	image.scale = Vector2(zoom, zoom)
	image.position = target.clamp(frameSize - frameSize * zoom, Vector2.ZERO)

	# The video sits over its still: the same point of the rect, at the same scale.
	if video:
		video.scale = image.scale
		video.position = image.position + videoRest * zoom
