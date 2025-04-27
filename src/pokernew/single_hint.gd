extends Control

var starIcon = load("res://data/assets/realdate/star_result.png")

func setup(stars: int, txt: String):
	for i in range(0, stars):
		var star = TextureRect.new()
		star.texture = starIcon
		star.custom_minimum_size.x = 20
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		%StarContainer.add_child(star)
	
	%HintText.text = txt
	custom_minimum_size.y = calculate_wrapped_text_height(%HintText.text, load("res://data/assets/general/art/PoetsenOne-Regular.ttf"), 16, %HintText.custom_minimum_size.x)
	var string_size = load("res://data/assets/general/art/PoetsenOne-Regular.ttf").get_string_size(%HintText.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	print(string_size)

	print(calculate_wrapped_text_height(%HintText.text, load("res://data/assets/general/art/PoetsenOne-Regular.ttf"), 16, 280))

func calculate_wrapped_text_height(text: String, font: Font, font_size: int, max_width: float) -> float:
	# Get the dimensions of the text as a single line
	var string_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Calculate how many lines we'll need
	var num_lines = ceil(string_size.x / max_width)
	
	# If it's less than one line, we still need at least one line
	num_lines = max(1, num_lines)
	
	# Calculate the total height by multiplying line height by number of lines
	var total_height = string_size.y * num_lines
	
	return total_height
