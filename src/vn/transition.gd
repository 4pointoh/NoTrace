extends ColorRect
class_name Transition

enum TransitionType {
	NONE,
	RED_CAR,
	NIGHT_CAR,
	SLEEP
}

# Authored for the portrait frame. In landscape the black has to cover the wider frame, and
# the picture and caption stay together in the middle of it.
var authoredWidth : float
var authoredSpriteX : float
var authoredLabelLeft : float
var authoredLabelRight : float
var authoredZ : int

# The plain cover must hide everything Main draws, including what sits above the transitions:
# the notifier, and the background while it fades (it is lifted to z 1 for that).
const COVER_Z = 10

# The stage transition on screen, so a plain cover laid over it can give it back (uncover).
var showingCard = false
var shownText = ""

func _ready():
	authoredWidth = size.x
	authoredZ = z_index
	authoredSpriteX = %TransitionSprite.position.x
	authoredLabelLeft = %TransitionLabel.offset_left
	authoredLabelRight = %TransitionLabel.offset_right
	DisplayMode.modeChanged.connect(fitFrame)

# Only moves what the frame asks for. The caption moves by its side offsets: setting its
# position would also pin its current height, and a caption that wrapped to more lines than
# authored would then push every later caption down.
func fitFrame(_mode = null):
	var frame = Vector2(DisplayMode.getBaseSize())
	var shift = (frame.x - authoredWidth) / 2 if DisplayMode.isLandscape() else 0.0
	var width = maxf(frame.x, authoredWidth)
	if size.x != width:
		size = Vector2(width, size.y)
	%TransitionSprite.position.x = authoredSpriteX + shift
	if %TransitionLabel.offset_left != authoredLabelLeft + shift:
		%TransitionLabel.offset_left = authoredLabelLeft + shift
		%TransitionLabel.offset_right = authoredLabelRight + shift

func playTransition(transitionType: TransitionType, text: String):
	show()
	position = Vector2(0,0)
	fitFrame()
	z_index = authoredZ
	%TransitionSprite.show()
	showingCard = true
	match transitionType:
		TransitionType.NONE:
			hide()
			showingCard = false
			return
		TransitionType.RED_CAR:
			playRedCarAnimation()
		TransitionType.NIGHT_CAR:
			playNightCarAnimation()
		TransitionType.SLEEP:
			playSleepAnimation()
	setText(text)
	shownText = text

# Plain black with nothing on it, for a frame change that has no stage transition to hide
# behind (eg: loading a save made in the other frame). Taken away with move_out() or uncover(),
# or by a transition played over it.
func cover():
	# A slide_out still running would otherwise keep moving it away, and hide it.
	%AnimationPlayer.stop()
	show()
	position = Vector2(0,0)
	fitFrame()
	z_index = COVER_Z
	%TransitionSprite.hide()
	setText("")

# Takes a plain cover away, giving back the stage transition it was laid over, if any.
func uncover():
	if !showingCard:
		hide()
		return
	z_index = authoredZ
	%TransitionSprite.show()
	setText(shownText)

func playRedCarAnimation():
	%TransitionSprite.play("redcar")

func playNightCarAnimation():
	%TransitionSprite.play("nightcar")

func playSleepAnimation():
	%TransitionSprite.play("sleep")

func setText(text):
	%TransitionLabel.text = text

func move_out():
	showingCard = false
	%AnimationPlayer.play("slide_out")
