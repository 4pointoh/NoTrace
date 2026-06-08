# res://tools/migrate_wallpaper_list.gd
@tool
extends EditorScript

# Put one or more .tres/.res paths to your WallpaperList resources here.
const LIST_PATHS := [
	"res://resources/wallpapers/all_wallpapers.tres"
]

func _run() -> void:
	if LIST_PATHS.is_empty():
		push_warning("Set LIST_PATHS to your WallpaperList resource paths in migrate_wallpaper_list.gd.")
		return

	_process_list_path()


func _process_list_path() -> void:
	var res = load("res://resources/wallpapers/all_wallpapers.tres")

	# Try to find the wallpapers array on the resource
	var wallpapers = res.wallpapers

	for i in wallpapers.size():
		var w: Wallpaper = wallpapers[i]
		if w == null:
			continue

		# 1) Read the current image/texture
		var tex: Texture2D = w.image
		
		# 2) Resolve the resource path of the texture (if any)
		var path := ""
		if tex:
			path = tex.resource_path
			# Some imported textures always have a resource_path like res://...png
			# But if for some reason it's still empty, attempt a loose fallback:
			if path == "" and tex.has("path"):
				path = str(tex.get("path"))

		w.wallpaperImagePath = path
		w.image = null

		var err := ResourceSaver.save(res, "res://resources/wallpapers/all_wallpapers.tres")
		if err != OK:
			push_error("Save failed for %s (err=%s)" % [err, err])
			# Optional: refresh the filesystem dock
		get_editor_interface().get_resource_filesystem().scan()
