extends Node

var FIRST_GAME_STAGE = preload("res://data/game_stages/vn/intro/gs_intro.tres")
#var FIRST_GAME_STAGE = preload("res://data/game_stages/vn/intro_after_poker/gs_intro_after_poker.tres")
var PHONE_STAGE = preload("res://data/game_stages/special/phone/gs_phone.tres")
var ALL_WALLPAPERS = preload("res://resources/wallpapers/all_wallpapers.tres")

var currentStage : GameStage
var nextStage : GameStage
var completedStages : Array[String]
var availableMessages : Array[GameStage]
var availableSelectableEvents : Array[GameStage]

var dateStorage : DateStorage

const VERSION = 001

signal notify(text : String, image : Texture)
signal fullscreenImage(image: Texture)
signal wallpaperChange(wallpaper : Wallpaper)
signal bgVolumeChanged
signal loadSave
signal playParticle(type: String)
signal showTopImage(image: Texture2D)

var bg_volume
var text_speed

var currentMusic = preload("res://data/assets/general/sounds/bg_music/title2.mp3")

#Wallpaper
var unlockedWallpapers : Array[String] = ["DEFAULT"]
var currentWallpaper : Wallpaper

func _init():
	currentStage = FIRST_GAME_STAGE
	nextStage = FIRST_GAME_STAGE.guaranteedNextGameStage
	currentWallpaper = ALL_WALLPAPERS.wallpapers[0]
	dateStorage = DateStorage.new()
	loadConfig()
	loadPersistentData()

func loadConfig():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		config.set_value("Audio", "bg_volume", 100);
		config.set_value("Text", "text_speed", 100)
		config.save("user://settings.cfg");
	
	bg_volume = config.get_value("Audio", "bg_volume")
	text_speed = config.get_value("Text", "text_speed")

func getBgVolume():
	return (bg_volume / 10)
	
func getTextSpeed():
	return text_speed
	
func setBgVolume(newVal):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("Audio", "bg_volume", newVal * 10)
	config.save("user://settings.cfg");
	bg_volume = newVal * 10
	bgVolumeChanged.emit()
	
func setTextSpeed(newVal):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("Text", "text_speed", newVal)
	config.save("user://settings.cfg");
	text_speed = newVal


func advanceGameStage():
	if !nextStage:
		return
		
	if currentStage.isCompletable:
		completedStages.append(currentStage.name)
		
	currentStage = nextStage
	
	if(currentStage.guaranteedNextGameStage):
		nextStage = currentStage.guaranteedNextGameStage
	else:
		nextStage = null

func setNextGameStage(stage):
	nextStage = stage
	
func setPhoneGameStage():
	setNextGameStage(PHONE_STAGE)
	advanceGameStage()

func getAvailableMessages():
	availableMessages = []
	
	if completedStages.has("intro_after_poker"):
		addMessage(Flags.LISA_FIRST_PHONE)
		addMessage(Flags.POKER_GIRLS_FIRST_PHONE)
	
	return availableMessages

func getAvailableSelectableEvents():
	availableSelectableEvents = []
	
	if completedStages.has('lisa_first_phone') and completedStages.has('poker_girls_first_phone'):
		addSelectableEvent(Flags.LISA_FIRST_MARKET_DATE)
		addSelectableEvent(Flags.ASHELY_FIRST_PARK_DATE)
	
	return availableSelectableEvents

func addSelectableEvent(event):
	if !completedStages.has(event.name):
		availableSelectableEvents.append(event)

func addMessage(message):
	if !completedStages.has(message.name):
		availableMessages.append(message)


# Unlocked a wallpaper requires a resource to be created in All_Wallpapers resource
# Then the text id value is passed in here
# Wallpapers in Dialogue scenes can be unlocked by emitting a signal & subscribing in DialogueManager
func unlockWallpaper(wallpaperResourceId, customMessage = ''):
	unlockedWallpapers.append(wallpaperResourceId)
	
	var selectedWallpaper
	for wallpaper in ALL_WALLPAPERS.wallpapers:
		if wallpaper.wallpaperId == wallpaperResourceId:
			selectedWallpaper = wallpaper
	
	if selectedWallpaper:
		if(customMessage == ''):
			notify.emit("Wallpaper Unlocked", selectedWallpaper.image)
		else:
			notify.emit(customMessage, selectedWallpaper.image)
	else:
		printerr("Attempted to unlock wallpaper " + wallpaperResourceId + " but no resource matched this name")
	
	savePersistentData()

func getWallpaper(wallpaperResourceId):
	var selectedWallpaper
	for wallpaper in ALL_WALLPAPERS.wallpapers:
		if wallpaper.wallpaperId == wallpaperResourceId:
			selectedWallpaper = wallpaper

	return selectedWallpaper
	
func unlockWallpaperWithDelay(wallpaperResourceId, delay, customMessage = ''):
	await get_tree().create_timer(delay).timeout
	unlockWallpaper(wallpaperResourceId, customMessage)

func setCurrentWallpaper(wallpaper):
	currentWallpaper = wallpaper
	wallpaperChange.emit(currentWallpaper)
	
func setImageFullscreen(image):
	fullscreenImage.emit(image)

func savePersistentData():
	var file = FileAccess.open("user://persistent.dat", FileAccess.WRITE)
	file.store_var(unlockedWallpapers)

func loadPersistentData():
	var file = FileAccess.open("user://persistent.dat", FileAccess.READ)
	# this isnt currently used but could be used to store stuff for a gallery

func saveSaveData(saveName):
	var file = FileAccess.open(saveName, FileAccess.WRITE)
	file.store_var(VERSION)
	file.store_var(completedStages)
	file.store_var(currentMusic)
	
	if currentStage.isPhoneMessageEvent:
		file.store_var("res://data/game_stages/special/phone/gs_phone.tres")
	else:
		file.store_var(currentStage.resource_path)
	file.store_var(unlockedWallpapers)
	file.store_var(dateStorage.askHistoryComplete)
	
	
func loadSaveData(saveName):
	var file = FileAccess.open(saveName, FileAccess.READ)
	if file:
		var saveVersion = file.get_var()
		var completedStageTemp = file.get_var()
		if(completedStageTemp):
			completedStages.assign(completedStageTemp)
		currentMusic = file.get_var()
		currentStage = load(file.get_var())
		unlockedWallpapers.assign(file.get_var())
		dateStorage.askHistoryComplete = file.get_var()
		
		if(currentStage.guaranteedNextGameStage):
			nextStage = currentStage.guaranteedNextGameStage
		else:
			nextStage = null
		
		dateStorage.clearCurrentDate()
		print('file version is ' + str(saveVersion))

	loadSave.emit()

func getExistingSaves():
	var availableFiles = []
	if FileAccess.file_exists("user://save1.dat"):
		availableFiles.append("user://save1.dat")
	if FileAccess.file_exists("user://save2.dat"):
		availableFiles.append("user://save2.dat")
	if FileAccess.file_exists("user://save3.dat"):
		availableFiles.append("user://save3.dat")
	if FileAccess.file_exists("user://save4.dat"):
		availableFiles.append("user://save4.dat")
	if FileAccess.file_exists("user://save5.dat"):
		availableFiles.append("user://save5.dat")
	if FileAccess.file_exists("user://save6.dat"):
		availableFiles.append("user://save6.dat")
	if FileAccess.file_exists("user://save7.dat"):
		availableFiles.append("user://save7.dat")
	if FileAccess.file_exists("user://save8.dat"):
		availableFiles.append("user://save8.dat")
	if FileAccess.file_exists("user://save9.dat"):
		availableFiles.append("user://save9.dat")
	if FileAccess.file_exists("user://save10.dat"):
		availableFiles.append("user://save10.dat")
	
	return availableFiles

func addDateAsk(id : String, successful : bool):
	dateStorage.addAsk(id, successful)
	print(str(dateStorage.askHistoryCurrentDate))
	
func getCurrentDateAskSuccessCount(id: String):
	return dateStorage.getCurrentDateSuccessCount(id)

func getCurrentDateAskFailureCount(id: String):
	return dateStorage.getCurrentDateFailureCount(id)
	
func getCompleteDateAskSuccessCount(id: String):
	return dateStorage.getCompleteDateSuccessCount(id)

func getCompleteDateAskFailureCount(id: String):
	return dateStorage.getCompleteDateFailureCount(id)

func getDateTotalAsks(id: String):
	return dateStorage.getTotalAsks(id)
	
func setCurrentAsk(id: String):
	dateStorage.currentAsk = id
	
func getCurrentAsk():
	return dateStorage.currentAsk

func getPreviousAsk():
	return dateStorage.lastAsked
	
func getDateLastFailure():
	return dateStorage.lastFailure
	
func resetDate():
	dateStorage.clearCurrentDate()

func hasDatePartnerAsked(id: String):
	return dateStorage.askHistoryCurrentDate.has(id)

func getDateStorage():
	return dateStorage

func modifyDateScore(progression, entertained, horny):
	dateStorage.currentDateEntertainmentScore += entertained
	dateStorage.currentDateProgressionScore += progression
	dateStorage.currentDateHornyScore += horny

func setDateComplete():
	completedStages.append(currentStage.name)

	if(currentStage.dateWinMarkThisStageComplete):
		completedStages.append(currentStage.dateWinMarkThisStageComplete)

func playParticleEffect(type : Heartsplosion.TYPES, animType : Heartsplosion.ANIM_TYPE):
	playParticle.emit(type, animType)

func showTopImg(texture : Texture2D):
	showTopImage.emit(texture)
