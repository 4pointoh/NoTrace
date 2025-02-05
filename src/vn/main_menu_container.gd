extends ColorRect

var saveMode = false
var loadMode = false
var showBack = false

@export var saveItem : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	$MainMenuContainer/TextSpeed.value = GlobalGameStage.getTextSpeed()
	$MainMenuContainer/BgVolume.value = GlobalGameStage.getBgVolume()
	$MainMenuContainer/BgVolume.value_changed.connect(_on_bg_volume_value_changed)
	$MainMenuContainer/TextSpeed.value_changed.connect(_on_text_speed_value_changed)

func showMenu(show_back = false):
	$MainMenuContainer.show()
	$SavesContainer.hide()
	$Label.hide()
	$Back.visible = show_back
	%CharName.text = GlobalGameStage.playerName
	showBack = show_back 
		
	
func showLoadMenu(show_back = false):
	showBack = show_back
	_on_load_pressed()

func _on_text_speed_value_changed(value):
	GlobalGameStage.setTextSpeed(value)

func _on_bg_volume_value_changed(value):
	GlobalGameStage.setBgVolume(value)

func _on_save_pressed():
	saveMode = true
	loadMode = false
	setup()
	$SavesContainer.show()
	$MainMenuContainer.hide()
	$Label.visible = true
	$Label.text = 'SAVE'
	

func _on_load_pressed():
	saveMode = false
	loadMode = true
	setup()
	$SavesContainer.show()
	$MainMenuContainer.hide()
	$Label.visible = true
	$Label.text = 'LOAD'
	$Back.visible = true
	

func setup():
	print(loadMode)
	for chi in $SavesContainer.get_children():
		chi.queue_free()
	
	var availableSaves = GlobalGameStage.getExistingSaves()
		
	var saveNum = 0
	while saveNum < 10:
		saveNum += 1
		var saveName = "user://save" + str(saveNum) + ".dat"
		
		var newSaveSelect = saveItem.instantiate()
		newSaveSelect.save_name = saveName
			
		if availableSaves.has(saveName):
			var savedgs = GlobalGameStage.getSaveDataInfo(saveName)
			var time = FileAccess.get_modified_time(saveName)
			var ut = Time.get_datetime_string_from_unix_time(time)
			
			if savedgs:
				newSaveSelect.text = "Save " + str(saveNum) + " - " + savedgs.displayName + ' | ' + str(ut) 
			else:
				newSaveSelect.text = "Save " + str(saveNum) + " - " + str(ut)
		else:
			newSaveSelect.text = "New Save"
			if loadMode:
				continue
		
		$SavesContainer.add_child(newSaveSelect)
		newSaveSelect.clicked.connect(_handle_save_selected)
	setCurrentSpeedText()

func _handle_save_selected(saveName):
	if saveMode:
		GlobalGameStage.saveSaveData(saveName)
		setup()
	elif loadMode:
		GlobalGameStage.loadSaveData(saveName)
	
func _on_back_pressed():
	if saveMode || loadMode:
		$SavesContainer.hide()
		$MainMenuContainer.show()
		$Label.visible = false
		saveMode = false
		loadMode = false
		$Back.visible = showBack
	else:
		visible = false

func _on_main_menu_pressed():
	pass # Replace with function body.


func _on_text_edit_text_changed():
	GlobalGameStage.setName(%CharName.text)


func _on_slow_button_pressed():
	GlobalGameStage.setSkipSpeed(0.2)
	setCurrentSpeedText()

func _on_fast_button_pressed():
	GlobalGameStage.setSkipSpeed(0.1)
	setCurrentSpeedText()

func _on_extreme_button_pressed():
	GlobalGameStage.setSkipSpeed(0.02)
	setCurrentSpeedText()

func _on_recommended_button_pressed():
	GlobalGameStage.setSkipSpeed(0.15)
	setCurrentSpeedText()

func setCurrentSpeedText():
	if GlobalGameStage.skip_speed == 0.2:
		%CurrentSpeed.text = 'Current: Slow'
	elif GlobalGameStage.skip_speed == 0.1:
		%CurrentSpeed.text = 'Current: Fast'
	elif GlobalGameStage.skip_speed == 0.02:
		%CurrentSpeed.text = 'Current: Extreme'
	elif GlobalGameStage.skip_speed == 0.15:
		%CurrentSpeed.text = 'Current: Recommended'


func _on_save_loc_open_pressed():
	OS.shell_open(OS.get_user_data_dir())
