@tool
extends EditorScript

# Creates ONLY the character resource
# Use char_art_loader to load states to it

func _run() -> void:
	var character_name: String = 'Ashely' #capitalize
	var character_variant: String = 'ashely_tshirt_new'
	
	var face_image_path: String = "res://data/characters/ashely/ashely_tshirt_new/face.png"
	
	var output_root: String = 'res://data/characters/' + character_name.to_lower() + '/' + character_variant + '/'
	var output_resource: String = output_root + character_variant + '.tres'     # Where .png files are located
	
	if FileAccess.file_exists(output_resource):
		push_error("Character already exists. Exiting" + output_resource)
		return

	DirAccess.make_dir_absolute(output_root)
		
	var newChar = Character.new()
	newChar.name = character_name
	newChar.editorName = character_variant
	
	if face_image_path.length() > 0:
		newChar.image = load(face_image_path)
	
	var save_result: Error = ResourceSaver.save(newChar, output_resource)
	if save_result != OK:
		push_error("Failed to save character to: %s" % output_resource)
	else:
		print("Successfully saved character to: %s" % output_resource)

