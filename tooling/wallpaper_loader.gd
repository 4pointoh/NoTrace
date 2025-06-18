@tool
extends EditorScript

func _run() -> void:
	var wallpaper_png_path = "res://data/background_lists/lisa_beach_beach/208.webp"
	var wallpaper_hint = 'Lisa At The Beach (4)'
	var wallpaper_id = 'LISA_BEACH_7' #used for unlocking it
	var all_wallpaper_path = "res://resources/wallpapers/all_wallpapers.tres"
	var all_wallpapers_resource = load(all_wallpaper_path)
	
	var newwallpaper = Wallpaper.new()
	newwallpaper.hint = wallpaper_hint
	newwallpaper.image = load(wallpaper_png_path)
	newwallpaper.wallpaperId = wallpaper_id
	
	all_wallpapers_resource.wallpapers.append(newwallpaper)
	var result = ResourceSaver.save(all_wallpapers_resource, all_wallpaper_path)
	if result != OK:
		push_error("Failed to save updated wallpapers resource.")
	else:
		print("Successfully updated and saved resource at: %s" % all_wallpaper_path)
