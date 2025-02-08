@tool
extends EditorScript

func _run() -> void:
	var character_variant: String = 'orange_skirt_new'
	var character_resource: String = 'res://data/characters/lisa/orange_skirt_new/orange_skirt_new.tres'
	var char_art_directory: String = "res://data/characters/lisa/orange_skirt_new/character_art/"         # Where .png files are located
	
	var existingchar = load(character_resource)
	
	if existingchar.states.size() > 0:
		push_error("Character already has states. Exiting. (This could fuck up the indexes in dialogues)")
	
	existingchar.states = []
	
	var dir: DirAccess = DirAccess.open(char_art_directory)
	if dir == null:
		push_error("Could not open directory: %s" % char_art_directory)
		return

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue

		if file_name.ends_with(".png"):
			
			var full_path: String = char_art_directory + "/" + file_name

			var tex: Texture2D = load(full_path)
			if tex == null:
				push_warning("Failed to load file as texture: %s" % full_path)
				continue

			# Create a new Background resource
			var newCharacterState = CharacterState.new()
			newCharacterState.name = file_name
			newCharacterState.scale = Vector2(0.7,0.7)
			newCharacterState.animateTransition = true
			newCharacterState.image = tex

			# Add it to the list
			existingchar.states.append(newCharacterState)

	dir.list_dir_end()
	
	var save_result: Error = ResourceSaver.save(existingchar, character_resource)
	if save_result != OK:
		push_error("Failed to save character states to: %s" % character_resource)
	else:
		print("Successfully saved character states to: %s" % character_resource)

