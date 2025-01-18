extends Node2D

@export var texture : Texture2D
@export var mainLabel : String

signal choice_selected(choice : String)

# Called when the node enters the scene tree for the first time.
func _ready():
	if(mainLabel.length() > 50):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",16)
	elif(mainLabel.length() > 30):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",20)
	elif(mainLabel.length() > 5):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",22)
	else:
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",40)
	
	$ChoiceButton/ChoiceLabel.text = mainLabel
	$ChoiceButton.texture_normal = texture


func _on_choice_button_pressed():
	choice_selected.emit(mainLabel)
	
