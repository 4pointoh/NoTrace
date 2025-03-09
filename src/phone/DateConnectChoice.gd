extends Control

signal selected(id : String)

var id

func _on_button_pressed():
	selected.emit(id)

func setup(id2, text2 : String, texture : Texture2D, numHearts : int):
	%TextureRect.texture = texture
	%Subtext.text = text2
	id = id2
	
	if numHearts > 0:
		%Heart1.show()
	
	if numHearts > 1:
		%Heart2.show()
	
	if numHearts > 2:
		%Heart3.show()
	
