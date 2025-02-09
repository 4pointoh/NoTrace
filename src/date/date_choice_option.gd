extends Node2D

@export var texture : Texture2D
@export var mainLabel : String

signal choice_selected(choice : String)

# Called when the node enters the scene tree for the first time.
func _ready():
	if(mainLabel.length() > 70):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",17)
	elif(mainLabel.length() > 30):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",19)
	elif(mainLabel.length() > 5):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",22)
	else:
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",40)
	
	$ChoiceButton/ChoiceLabel.text = mainLabel
	$ChoiceButton.texture_normal = texture

func setIndex(index):
	if(index == 0):
		%FooterBg.texture = load("res://data/assets/date/art/transparent_teal_hard_rounded_rect_8px9patch.png")
		%ChoiceButton.texture_hover = load("res://data/assets/date/art/transparent_teal_rounded_rect_8px9patch.png")
	elif(index == 1):
		%FooterBg.texture = load("res://data/assets/date/art/transparent_pink_hard_rounded_rect_8px9patch.png")
		%ChoiceButton.texture_hover = load("res://data/assets/date/art/transparent_pink_rounded_rect_8px9patch.png")
	elif(index == 2):
		%FooterBg.texture = load("res://data/assets/date/art/transparent_orange_hard_rounded_rect_8px9patch.png")
		%ChoiceButton.texture_hover = load("res://data/assets/date/art/transparent_orange_rounded_rect_8px9patch.png")
	elif(index == 3):
		%FooterBg.texture = load("res://data/assets/date/art/transparent_light_green_hard_rounded_rect_8px9patch.png")
		%ChoiceButton.texture_hover = load("res://data/assets/date/art/transparent_green_rounded_rect_8px9patch.png")

func _on_choice_button_pressed():
	choice_selected.emit(mainLabel)
	
