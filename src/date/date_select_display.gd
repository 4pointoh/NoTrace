extends Node2D

signal choice_selected(index : int)
signal skip_date_selected()

func _ready():
	if GlobalGameStage.hasCompletedCurrentStageGlobally():
		%SkipButton.show()
	else:
		%SkipButton.hide()

func showWithAnimation():
	show()
	%AnimationPlayer.play("pop_up")

func setBusinessLabel(label : String):
	%BusinessButton.setMainLabel(label)

func setTalkCgAvailable(available : bool):
	%TalkButton.setCgsAvailable(available)

func setFlirtCgAvailable(available : bool):
	%FlirtButton.setCgsAvailable(available)

func setBusinessCgAvailable(available : bool):
	%BusinessButton.setCgsAvailable(available)

func setTalkProgressNeeded(locked: bool):
	%TalkButton.setProgressNeeded(locked)

func setFlirtProgressNeeded(locked: bool):
	%FlirtButton.setProgressNeeded(locked)

func setBusinessProgressNeeded(locked: bool):
	%BusinessButton.setProgressNeeded(locked)

func _on_talk_button_clicked():
	choice_selected.emit(0)
	%AudioStreamPlayer.play()

func _on_flirt_button_clicked():
	choice_selected.emit(1)
	%AudioStreamPlayer.play()

func _on_business_button_clicked():
	choice_selected.emit(2)
	%AudioStreamPlayer.play()

func _on_small_talk_button_pressed():
	choice_selected.emit(3)
	%AudioStreamPlayer.play()

func _on_skip_button_pressed():
	skip_date_selected.emit()
