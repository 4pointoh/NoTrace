extends Control

# Define available particle types with their corresponding textures
var particle_types = {
	"heart": load("res://data/assets/date/art/heart_transparent.png"),
	"smile": load("res://data/assets/date/art/transparent_smile1.png"),
	"laugh": load("res://data/assets/date/art/laugh_transparent.png"),
	"poker": load("res://data/assets/date/art/poker_transparent.png"),
	"annoyed": load("res://data/assets/date/art/annoyed_transparent.png")
}

# Dictionary to track the weights (spawn frequency) of each particle type
var particle_weights = {}

var particles = []
var is_raining = false
var spawn_timer = 0.0
var base_spawn_rate = 0.5
var desired_particle_count = 10
var particle_speed = 100

class Particle:
	var particle_types = {
	"heart": load("res://data/assets/date/art/heart_transparent.png"),
	"smile": load("res://data/assets/date/art/transparent_smile1.png"),
	"laugh": load("res://data/assets/date/art/laugh_transparent.png"),
	"poker": load("res://data/assets/date/art/poker_transparent.png"),
	"annoyed": load("res://data/assets/date/art/annoyed_transparent.png")
	}

	var sprite: Sprite2D
	var speed: float

	func _init(pos: Vector2, spd: float, parent: Node, type: String):
		speed = spd

		# Create sprite
		sprite = Sprite2D.new()
		sprite.texture = particle_types[type]
		sprite.position = pos
		parent.add_child(sprite)

		# Create rotation tween
		var tween = parent.create_tween()
		tween.tween_property(sprite, "rotation", randf_range(-PI, PI), 5.0)

func _ready():
	pass

func get_current_spawn_rate() -> float:
	return base_spawn_rate / desired_particle_count

func _process(delta):
	if is_raining:
		spawn_timer += delta
		if spawn_timer >= get_current_spawn_rate() and particles.size() < desired_particle_count:
			spawn_timer -= get_current_spawn_rate()
			spawn_particle()

	# Update particles
	var i = particles.size() - 1
	while i >= 0:
		var particle = particles[i]
		particle.sprite.position.y += particle.speed * delta

		# Remove particles only after they're fully off-screen
		if particle.sprite.position.y > size.y + particle.sprite.texture.get_size().y:
			particle.sprite.queue_free()  # Clean up sprite
			particles.remove_at(i)

		i -= 1

func spawn_particle():
	# Calculate total weight
	var total_weight = 0
	for weight in particle_weights.values():
		total_weight += weight

	if total_weight == 0:
		return  # No particles to spawn

	# Weighted random selection
	var rand = randi() % total_weight
	var cumulative = 0
	var selected_type = null
	for type in particle_weights.keys():
		cumulative += particle_weights[type]
		if rand < cumulative:
			selected_type = type
			break

	if selected_type == null:
		return  # Should not happen

	var texture = particle_types[selected_type]
	var spawn_x = randf_range(0, size.x)
	var particle = Particle.new(
		Vector2(spawn_x, -texture.get_size().y),
		particle_speed * randf_range(0.8, 1.2),
		self,
		selected_type
	)
	particles.append(particle)

func start_rain():
	is_raining = true
	spawn_timer = 0.0

func stop_rain():
	is_raining = false
	# Optional: clear existing particles
	for particle in particles:
		particle.sprite.queue_free()
	particles.clear()

func set_particle_count(count: int):
	desired_particle_count = max(1, count)

func addParticle(type: String):
	if particle_types.has(type):
		if particle_weights.has(type):
			particle_weights[type] += 1
		else:
			particle_weights[type] = 1
	else:
		print("Unknown particle type: ", type)
