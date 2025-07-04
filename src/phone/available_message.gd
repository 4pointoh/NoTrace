extends Control

signal pressed(stage: GameStage)

var gameStage

func setMessageName(newStage):
	gameStage = newStage
	$ColorRect/Name.text = newStage.contactName
	if newStage.contactImage:
		$ColorRect/icon.show()
		$ColorRect/icon.texture = newStage.contactImage
	else:
		$ColorRect/icon.hide()
	
	if newStage.contactName == 'Lisa':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg3_outline.png")
	elif newStage.contactName == 'Ashely' or newStage.contactName == 'Unknown Number':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg5_outline.png")
	elif newStage.contactName == 'Chad':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg6_outline.png")
	elif newStage.contactName == 'Amy':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg6_shadow.png")
	elif newStage.contactName == 'Ana' or newStage.contactName == 'Anna':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg7_outline.png")

func setPastMessageName(newStage):
	gameStage = newStage

	$ColorRect/Name.text = newStage.displayName
	$ColorRect/Name.set("theme_override_font_sizes/font_size", 16)

	if newStage.contactImage:
		$ColorRect/icon.show()
		$ColorRect/icon.texture = newStage.contactImage
	else:
		$ColorRect/icon.hide()
	
	if newStage.contactName == 'Lisa':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg3_outline.png")
	elif newStage.contactName == 'Ashely' or newStage.contactName == 'Unknown Number':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg5_outline.png")
	elif newStage.contactName == 'Chad':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg6_outline.png")
	elif newStage.contactName == 'Amy':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg6_shadow.png")
	elif newStage.contactName == 'Ana' or newStage.contactName == 'Anna':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg7_outline.png")

func _on_button_pressed():
	pressed.emit(gameStage)
