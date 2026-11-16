extends RefCounted
class_name BackgroundCache

## Loads background textures on demand and keeps only the most recently used
## few in memory, instead of loading every texture in a stage's background
## lists up front (which OOMs machines with less RAM).

const MAX_CACHED := 8

# imagePath -> Texture2D, ordered oldest-used first (Godot Dictionaries keep
# insertion order, so erase + reinsert moves an entry to the back).
static var _cache := {}
# imagePath -> true while a threaded load is in flight.
static var _pending := {}

## Start loading a texture in the background. Cheap to call repeatedly.
static func prefetch(path : String):
	_drainFinished()
	if path == '' or _cache.has(path) or _pending.has(path):
		return
	if ResourceLoader.load_threaded_request(path, "Texture2D") == OK:
		_pending[path] = true

## Get a texture, blocking only if it isn't loaded yet. Returns the same
## instance for the same path while cached, so texture identity comparisons
## keep working.
static func getTexture(path : String) -> Texture2D:
	_drainFinished()
	if path == '':
		return null
	if _cache.has(path):
		var tex = _cache[path]
		_cache.erase(path)
		_cache[path] = tex
		return tex
	var tex : Texture2D
	if _pending.has(path):
		_pending.erase(path)
		tex = ResourceLoader.load_threaded_get(path)
	else:
		tex = load(path)
	if tex == null:
		printerr('BackgroundCache: failed to load texture at ', path)
		return null
	_insert(path, tex)
	return tex

# Collect finished prefetches into the cache. A threaded request that is never
# load_threaded_get'd stays pinned inside ResourceLoader forever.
static func _drainFinished():
	for path in _pending.keys():
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_pending.erase(path)
			var tex = ResourceLoader.load_threaded_get(path)
			if tex:
				_insert(path, tex)

static func _insert(path : String, tex : Texture2D):
	_cache[path] = tex
	while _cache.size() > MAX_CACHED:
		_cache.erase(_cache.keys()[0])
