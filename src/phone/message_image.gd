extends MarginContainer

signal phone_image_clicked()

var noFullscreen = false

func setTexture(texture, skipBlur = false):
	$MessageImage.texture = texture
	
	if(skipBlur):
		$MessageImage.material.set('shader_parameter/amount', 0)
		$Label.visible = false
	else:
		$AnimationPlayer.play("unblur")

func _on_button_pressed():
	if noFullscreen:
		return
		
	GlobalGameStage.setImageFullscreen($MessageImage.texture)
