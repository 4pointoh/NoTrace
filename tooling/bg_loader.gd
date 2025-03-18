@tool
extends EditorScript

func _run() -> void:
	var input_dir_name : String = "anna_burger"
	var input_directory: String = "res://data/background_lists/" + input_dir_name + "/"         # Where .png files are located
	var output_path: String = "res://data/background_lists/" + input_dir_name + "/" + input_dir_name + ".tres"     # Where to save generated .tres
	create_background_list_from_directory(input_directory, output_path, input_dir_name)

func create_background_list_from_directory(directory_path: String, output_path: String, input_dir_name) -> void:
	var background_list: BackgroundList = BackgroundList.new()
	background_list.name = input_dir_name
	background_list.images = []

	var dir: DirAccess = DirAccess.open(directory_path)
	if dir == null:
		push_error("Could not open directory: %s" % directory_path)
		return

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue

		if file_name.ends_with(".png") or file_name.ends_with(".webp"):
			var full_path: String = directory_path + "/" + file_name

			# Instead of using ImageTexture.load(), do this:
			# load() returns a Resource, which should be a Texture2D for a PNG file.
			var tex: Texture2D = load(full_path)
			if tex == null:
				push_warning("Failed to load file as texture: %s" % full_path)
				continue

			# Create a new Background resource
			var bg: Background = Background.new()
			bg.name = file_name
			bg.images = tex  # Assign the loaded texture

			# Add it to the list
			background_list.images.append(bg)

	dir.list_dir_end()

	# Save the BackgroundList as a .tres
	var save_result: Error = ResourceSaver.save(background_list, output_path)
	if save_result != OK:
		push_error("Failed to save BackgroundList to: %s" % output_path)
	else:
		print("Successfully saved BackgroundList to: %s" % output_path)
