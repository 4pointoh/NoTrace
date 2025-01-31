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
	elif newStage.contactName == 'Ana':
		$ColorRect.texture = load("res://data/assets/phone/art/message_text_bg7_outline.png")



func _on_button_pressed():
	pressed.emit(gameStage)
