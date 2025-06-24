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

var dbox_position_upper = Vector2(120,100)
var dbox_position_upper_mid = Vector2(120,150)
var dbox_position_max_upper = Vector2(120,10)
var dbox_position_mid = Vector2(120, 680)
var dbox_position_bottom = Vector2(120, 900)
var dbox_position_bottom_left = Vector2(55, 890)
var dbox_position_bottom_right = Vector2(200, 950)
var dbox_position_max_lower = Vector2(55, 950)

var currentBackground : Background
var currentCharacterState : CharacterState

var originalXPos

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
func _process(delta):
	
	if enableQuickSkip and GlobalGameStage.hasCompletedStageGloballySoft():
		elapsedQuickSkipTime += delta
		if elapsedQuickSkipTime > GlobalGameStage.skip_speed:
			clickNext()
			elapsedQuickSkipTime = 0

func clearCurrentBg():
	currentBackground = null

func setDialogueData(data : DialogueData):
	$DialoguePlayer.set_data(data)
	
func startDialogue(startKey = null):
	originalXPos = $DialoguePlayer.position.x
	if startKey:
		$DialoguePlayer.start(startKey)
	else:
		$DialoguePlayer.start()
	
func tweenYouDialogue():
	var Y_POS = 100
	$DialoguePlayer.position = Vector2(-800,Y_POS)
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", Vector2(120,Y_POS), .6).set_trans(Tween.TRANS_QUAD)
	
func tweenLisaDialogue():
	var Y_POS = 10
	$DialoguePlayer.position = Vector2(1200,Y_POS)
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", Vector2(120,Y_POS), .4).set_trans(Tween.TRANS_BOUNCE)

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
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_upper, .6).set_trans(Tween.TRANS_QUAD)

func setDialogueBoxUpperMid():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_upper_mid, .6).set_trans(Tween.TRANS_QUAD)
	
func setDialogueBoxMaxUpper():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_max_upper, .6).set_trans(Tween.TRANS_QUAD)

func setDialogueBoxMid():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_mid, .6).set_trans(Tween.TRANS_QUAD)
	
func setDialogueBoxBottom():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_bottom, .6).set_trans(Tween.TRANS_QUAD)

func setDialogueBoxBottomLeft():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_bottom_left, .6).set_trans(Tween.TRANS_QUAD)

func setDialogueBoxBottomRight():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_bottom_right, .6).set_trans(Tween.TRANS_QUAD)

func setDialogueBoxMaxLower():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_max_lower, .6).set_trans(Tween.TRANS_QUAD)

func stopDialogue():
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

func toggleUi():
	uiVisible = !uiVisible
	var currentYPos = $DialoguePlayer.position.y
	
	var tween = get_tree().create_tween()
	if uiVisible:
		tween.tween_property($DialoguePlayer, "position", Vector2(originalXPos,currentYPos), .4).set_trans(Tween.TRANS_QUAD)
	else:
		originalXPos = $DialoguePlayer.position.x
		tween.tween_property($DialoguePlayer, "position", Vector2(1200,currentYPos), .4).set_trans(Tween.TRANS_QUAD)

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
	if GlobalGameStage.currentStage.isPokerMatch or GlobalGameStage.currentStage.isDate or GlobalGameStage.currentStage.isPhoneScreen or GlobalGameStage.currentStage.isPhoneMessageEvent or GlobalGameStage.currentStage.isRealDate:
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
	
	if !GlobalGameStage.hasCompletedStageGloballySoft() or GlobalGameStage.currentStage.isPokerMatch or GlobalGameStage.currentStage.isDate or GlobalGameStage.currentStage.isPhoneScreen or GlobalGameStage.currentStage.isPhoneMessageEvent:
		%SkipLabel.visible = false

func setDialogueBoxPosition(position: DboxPosition):
	match position:
		DboxPosition.NO_CHANGE: pass
		DboxPosition.MAX_UPPER: setDialogueBoxMaxUpper()
		DboxPosition.UPPER: setDialogueBoxUpper()
		DboxPosition.UPPER_MID: setDialogueBoxUpperMid()
		DboxPosition.MID: setDialogueBoxMid()
		DboxPosition.BOTTOM: setDialogueBoxBottom()
		DboxPosition.BOTTOM_LEFT: setDialogueBoxBottomLeft()
		DboxPosition.MAX_LOWER: setDialogueBoxMaxLower()
