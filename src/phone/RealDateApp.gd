extends Node2D

@export var realDateFace : PackedScene
@export var realDateChoice : PackedScene

signal selected(stage : GameStage)

func setup():
	%GirlInfo.hide()
	%HelpText.show()
	
	GlobalGameStage.startMusic('res://data/assets/general/sounds/bg_music/new/Untitled(20).mp3')
	
	if GlobalGameStage.hasUnlockedDateGirl(GlobalGameStage.CHARACTERS.LISA):
		addFace('res://data/characters/lisa/phone_icons/default.png', GlobalGameStage.CHARACTERS.LISA)
	else:
		addFace('res://data/assets/realdate/unknown_face.png', GlobalGameStage.CHARACTERS.UNKNOWN, true)
	
	if GlobalGameStage.hasUnlockedDateGirl(GlobalGameStage.CHARACTERS.ASHLEY):
		addFace('res://data/characters/ashely/phone_icons/default.png', GlobalGameStage.CHARACTERS.ASHLEY)
	else:
		addFace('res://data/assets/realdate/unknown_face.png', GlobalGameStage.CHARACTERS.UNKNOWN, true)
	
	if GlobalGameStage.hasUnlockedDateGirl(GlobalGameStage.CHARACTERS.ANA):
		addFace('res://data/characters/anna/phone_icons/default.png', GlobalGameStage.CHARACTERS.ANA)
	else:
		addFace('res://data/assets/realdate/unknown_face.png', GlobalGameStage.CHARACTERS.UNKNOWN, true)
	
	if GlobalGameStage.hasUnlockedDateGirl(GlobalGameStage.CHARACTERS.AMY):
		addFace('res://data/characters/amy/phone_icons/default.png', GlobalGameStage.CHARACTERS.AMY)
	else:
		addFace('res://data/assets/realdate/unknown_face.png', GlobalGameStage.CHARACTERS.UNKNOWN, true)
	
	
func addFace(path : String, girl : GlobalGameStage.CHARACTERS, unknown = false):
	var texRec = realDateFace.instantiate()
	texRec.setup(girl, load(path))
	
	if !unknown:
		texRec.clicked.connect(_handle_face_clicked)
		
	texRec.custom_minimum_size.x = 80
	%FaceContainer.add_child(texRec)

func reset():
	for ch in %GridContainer.get_children():
		%GridContainer.remove_child(ch)
		ch.queue_free()
	
	for ch in %FaceContainer.get_children():
		%FaceContainer.remove_child(ch)
		ch.queue_free()
		
	hide()

func _handle_face_clicked(girl : GlobalGameStage.CHARACTERS):
	
	%RelLevel.text = str(GlobalGameStage.getRelationshipLevel(girl))
	%CharName.text = GlobalGameStage.getCharNameForGirl(girl)
	%GirlInfo.show()
	%HelpText.hide()
	
	for ch in %GridContainer.get_children():
		%GridContainer.remove_child(ch)
		ch.queue_free()
	
	var rds = GlobalGameStage.getRealDatesForGirl(girl)
	
	for rd in rds:
		var rdc = realDateChoice.instantiate()
		var gameSt = load(rd)
		rdc.setup(rd, gameSt.stageButtonLabel, gameSt.stageButtonTexture, gameSt.heartLevel)
		rdc.selected.connect(_handle_date_selected)
		%GridContainer.add_child(rdc)
	
func _handle_date_selected(id):
	selected.emit(load(id))
