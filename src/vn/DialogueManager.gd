extends Control

var dialog_bg_you = preload("res://data/assets/general/art/you_dialogue_bg.png")
var dialog_bg_lisa = preload("res://data/assets/general/art/lisa_dialogue_bg.png")
var dialog_bg_ashely = preload("res://data/assets/general/art/ashely_dialogue_bg.png")
var dialog_bg_amy = preload("res://data/assets/general/art/amy_dialogue_bg.png")

var lisa_dialog_sound = preload("res://data/assets/general/sounds/voice.ogg")
var you_dialog_sound = preload("res://data/assets/general/sounds/sound.wav")

var uiVisible = true
var muted = false

signal dialogue_signal(value: String)
signal dialogue_ended
signal dialogue_proceeded

var dbox_position_upper = Vector2(120,100)
var dbox_position_max_upper = Vector2(120,10)
var dbox_position_mid = Vector2(120, 680)
var dbox_position_bottom = Vector2(120, 900)
var dbox_position_bottom_left = Vector2(55, 890)

var currentBackground : Background
var currentCharacterState : CharacterState

func setDialogueData(data : DialogueData):
	$DialoguePlayer.set_data(data)
	
func startDialogue(startKey = null):
	
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

func setDefaultBg():
	$AudioStreamPlayer.stream = you_dialog_sound
	if !muted:
		$AudioStreamPlayer.play()
	$DialoguePlayer.remove_theme_stylebox_override("panel")

func muteDialogueBox():
	muted = true
	
func unmuteDialogueBox():
	muted = false

func setDialogueBoxUpper():
	var tween = get_tree().create_tween()
	tween.tween_property($DialoguePlayer, "position", dbox_position_upper, .6).set_trans(Tween.TRANS_QUAD)
	
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

func stopDialogue():
	$DialoguePlayer.stop()

func _on_dialogue_player_dialogue_proceeded(node_type):
	if(node_type != '1'): return 
	
	match($DialoguePlayer.speaker.text):
		"Lisa": setLisaBg()
		"You": setYouBg()
		"Ashely": setAshelyBg()
		"Amy": setAshelyBg()
		_: setDefaultBg()
	
	getCurrentNodeInfo()
	dialogue_proceeded.emit()

func getCurrentNodeInfo():
	currentCharacterState = $DialoguePlayer.characterState
	currentBackground = $DialoguePlayer.background
	
func _on_dialogue_player_dialogue_signal(value):
	match(value):
		"tween_lisa": tweenLisaDialogue()
		"tween_you": tweenYouDialogue()
		"reposition_upper": setDialogueBoxUpper()
		"reposition_mid": setDialogueBoxMid()
		"reposition_bottom": setDialogueBoxBottom()
		"reposition_bottom_left": setDialogueBoxBottomLeft()
		"unlock_wp_lisa_leaving": GlobalGameStage.unlockWallpaper("LISA_LEAVING")
	
	dialogue_signal.emit(value)

func toggleUi():
	uiVisible = !uiVisible
	var currentYPos = $DialoguePlayer.position.y
	
	var tween = get_tree().create_tween()
	if uiVisible:
		tween.tween_property($DialoguePlayer, "position", Vector2(120,currentYPos), .4).set_trans(Tween.TRANS_QUAD)
	else:
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
