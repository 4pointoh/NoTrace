extends Node2D
@export var shader_material = load("res://src/date/blur_material.tres") as ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

signal clicked_continue()
signal clicked_play_again()

# The memories grid was laid out for portrait art: three tiles to a row, overlapping a little. Wide
# art (the landscape dates') gets wide tiles instead, two to a row, filling the same space.
const WIDE_TILE = Vector2(240, 135)
const WIDE_COLUMNS = 2
const WIDE_SEPARATION = 10
var wideTiles = false

func set_memories(memories : Dictionary):

	var totalMemoryCount = 0
	var unlockedMemoryCount = 0

	var wallpapers = memories.keys().map(func(memory): return GlobalGameStage.getWallpaper(memory))
	if wallpapers.size() > 0:
		var art : Texture2D = load(wallpapers[0].wallpaperImagePath)
		wideTiles = art.get_width() > art.get_height()
	if wideTiles:
		$ImageGrid.columns = WIDE_COLUMNS
		$ImageGrid.add_theme_constant_override("h_separation", WIDE_SEPARATION)

	for memory in memories.keys():
		totalMemoryCount += 1
		var wallpaper = GlobalGameStage.getWallpaper(memory)
		if memories[memory]:
			appendUnlockedMemory(wallpaper)
			unlockedMemoryCount += 1
		else:
			appendLockedMemory(wallpaper)
		
	setLabel(totalMemoryCount, unlockedMemoryCount)

func memoryTile(wallpaper) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(wallpaper.wallpaperImagePath)
	if wideTiles:
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture_rect.custom_minimum_size = WIDE_TILE
	else:
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(200, 200)
	return texture_rect

func appendUnlockedMemory(wallpaper):
	$ImageGrid.add_child(memoryTile(wallpaper))

func appendLockedMemory(wallpaper):
	var texture_rect = memoryTile(wallpaper)
	texture_rect.material = shader_material
	texture_rect.material.set_shader_parameter("amount", 200)
	$ImageGrid.add_child(texture_rect)

func setLabel(totalMemoryCount, unlockedMemoryCount):
	$MemoryCountLabel.text = str(unlockedMemoryCount) + "/" + str(totalMemoryCount) + " Memories Unlocked"

func _on_continue_pressed():
	clicked_continue.emit()

func _on_play_again_pressed() -> void:
	clicked_play_again.emit()
