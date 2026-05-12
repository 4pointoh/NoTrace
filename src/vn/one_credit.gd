extends Node2D

func setup(playername : String, title : String):
	%Title.add_theme_color_override("font_color", getColorFromTitle(title))
	%Title.text = title
	%Name.text = playername

func getColorFromTitle(title: String):
	if title == 'OG Top Supporter':
		return Color.AQUA
	elif title == 'OG Top GOAT':
		return Color.GOLD
	elif title == 'Top Supporter':
		return Color.GREEN
	elif title == 'King of Typos':
		return Color.CORAL

# On your script, e.g., on the parent Node2D
#func _input(event):
#	if event is InputEventMouseMotion:
#		# A simple example mapping mouse-x to shift-h (-1.0 to 1.0)
#		var viewport_width = get_viewport().size.x
#		var normalized_mouse_x = (event.position.x / viewport_width) * 2.0 - 1.0

		# Adjust and set the parameter
		# Keep it small, e.g., mouse range is wide, make shift range -0.5 to 0.5
#		var material = $TextureRect.material
#		material.set_shader_parameter("perspective_shift_h", normalized_mouse_x * 0.5)
