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
