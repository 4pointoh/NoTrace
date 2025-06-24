extends Control

signal selectedMode(mode: int)

var locked = false
var selectionIndex = -1

func highlightSelection():
	%PokerProPlus.modulate = Color(.17, .95, 0, 1.0)

func unHighlightSelection():
	%PokerProPlus.modulate =  Color(1.0, 1.0, 1.0, 1.0)

func setLocked():
	locked = true
	%ProPlusLocked.show()
	%ProPlusUnlockLabel.show()
	%ProPlusPokerLabel.hide()

func setUnlocked():
	locked = false
	%ProPlusLocked.hide()
	%ProPlusUnlockLabel.hide()
	%ProPlusPokerLabel.show()

func setText(txt):
	%ProPlusPokerLabel.text = txt

func _on_pro_plus_button_pressed() -> void:
	if locked:
		return

	selectedMode.emit(selectionIndex)
	highlightSelection()

func playUnlockedAnimation() -> void:
	setLocked()
	await get_tree().create_timer(1).timeout
	%AudioStreamPlayer.stream = load("res://data/assets/general/sound_effects/unlock.mp3")
	%AudioStreamPlayer.play()
	emitGoldExplosion()
	setUnlocked()

func emitGoldExplosion():
	# Create particles dynamically
	var particles = %CPUParticles2D
	
	# Position particles at the center or wherever appropriate
	particles.position = Vector2(position.x + 185, position.y + 75)  # Adjust as needed
	
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
	particles.color = Color.GOLD
	
	# Start emitting
	particles.emitting = true

	#Tween back to emitting false after 2 seconds
	var tween = get_tree().create_tween()
	tween.tween_property(particles, "emitting", false, 2.0)
