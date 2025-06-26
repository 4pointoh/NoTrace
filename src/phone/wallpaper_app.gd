extends Node2D

@export var newWallpaper : PackedScene

var wallpapers : WallpaperList
var pageIndex = 0
var maxPages = 0

var currentSelection
var wallpaperNotUnlockedImage

func reset():
	currentSelection = null
	wallpapers = null
	
	for ch in $SelectionContainer.get_children():
		$SelectionContainer.remove_child(ch)
		ch.queue_free()
		
	hide()

func setup():
	wallpapers = load("res://resources/wallpapers/all_wallpapers.tres")
	wallpaperNotUnlockedImage = load("res://data/assets/phone/art/wallpaper_not_unlocked2.png")
	$Previous.disabled = true
	$Next.disabled = false

	# Calculate the number of pages
	maxPages = int(wallpapers.wallpapers.size() / 9)

	# Set the current page to 0
	pageIndex = 0

	setupWallpaperPage(pageIndex)

func setupWallpaperPage(pageNumber: int):
	# Clear the current grid container
	for ch in %GridContainer.get_children():
		%GridContainer.remove_child(ch)
		ch.queue_free()

	var totalWallpapers = wallpapers.wallpapers.size()

	# Max per page
	var maxPerPage = 9

	# Calculate the start and end index for the current page
	var startIndex = pageNumber * maxPerPage
	var endIndex = startIndex + maxPerPage
	if endIndex > totalWallpapers:
		endIndex = totalWallpapers

	# Ensure the start index is within bounds
	if startIndex < 0:
		startIndex = 0
	
	# Ensure the end index is within bounds
	if endIndex > totalWallpapers:
		endIndex = totalWallpapers
	
	# Create a new wallpaper selection for each wallpaper in the current page
	for i in range(startIndex, endIndex):
		var newSelection = newWallpaper.instantiate()
		newSelection.index = i
		newSelection.hasVideo = wallpapers.wallpapers[i].video != null and wallpapers.wallpapers[i].video != ""

		newSelection.hovered.connect(_on_wallpaper_hovered)
		newSelection.selected.connect(_on_wallpaper_selected)
		newSelection.view.connect(_on_wallpaper_viewed)
		newSelection.video.connect(_on_video_pressed)
		
		var curPaper = wallpapers.wallpapers[i]

		var unlocked = GlobalGameStage.unlockedWallpapers.has(curPaper.wallpaperId)
		if unlocked:
			newSelection.texture = curPaper.image
			newSelection.unlocked = true
		else:
			newSelection.texture = wallpaperNotUnlockedImage
			newSelection.unlocked = false

		%GridContainer.add_child(newSelection)

func _on_next_pressed():
	if pageIndex > maxPages - 1:
		return

	pageIndex += 1
	
	$VideoStreamPlayer.hide()
	
	if pageIndex == maxPages:
		$Next.disabled = true
	
	if pageIndex != 0:
		$Previous.disabled = false
		
	setupWallpaperPage(pageIndex)

func _on_previous_pressed():
	pageIndex -= 1

	$VideoStreamPlayer.hide()
	
	if pageIndex == 0:
		$Previous.disabled = true
	
	if pageIndex < maxPages:
		$Next.disabled = false
		
	setupWallpaperPage(pageIndex)

func _on_video_pressed(index: int):	
	$VideoStreamPlayer.show()
	$VideoStreamPlayer.stream = load(wallpapers.wallpapers[index].video)
	$VideoStreamPlayer.play()
	%HideVideo.show()
	$Previous.hide()
	$Next.hide()
	%HintContainer.hide()

func _on_wallpaper_hovered(index: int):
	%Hint.text = wallpapers.wallpapers[index].hint
	%Hint.show()

func _on_wallpaper_selected(index: int):
	GlobalGameStage.setCurrentWallpaper(wallpapers.wallpapers[index])

func _on_wallpaper_viewed(index: int):
	GlobalGameStage.setImageFullscreen(wallpapers.wallpapers[index].image, index)

func _on_hide_video_pressed() -> void:
	$VideoStreamPlayer.stop()
	$VideoStreamPlayer.hide()
	$VideoStreamPlayer.stream = null
	%HideVideo.hide()
	$Previous.show()
	$Next.show()
	%HintContainer.show()
