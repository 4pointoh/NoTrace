extends Node2D

var dontAutoAdvance = false
var inputDisabled = false
var shouldFade = false
var shouldFadeQuick = false
var isVideoPause = false
var isFullscreenImage = false
var currentStageIsLoaded = false
var forcePhoneStage = false
var isSkipping = false
var inTransition = false

@export var pokerGameSceneTexasHoldEm : PackedScene
@export var pokerGameSceneFiveCardDraw : PackedScene
@export var phoneScene : PackedScene
@export var dateMinigameScene : PackedScene
@export var heartsplosion : PackedScene
@export var sceneSelector : PackedScene

var currentPokerGame
var currentPhone
var currentDate
var currentSceneSelector

var testToggle = false

var firstSceneMusic = load("res://data/assets/general/sounds/bg_music/title2.mp3")

func _ready():
	GameStageStorage.loadStages("res://resources/game_stage_lists/part_one.tres")
	$DialogueManager.setDialogueData(GlobalGameStage.currentStage.dialogue)
	GlobalGameStage.notify.connect(_handle_notify)
	GlobalGameStage.fullscreenImage.connect(_handle_fullscreenImage)
	GlobalGameStage.bgVolumeChanged.connect(_handle_bg_volume_change)
	GlobalGameStage.loadSave.connect(_handle_save_loaded)
	GlobalGameStage.playParticle.connect(_handle_play_particle)
	playBgMusic(load("res://data/assets/general/sounds/bg_music/title.mp3"))

func _handle_notify(text, image):
	$Notifier.play(text, image)
	
func _handle_fullscreenImage(image):
	isFullscreenImage = true
	$FullscreenImageBg/FullscreenImage.texture = image
	$FullscreenImageBg.show()
	$FullscreenImageBg/FullscreenImage.show()

func testFunction():
	print('testing')

func _input(event):
	if inputDisabled:
		pass

	if event.is_action_pressed('DebuButton'):
		testFunction()

	if event.is_action_pressed('quick_skip'):
		if !inTransition:
			isSkipping = true
			$DialogueManager.startQuickSkip()
	
	if event.is_action_released('quick_skip'):
		isSkipping = false
		$DialogueManager.stopQuickSkip()
	
	if event.is_action_pressed("hide_ui"):
		Node2D.print_orphan_nodes()
		toggleUi()
		$DialogueManager.refocusDbox()
	
	if event.is_action_pressed("menu"):
		#toggleUi()
		if $MainMenuContainer.visible:
			$MainMenuContainer.hide()
			$DialogueManager.refocusDbox()
		else:
			$MainMenuContainer.showMenu()
			$MainMenuContainer.show()
	
	if isFullscreenImage && event.is_action_released("disable_fullscreen_image"):
		isFullscreenImage = false
		$FullscreenImageBg.hide()
		$FullscreenImageBg/FullscreenImage.hide()

func toggleUi():
	if GlobalGameStage.currentStage.isPokerMatch && !currentPokerGame.dialoguePause:
		currentPokerGame.visible = !currentPokerGame.visible
	if GlobalGameStage.currentStage.isDate:
		currentDate.visible = !currentDate.visible
	
	$DialogueManager.toggleUi()

func beginMidSceneTransition():
	disableInput()
	$DialogueManager.disableDialogueProgression()

	if GlobalGameStage.currentStage.delayMusicToTransition:
		playBgMusic(GlobalGameStage.currentStage.startingMusic)

	if !isSkipping and GlobalGameStage.currentStage.middleTransition:
		inTransition = true
		playTransition(GlobalGameStage.currentStage.middleTransition, GlobalGameStage.currentStage.middleTransitionText)
		await get_tree().create_timer(5.0).timeout
	
	$DialogueManager.enableDialogueProgression()
	%Transition.move_out()
	enableInput()
	inTransition = false
	
func advanceGameStage():
	if !isSkipping and GlobalGameStage.currentStage.endTransition:
		disableInput()
		inTransition = true
		playTransition(GlobalGameStage.currentStage.endTransition, GlobalGameStage.currentStage.endTransitionText)
		await get_tree().create_timer(5.0).timeout
	
	GlobalGameStage.advanceGameStage()

	if !isSkipping and GlobalGameStage.currentStage.startTransition:
		disableInput()
		inTransition = true
		playTransition(GlobalGameStage.currentStage.startTransition, GlobalGameStage.currentStage.startTransitionText)
		await get_tree().create_timer(5.0).timeout

	if(inTransition):
		inTransition = false
		enableInput()
		%Transition.move_out()
	beginStage()
	
func beginStage():

	dontAutoAdvance = false
	$DialogueManager.clearCurrentBg()
	$DialogueManager.setDialogueData(GlobalGameStage.currentStage.dialogue)
	
	print('ENTERING STAGE: ' + GlobalGameStage.currentStage.name)
	if GlobalGameStage.currentStage.isPokerMatch:
		$Background.enableZoomPan()
		startNewPoker()
	elif GlobalGameStage.currentStage.isPhoneScreen || GlobalGameStage.currentStage.isPhoneMessageEvent:
		if !inPhoneScene():
			startNewPhone()
		if GlobalGameStage.currentStage.isPhoneMessageEvent:
			currentPhone.startConversation()
		$Background.disableZoomPan()
		$Background.setBackground(GlobalGameStage.currentStage.startingBackground)
	elif GlobalGameStage.currentStage.isDate:
		$Background.enableZoomPan()
		startNewDate()
	else:
		$Background.disableZoomPan()
		$DialogueManager.startDialogue()
		if !$DialogueManager.uiVisible:
			$DialogueManager.toggleUi()
	
	if GlobalGameStage.currentStage.startingMusic and not GlobalGameStage.currentStage.delayMusicToTransition:
		playBgMusic(GlobalGameStage.currentStage.startingMusic)

func inPhoneScene():
	return is_instance_valid(currentPhone) && currentPhone
	
func startNewPhone():
	currentPhone = phoneScene.instantiate()
	currentPhone.newMessageSelect.connect(_on_phone_new_message_select)
	currentPhone.beginDialogue.connect(_on_phone_begin_dialogue)
	currentPhone.conversationComplete.connect(_on_phone_conversation_complete)
	currentPhone.newStageSelect.connect(_on_phone_new_stage_select)
	$Background.add_sibling(currentPhone)
	currentPhone.setup()

func startNewPoker():
	createPokerGame()
	currentPokerGame.gamePaused.connect(_on_poker_game_five_game_paused)
	currentPokerGame.gameWon.connect(_on_poker_game_five_game_won)
	currentPokerGame.gameLost.connect(_on_poker_game_five_game_lost)
	currentPokerGame.setup()
	add_child(currentPokerGame)
	$Background.setBackground(GlobalGameStage.currentStage.startingBackground)

func createPokerGame():
	if(GlobalGameStage.currentStage.pokerType == PokerEnums.PokerType.TEXAS_HOLD_EM):
		currentPokerGame = pokerGameSceneTexasHoldEm.instantiate()
	else:
		currentPokerGame = pokerGameSceneFiveCardDraw.instantiate()

func startNewDate():
	$DialogueManager.setDialogueBoxMaxUpper()
	currentDate = dateMinigameScene.instantiate()
	currentDate.dialogueStart.connect(_on_date_dialogue_start)
	currentDate.dateComplete.connect(_on_date_complete)
	currentDate.setWallpaper.connect(_on_date_set_wallpaper)
	currentDate.initFromGameStage(GlobalGameStage.currentStage)
	add_child(currentDate)
	move_child(currentDate, $DialogueManager.get_index() - 1)

func _on_start_pressed():
	%NameEnter.show()

func _on_name_enter_start():
	hideTitleStuff()
	$DialogueManager.startDialogue()
	playBgMusic(firstSceneMusic)


func hideTitleStuff():
	$Start.visible = false
	$Options.visible = false
	$Load.visible = false
	$Title.visible = false
	$SceneSelect.visible = false
	$Gallery.visible = false

func setDontAutoAdvance():
	dontAutoAdvance = true

func _on_dialogue_manager_dialogue_signal(value):
	match(value):
		"dont_auto_advance": setDontAutoAdvance()
		"hide_char": $CharacterManager.hideCharacter()
		"video_pause": videoPause()
		"fade_next": fadeNext() #sets up fade for the next background transition. Only fires if the background changes
		"fade_next_quick": fadeNextQuick()
		"music_home": playMusicHome()
		"music_whimsical": playMusicWhimsical()
		"music_neon_lights": playMusicNeonLights()
		"walk_on": $CharacterManager.walkOnNext()
		"walk_off": $CharacterManager.characterWalkOff()
		"zoom": $CharacterManager.zoomCharacter()
		"transition": beginMidSceneTransition()

func videoPause():
	isVideoPause = true
	$DialogueManager.muteDialogueBox()
	disableInput()
	$DialogueManager.hideUiFast()
	await get_tree().create_timer(6).timeout
	$DialogueManager.unhideUiFast()
	enableInput()
	$DialogueManager.unmuteDialogueBox()
	isVideoPause = false

func playMusicHome():
	playBgMusic(load("res://data/assets/general/sounds/bg_music/home2.mp3"))
	
func playMusicWhimsical():
	playBgMusic(load("res://data/assets/general/sounds/bg_music/Whispers of the Night.mp3"))

func playMusicNeonLights():
	playBgMusic(load("res://data/assets/general/sounds/bg_music/new/Untitled(11).mp3"))

func fadeNext():
	$Background.shouldFade = true

func fadeNextQuick():
	$Background.shouldFadeQuick = true

func disableInput():
	inputDisabled = true
	
func enableInput():
	inputDisabled = false

func _on_dialogue_manager_dialogue_ended():
	$CharacterManager.hideCharacter()
	
	if currentStageIsLoaded:
		currentStageIsLoaded = false
		return
		
	# We're in a poker game and just completed some dialogue
	if forcePhoneStage:
		forcePhoneStage = false
		GlobalGameStage.setPhoneGameStage()
		beginStage()
	elif validPokerGameRunning():
		$Background.enableZoomPan()
		currentPokerGame.show()
		currentPokerGame.removeDialoguePause()
	elif dontAutoAdvance: # We want to pause at the end, usually for cgs
		$Continue.visible = true
	elif inPhoneScene() && currentPhone.inConversation:
		currentPhone.dialogueComplete()
	elif GlobalGameStage.currentStage.isDate:
		currentDate.processDialogueComplete()
	else:
		advanceGameStage()

func validPokerGameRunning():
	return is_instance_valid(currentPokerGame) && currentPokerGame && currentPokerGame.dialoguePause

func _on_poker_game_five_game_paused():
	var nextAction = currentPokerGame.nextPokerAction
	if nextAction.actionResult == PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE:
		$Background.disableZoomPan()

		if nextAction.shouldHidePoker:
			currentPokerGame.hide()
			
		$DialogueManager.setDialogueBoxBottom()
		$DialogueManager.startDialogue(nextAction.dialogueStartKey)

func _on_poker_game_five_game_lost():
	remove_child(currentPokerGame)
	currentPokerGame.queue_free()
	$Background.setBackground(GlobalGameStage.currentStage.startingBackground)
	startNewPoker()

func _on_poker_game_five_game_won():
	currentPokerGame.queue_free()
	advanceGameStage()

func _on_date_dialogue_start(key):
	$DialogueManager.startDialogue(key)

func _on_date_complete(success, dialogueKey = null):
	currentDate.queue_free()
	if(success):
		GlobalGameStage.setDateComplete()
		GlobalGameStage.setNextGameStage(GlobalGameStage.currentStage.dateWinGameStage)
		advanceGameStage()
	else:
		GlobalGameStage.softCompleteCurrentStage()
		fadeNext()
		forcePhoneStage = true

		if(!dialogueKey):
			$DialogueManager.startDialogue(GlobalGameStage.currentStage.dateLossDialogueKey)
		else:
			$DialogueManager.startDialogue(dialogueKey)

func _on_date_set_wallpaper(wallpaper):
	$Background.setBackground(wallpaper)

func _on_dialogue_manager_dialogue_proceeded():
	#$DialogueManager.refocusDbox()
	
	if GlobalGameStage.currentStage.isDate:
		return #we manage our own backgrounds in the date
		
	if($DialogueManager.currentCharacterState):
		$CharacterManager.setCharacter($DialogueManager.currentCharacterState)
	
	if($DialogueManager.currentBackground):
		$Background.setBackground($DialogueManager.currentBackground)

func _on_background_is_fading():
	if isVideoPause: return
	disableInput()
	$DialogueManager.hideUiFast()
	$Background.z_index = 1
	await get_tree().create_timer(1).timeout
	$DialogueManager.unhideUiFast()
	$Background.z_index = 0
	enableInput()


func _on_continue_pressed():
	$Continue.visible = false
	advanceGameStage()

func _on_phone_new_message_select(stage):
	GlobalGameStage.setNextGameStage(stage)
	advanceGameStage()

func _on_phone_new_stage_select(stage):
	currentPhone.destroy()
	GlobalGameStage.setNextGameStage(stage)
	advanceGameStage()

func _on_phone_begin_dialogue(key):
	$DialogueManager.startDialogue(key)

func _on_phone_conversation_complete():
	GlobalGameStage.setPhoneGameStage()

func playBgMusic(stream):
	$AudioStreamPlayer2D.volume_db = GlobalGameStage.getBgVolume()
	$AudioStreamPlayer2D.stream = stream
	$AudioStreamPlayer2D.play()
	GlobalGameStage.currentMusic = stream.get_path()

func _handle_bg_volume_change():
	$AudioStreamPlayer2D.volume_db = GlobalGameStage.getBgVolume()

func _handle_save_loaded():
	currentStageIsLoaded = true
	
	if is_instance_valid(currentPhone):
		currentPhone.free()
	
	if is_instance_valid(currentPokerGame):
		currentPokerGame.free()
	
	if is_instance_valid(currentDate):
		currentDate.free()
	
	playBgMusic(load(GlobalGameStage.currentMusic))
	$DialogueManager.stopDialogue()
	$MainMenuContainer.visible = false
	$DialogueManager.clearCurrentBg()
	
	if !$DialogueManager.uiVisible:
		$DialogueManager.toggleUi()
	
	if GlobalGameStage.currentStage.startingBackground:
		$Background.setBackground(GlobalGameStage.currentStage.startingBackground)
	
	hideTitleStuff()
	beginStage()

func _handle_play_particle(type : Heartsplosion.TYPES, animType : Heartsplosion.ANIM_TYPE):
	if type == Heartsplosion.TYPES.NONE:
		return
	var hearts = heartsplosion.instantiate()
	hearts.setType(type)
	hearts.setAnimType(animType)
	add_child(hearts)

func _on_load_pressed():
	$MainMenuContainer.showLoadMenu(true)
	$MainMenuContainer.show()

func _on_options_pressed():
	$MainMenuContainer.showMenu(true)
	$MainMenuContainer.show()

func showEnterName():
	%NameEnter.show()


func _on_child_entered_tree(node):
	move_child.call_deferred($MainMenuContainer, -1)

func _on_scene_select_pressed():
	currentSceneSelector = sceneSelector.instantiate()
	currentSceneSelector.sceneSelectStageSelected.connect(_on_scene_select_stage_selected)
	currentSceneSelector.closeSceneSelect.connect(_on_scene_select_close)
	add_child(currentSceneSelector)

func _on_gallery_pressed():
	print('hi2')

func _on_scene_select_stage_selected(stage):
	currentSceneSelector.queue_free()
	hideTitleStuff()
	GlobalGameStage.setNextGameStage(stage)
	advanceGameStage()

func _on_scene_select_close():
	currentSceneSelector.queue_free()

func playTransition(transitionType, text):
	%Transition.playTransition(transitionType, text)
