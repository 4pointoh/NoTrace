extends Panel

func play(text, image = null):
	visible = true
	%Text.text = text
	if image:
		%Image.texture = image
	else:
		%Image.visible = false
	
	%Anim.play("open")
	await %Anim.animation_finished
	%Anim.play_backwards("open")
	await %Anim.animation_finished
	visible = false
