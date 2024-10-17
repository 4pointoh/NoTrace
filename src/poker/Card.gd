extends Control
class_name Card

var textureClub = preload("res://data/assets/poker/art/club.png")
var textureHeart = preload("res://data/assets/poker/art/heart.png")
var textureSpade = preload("res://data/assets/poker/art/spade.png")
var textureDiamond = preload("res://data/assets/poker/art/diamond.png")
var cardback = preload("res://data/assets/poker/art/cardfront.png")
var cardfront = preload("res://data/assets/poker/art/cardback.png")

var nonUiCard : NonUiCard

var flipped = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if nonUiCard.suit == "hearts":
		makeRed()
		$TextureRect/Icon.texture = textureHeart
	elif nonUiCard.suit == "diamonds":
		makeRed()
		$TextureRect/Icon.texture = textureDiamond
	elif nonUiCard.suit == "spades":
		makeBlack()
		$TextureRect/Icon.texture = textureSpade
	elif nonUiCard.suit == "clubs":
		makeBlack()
		$TextureRect/Icon.texture = textureClub
		
	$TextureRect/NumberBottomLeft.text = nonUiCard.value
	$TextureRect/NumberBottomRight.text = nonUiCard.value
	$TextureRect/NumberTopLeft.text = nonUiCard.value
	$TextureRect/NumberTopRight.text = nonUiCard.value
	
func flip():
	$TextureRect/AnimationPlayer.play("flip")
	
func toggleCardback():
	flipped = !flipped
	if flipped:
		setCardback()
	else:
		setCardfront()
	
func setCardback():
	$TextureRect/NumberBottomLeft.visible = false
	$TextureRect/NumberBottomRight.visible = false
	$TextureRect/NumberTopLeft.visible = false
	$TextureRect/NumberTopRight.visible = false
	$TextureRect/Icon.visible = false
	$TextureRect.texture = cardback
	
func setCardfront():
	$TextureRect/NumberBottomLeft.visible = true
	$TextureRect/NumberBottomRight.visible = true
	$TextureRect/NumberTopLeft.visible = true
	$TextureRect/NumberTopRight.visible = true
	$TextureRect/Icon.visible = true
	$TextureRect.texture = cardfront
	
func makeRed():
	$TextureRect/NumberBottomLeft.add_theme_color_override("font_color","red")
	$TextureRect/NumberBottomRight.add_theme_color_override("font_color","red")
	$TextureRect/NumberTopLeft.add_theme_color_override("font_color","red")
	$TextureRect/NumberTopRight.add_theme_color_override("font_color","red")

func makeBlack():
	$TextureRect/NumberBottomLeft.add_theme_color_override("font_color","black")
	$TextureRect/NumberBottomRight.add_theme_color_override("font_color","black")
	$TextureRect/NumberTopLeft.add_theme_color_override("font_color","black")
	$TextureRect/NumberTopRight.add_theme_color_override("font_color","black")
	
