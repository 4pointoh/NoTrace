extends Node2D

var lifeLostTexture : Texture = load("res://data/assets/poker/art/life_lost.png")
var greenLifeDefaultTexture : Texture = load("res://data/assets/poker/art/life.png")
var greenLifeStarTexture : Texture = load("res://data/assets/poker/art/life_star.png")
var blueLifeDefaultTexture : Texture = load("res://data/assets/poker/art/life_plus.png")
var blueLifeStarTexture : Texture = load("res://data/assets/poker/art/life_plus_star.png")

var CONTAINER_MAX_SIZE : int = 10


func setLives(maxLives: int, starLives: Array[int], currentLives: int):
	# Clear previous lives
	for child in %LivesContainer.get_children():
		child.queue_free()

	var blueLives = false

	if currentLives > 10:
		blueLives = true
	else:
		blueLives = false

	var lifeTexture = blueLifeDefaultTexture if blueLives else greenLifeDefaultTexture
	var starTexture = blueLifeStarTexture if blueLives else greenLifeStarTexture


	if blueLives:
		for i in range(20, 10, -1):
			var textureRect = TextureRect.new()
			textureRect.custom_minimum_size = Vector2(80, 10)
			textureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL

			if currentLives < i:
				textureRect.texture = lifeLostTexture 
			elif i in starLives:
				textureRect.texture = starTexture
			else:
				textureRect.texture = lifeTexture
			
			%LivesContainer.add_child(textureRect)

	else:
		for i in range(10, 0, -1):
			var textureRect = TextureRect.new()
			textureRect.custom_minimum_size = Vector2(80, 10)
			textureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL

			if currentLives < i:
				textureRect.texture = lifeLostTexture 
			elif i in starLives:
				textureRect.texture = starTexture
			else:
				textureRect.texture = lifeTexture
			
			if (maxLives < CONTAINER_MAX_SIZE) and (i > maxLives):
				continue

			%LivesContainer.add_child(textureRect)
