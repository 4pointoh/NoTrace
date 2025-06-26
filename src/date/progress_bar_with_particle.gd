extends Node2D

@export var texture : Texture2D
@export var particle : Texture2D
@export var particle_color : Color
@export var spawn_sound : AudioStream 
@export var collect_sound : AudioStream

var target_position: Vector2
var spawn_position: Vector2
var diamonds_in_motion = []
var progress_per_cluster = 0.2
var current_progress = 0
var target_progress = 0
var progress_per_diamond = 2.0
var is_draining = false
var drain_speed = 50.0  # Progress points per second

const DIAMONDS_PER_CLUSTER = 5
const CLUSTER_SPREAD = 400
const CLUSTER_TIME_VARIANCE = 0.1
const MOVEMENT_SPEED = 0.8

func _ready():
	$ProgressBar.texture = texture
	set_progress(0)
	spawn_position = Vector2(-300,-300)
	target_position = $ProgressBar.position
	current_progress = 10

	var spawn_audio = AudioStreamPlayer2D.new()
	spawn_audio.name = "SpawnAudio"
	spawn_audio.stream = spawn_sound
	add_child(spawn_audio)

	var collect_audio = AudioStreamPlayer2D.new()
	collect_audio.name = "CollectAudio"
	collect_audio.stream = collect_sound
	collect_audio.pitch_scale = 1
	add_child(collect_audio)

	var pitch_reset_timer = Timer.new()
	pitch_reset_timer.name = "PitchResetTimer"
	pitch_reset_timer.one_shot = true
	pitch_reset_timer.wait_time = 2.0
	pitch_reset_timer.connect("timeout", _on_pitch_reset_timeout)
	add_child(pitch_reset_timer)

func _on_pitch_reset_timeout():
	$CollectAudio.pitch_scale = 1

func _process(delta):
	# Handle progress bar draining
	if is_draining:
		if current_progress > target_progress:
			current_progress = max(target_progress, current_progress - drain_speed * delta)
			$ProgressBar.material.set_shader_parameter("fill_amount", (current_progress/100.0))
		else:
			is_draining = false

	var completed_diamonds = []
	var cluster_complete = false
	
	for diamond in diamonds_in_motion:
		diamond.t += delta * MOVEMENT_SPEED
		
		if diamond.t >= 1.0:
			diamond.particles.position = Vector2.ZERO
			diamond.particles.emitting = true
			completed_diamonds.append(diamond)

			if not is_draining:  # Only update progress if not currently draining
				current_progress += progress_per_diamond
				$ProgressBar.material.set_shader_parameter("fill_amount", (current_progress/100.0))

			if(!$CollectAudio.playing):
				$CollectAudio.pitch_scale = $CollectAudio.pitch_scale + 0.2
				$CollectAudio.play()

			$PitchResetTimer.start()
		else:
			var t = diamond.t
			var start_pos = spawn_position + diamond.offset
			var end_pos = target_position
			
			var ease_t = ease(t, 2.0)
			var new_pos = start_pos.lerp(end_pos, ease_t)
			new_pos.y += -150 * sin(t * PI)
			new_pos.x += diamond.offset.x * (1.0 - t) * sin(t * PI * 2)
			
			diamond.sprite.position = new_pos
			diamond.sprite.rotation = diamond.base_rotation + t * PI * 2 * diamond.rotation_speed
			diamond.sprite.scale = Vector2.ONE * (1.0 - t * 0.3)
			
	if completed_diamonds.size() > 0:
		if completed_diamonds.size() == diamonds_in_motion.size():
			cluster_complete = true
			
		for diamond in completed_diamonds:
			var particles = diamond.particles
			particles.get_parent().remove_child(particles)
			add_child(particles)
			particles.position = diamond.sprite.position
			
			var timer = get_tree().create_timer(particles.lifetime + 0.1)
			timer.connect("timeout", particles.queue_free, 4)
			
			diamond.sprite.queue_free()
			diamonds_in_motion.erase(diamond)

	return cluster_complete

func set_progress(progress : float):
	target_progress = progress
	if progress < current_progress:
		# Start the draining animation
		is_draining = true
	else:
		# For increasing progress, spawn diamonds that will update progress on collision
		collect_multiple_clusters(int((progress - current_progress) / (progress_per_diamond * DIAMONDS_PER_CLUSTER)))

func create_particle_effect() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 0.8
	particles.amount = 20
	particles.speed_scale = 2.0
	
	# Particle properties
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 980)
	particles.initial_velocity_min = 300
	particles.initial_velocity_max = 450
	particles.scale_amount_min = 4.0
	particles.scale_amount_min = 6.0
	
	# Color gradient
	var gradient = Gradient.new()
	gradient.colors = [particle_color]
	particles.color_ramp = gradient
	
	return particles

func spawn_diamond_cluster():
	if(!$SpawnAudio.playing):
		$SpawnAudio.play()

	for i in range(DIAMONDS_PER_CLUSTER):
		var diamond = Sprite2D.new()
		diamond.texture = particle
		
		var offset = Vector2(
			randf() * CLUSTER_SPREAD - CLUSTER_SPREAD/2.0,
			randf() * CLUSTER_SPREAD - CLUSTER_SPREAD/2.0
		)
		
		diamond.position = spawn_position + offset
		add_child(diamond)
		
		# Setup particles
		var particles = create_particle_effect()
		diamond.add_child(particles)
		
		diamonds_in_motion.append({
			"sprite": diamond,
			"t": randf() * CLUSTER_TIME_VARIANCE,
			"offset": offset,
			"base_rotation": randf() * PI * 2,
			"rotation_speed": randf() * 2 - 1,
			"particles": particles
		})

func collect_multiple_clusters(num_clusters: int = 1):
	for i in range(num_clusters):
		spawn_diamond_cluster()
		await get_tree().create_timer(0.1).timeout

# Example usage
func _on_trigger_collection():
	collect_multiple_clusters(3)
