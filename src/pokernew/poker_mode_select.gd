extends Node2D

signal selectedMode(mode: int)

func _ready():
	setRegularModeText()
	setProPlusModeText()
	setProPlusMaxModeText()
	
	%RegularMode.hide()
	%PokerProPlus.hide()
	%PokerProPlusMax.hide()
	
	if GlobalGameStage.currentStage.allowProPlus:
		%RegularMode.show()
		%PokerProPlus.show()
		%NormalModeDescription.show()
		if GlobalGameStage.getCurrentStagePokerLosses() > 0:
			%ProPlusLocked.hide()
			%ProPlusDescription.show()
			%ProPlusUnlockLabel.hide()
			%ProPlusButton.disabled = false
		else:
			%ProPlusButton.disabled = true
	
	if GlobalGameStage.currentStage.allowProPlusMax:
		%RegularMode.show()
		%PokerProPlusMax.show()
		%NormalModeDescription.show()
		if GlobalGameStage.getCurrentStagePokerWins() > 0:
			%ProPlusMaxLocked.hide()
			%ProPlusMaxDescription.show()
			%ProPlusMaxUnlockLabel.hide()
			%ProPlusMaxButton.disabled = false
		else:
			%ProPlusMaxButton.disabled = true
	
	_on_normal_mode_button_pressed()

func highlightSelection(selection: int):
	%RegularMode.modulate = Color(1.0, 1.0, 1.0, 1.0)
	%PokerProPlus.modulate = Color(1.0, 1.0, 1.0, 1.0)
	%PokerProPlusMax.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if selection == 0:
		%RegularMode.modulate = Color(.17, .95, 0, 1.0)
	elif selection == 1:
		%PokerProPlus.modulate = Color(.17, .95, 0, 1.0)
	elif selection == 2:
		%PokerProPlusMax.modulate = Color(.17, .95, 0, 1.0)
	
func setRegularModeText():
	if GlobalGameStage.currentStage.cheatCount == 0:
		%NormalModeDescription.text = "No Cheats"
	elif GlobalGameStage.currentStage.cheatCount == 1:
		%NormalModeDescription.text = "1 Cheat"
	elif GlobalGameStage.currentStage.cheatCount > 1:
		%NormalModeDescription.text = str(GlobalGameStage.currentStage.cheatCount) + " Cheats"

func setProPlusModeText():
	if GlobalGameStage.currentStage.proPlusCheats == 0:
		%ProPlusDescription.text = "No Cheats"
	elif GlobalGameStage.currentStage.proPlusCheats == 1:
		%ProPlusDescription.text = "1 Cheat"
	elif GlobalGameStage.currentStage.proPlusCheats > 1:
		%ProPlusDescription.text = str(GlobalGameStage.currentStage.proPlusCheats) + " Cheats"

func setProPlusMaxModeText():
	if GlobalGameStage.currentStage.proPlusMaxCheats == 0:
		%ProPlusMaxDescription.text = "No Cheats"
	elif GlobalGameStage.currentStage.proPlusMaxCheats == 1:
		%ProPlusMaxDescription.text = "1 Cheat"
	elif GlobalGameStage.currentStage.proPlusMaxCheats > 1:
		%ProPlusMaxDescription.text = str(GlobalGameStage.currentStage.proPlusMaxCheats) + " Cheats"

func _on_pro_plus_max_button_pressed() -> void:
	selectedMode.emit(2)
	highlightSelection(2)

func _on_pro_plus_button_pressed() -> void:
	selectedMode.emit(1)
	highlightSelection(1)

func _on_normal_mode_button_pressed() -> void:
	selectedMode.emit(0)
	highlightSelection(0)
