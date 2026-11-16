extends Control

# Drifting petals, pollen and the like. Each child emitter is one atmosphere, named for the
# dialogue signal that turns it on: a child called Petals answers atmosphere_petals. To add
# one, duplicate an emitter in the editor, rename it and restyle it in the inspector. No code
# changes. Only one plays at a time, and atmosphere_off lets it die away naturally.
#
# This is the near layer, in CinematicLayer, over the picture. (A far layer behind portrait
# cards comes with the cards.)

## Seconds for an atmosphere to fade in. Emitters start already spread across the frame, and
## the fade keeps that from reading as a pop.
@export var fadeIn := 1.5
## How far the particles slide against the mouse, in pixels. Nearer layers should slide further:
## that difference is the depth.
@export var parallax := 60.0
## Optional. The background's camera, so particles lean together with the picture.
@export var camera : Node

# What dialogue last asked for.
var wanted = ""
var current : CPUParticles2D

func _ready():
	resized.connect(fitEmitters)
	fitEmitters()
	clear()

# Emitters cover whatever the frame currently is, plus a margin so nothing pops in at an edge.
func fitEmitters():
	for emitter in get_children():
		emitter.position = size / 2
		emitter.emission_rect_extents = size / 2 + Vector2(120, 120)

func play(atmosphereName : String):
	wanted = atmosphereName
	refresh()

func stop():
	wanted = ""
	refresh()

# Ends the atmosphere at once, petals already in the air included (stop() lets them die away).
func clear():
	wanted = ""
	current = null
	for emitter in get_children():
		emitter.emitting = false
		emitter.hide()

func refresh():
	var target = emitterNamed(wanted) if wanted != "" else null
	if target == current:
		return

	if current:
		current.emitting = false
	current = target
	if current:
		current.modulate.a = 0.0
		current.show()
		current.restart()
		current.emitting = true
		create_tween().tween_property(current, "modulate:a", 1.0, fadeIn)

func emitterNamed(atmosphereName : String) -> CPUParticles2D:
	for emitter in get_children():
		if emitter.name.to_lower() == atmosphereName.to_lower():
			return emitter

	push_warning("No atmosphere named '%s' in %s" % [atmosphereName, get_path()])
	return null

func _process(_delta):
	if current and camera:
		current.position = size / 2 - camera.lean * parallax * 2.0
