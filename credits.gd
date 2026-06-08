extends Node2D

var currentTimePassed = 0.0
var curtainClosedTimer = 0.0
var curtainsReadyToOpenTimer = 0.0
var curtainsReadyToOpen = false
var curtainsOpened = false
var lyrics = getLyricsArray()
var images = getImagesArray()

var cheerSound = load("res://data/assets/general/sound_effects/live_show_cheer.mp3")

var useALyric = true
var useBg1 = true
const FADE_DURATION = 0.5

var creditsQueue: Array = []
var currentCreditIndex: int = 0
var currentCreditNode: Node2D = null
var lastCreditFadedOut: bool = false
const CREDITS_START_TIME = 7.0
const CREDITS_END_TIME = 79.0

@export var OneCreditScene : PackedScene

var creditIndex = 0

signal creditsEnded

func _process(delta: float) -> void:
	if !curtainsReadyToOpen:
		curtainsReadyToOpenTimer += delta
		if curtainsReadyToOpenTimer > 3.0:
			curtainsReadyToOpen = true
			%VideoStreamPlayer.show()
	elif curtainsOpened:
		currentTimePassed += delta
		if lyrics.has(roundDownToTenths(currentTimePassed)):
			if useALyric:
				%LyricA.text = str(lyrics[roundDownToTenths(currentTimePassed)])
			else:
				%LyricB.text = str(lyrics[roundDownToTenths(currentTimePassed)])

			setPositionOfLabelAndSlideIn()
			useALyric = !useALyric
			#lyrics.erase(roundDownToTenths(currentTimePassed))
		
		if images.has(roundDownToTenths(currentTimePassed)):
			creditIndex += 1
			if creditIndex == 1:
				%VideoStreamPlayer.hide()
			crossfadeBackground(images[roundDownToTenths(currentTimePassed)])
			images.erase(roundDownToTenths(currentTimePassed))
		
		checkAndShowCredits()
		
		if currentTimePassed > 92:
			creditsEnded.emit()
	elif curtainsReadyToOpen and not curtainsOpened:
		curtainClosedTimer += delta
		if curtainClosedTimer > .5 and curtainClosedTimer < 2:
			%bg1.show()
			%bg2.show()
			%BlackBg.show()
			%Subtitles.show()
			tweenCurtains()
		elif curtainClosedTimer > 2:
			curtainsOpened = true
			%AudioStreamPlayer2D.volume_db = GlobalGameStage.getBgVolume()
			%AudioStreamPlayer2D.play()

func _ready() -> void:
	$AudioStreamPlayer2D2.play()
	$AudioStreamPlayer2D2.volume_db = GlobalGameStage.getBgVolume()
	var leftTargetX = %CurtainsLeft.position.x
	var rightTargetX = %CurtainsRight.position.x
	
	%CurtainsLeft.position.x = -700
	%CurtainsRight.position.x = 1000
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(%CurtainsLeft, "position:x", leftTargetX, 1.0)
	tween.tween_property(%CurtainsRight, "position:x", rightTargetX, 1.0)
	
	setupCreditsQueue()

func setupCreditsQueue():
	var creditsDict = getCreditsArray()
	var creditsList = []
	for playerName in creditsDict.keys():
		creditsList.append({"name": playerName, "title": creditsDict[playerName]})
	creditsList.shuffle()
	
	var totalCredits = creditsList.size()
	var timePerCredit = (CREDITS_END_TIME - CREDITS_START_TIME) / totalCredits
	
	for i in range(totalCredits):
		var triggerTime = CREDITS_START_TIME + (i * timePerCredit)
		creditsQueue.append({
			"time": triggerTime,
			"name": creditsList[i]["name"],
			"title": creditsList[i]["title"],
			"shown": false
		})

func checkAndShowCredits():
	if currentCreditIndex >= creditsQueue.size():
		if not lastCreditFadedOut and currentTimePassed >= CREDITS_END_TIME and currentCreditNode != null:
			fadeOutCredit(currentCreditNode)
			currentCreditNode = null
			lastCreditFadedOut = true
		return
	
	var creditData = creditsQueue[currentCreditIndex]
	if currentTimePassed >= creditData["time"] and not creditData["shown"]:
		showCredit(creditData)
		creditsQueue[currentCreditIndex]["shown"] = true
		currentCreditIndex += 1

func showCredit(creditData: Dictionary):
	if currentCreditNode != null:
		fadeOutCredit(currentCreditNode)
	
	var creditInstance = OneCreditScene.instantiate()
	add_child(creditInstance)
	
	var randomX = randf_range(0, 420)
	var randomY = randf_range(500, 700)
	creditInstance.position = Vector2(randomX, randomY)
	
	creditInstance.setup(creditData["name"], creditData["title"])
	
	creditInstance.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(creditInstance, "modulate:a", 1.0, 0.5)
	
	currentCreditNode = creditInstance

func fadeOutCredit(creditNode: Node2D):
	var tween = get_tree().create_tween()
	tween.tween_property(creditNode, "modulate:a", 0.0, 0.5)
	tween.tween_callback(creditNode.queue_free)

func setPositionOfLabelAndSlideIn():
	var relevantLyric
	var otherLyric

	if useALyric:
		relevantLyric = %LyricA
		otherLyric = %LyricB
	else:
		relevantLyric = %LyricB
		otherLyric = %LyricA

	relevantLyric.position = %Clipper.position
	relevantLyric.position.y += %Clipper.size.y

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(relevantLyric, "position:y", %Clipper.position.y, 0.15)
	tween.tween_property(otherLyric, "position:y", %Clipper.position.y - %Clipper.size.y, 0.15)	

func roundDownToTenths(value: float) -> float:
	return floor(value * 10) / 10.0

func _input(event):
	if event.is_action_pressed('DebuButton'):
		print(currentTimePassed)

func tweenCurtains():
	if !$AudioStreamPlayer2D2.playing:
		$AudioStreamPlayer2D2.stream = cheerSound
		$AudioStreamPlayer2D2.play()
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(%CurtainsLeft, "position:x", -700, 1.5)
	tween.tween_property(%CurtainsRight, "position:x", 1000, 3)	

func crossfadeBackground(imagePath: String):
	var newTexture = load(imagePath)
	var fadeInBg: TextureRect
	var fadeOutBg: TextureRect
	
	if useBg1:
		fadeInBg = %bg1
		fadeOutBg = %bg2
	else:
		fadeInBg = %bg2
		fadeOutBg = %bg1
	
	fadeInBg.texture = newTexture
	fadeInBg.modulate.a = 0.0
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(fadeInBg, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(fadeOutBg, "modulate:a", 0.0, FADE_DURATION)
	
	useBg1 = !useBg1

func getLyricsArray():
	return {
		.1: "My face is on the side of the bus downtown",
		3.0: "But you're the only one not lookin' around.",
		6.0: "Past the camera lens and the record label",
		9.0: "No security-detail. No script to read.",
		12.5: "Just the kind of ghost that I wanted to be!",
		17.3: "You never asked for a name or a headline story ",
		20.0: "You looked past the stars and the wide-eyed boys",
		23.2: "Maybe you knew, but you played it so cool",
		26.5: "Just a guy who helped me break all the rules!",
		29.9: "And there's no trace of luck!",
		33.4: "(No Trace of Luck!)",
		35.8: "This isn't a gamble or a lucky draw!",
		41.2: "You didn't stumble on some kind of prize",
		44.0: "You chose to see me with your own two eyes",
		46.5: "(You chose to see me with your own two eyes!)",
		52.2: "I'm scrubbing the glitter in the dressing room tray",
		54.6: "Wiping the stage lights and the makeup away",
		57.5: "Tucking my hair in that thrift-store hat",
		60.0: "Racing the clock just to see where you're at!",
		64.7: "And there's no trace of luck",
		66.1: "(No Trace of Luck!)",
		67.7: "This isn't a gamble or a lucky draw!",
		70.7: "You didn't stumble on some kind of prize",
		73.2: "You chose to see me with your own two eyes!",
		79.0: "(You chose to see me with your own two eyes!)",
		85.0: "💕💕 Thank you all for playing! 💕💕"
	}

func getImagesArray():
	return {
		9.0: "res://data/assets/general/art/credits_art/credits2.webp",
		20.0: "res://data/assets/general/art/credits_art/credits3.webp",
		29.9: "res://data/assets/general/art/credits_art/credits4.webp",
		41.2: "res://data/assets/general/art/credits_art/credits5.webp",
		52.2: "res://data/assets/general/art/credits_art/credits6.webp",
		60.0: "res://data/assets/general/art/credits_art/credits7.webp",
		70.7: "res://data/assets/general/art/credits_art/credits8.webp",
		79.0: "res://data/assets/general/art/credits_art/credits9.png",
		85.0: "res://data/assets/general/art/credits_art/credits_test.png"
	}

func getCreditsArray():
	return {
		"Tim \"Manax\" Oertel": "King of Typos",
		"Nobletz": "OG Top Supporter",
		"H2Ooze": "OG Top GOAT",
		"Wrizt": "OG Top Supporter",
		"Joe": "OG Top Supporter",
		"PrinzAffe": "OG Top Supporter",
		"Johnny S": "Top Supporter",
		"Christopher Hollier": "OG Top Supporter",
		"kros": "OG Top Supporter",
	}

# [Verse 1] My face is on the side of the bus downtown But you’re the only one not looking around. Past the camera lens and the record-label. No security detail, no script to read Just the kind of ghost that I wanted to be

# [Prechorus] You never asked for a name or a headline story You looked past the stars and the wide-eyed boys. Maybe you knew, but you played it so cool Just a guy who helped me break all the rules

# [Chorus] And there’s no trace of luck No trace of luck This isn’t a gamble or a lucky draw. You didn't stumble on some kind of prize You chose to see me with your own two eyes

# [Verse 2] I’m scrubbing the glitter in the dressing room tray Wiping the stage lights and the makeup away Tucking my hair in that thrift-store hat Racing the clock just to see where you’re at!

# [Chorus] And there’s no trace of luck No trace of luck This isn’t a gamble or a lucky draw You didn't stumble on some kind of prize You chose to see me with your own two eyes
