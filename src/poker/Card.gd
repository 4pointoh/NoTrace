extends Control
class_name Card

var textureClub = preload("res://data/assets/poker/art/club.png")
var textureHeart = preload("res://data/assets/poker/art/heart.png")
var textureSpade = preload("res://data/assets/poker/art/spade.png")
var textureDiamond = preload("res://data/assets/poker/art/diamond.png")
var cardback = preload("res://data/assets/poker/art/cardfront.png")
var cardfront = preload("res://data/assets/poker/art/cardback.png")

var nonUiCard : NonUiCard
var index : int
var selectable : bool = false
var selected : bool = false
var flipped = true

signal cardClicked(index : int, selected : bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	if nonUiCard.suit == "hearts":
		$TextureRect/Icon.texture = textureHeart
	elif nonUiCard.suit == "diamonds":
		$TextureRect/Icon.texture = textureDiamond
	elif nonUiCard.suit == "spades":
		$TextureRect/Icon.texture = textureSpade
	elif nonUiCard.suit == "clubs":
		$TextureRect/Icon.texture = textureClub
	
	if(nonUiCard.value == "T"):
		$TextureRect/NumberTopLeft.text = "10"
	else:
		$TextureRect/NumberTopLeft.text = nonUiCard.value
	
func flip():
	$TextureRect/AnimationPlayer.play("flip")
	
func toggleCardback():
	flipped = !flipped
	if flipped:
		setCardback()
	else:
		setCardfront()
	
func setCardback():
	$TextureRect/NumberTopLeft.visible = false
	$TextureRect/Icon.visible = false
	$TextureRect.texture = cardback
	
func setCardfront():
	$TextureRect/NumberTopLeft.visible = true
	$TextureRect/Icon.visible = true
	$TextureRect.texture = cardfront

func _on_button_pressed():
	if selectable:
		setSelected()
		cardClicked.emit(index, selected)

func setSelected():
	selected = !selected
	%Border.visible = selected

func disableSelection():
	selected = false
	selectable = false
	%Border.visible = false
