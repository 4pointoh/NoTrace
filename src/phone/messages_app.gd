extends Node2D

@export var availableMessage : PackedScene
@export var messageText : PackedScene
@export var messageImage : PackedScene
@export var loadingAnim : PackedScene
@export var partnerStatus : PackedScene

var currentConversation
var contactName
var nextAction
var lastAddedMessage
var isFirstAction
var currentStatusMessage

var notUnlockedTexture = preload("res://data/assets/phone/art/loading_image.png")

@onready var imageLoadingSound = load("res://data/assets/phone/sounds/message_happy.wav")
@onready var imageFinishedLoadingSound = load("res://data/assets/phone/sounds/image_loading.wav")

@onready var messageSentSound = load("res://data/assets/phone/sounds/noti1.wav")
@onready var messageReceivedHappySound = load("res://data/assets/phone/sounds/message_high.wav")
@onready var messageReceivedDefaultSound = load("res://data/assets/phone/sounds/message_sent.wav")

@onready var messageStartTyping = load("res://data/assets/phone/sounds/click.wav")

signal newMessageSelect(stage : GameStage)
signal conversationComplete
signal beginDialogue(key : String)

func setup():
	var existingMsgs = $AvailableMessagesContainer.get_children()
	for existingMsg in existingMsgs:
		$AvailableMessagesContainer.remove_child(existingMsg)
		existingMsg.queue_free()
	
	var msgs = GlobalGameStage.getAvailableMessages()
	for msg in msgs:
		addAvailableMessage(msg)
	
	$AvailableMessagesContainer.show()

func addAvailableMessage(newMessage):
	var message = availableMessage.instantiate()
	message.pressed.connect(onMessageSelect)
	message.setMessageName(newMessage)
	$AvailableMessagesContainer.add_child(message)

func onMessageSelect(selectedStage):
	if selectedStage.contactImage:
		$HBoxContainer/icon.show()
		$HBoxContainer/icon.texture = selectedStage.contactImage
	else:
		$HBoxContainer/icon.hide()
	newMessageSelect.emit(selectedStage)

func onComplete():
	$HBoxContainer/icon.hide()
	conversationComplete.emit()

func closeApp():
	$MessageScreen.hide()
	$AvailableMessagesContainer.hide()
	$Respond.hide()
	hide()
	$HBoxContainer/ContactName.text = "Contacts"
	
func startConversation():
	$AvailableMessagesContainer.visible = false
	$MessageScreen.clear()
	lastAddedMessage = null
	$MessageScreen.visible = true
	currentConversation = GlobalGameStage.currentStage.phoneScript.new()
	contactName = GlobalGameStage.currentStage.contactName
	
	$HBoxContainer/ContactName.text = contactName
	isFirstAction = true
	processNextAction()

func processNextAction():
	nextAction = currentConversation.getNextAction()
	
	if nextAction.action == PhoneAction.ACTIONS.TEXT_YOU:
		enableRespond()
	elif nextAction.action == PhoneAction.ACTIONS.TEXT_PARTNER:
		if lastAddedMessage:
			if isFirstAction:
				await readReceiptDelay()
			else:
				await readReceiptFast()
				
			await loadingMessage()
			
		addText(false, nextAction.message, nextAction.soundType)
		
		isFirstAction = false
		processNextAction()
	elif nextAction.action == PhoneAction.ACTIONS.IMAGE_PARTNER:
		await loadingMessage()
		await addImage(nextAction.image)
		
		isFirstAction = false
		processNextAction()
	elif nextAction.action == PhoneAction.ACTIONS.CHOICE:
		enableRespond()
	elif nextAction.action == PhoneAction.ACTIONS.DIALOGUE:
		startDialogue(nextAction.dialogueKey)
	elif nextAction.action == PhoneAction.ACTIONS.COMPLETE:
		onComplete()
	elif nextAction.action == PhoneAction.ACTIONS.PARTNER_DELAY:
		await delay(nextAction.message)
		processNextAction()

func loadingMessage():
	var loading = loadingAnim.instantiate()
	loading.play()
	await get_tree().create_timer(2).timeout
	
	# Remove the status if it's there
	if(is_instance_valid(currentStatusMessage) and currentStatusMessage):
		$MessageScreen/VBoxContainer.remove_child(currentStatusMessage)
		currentStatusMessage.queue_free()
		currentStatusMessage = null
		
	$MessageScreen/VBoxContainer.add_child(loading)
	$AudioStreamPlayer2D.stream = messageStartTyping
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(4).timeout
	$MessageScreen/VBoxContainer.remove_child(loading)
	loading.queue_free()
	
func delay(message):
	if(message):
		await get_tree().create_timer(1.75).timeout
		currentStatusMessage = partnerStatus.instantiate()
		currentStatusMessage.setText(message)
		$MessageScreen/VBoxContainer.add_child(currentStatusMessage)
		await get_tree().create_timer(3).timeout
	else:
		await get_tree().create_timer(4).timeout
	
func readReceiptDelay():
	await get_tree().create_timer(2).timeout
	lastAddedMessage.enableReadReceipt()
	await get_tree().create_timer(2).timeout

func readReceiptFast():
	await get_tree().create_timer(1).timeout
	lastAddedMessage.enableReadReceipt()
	
func addText(isPlayer, message, soundType = PhoneAction.SOUND_TYPE.DEFAULT):
	var newText = messageText.instantiate()
	newText.setMessage(isPlayer, message, contactName)
	
	if isPlayer:
		newText.size_flags_horizontal = Control.SIZE_SHRINK_END
	else:
		newText.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	lastAddedMessage = newText
	$MessageScreen/VBoxContainer.add_child(newText)
	
	if isPlayer:
		$AudioStreamPlayer2D.stream = messageSentSound
		$AudioStreamPlayer2D.play()
	elif soundType == PhoneAction.SOUND_TYPE.DEFAULT:
		$AudioStreamPlayer2D.stream = messageReceivedDefaultSound
		$AudioStreamPlayer2D.play()
	elif soundType == PhoneAction.SOUND_TYPE.HAPPY:
		$AudioStreamPlayer2D.stream = messageReceivedHappySound
		$AudioStreamPlayer2D.play()

func enableRespond():
	$Respond.visible = true

func disableRespond():
	$Respond.visible = false

func addImage(image):
	var newImage = messageImage.instantiate()
	newImage.setTexture(image)
	newImage.noFullscreen = true
	$MessageScreen/VBoxContainer.add_child(newImage)
	$AudioStreamPlayer2D.stream = imageLoadingSound
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(5).timeout
	$AudioStreamPlayer2D.stream = imageFinishedLoadingSound
	$AudioStreamPlayer2D.play()
	newImage.noFullscreen = false

func startDialogue(key):
	await get_tree().create_timer(2).timeout
	beginDialogue.emit(key)

func setDialogueEnded():
	processNextAction()

func addChoices(choices):
	$Choice.setChoices(choices)
	$Choice.visible = true
	$Choice/AnimationPlayer.play("slide_in")

func _on_choice_choice(id, text):
	currentConversation.handleChoice(id)
	addText(true, text)
	$Choice.visible = false
	processNextAction()

func _on_respond_pressed():
	if nextAction.action == PhoneAction.ACTIONS.TEXT_YOU:
		disableRespond()
		addText(true, nextAction.message)
		processNextAction()
	elif nextAction.action == PhoneAction.ACTIONS.CHOICE:
		disableRespond()
		addChoices(nextAction.choices)

func playMessageSent():
	pass

func playMessageReceived():
	pass
	
func playImageLoading():
	pass
	
func playImageFinishedLoading():
	pass