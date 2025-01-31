extends Node2D

var currentCharacterState
var shouldWalkOn = false

func setCharacter(newCharacterState):
	if currentCharacterState and (currentCharacterState.name == newCharacterState.name) and $MainCharacter.visible:
		return
	
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

	if shouldWalkOn:
		characterWalkOn(newCharacterState)
		shouldWalkOn = false
	else:
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

func zoomCharacter():
	var tween = get_tree().create_tween()
	tween.tween_property($MainCharacter, "scale", Vector2($MainCharacter.scale.x + .25, $MainCharacter.scale.y + .25), .5)
	tween.set_parallel()
	tween.tween_property($MainCharacter, "position", Vector2($MainCharacter.position.x, $MainCharacter.position.y + 200), .5)

func characterWalkOff():
	var tween = get_tree().create_tween()
	tween.tween_property($MainCharacter, "position", Vector2($MainCharacter.position.x + 1000, $MainCharacter.position.y), .65)

func characterWalkOn(newCharacterState):
	$MainCharacter.texture = newCharacterState.image
	$MainCharacter.scale = newCharacterState.scale
	$MainCharacter.position = align_sprite_bottom_right(newCharacterState)
	$MainCharacter.position = Vector2($MainCharacter.position.x + 500, $MainCharacter.position.y)
	$MainCharacter.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property($MainCharacter, "position", align_sprite_bottom_right(newCharacterState), 1).set_trans(Tween.TRANS_SPRING)


func align_sprite_bottom_right(characterState):
	var viewport_size = get_viewport_rect().size
	var sprite_size = $MainCharacter.texture.get_size() *  characterState.scale
	
	# Calculate the position to align the sprite to the bottom-right corner
	var bottom_right_position = Vector2(viewport_size.x - sprite_size.x/2, viewport_size.y - sprite_size.y/2)
	
	# Set the sprite's position
	return bottom_right_position

func walkOnNext():
	shouldWalkOn = true
