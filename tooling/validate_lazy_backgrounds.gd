# Read-only validation of the lazy background system. Safe to re-run anytime:
#   <godot.exe> --headless --path . -s tooling/validate_lazy_backgrounds.gd
#
# Checks that:
#  1. every BackgroundList .tres loads without pulling any textures
#  2. every Background has a valid, loadable imagePath
#  3. BackgroundCache loads textures on demand and evicts old ones
extends SceneTree

const WORST_STAGE_BGS := "res://data/game_stages/vn/lisa_sp_poker_poker3_after/bgs.tres"

var errors := 0

func _init():
	_validateAllLists()
	_validateWorstStageIsLazy()
	_validateCacheBehavior()
	print("--- validation %s (%d error(s)) ---" % ["FAILED" if errors > 0 else "PASSED", errors])
	quit(1 if errors > 0 else 0)

func _validateAllLists():
	var listPaths : Array[String] = []
	_collect("res://data/background_lists", listPaths)
	var bgCount := 0
	var samplePaths : Array[String] = []
	for path in listPaths:
		var res = load(path)
		if res == null:
			printerr("failed to load ", path)
			errors += 1
			continue
		if not ("images" in res and res.get_script().resource_path.ends_with("BackgroundList.gd")):
			continue
		for bg in res.images:
			bgCount += 1
			if bg == null:
				print("note: null Background entry in ", path)
				continue
			if bg.images != null:
				printerr("EAGER TEXTURE still present on '%s' in %s" % [bg.name, path])
				errors += 1
			if bg.imagePath == "":
				printerr("empty imagePath on '%s' in %s" % [bg.name, path])
				errors += 1
			elif not ResourceLoader.exists(bg.imagePath, "Texture2D"):
				printerr("imagePath does not resolve to a texture: ", bg.imagePath)
				errors += 1
			elif samplePaths.size() < 12:
				samplePaths.append(bg.imagePath)
	print("checked %d Backgrounds across %d list files" % [bgCount, listPaths.size()])
	_samplePathsForCacheTest = samplePaths

func _validateWorstStageIsLazy():
	var start = Time.get_ticks_msec()
	var bgls = load(WORST_STAGE_BGS)
	var elapsed = Time.get_ticks_msec() - start
	if bgls == null:
		printerr("failed to load worst-stage bgs.tres")
		errors += 1
		return
	var textureCount := 0
	var loadedCount := 0
	for bgl in bgls.backgroundLists:
		for bg in bgl.images:
			textureCount += 1
			if ResourceLoader.has_cached(bg.imagePath):
				loadedCount += 1
	print("worst stage: %d backgrounds referenced, %d textures actually loaded, list load took %d ms"
			% [textureCount, loadedCount, elapsed])
	if loadedCount > 0:
		printerr("expected 0 textures loaded eagerly, got ", loadedCount)
		errors += 1

var _samplePathsForCacheTest : Array[String] = []

# Loads happen inside helper functions: GDScript keeps expression temporaries
# alive in the calling function's stack registers, which would otherwise pin
# the textures and make the eviction checks below meaningless.
func _validateCacheBehavior():
	if _samplePathsForCacheTest.size() < 10:
		printerr("not enough sample paths for cache test")
		errors += 1
		return
	var first = _samplePathsForCacheTest[0]
	if not _loadAndCheckIdentity(first):
		printerr("cache failed to load, or returned unstable instances for ", first)
		errors += 1
		return
	_churnCache() # load enough other textures to evict the first one (MAX_CACHED = 8)
	if ResourceLoader.has_cached(first):
		printerr("evicted texture is still resident: ", first)
		errors += 1
	if not ResourceLoader.has_cached(_samplePathsForCacheTest[9]):
		printerr("most recently used texture should still be cached")
		errors += 1
	print("cache behavior OK: on-demand load, stable identity, LRU eviction frees memory")

func _loadAndCheckIdentity(path : String) -> bool:
	var a = BackgroundCache.getTexture(path)
	var b = BackgroundCache.getTexture(path)
	return a != null and a == b

func _churnCache():
	for i in range(1, 10):
		if BackgroundCache.getTexture(_samplePathsForCacheTest[i]) == null:
			printerr("cache failed to load ", _samplePathsForCacheTest[i])
			errors += 1

func _collect(root : String, out : Array[String]):
	var dir = DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry = dir.get_next()
		if entry == "":
			break
		var full = root.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_collect(full, out)
		elif entry.ends_with(".tres"):
			out.append(full)
	dir.list_dir_end()
