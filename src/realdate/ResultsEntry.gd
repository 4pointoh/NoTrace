extends Control

signal finished

var playerColor
var cpuColor
var resultNumber

var particles

var matchSound = load("res://data/assets/realdate/sounds/ding5.mp3")
var mismatchSound = load("res://data/assets/realdate/sounds/clunk4.mp3")

func setup(playerColor2: RealDateColorHelper.TopicColors, cpuColor2 : RealDateColorHelper.TopicColors, resultNumber2 : int):
	%PlayerChoice.show()
	%CPUChoice.hide()
	%Label.show()
	%Star.hide()
	
	playerColor = playerColor2
	cpuColor = cpuColor2
	resultNumber = resultNumber2
	
	%PlayerChoice.texture = RealDateColorHelper.getColorCircleTextureForColor(playerColor)
	%Label.text = str(resultNumber)
	

func playAnimation():
	# First hide everything
	%PlayerChoice.show()
	%CPUChoice.hide()
	%Label.show()
	%Star.hide()
	
	# Set up textures and result text
	%PlayerChoice.texture = RealDateColorHelper.getColorCircleTextureForColor(playerColor)
	%CPUChoice.texture = RealDateColorHelper.getColorCircleTextureForColor(cpuColor)
	%Label.text = str(resultNumber)

	# Show CPU choice after delay
	%CPUChoice.show()
	
	# If choices match, show particle effect and star
	if playerColor == cpuColor:
		%AudioStreamPlayer.stream = matchSound
		%AudioStreamPlayer.play()
		%Star.show()
		
		# Create particles dynamically
		particles = CPUParticles2D.new()
		add_child(particles)
		
		# Position particles at the center or wherever appropriate
		particles.position = %PlayerChoice.position
		
		# Configure particle properties
		particles.amount = 50
		particles.lifetime = 2.0
		particles.explosiveness = 1
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 5.0
		particles.direction = Vector2(0, -1)
		particles.spread = 180
		particles.gravity = Vector2(0, 98)
		particles.initial_velocity_min = 100
		particles.initial_velocity_max = 200
		particles.scale_amount_max = 10.0
		
		# Set particle color based on the matching color
		particles.color = Color.RED
		
		# Start emitting
		particles.emitting = true
	else:
		%AudioStreamPlayer.stream = mismatchSound
		%AudioStreamPlayer.play()

	# Emit finished signal to notify parent
	finished.emit()

func freeParticles():
	if particles:
		particles.queue_free()
