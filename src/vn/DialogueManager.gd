extends Control
class_name DialogueManager

var dialog_bg_you = load("res://data/assets/general/art/you_dialogue_bg.png")
var dialog_bg_lisa = load("res://data/assets/general/art/lisa_dialogue_bg.png")
var dialog_bg_ashely = load("res://data/assets/general/art/ashely_dialogue_bg.png")
var dialog_bg_amy = load("res://data/assets/general/art/amy_dialogue_bg.png")
var dialog_bg_anna = load("res://data/assets/general/art/anna_dialogue_bg.png")
var dialog_other = load("res://data/assets/general/art/dialogue_other.png")

var lisa_dialog_sound = load("res://data/assets/general/sounds/voice.ogg")
var you_dialog_sound = load("res://data/assets/general/sounds/sound.wav")

var uiVisible = true
var muted = false
var enableQuickSkip = false

signal dialogue_signal(value: String)
signal dialogue_ended
signal dialogue_proceeded

# Which marker the box is on, so a change of frame can put it in the same place in the other
# layout. The placements themselves live in the scene: see Layouts and dialogue_layout.gd.
var currentPlacement = "Default"
var cardShowing = false
var modeChangedFrame = -1
# The box has one motion at a time: every move goes through moveBox(), which cancels the last.
var boxTween : Tween
# A layout change slides the box only once a dialogue is under way: at the start of one there
# is nothing continuous on screen to slide from, so it snaps straight into place.
var layoutSettled = false

var currentBackground : Background
var currentCharacterState : CharacterState

enum DboxPosition{
	NO_CHANGE,
	MAX_UPPER,
	UPPER,
	UPPER_MID,
	MID,
	BOTTOM,
	BOTTOM_LEFT,
	MAX_LOWER
}


var elapsedQuickSkipTime = 0.0
func _ready():
	DisplayMode.modeChanged.connect(_handle_display_mode_changed)

# Three marker layouts in the scene: Portrait, Landscape (wide art fills the frame) and
# LandscapeCard (a portrait card sits to the left, so the box takes the column beside it).
func currentLayout():
	if !DisplayMode.isLandscape():
		return $Layouts/Portrait
	return $Layouts/LandscapeCard if cardShowing else $Layouts/Landscape

func _handle_display_mode_changed(_mode):
	modeChangedFrame = Engine.get_process_frames()
	applyLayout(false)

# Background reports whether its picture is a card. Between two landscape layouts the box
# slides over; when this arrives as part of a frame change it snaps with everything else.
func setCardPresentation(showing : bool):
	if showing == cardShowing:
		return
	cardShowing = showing
	applyLayout(uiVisible and layoutSettled and Engine.get_process_frames() != modeChangedFrame)

func applyLayout(animated : bool):
	var layout = currentLayout()
	layout.applyFonts($DialoguePlayer)

	var target = layout.placementOf(currentPlacement)
	if !uiVisible:
		target.x = layout.placementOf("HiddenUi").x
	moveBox(target, .5 if animated else 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT, animated)

# Every move of the box, so two can never fight over it. A slide between layouts also animates
# the size; any move that cuts one short finishes the size first, so it is never left half-way.
func moveBox(target : Vector2, duration : float, transition := Tween.TRANS_QUAD, easing := Tween.EASE_IN_OUT, animateSize := false):
	if boxTween:
		boxTween.kill()
	var boxSize = currentLayout().boxSize()
	if !animateSize or duration <= 0.0:
		$DialoguePlayer.size = boxSize
	if duration <= 0.0:
		$DialoguePlayer.position = target
		return

	boxTween = create_tween().set_parallel().set_trans(transition).set_ease(easing)
	boxTween.tween_property($DialoguePlayer, "position", target, duration)
	if animateSize:
		boxTween.tween_property($DialoguePlayer, "size", boxSize, duration)
	# A tween can end a rounding error short of its target (float32 start + delta * ease). Land
	# exactly, so the box's resting place is always the marker's, not 0.0002 px away from it.
	boxTween.finished.connect(settleBox.bind(target, boxSize))

func settleBox(target : Vector2, boxSize : Vector2):
	$DialoguePlayer.position = target
	$DialoguePlayer.size = boxSize

func moveDialogueBoxTo(placement : String):
	currentPlacement = placement
	moveBox(currentLayout().placementOf(placement), .6)

func slideDialogueBoxIn(from : String, placement : String, duration : float, transition : Tween.TransitionType):
	currentPlacement = placement
	$DialoguePlayer.position = currentLayout().placementOf(from)
	moveBox(currentLayout().placementOf(placement), duration, transition)

func _process(delta):

	if enableQuickSkip and GlobalGameStage.canSkipCurrentDialogue():
		elapsedQuickSkipTime += delta
		if elapsedQuickSkipTime > GlobalGameStage.skip_speed:
			clickNext()
			elapsedQuickSkipTime = 0

func clearCurrentBg():
	currentBackground = null

func setDialogueData(data : DialogueData):
	$DialoguePlayer.set_data(data)
	
func startDialogue(startKey = null):
	layoutSettled = false
	if startKey:
		GlobalGameStage.setDialogueKeySeen(startKey)
		$DialoguePlayer.start(startKey)
	else:
		$DialoguePlayer.start()
	
func tweenYouDialogue():
	slideDialogueBoxIn("TweenYouFrom", "Upper", .6, Tween.TRANS_QUAD)

func tweenLisaDialogue():
	slideDialogueBoxIn("TweenLisaFrom", "MaxUpper", .4, Tween.TRANS_BOUNCE)

func setLisaBg():
	$AudioStreamPlayer.stream = lisa_dialog_sound
	
	if !muted:
		$AudioStreamPlayer.play()
	var style : StyleBoxTexture = StyleBoxTexture.new()
	style.texture = dialog_bg_lisa
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)
	
func setYouBg():
	$AudioStreamPlayer.stream = you_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	var style : StyleBoxTexture = StyleBoxTexture.new()
	style.texture = dialog_bg_you
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)

func setOtherBg():
	$AudioStreamPlayer.stream = you_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	var style : StyleBoxTexture = StyleBoxTexture.new()
	style.texture = dialog_other
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)

func setAshelyBg():
	$AudioStreamPlayer.stream = lisa_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	var style : StyleBoxTexture = StyleBoxTexture.new()
	style.texture = dialog_bg_ashely
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)

func setAmyBg():
	$AudioStreamPlayer.stream = lisa_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	var style : StyleBoxTexture = StyleBoxTexture.new()
	style.texture = dialog_bg_amy
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)

func setAnnaBg():
	$AudioStreamPlayer.stream = lisa_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	var style : StyleBoxTexture = StyleBoxTexture.new()
	style.texture = dialog_bg_anna
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)

func setDefaultBg(charName : String):
	$AudioStreamPlayer.stream = you_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	
	var style
	if(charName.length() > 0):
		style = StyleBoxTexture.new()
		style.texture = dialog_other
	else:
		style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.7) # Black with 50% alpha
	$DialoguePlayer.add_theme_stylebox_override ("panel", style)

func muteDialogueBox():
	muted = true
	
func unmuteDialogueBox():
	muted = false

func setDialogueBoxUpper():
	moveDialogueBoxTo("Upper")

func setDialogueBoxUpperMid():
	moveDialogueBoxTo("UpperMid")

func setDialogueBoxMaxUpper():
	moveDialogueBoxTo("MaxUpper")

func setDialogueBoxMid():
	moveDialogueBoxTo("Mid")

func setDialogueBoxBottom():
	moveDialogueBoxTo("Bottom")

func setDialogueBoxBottomLeft():
	moveDialogueBoxTo("BottomLeft")

func setDialogueBoxBottomRight():
	moveDialogueBoxTo("BottomRight")

func setDialogueBoxMaxLower():
	moveDialogueBoxTo("MaxLower")

func stopDialogue():
	layoutSettled = false
	$DialoguePlayer.stop()

func _on_dialogue_player_dialogue_proceeded(node_type):
	if(node_type != '1'): return 
	
	match($DialoguePlayer.speaker.text):
		"Lisa": setLisaBg()
		"You": setYouBg()
		"Ashely": setAshelyBg()
		"Amy": setAmyBg()
		"Anna": setAnnaBg()
		"Random Party Girl": setAnnaBg()
		_: setDefaultBg($DialoguePlayer.speaker.text)
	
	getCurrentNodeInfo()
	dialogue_proceeded.emit()
	layoutSettled = true

func getSpeakerName() -> String:
	return $DialoguePlayer.speaker.text

func getCurrentNodeInfo():
	currentCharacterState = $DialoguePlayer.characterState
	currentBackground = $DialoguePlayer.background
	
func _on_dialogue_player_dialogue_signal(value):
	match(value):
		"tween_lisa": tweenLisaDialogue()
		"tween_you": tweenYouDialogue()
		"reposition_top": setDialogueBoxMaxUpper()
		"reposition_upper": setDialogueBoxUpper()
		"reposition_upper_mid": setDialogueBoxUpperMid()
		"reposition_mid": setDialogueBoxMid()
		"reposition_bottom": setDialogueBoxBottom()
		"reposition_bottom_left": setDialogueBoxBottomLeft()
		"reposition_bottom_right": setDialogueBoxBottomRight()
		"reposition_max_lower": setDialogueBoxMaxLower()
		"unlock_wp_lisa_leaving": GlobalGameStage.unlockWallpaper("LISA_LEAVING")
	
	dialogue_signal.emit(value)

# Hides the box off the side of the frame, or brings it back. Both ends are worked out from the
# placement the box was last given, never from where it happens to be: H can come in the middle
# of a move, or the placement can change while the box is hidden (a new stage moving it), and
# either way it comes back onto its marker.
func toggleUi():
	uiVisible = !uiVisible
	var target = currentLayout().placementOf(currentPlacement)
	if !uiVisible:
		target.x = currentLayout().placementOf("HiddenUi").x
	moveBox(target, .4)

func hideUiFast():
	visible = false
	
func unhideUiFast():
	visible = true

func _on_dialogue_player_dialogue_ended():
	dialogue_ended.emit()


func _on_visibility_changed():
	if visible == true:
		$DialoguePlayer.refocusOption()

func refocusDbox():
	$DialoguePlayer.refocusOption()

func unfocusDbox():
	$DialoguePlayer.unfocusOption()
	
func clickNext():
	if !canAdvanceDialogue():
		return

	$DialoguePlayer.clickNext()

func canAdvanceDialogue() -> bool:
	if GlobalGameStage.preventSkipping or GlobalGameStage.currentStage.isPhoneScreen or GlobalGameStage.currentStage.isPhoneMessageEvent or GlobalGameStage.currentStage.isRealDate:
		return false
	
	return true

func startQuickSkip():
	enableQuickSkip = true
	
func stopQuickSkip():
	enableQuickSkip = false

func disableDialogueProgression():
	$DialoguePlayer.set_disable_next()

func enableDialogueProgression():
	$DialoguePlayer.set_enable_next()

func _on_dialogue_player_item_rect_changed():
	%SkipLabel.position = $DialoguePlayer.position
	%SkipLabel.position.y += ($DialoguePlayer.size.y - %SkipLabel.size.y)
	
func _on_dialogue_player_visibility_changed():
	%SkipLabel.visible = $DialoguePlayer.visible
	
	if !$DialoguePlayer.visible:
		return
	
	var onPhone = GlobalGameStage.currentStage.isPhoneScreen or GlobalGameStage.currentStage.isPhoneMessageEvent
	%SkipLabel.visible = !onPhone and GlobalGameStage.canSkipCurrentDialogue() #No skipping on phones

func setDialogueBoxPosition(pos: DboxPosition):
	match pos:
		DboxPosition.NO_CHANGE: pass
		DboxPosition.MAX_UPPER: setDialogueBoxMaxUpper()
		DboxPosition.UPPER: setDialogueBoxUpper()
		DboxPosition.UPPER_MID: setDialogueBoxUpperMid()
		DboxPosition.MID: setDialogueBoxMid()
		DboxPosition.BOTTOM: setDialogueBoxBottom()
		DboxPosition.BOTTOM_LEFT: setDialogueBoxBottomLeft()
		DboxPosition.MAX_LOWER: setDialogueBoxMaxLower()
