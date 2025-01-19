extends Node2D

@export var texture : Texture2D
@export var mainLabel : String

var disabled = false

signal clicked

# Called when the node enters the scene tree for the first time.
func _ready():
	if(mainLabel.length() > 5):
		$ChoiceButton/ChoiceLabel.set("theme_override_font_sizes/font_size",25)
	
	$ChoiceButton/ChoiceLabel.text = mainLabel
	$ChoiceButton.texture_normal = texture

func setMainLabel(text):
	$ChoiceButton/ChoiceLabel.text = text
	
func setCgsAvailable(available):
	if(available):
		%PossibleMemoriesLabel.show()
	else:
		%PossibleMemoriesLabel.hide()

func setProgressNeeded(needed):
	if(needed):
		var completeTexture = load("res://data/assets/date/art/grey_rounded_bottom.png")
		$ChoiceButton/FooterBg.texture = completeTexture
		$ChoiceButton/FooterText.text = 'Progress Needed!'
		$ChoiceButton/FooterBg.show()
		$ChoiceButton/FooterText.show()
		disabled = true
	else:
		$ChoiceButton/FooterBg.hide()
		$ChoiceButton/FooterText.hide()
		disabled = false
	
func setComplete(complete):
	if(complete):
		var completeTexture = load("res://data/assets/date/art/green_rounded_bottom.png")
		$ChoiceButton/FooterBg.texture = completeTexture
		$ChoiceButton/FooterText.text = 'Complete!'
		$ChoiceButton/FooterBg.show()
		$ChoiceButton/FooterText.show()
	else:
		$ChoiceButton/FooterBg.hide()
		$ChoiceButton/FooterText.hide()


func _on_choice_button_pressed():
	if(disabled == false):
		clicked.emit()
		


func _on_choice_button_mouse_entered():
	if(disabled):
		%Locked.show()
	else:
		%Hover.show()

func _on_choice_button_mouse_exited():
	%Locked.hide()
	%Hover.hide()
