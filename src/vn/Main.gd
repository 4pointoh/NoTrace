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
var imageToRestoreOnDialogueEnd : Background = null
var fullscreenImageIndex

@export var pokerGameSceneTexasHoldEm : PackedScene
@export var pokerGameSceneFiveCardDraw : PackedScene
@export var phoneScene : PackedScene
@export var dateMinigameScene : PackedScene
@export var heartsplosion : PackedScene
@export var sceneSelector : PackedScene
@export var realDateScene : PackedScene
@export var characterUnlockPanel : PackedScene

var currentPokerGame
var currentPhone
var currentDate
var currentRealDate
var currentSceneSelector

var currentUnlockPanel

var testToggle = false

var firstSceneMusic = load("res://data/assets/general/sounds/bg_music/title2.mp3")

func _ready():
	#GameStageStorage.loadStages("res://resources/game_stage_lists/part_one.tres")
	$DialogueManager.setDialogueData(GlobalGameStage.currentStage.dialogue)
	GlobalGameStage.notify.connect(_handle_notify)
	GlobalGameStage.fullscreenImage.connect(_handle_fullscreenImage)
	GlobalGameStage.bgVolumeChanged.connect(_handle_bg_volume_change)
	GlobalGameStage.loadSave.connect(_handle_save_loaded)
	GlobalGameStage.playParticle.connect(_handle_play_particle)
	GlobalGameStage.startMusicSignal.connect(_handle_play_music)
	playBgMusic(load("res://data/assets/general/sounds/bg_music/title.mp3"), true)

	if DisplayServer.screen_get_size().y <= 1152:
		DisplayServer.window_set_size(Vector2i(448, 576))
		%SmallResolution.show()

func _handle_notify(text, image):
	$Notifier.play(text, image)
	
func _handle_fullscreenImage(image, index):
	if index == null:
		%NextImage.hide()
		%PrevImage.hide()
	else:
		%NextImage.show()
		%PrevImage.show()
	
	fullscreenImageIndex = index

	isFullscreenImage = true
	$FullscreenImageBg/FullscreenImage.texture = image
	$FullscreenImageBg.show()
	$FullscreenImageBg/FullscreenImage.show()

func testFunction():
	print('testing')

func unlockChar(character : GlobalGameStage.CHARACTERS):
	GlobalGameStage.unlockDateGirl(character)

	if !isSkipping:
		currentUnlockPanel = characterUnlockPanel.instantiate()
		currentUnlockPanel.setup(character)
		currentUnlockPanel.continued.connect(_on_unlock_button_pressed)
		currentUnlockPanel.position = Vector2(200,850)
		add_child(currentUnlockPanel)
		currentUnlockPanel.animate()
		inTransition = true
		disableInput()
		$DialogueManager.disableDialogueProgression()
		$DialogueManager.hideUiFast()

		if(character == GlobalGameStage.CHARACTERS.ASHLEY):
			$Background.playFullscreenAnim("res://data/assets/fullscreen_anim/ashely_theater/ashely_theater_frames.tres")

func _on_unlock_button_pressed():
	currentUnlockPanel.queue_free()
	inTransition = false
	enableInput()
	$DialogueManager.enableDialogueProgression()
	$DialogueManager.unhideUiFast()

func endUnlockSequence():
	$Background.stopFullscreenAnim()

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

func toggleUi():
	if GlobalGameStage.currentStage.isPokerMatch && !currentPokerGame.dialoguePause:
		currentPokerGame.visible = !currentPokerGame.visible
	if GlobalGameStage.currentStage.isDate:
		currentDate.visible = !currentDate.visible
	
	$DialogueManager.toggleUi()

func playSceneMusic():
	if GlobalGameStage.currentStage.randomMusic.size() > 0:
		var randomIndex = randi() % GlobalGameStage.currentStage.randomMusic.size()

		var newStream = load(GlobalGameStage.currentStage.randomMusic[randomIndex].resource_path)

		while $AudioStreamPlayer2D.stream == newStream:
			randomIndex = randi() % GlobalGameStage.currentStage.randomMusic.size()
			newStream = load(GlobalGameStage.currentStage.randomMusic[randomIndex].resource_path)

		playBgMusic(GlobalGameStage.currentStage.randomMusic[randomIndex])
	elif GlobalGameStage.currentStage.startingMusic:
		playBgMusic(GlobalGameStage.currentStage.startingMusic)

func beginMidSceneTransition():
	disableInput()
	$DialogueManager.disableDialogueProgression()

	if GlobalGameStage.currentStage.delayMusicToTransition:
		playSceneMusic()

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

	if GlobalGameStage.currentStage.repositionDialogueBoxTo != DialogueManager.DboxPosition.NO_CHANGE:
		$DialogueManager.setDialogueBoxPosition(GlobalGameStage.currentStage.repositionDialogueBoxTo)
	
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
	elif GlobalGameStage.currentStage.isRealDate:
		$Background.enableZoomPan()
		startNewRealDate()
	else:
		$Background.disableZoomPan()
		$DialogueManager.startDialogue()
		if !$DialogueManager.uiVisible:
			$DialogueManager.toggleUi()
	
	if GlobalGameStage.currentStage.startingMusic and not GlobalGameStage.currentStage.delayMusicToTransition:
		playSceneMusic()

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

func startNewRealDate():
	$Background.setBackground(GlobalGameStage.currentStage.startingBackground)
	currentRealDate = realDateScene.instantiate()
	currentRealDate.dateComplete.connect(_on_realdate_complete)
	currentRealDate.showStart()
	add_child(currentRealDate)
	move_child(currentRealDate, $DialogueManager.get_index() - 1)

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
	%SmallResolution.visible = false

func _handle_play_music(music):
	playBgMusic(load(music))

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
		"unlock_char_ashely": unlockChar(GlobalGameStage.CHARACTERS.ASHLEY)
		"unlock_char_amy": unlockChar(GlobalGameStage.CHARACTERS.AMY)
		"unlock_char_lisa": unlockChar(GlobalGameStage.CHARACTERS.LISA)
		"unlock_char_anna": unlockChar(GlobalGameStage.CHARACTERS.ANA)
		"end_unlock_sequence": endUnlockSequence()
		"unlock_lisa_cat_convo": unlockLisaCatConvo()
		"music_passion": playMusicPassion()

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

func playMusicPassion():
	playBgMusic(load("res://data/assets/general/sounds/bg_music/passion.mp3"))

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
		if imageToRestoreOnDialogueEnd:
			$Background.shouldFade = true
			$Background.setBackground(imageToRestoreOnDialogueEnd)
			imageToRestoreOnDialogueEnd = null

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

	if nextAction.restoreImageOnCompletion:
		imageToRestoreOnDialogueEnd = $Background.background
	else:
		imageToRestoreOnDialogueEnd = null

	if nextAction.actionResult == PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE:
		$Background.disableZoomPan()
		$Background.shouldFade = true

		if nextAction.shouldHidePoker:
			currentPokerGame.hide()

		$DialogueManager.startDialogue(nextAction.dialogueStartKey)

func _on_poker_game_five_game_lost():
	remove_child(currentPokerGame)
	currentPokerGame.queue_free()
	$Background.setBackground(GlobalGameStage.currentStage.startingBackground)
	playSceneMusic()
	startNewPoker()

func _on_poker_game_five_game_won():
	if GlobalGameStage.currentStage.markStagesCompleteOnPokerWin.size() > 0:
		for stage in GlobalGameStage.currentStage.markStagesCompleteOnPokerWin:
			GlobalGameStage.markStageComplete(stage)

	currentPokerGame.queue_free()
	advanceGameStage()

func _on_date_dialogue_start(key):
	$DialogueManager.startDialogue(key)

func _on_date_complete(success, dialogueKey = null, retry = false):
	currentDate.queue_free()
	if(retry):
		GlobalGameStage.setNextGameStage(GlobalGameStage.currentStage)
		advanceGameStage()
	elif(success):
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

func playBgMusic(stream, skipCheck = false):
	if $AudioStreamPlayer2D.stream == stream && !skipCheck:
		return

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

func _on_realdate_complete(mode):
	if mode == 0:
		GlobalGameStage.setNextGameStage(GlobalGameStage.currentStage.perfectDateGameStage)
	elif mode == 1:
		GlobalGameStage.setNextGameStage(GlobalGameStage.currentStage.midDateGameStage)
		
	advanceGameStage()
	currentRealDate.queue_free()
	
func unlockLisaCatConvo():
	GlobalGameStage.askedAboutLyric = true

func _on_close_image_pressed() -> void:
	isFullscreenImage = false
	$FullscreenImageBg.hide()
	$FullscreenImageBg/FullscreenImage.hide()

func _on_prev_image_pressed() -> void:
	if fullscreenImageIndex - 1 < 0:
		return

	fullscreenImageIndex = fullscreenImageIndex - 1

	var wallpapers = load("res://resources/wallpapers/all_wallpapers.tres")

	if GlobalGameStage.unlockedWallpapers.has(wallpapers.wallpapers[fullscreenImageIndex].wallpaperId):
		$FullscreenImageBg/FullscreenImage.texture = wallpapers.wallpapers[fullscreenImageIndex].image
	else:
		$FullscreenImageBg/FullscreenImage.texture = load("res://data/assets/phone/art/wallpaper_not_unlocked2.png")

func _on_next_image_pressed() -> void:
	var wallpapers = load("res://resources/wallpapers/all_wallpapers.tres")

	if fullscreenImageIndex + 1 >= wallpapers.wallpapers.size():
		return

	fullscreenImageIndex = fullscreenImageIndex + 1

	if GlobalGameStage.unlockedWallpapers.has(wallpapers.wallpapers[fullscreenImageIndex].wallpaperId):
		$FullscreenImageBg/FullscreenImage.texture = wallpapers.wallpapers[fullscreenImageIndex].image
	else:
		$FullscreenImageBg/FullscreenImage.texture = load("res://data/assets/phone/art/wallpaper_not_unlocked2.png")
