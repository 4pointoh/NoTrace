extends Control

@export var iconTexture : Texture2D
@export var color : RealDateColorHelper.TopicColors

var currentSymbol = 0

signal hoveringTacker(currentColor: RealDateColorHelper.TopicColors)
signal notHoveringTracker

func _ready():
	$TextureRect.texture = iconTexture


func _on_button_pressed():
	currentSymbol = (currentSymbol + 1) % 3
	
	if currentSymbol == 0:
		$Label.text = '?'
	elif currentSymbol == 1:
		$Label.text = '❌'
	elif currentSymbol == 2:
		$Label.text = '🤔'

func disable():
	modulate = Color(.25, .25, .25, 0.5)
	#%Disabled.show()

func _on_button_mouse_entered():
	hoveringTacker.emit(color)

func _on_button_mouse_exited():
	notHoveringTracker.emit()
