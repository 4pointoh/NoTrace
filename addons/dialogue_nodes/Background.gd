@tool
extends Control

signal file_selected(backgroundLists : Array[BackgroundList])
signal modified

@onready var loadButton = $HBoxContainer/LoadButton
@onready var filePath = $HBoxContainer/FilePath
@onready var resetButton = $HBoxContainer/ResetButton
@onready var openDialog = $OpenDialog

var bgLists : Array[BackgroundList]


func load_file(path : String):
	filePath.text = path
	_on_filePath_changed()
	
	if path.ends_with('.tres') and load(path) is BackgroundLists:
		return
	
	if path != '':
		printerr('Invalid Background Lists resource file!')


func _on_loadButton_pressed():
	openDialog.popup_centered()


func _on_resetButton_pressed():
	filePath.text = ''
	_on_filePath_changed()


func _on_filePath_changed():
	bgLists = []
	if filePath.text == '':
		resetButton.hide()
	else:
		resetButton.show()
		
		var path = filePath.text
		if path.ends_with('.tres'):
			var file = load(path)
			if file is BackgroundLists:
				bgLists = file.backgroundLists
	file_selected.emit(bgLists)
	modified.emit()
