@tool
extends EditorScript

func _run() -> void:
	var gamestageName = 'ana_realdate_one_date1'
	
	var backgroundLists: Array[String] = [
		'res://data/background_lists/home/home_bgl.tres'
	]
	
	var characters: Array[String] = [
		'res://data/characters/you/you.tres',
		'res://data/characters/anna/anna_party/anna_party_with_name.tres'
	]
	
	var type = "realdate" #vn, poker, date, phonemessage, special
	var output_path: String = "res://data/game_stages/"    
	
	if type == "vn":
		output_path += "vn"
	elif type == "special":
		output_path += "special"
	elif type == "poker":
		output_path += "poker"
	elif type == "phonemessage":
		output_path += "phone_message"
	elif type == "date":
		output_path += "dates"
	elif type == "realdate":
		output_path += "realdate"
	else:
		assert(false)

	output_path += '/' + gamestageName
	
	var output_path_temp = output_path + '/gs_' + gamestageName + '.tres'
	print(output_path_temp)
	if FileAccess.file_exists(output_path_temp):
		push_error("File already exists at '%s'. Aborting to avoid overwrite." % output_path_temp)
		return
	
	create_game_stage_data(output_path, gamestageName, backgroundLists, characters, type)

func create_game_stage_data(output_path: String, gamestageName: String, backgroundLists : Array[String], characters: Array[String], type: String) -> void:
	var newGameStage: GameStage = GameStage.new()
	var newDialogueData: DialogueData = DialogueData.new()
	var newCharacterList: CharacterList = CharacterList.new()
	var newBgLists: BackgroundLists = BackgroundLists.new()
	
	var gs_output =  output_path + '/gs_' + gamestageName + '.tres'
	var char_output = output_path + '/characters' + '.tres'
	var dialogue_output = output_path + '/d_' + gamestageName + '.tres'
	var background_list_output = output_path + '/bgs' + '.tres'
	
	for bgl in backgroundLists:
		newBgLists.backgroundLists.append(load(bgl))
	
	for char in characters:
		newCharacterList.characters.append(load(char))
	
	print(output_path)
	DirAccess.make_dir_absolute(output_path)
	
	var save_result: Error = ResourceSaver.save(newBgLists, background_list_output)
	if save_result != OK:
		push_error("Failed to save BackgroundLists to: %s" % background_list_output)
	else:
		print("Successfully saved BackgroundLists to: %s" % background_list_output)
	
	save_result = ResourceSaver.save(newCharacterList, char_output)
	if save_result != OK:
		push_error("Failed to save character list to: %s" % char_output)
	else:
		print("Successfully saved character list to: %s" % char_output)
	
	
	newDialogueData.backgroundList = background_list_output
	newDialogueData.characters = char_output
	
	save_result = ResourceSaver.save(newDialogueData, dialogue_output)
	if save_result != OK:
		push_error("Failed to save dialogue data to: %s" % dialogue_output)
	else:
		print("Successfully saved dialogue data to: %s" % dialogue_output)
	
	newGameStage.name = gamestageName
	newGameStage.dialogue = load(dialogue_output)
	newGameStage.dialogueStartKey = 'START'
	
	if type == "poker":
		newGameStage.isPokerMatch = true
		newGameStage.playerStartingMoney = 200
		newGameStage.cpuStartingMoney = 200
		newGameStage.startingAnte = 20
		newGameStage.opponentName = 'REPLACE_ME'
		newGameStage.maxRaise = 40
	
		var template_script_path = "res://data/game_stages/poker/lisa_park_training_poker/scripts/lisa_park_training_poker_script.gd"
		var poker_script_output_path = output_path + "/" + gamestageName + "_poker_script.gd"
		var template_file = FileAccess.open(template_script_path, FileAccess.READ)
		if template_file == null:
			push_error("Cannot open template script: %s" % template_script_path)
			return

		var new_script_file = FileAccess.open(poker_script_output_path, FileAccess.WRITE_READ)
		if new_script_file == null:
			template_file.close()
			push_error("Cannot create target script file: %s" % poker_script_output_path)
			return

		var script_content: String = template_file.get_as_text()
		new_script_file.store_string(script_content)
		new_script_file.close()
		template_file.close()

		var new_script_resource: GDScript = load(poker_script_output_path)
		if new_script_resource == null:
			push_error("Failed to load new script at: %s" % poker_script_output_path)
			return

		newGameStage.pokerScript = new_script_resource
		newGameStage.isCompletable = true
	elif type == 'date':
		newGameStage.isDate = true
		newGameStage.isCompletable = true
		
		var template_script_path = "res://data/game_stages/dates/ashely_park_date/scripts/ashely_park_date_script.gd"
		var poker_script_output_path = output_path + "/" + gamestageName + "_date_script.gd"
		var template_file = FileAccess.open(template_script_path, FileAccess.READ)
		if template_file == null:
			push_error("Cannot open template script: %s" % template_script_path)
			return

		var new_script_file = FileAccess.open(poker_script_output_path, FileAccess.WRITE_READ)
		if new_script_file == null:
			template_file.close()
			push_error("Cannot create target script file: %s" % poker_script_output_path)
			return

		var script_content: String = template_file.get_as_text()
		new_script_file.store_string(script_content)
		new_script_file.close()
		template_file.close()

		var new_script_resource: GDScript = load(poker_script_output_path)
		if new_script_resource == null:
			push_error("Failed to load new script at: %s" % poker_script_output_path)
			return

		newGameStage.dateScript = new_script_resource
		newGameStage.dateCharacter = 'CHARACTER_NAME'
		newGameStage.dateTitle = "DATE WITH [REPLACEME]"
		newGameStage.dateBusinessButtonLabel = 'REPLACEME'
		newGameStage.maxProgress = 180
		newGameStage.dateLossDialogueKey = 'LOST'
	elif type == 'phonemessage':
		newGameStage.isPhoneMessageEvent = true
		newGameStage.contactName = 'REPLACEME'
	elif type == 'realdate':
		newGameStage.isRealDate = true
		newGameStage.numberOfSelections = 4
		newGameStage.firstRoundGuesses = 6
		newGameStage.secondRoundGuesses = 4

	save_result = ResourceSaver.save(newGameStage, gs_output)
	if save_result != OK:
		push_error("Failed to save game stage to: %s" % gs_output)
	else:
		print("Successfully saved game stage to: %s" % gs_output)
