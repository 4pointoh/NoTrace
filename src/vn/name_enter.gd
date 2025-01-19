extends ColorRect


func _on_button_pressed():
	var name2 = %TextEdit.text
	
	if name2.length() == 0:
		name2 = 'Sam'
	
	GlobalGameStage.setName(name2)
	
	print(GlobalGameStage.playerName)
	hide()
