extends Node2D
class_name Heartsplosion

enum TYPES {
	NONE,
	HEARTS,
	HAPPY,
	CONCERNED,
	CONFUSED,
	ANNOYED,
	PISSED,
	HORNY,
	SURPRISED,
	CHIPS,
	LAUGH,
	INNOCENT,
	BLUSH
}

enum ANIM_TYPE {
	EXPLODE,
	RAIN
}

var sprites = []
var explosion_duration = 1.5
var max_distance = 150
var texture : Texture2D
var sound : AudioStream
var animType : ANIM_TYPE
var isRaining = false


var rain_spawn_count = 300
var rain_spawn_interval = 0.03
var rain_fall_speed = 700.0
var rain_duration = 3.0  # Duration of the rain effect in seconds
var rain_spawn_timer = 0.0
var rain_sprites_spawned = 0
var rain_time_elapsed = 0.
var spawn_direction = 1  # 1 for left-to-right, -1 for right-to-left
var current_spawn_position = 0.0

func _ready():
	if sound:
		$AudioStreamPlayer2D.stream = sound
		$AudioStreamPlayer2D.play()
	
	if animType == ANIM_TYPE.EXPLODE:
		explode()
	elif animType == ANIM_TYPE.RAIN:
		rain()

func _process(delta):
	if isRaining:
		rain_time_elapsed += delta
		if rain_time_elapsed >= rain_duration:
			isRaining = false
			return

		rain_spawn_timer += delta
		if rain_spawn_timer >= rain_spawn_interval and rain_sprites_spawned < rain_spawn_count:
			spawn_rain_sprite()
			rain_spawn_timer = 0.0

func setType(type : TYPES):
	if(type == TYPES.HEARTS):
		setTextureToHearts()
	elif(type == TYPES.HAPPY):
		setTextureToHappy()
	elif(type == TYPES.CONCERNED):
		setTextureToConcerned()
	elif(type == TYPES.CONFUSED):
		setTextureToConfused()
	elif(type == TYPES.ANNOYED):
		setTextureToAnnoyed()
	elif(type == TYPES.PISSED):
		setTextureToPissed()
	elif(type == TYPES.HORNY):
		setTextureToHorny()
	elif(type == TYPES.SURPRISED):
		setTextureToSurprised()
	elif(type == TYPES.CHIPS):
		setTextureToPoker()
	elif(type == TYPES.LAUGH):
		setTextureToLaugh()
	elif(type == TYPES.INNOCENT):
		setTextureToBlush()
	elif(type == TYPES.BLUSH):
		setTextureToInnocent()

func setAnimType(type : ANIM_TYPE):
	animType = type
	
	if(type == ANIM_TYPE.EXPLODE):
		var spawn_area: Rect2 = Rect2(400, 500, 200, 200)
		var spawn_position = Vector2(
				randf_range(spawn_area.position.x, spawn_area.end.x),
				randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		position = spawn_position
	elif(type == ANIM_TYPE.RAIN):
		position = Vector2(0.0,-60.0)

func setTextureToHearts():
	texture = load("res://data/assets/date/art/heart.png")
	sound = load("res://data/assets/general/sounds/tone4.wav")

func setTextureToHappy():
	texture = load("res://data/assets/date/art/happy.png")
	sound = load("res://data/assets/general/sounds/success2.wav")

func setTextureToConcerned():
	texture = load("res://data/assets/date/art/concerned.png")
	sound = load("res://data/assets/general/sounds/doubt.wav")

func setTextureToConfused():
	texture = load("res://data/assets/date/art/confused.png")
	sound = load("res://data/assets/general/sounds/doubt.wav")

func setTextureToAnnoyed():
	texture = load("res://data/assets/date/art/annoyed.png")
	sound = load("res://data/assets/general/sounds/doubt.wav")

func setTextureToPissed():
	texture = load("res://data/assets/date/art/pissed.png")
	sound = load("res://data/assets/general/sounds/huh.wav")

func setTextureToHorny():
	texture = load("res://data/assets/date/art/horny.png")
	sound = load("res://data/assets/general/sounds/mmmm.wav")

func setTextureToSurprised():
	texture = load("res://data/assets/date/art/surprised.png")
	sound = load("res://data/assets/general/sounds/doubt.wav")

func setTextureToLaugh():
	texture = load("res://data/assets/date/art/laugh.png")
	sound = load("res://data/assets/general/sounds/laugh2.wav")

func setTextureToInnocent():
	texture = load("res://data/assets/date/art/blush_surprise.png")
	sound = load("res://data/assets/general/sounds/mmm.wav")
	
func setTextureToBlush():
	texture = load("res://data/assets/date/art/blush.png")
	sound = load("res://data/assets/general/sounds/huh.wav")

func setTextureToPoker():
	texture = load("res://data/assets/poker/art/chip.png")
	sound = load("res://data/assets/poker/sounds/more_chips.wav")

func explode():
	if isRaining:
		return
	for i in range(3):
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2.ZERO
		add_child(sprite)
		sprites.append(sprite)
	for i in range(sprites.size()):
		var sprite = sprites[i]
		var angle = 2 * PI * i / sprites.size()
		var target_position = Vector2(cos(angle), sin(angle)) * max_distance
		
		var target_rotation = randf_range(-PI, PI)
		
		# Create a Tween for smooth animation
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(sprite, "position", target_position, explosion_duration)
		tween.parallel().tween_property(sprite, "rotation", target_rotation, explosion_duration)
		tween.tween_property(sprite, "modulate:a", 0.0, explosion_duration * .5)
		
		# Queue free (delete) the sprite when the animation is done
		tween.tween_callback(sprite.queue_free)

func spawn_rain_sprite():
	var sprite = Sprite2D.new()
	sprite.texture = load("res://data/assets/date/art/happy.png")
	add_child(sprite)
	
	# Set x position based on current spawn position
	var viewport_size = get_viewport_rect().size
	sprite.position = Vector2(current_spawn_position * viewport_size.x, -50)
	
	# Update spawn position for next sprite
	current_spawn_position += 0.3 * spawn_direction  # Adjust 0.05 to control spacing
	
	# Change direction if we've reached the edges
	if current_spawn_position >= 1.0:
		spawn_direction = -1
		current_spawn_position = 1.0
	elif current_spawn_position <= 0.0:
		spawn_direction = 1
		current_spawn_position = 0.0
	
	# Add falling animation
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", viewport_size.y + 150, viewport_size.y / rain_fall_speed)
	tween.tween_callback(sprite.queue_free)
	
	rain_sprites_spawned += 1

func rain():
	isRaining = true
	rain_time_elapsed = 0.0
	rain_sprites_spawned = 0
	spawn_direction = 1
	current_spawn_position = 0.0
