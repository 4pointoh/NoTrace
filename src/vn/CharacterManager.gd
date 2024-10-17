extends Node2D

var currentCharacterState

func setCharacter(newCharacterState):
	var animateState = false
	
	# On the first entrance of the character, we dont want the animation
	var skipAnim = false
	if !currentCharacterState:
		skipAnim = true
	
	if !currentCharacterState:
		animateState = newCharacterState.animateTransition
	else:
		animateState = currentCharacterState.animateTransition || newCharacterState.animateTransition
	
	currentCharacterState = newCharacterState
	$MainCharacter.visible = true
	
	if animateState and !skipAnim:
		setCharacterTextureWithAnim(newCharacterState)
	else:
		setCharacterTextureNow(newCharacterState)

func setCharacterTextureNow(newCharacterState):
	$MainCharacter.texture = newCharacterState.image
	$MainCharacter.scale = newCharacterState.scale
	$MainCharacter.position = align_sprite_bottom_right(newCharacterState)
	
func setTextureInAnimation(newCharacterState):
	$MainCharacter.texture = newCharacterState.image
	$MainCharacter.scale.y = newCharacterState.scale.y
	$MainCharacter.position = align_sprite_bottom_right(newCharacterState)
	grow(newCharacterState)

func setCharacterTextureWithAnim(newCharacterState):
	$AnimationPlayer/AudioStreamPlayer2D.play()
	var tween = get_tree().create_tween()
	tween.tween_property($MainCharacter, "scale", Vector2(0, newCharacterState.scale.y), .05)
	tween.tween_callback(setTextureInAnimation.bind(newCharacterState))

func grow(newCharacterState):
	var tween = get_tree().create_tween()
	tween.tween_property($MainCharacter, "scale", Vector2( newCharacterState.scale.x, newCharacterState.scale.y), .05)
	tween.tween_callback(setAlignment.bind(newCharacterState))

func setAlignment(newCharacterState):
	$MainCharacter.position = align_sprite_bottom_right(newCharacterState)
	
func hideCharacter():
	$MainCharacter.visible = false
	currentCharacterState = null

func align_sprite_bottom_right(characterState):
	var viewport_size = get_viewport_rect().size
	var sprite_size = $MainCharacter.texture.get_size() *  characterState.scale
	
	# Calculate the position to align the sprite to the bottom-right corner
	var bottom_right_position = Vector2(viewport_size.x - sprite_size.x/2, viewport_size.y - sprite_size.y/2)
	
	# Set the sprite's position
	return bottom_right_position
