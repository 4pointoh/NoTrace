extends Node2D
@export var shader_material = load("res://src/date/blur_material.tres") as ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

signal clicked_continue()

func set_memories(memories : Dictionary):

	var totalMemoryCount = 0
	var unlockedMemoryCount = 0

	for memory in memories.keys():
		totalMemoryCount += 1
		var wallpaper = GlobalGameStage.getWallpaper(memory)
		if memories[memory]:
			appendUnlockedMemory(wallpaper)
			unlockedMemoryCount += 1
		else:
			appendLockedMemory(wallpaper)
		
	setLabel(totalMemoryCount, unlockedMemoryCount)

func appendUnlockedMemory(wallpaper):
	var texture_rect = TextureRect.new()
	texture_rect.texture = wallpaper.image
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(200, 200)
	$ImageGrid.add_child(texture_rect)

func appendLockedMemory(wallpaper):
	var texture_rect = TextureRect.new()
	texture_rect.texture = wallpaper.image
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(200, 200)
	texture_rect.material = shader_material
	texture_rect.material.set_shader_parameter("amount", 200)
	$ImageGrid.add_child(texture_rect)

func setLabel(totalMemoryCount, unlockedMemoryCount):
	$MemoryCountLabel.text = str(unlockedMemoryCount) + "/" + str(totalMemoryCount) + " Memories Unlocked"

func _on_continue_pressed():
	clicked_continue.emit()
