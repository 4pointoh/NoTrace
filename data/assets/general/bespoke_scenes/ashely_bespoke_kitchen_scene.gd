extends Node2D

var phoneOffImg : Texture2D
var phoneOnImg : Texture2D
var buzzSound
var phoneOnTime : float
var phoneBuzzDuration : float = 1
var _is_escalating_buzz := false
var currentMessageIndex = 0
var messageElements = []

var messageTimers = [0,0,0,0,0]
var messageTimerDurationSlow = 1
var messageTimerDurationFast = 0.2
var useFastMessageTimer = false

var messageElementsReady = false

func _ready():
	startScene()
	await get_tree().create_timer(4).timeout
	startEscalatingBuzz()
	messageElementsReady = true
	messageElements = [
		%MessageFromLeft1,
		%MessageFromRight1,
		%MessageFromLeft2,
		%MessageFromRight2,
		%MessageFromLeft3,
	]
	
	%MessageFromLeft1.text = 'Message From:\n' + GlobalGameStage.playerName
	%MessageFromRight1.text =  'Message From:\n' + GlobalGameStage.playerName
	%MessageFromLeft2.text = 'Message From:\n' + GlobalGameStage.playerName
	%MessageFromRight2.text = 'Message From:\n' + GlobalGameStage.playerName
	%MessageFromLeft3.text = 'Message From:\n' + GlobalGameStage.playerName

func _process(delta: float) -> void:
	phoneOnTime += delta
	if phoneOnTime > phoneBuzzDuration:
		setPhoneOff()
	
	var messageTimerDuration
	if messageElementsReady:
		for i in range(messageTimers.size()):
			if messageElements[i].visible:
				if useFastMessageTimer:
					messageTimerDuration = messageTimerDurationFast
				else:
					messageTimerDuration = messageTimerDurationSlow
				
				messageTimers[i] += delta
				if messageTimers[i] > messageTimerDuration:
					messageTimers[i] = 0
					messageElements[i].visible = false


func startScene():
	phoneOffImg = load('res://data/assets/general/bespoke_scenes/ashely_bespoke_kitchen_1.png')
	phoneOnImg = load('res://data/assets/general/bespoke_scenes/ashely_bespoke_kitchen_2.png')
	buzzSound = load('res://data/assets/general/bespoke_scenes/phone_buzz.mp3')
	%AudioStreamPlayer2D.stream = buzzSound
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.5)

func playPhoneBuzz():
	phoneOnTime = 0
	setPhoneIlluminated()
	%AudioStreamPlayer2D.play()
	messageElements[currentMessageIndex].visible = true
	currentMessageIndex += 1
	if currentMessageIndex >= messageElements.size():
		currentMessageIndex = 0

func startEscalatingBuzz() -> void:
	if _is_escalating_buzz:
		return
	_is_escalating_buzz = true
	call_deferred("_run_escalating_buzz")

func _run_escalating_buzz() -> void:
	# Ramp delays down in stages before finishing with a rapid-fire burst.
	var staged_intervals := [5.0, 4.0, 4.0, 4.0, 2, 2, 2, 0.8, 0.6, 0.4, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]
	for interval in staged_intervals:
		playPhoneBuzz()
		await get_tree().create_timer(interval).timeout

	# Hold the fastest pace for a bit longer to sell the gag.
	messageTimerDurationFast = true
	var final_burst_interval := 0.1
	var final_burst_count := 25
	for i in range(final_burst_count):
		if i == final_burst_count:
			%AudioStreamPlayer2D.stop()
			return
		playPhoneBuzz()
		await get_tree().create_timer(final_burst_interval).timeout

	_is_escalating_buzz = false
	GlobalGameStage.stopBespoke('Ashely Kitchen Phone')

func setPhoneIlluminated():
	%TextureRect.texture = phoneOnImg

func setPhoneOff():
	%TextureRect.texture = phoneOffImg

func _on_button_pressed() -> void:
	startEscalatingBuzz()
