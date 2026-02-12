extends Node2D

signal newMessageSelect(stage : GameStage)
signal newStageSelect(stage : GameStage)
signal showTimeline(stage : GameStage)
signal beginDialogue(key : String)
signal conversationComplete()

var availableMessages
var inConversation

var showingApps = true

@onready var appOpenSound = load("res://data/assets/phone/sounds/app_open.wav")
@onready var appBackSound = load("res://data/assets/phone/sounds/back.wav")

func _init():
	GlobalGameStage.wallpaperChange.connect(setWallpaper)
	
func setup():
	if GlobalGameStage.shouldRandomizeWallpaper():
		$PhoneBox/Wallpaper.texture = load(GlobalGameStage.getRandomUnlockedWallpaper())
	else:
		$PhoneBox/Wallpaper.texture = load(GlobalGameStage.currentWallpaper.wallpaperImagePath)
		
	show()
	$AnimationPlayer.play("phone_up")
	$PhoneBox/Back.visible = false
	setNotificationIcons()

func destroy():
	hide()
	queue_free()
	
func setNotificationIcons():
	var availMessages = GlobalGameStage.getAvailableMessages()
	var availEvents = GlobalGameStage.getAvailableSelectableEvents()
	
	if(availMessages.size() > 0):
		$PhoneBox/NotificationIconMessages.visible = true
		$PhoneBox/NotificationIconMessages.setNumber(availMessages.size())
	else:
		$PhoneBox/NotificationIconMessages.visible = false
	
	if(availEvents.size() > 0):
		$PhoneBox/NotificationIconEvents.visible = true
		$PhoneBox/NotificationIconEvents.setNumber(availEvents.size())
	else:
		$PhoneBox/NotificationIconEvents.visible = false

func setWallpaper(wallaper):
	$PhoneBox/Wallpaper.texture = load(wallaper.wallpaperImagePath)

func _on_messages_pressed():
	playAppOpenSound()
	toggleAppIcons()
	%MessagesApp.setup()
	%MessagesApp.visible = true
	%Back.visible = true
	%AnimationPlayer.play("messages_up")


func _on_wallpaper_icon_pressed():
	playAppOpenSound()
	toggleAppIcons()
	%WallpaperApp.setup()
	%WallpaperApp.visible = true
	%Back.visible = true
	%AnimationPlayer.play("wallpaper_up")

func _on_back_pressed():
	playBackSound()
	if inConversation:
		inConversation = false
		conversationComplete.emit()
	%MessagesApp.closeApp()
	%ContinueApp.closeApp()
	%WallpaperApp.reset()
	%ContinueApp.reset()
	%RealDateApp.reset()
	%Back.visible = false
	toggleAppIcons()
	setNotificationIcons()
	GlobalGameStage.startDefaultPhoneMusic()

func _on_continue_icon_pressed():
	playAppOpenSound()
	toggleAppIcons()
	%ContinueApp.setup()
	%ContinueApp.visible = true;
	%Back.visible = true
	%AnimationPlayer.play("continue_up")

func toggleAppIcons():
	var apps = get_tree().get_nodes_in_group("App")
	for app in apps:
		app.visible = !app.visible
	$PhoneBox/NotificationIconEvents.visible = false
	$PhoneBox/NotificationIconMessages.visible = false
	%ToggleAppViewBg.visible = !%ToggleAppViewBg.visible

func startConversation():
	%Back.visible = false
	%MessagesApp.startConversation()

func loadPreparedMessages(processNextAction = true):
	%MessagesApp.loadPreparedMessages()
	if processNextAction:
		%MessagesApp.processNextAction()

func _on_messages_app_new_message_select(stage):
	playAppOpenSound()
	inConversation = true
	newMessageSelect.emit(stage)

func _on_messages_app_conversation_complete():
	%Back.visible = true

func _on_messages_app_begin_dialogue(key):
	beginDialogue.emit(key)
	
func dialogueComplete():
	%MessagesApp.setDialogueEnded()

func playAppOpenSound():
	$AudioStreamPlayer2D.stream = appOpenSound
	$AudioStreamPlayer2D.play()

func playBackSound():
	$AudioStreamPlayer2D.stream = appBackSound
	$AudioStreamPlayer2D.play()


func _on_continue_app_selected(stage):
	playAppOpenSound()
	newStageSelect.emit(stage)

func _on_realdate_app_selected(stage):
	playAppOpenSound()
	newStageSelect.emit(stage)

func _on_real_date_icon_pressed():
	playAppOpenSound()
	toggleAppIcons()
	%RealDateApp.setup()
	%RealDateApp.visible = true
	%Back.visible = true
	%AnimationPlayer.play("realdate_up")

func _on_continue_app_selected_timeline(stage: GameStage) -> void:
	playAppOpenSound()
	showTimeline.emit(stage)


func _on_toggle_app_view_pressed() -> void:
	showingApps = !showingApps
	if showingApps:
		var apps = get_tree().get_nodes_in_group("App")
		for app in apps:
			app.visible = true
		setNotificationIcons()
	else:
		var apps = get_tree().get_nodes_in_group("App")
		for app in apps:
			app.visible = false
		%NotificationIconEvents.hide()
		%NotificationIconMessages.hide()
