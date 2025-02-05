extends Node2D

@export var wallpaperSelection : PackedScene
var wallpapers : WallpaperList
var wallpaperIndex = 0

var currentSelection
var wallpaperNotUnlockedImage

func reset():
	currentSelection = null
	wallpapers = null
	wallpaperIndex = 0
	
	for ch in $SelectionContainer.get_children():
		$SelectionContainer.remove_child(ch)
		ch.queue_free()
		
	hide()

func setup():
	wallpapers = load("res://resources/wallpapers/all_wallpapers.tres")
	wallpaperNotUnlockedImage = load("res://data/assets/phone/art/wallpaper_not_unlocked.png")
	$Previous.disabled = true
	$Next.disabled = false
	
	var newSelection = wallpaperSelection.instantiate()
	var curPaper = wallpapers.wallpapers[0]
	newSelection.setup(curPaper.hint, curPaper.image)
	newSelection.position = Vector2(0,0)
	currentSelection = newSelection
	$SelectionContainer.add_child(newSelection)

func setSelection(isNext):
	var newSelection = wallpaperSelection.instantiate()
	var curPaper = wallpapers.wallpapers[wallpaperIndex]
	
	var unlocked = GlobalGameStage.unlockedWallpapers.has(curPaper.wallpaperId)
	if unlocked:
		newSelection.setup(curPaper.hint, curPaper.image)
	else:
		newSelection.setup(curPaper.hint, wallpaperNotUnlockedImage, true)
		
	$SelectionContainer.add_child(newSelection)
	
	if unlocked:
		$Set.disabled = false
	else:
		$Set.disabled = true
	
	if isNext:
		currentSelection.scrollOutLeft()
		await newSelection.scrollInRight()
	else:
		currentSelection.scrollOutRight()
		await newSelection.scrollInLeft()
		
	$SelectionContainer.remove_child(currentSelection)
	currentSelection.queue_free()
	currentSelection = newSelection

func _on_next_pressed():
	if wallpaperIndex > wallpapers.wallpapers.size() - 1:
		return
		
	wallpaperIndex += 1
	
	if wallpaperIndex == wallpapers.wallpapers.size() - 1:
		$Next.disabled = true
	
	if wallpaperIndex > 0:
		$Previous.disabled = false
		
	setSelection(true)

func _on_previous_pressed():
	if wallpaperIndex == 0:
		return
		
	wallpaperIndex -= 1
	
	if wallpaperIndex == 0:
		$Previous.disabled = true
	
	if wallpaperIndex < wallpapers.wallpapers.size() - 1:
		$Next.disabled = false
		
	setSelection(false)

func _on_set_pressed():
	GlobalGameStage.setCurrentWallpaper(wallpapers.wallpapers[wallpaperIndex])
