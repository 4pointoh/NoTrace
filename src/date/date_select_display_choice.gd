extends Node2D

@export var texture : Texture2D
@export var mainLabel : String

var disabled = false
var progressNeeded = false
var complete = false

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
	progressNeeded = needed
	updateFooter()

# Nothing left to ask under this button
func setComplete(isComplete):
	complete = isComplete
	updateFooter()

func updateFooter():
	disabled = progressNeeded or complete
	if(complete):
		$ChoiceButton/FooterBg.texture = load("res://data/assets/date/art/green_rounded_bottom.png")
		$ChoiceButton/FooterText.text = 'Complete!'
	elif(progressNeeded):
		$ChoiceButton/FooterBg.texture = load("res://data/assets/date/art/grey_rounded_bottom.png")
		$ChoiceButton/FooterText.text = 'Progress Needed!'
	$ChoiceButton/FooterBg.visible = disabled
	$ChoiceButton/FooterText.visible = disabled


func _on_choice_button_pressed():
	if(disabled == false):
		clicked.emit()
		


func _on_choice_button_mouse_entered():
	if(complete):
		return
	if(disabled):
		%Locked.show()
	else:
		%Hover.show()

func _on_choice_button_mouse_exited():
	%Locked.hide()
	%Hover.hide()
