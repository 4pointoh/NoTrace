extends Control

# The portrait -> landscape reveal, as a set-piece. play() below is the whole sequence, top to
# bottom. Everything it moves is a node in LandscapeReveal.tscn, so the look (bars, seam light,
# vignette, title card, petals, the build sound) is edited in the scene, and the order and
# timing are edited here.
#
# The old portrait frame is a matte drawn by this scene, inside a frame that is already
# landscape: the game switches mode at the fully black moment near the start (that is also
# where a windowed game pays for its one OS window resize, unseen, behind Main's cover). Drawing
# the bars ourselves is what lets light and petals cross into them, and it looks identical
# windowed and fullscreen.
#
# This node never touches the rest of the game. It asks, through signals, and whoever owns it
# (CinematicLayer) answers.

## The screen is fully black: put the new picture up and change the frame now. The reveal holds
## on black until the frame is landscape.
signal enteredBlack
## kind is "tight" (snap), "push" (creep closer during the build) or "wide" (pull back).
signal cameraRequested(kind : String, duration : float)
signal musicFadeRequested
## Empty clears the atmosphere (as the screen goes black); a name starts it (as the frame opens).
signal atmosphereRequested(atmosphereName : String)
## Fired early by the track's own pickup, so that its downbeat lands as the frame opens.
signal musicRequested(stream : AudioStream)
signal finished

@export_group("Timing")
## Dip to black, the hold while the game changes shape underneath, and the rise back.
@export var fadeToBlack := 0.5
@export var holdBlack := 0.35
@export var fadeFromBlack := 0.8
## The build-up. Must match the time from the start of the Build sound to its peak.
@export var buildDuration := 2.88
## A few petals slip out of the old frame into the bars during the build, as a tease before
## the burst. Turn off to hold every petal back for the burst itself.
@export var petalsEscapeFirst := true
## How long into the build those first petals leave the old frame.
@export var escapeAfter := 0.7
## The frame bursting open, and the camera pulling back with it (a little longer, so the
## picture is still settling after the frame has arrived).
@export var openDuration := 1.7
@export var pullBackDuration := 2.6
@export var titleHold := 3.0

@export_group("Look")
## The old frame's shape, width / height. Sizes the matte.
@export var portraitAspect := 896.0 / 1152.0
@export_range(0.0, 1.0) var vignetteStrength := 0.6
@export_range(0.0, 1.0) var bloomStrength := 0.55

# 0 shows the old portrait frame, 1 is fully open. A setter, so the matte is already right in
# the same call that changes it and no frame is ever drawn with a stale one.
var opening := 1.0:
	set(value):
		opening = value
		layout()
var ruleAmount := 0.0:
	set(value):
		ruleAmount = value
		layout()

var isPlaying = false

func _ready():
	resized.connect(layout)
	layout()
	visible = false

func play(config : LandscapeRevealConfig):
	isPlaying = true
	visible = true
	%Title.text = config.title
	%Subtitle.text = config.subtitle
	opening = 0.0

	# Quiet: the room empties out, and we cut to the new picture through black.
	musicFadeRequested.emit()
	await fade($Blackout, "color:a", 1.0, fadeToBlack)
	enteredBlack.emit()
	while !DisplayMode.isLandscape():
		await DisplayMode.modeChanged
	cameraRequested.emit("tight", 0.0)
	# Nothing drifts through the build: the burst has to be the moment petals arrive.
	atmosphereRequested.emit("")
	await wait(holdBlack)
	await fade($Blackout, "color:a", 0.0, fadeFromBlack)

	# Anticipation: everything rises together in one smooth curve, with the breeze. The light
	# only ever grows: a steady glow reads as warmth, a flicker reads as sci-fi.
	$Build.volume_db = GlobalGameStage.getBgVolume()
	$Build.play()
	cameraRequested.emit("push", buildDuration)
	fade($Vignette, "modulate:a", vignetteStrength, buildDuration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	for seam in [$SeamLeft, $SeamRight]:
		fade(seam, "modulate:a", 1.0, buildDuration, Tween.TRANS_QUAD, Tween.EASE_IN)

	# The hit at the end of the build is the music's own downbeat, so the track starts early by
	# exactly its pickup (plus output latency, so the beat is heard on the frame, not after it).
	var musicLead = minf(buildDuration, config.musicDownbeat + AudioServer.get_output_latency())
	var firstPetals = minf(escapeAfter, buildDuration - musicLead)
	await wait(firstPetals)
	$EscapeLeft.emitting = petalsEscapeFirst
	$EscapeRight.emitting = petalsEscapeFirst
	await wait(buildDuration - musicLead - firstPetals)
	if config.music:
		musicRequested.emit(config.music)
	await wait(musicLead)

	# The break: fast out of the gate, then a long glide. No impact sound, nothing shakes.
	$EscapeLeft.emitting = false
	$EscapeRight.emitting = false
	$Burst.restart()
	$Bloom.color.a = bloomStrength
	# What the burst leaves behind fades in while it disperses.
	if config.atmosphere != "":
		atmosphereRequested.emit(config.atmosphere)
	cameraRequested.emit("wide", pullBackDuration)
	fade(self, "opening", 1.0, openDuration, Tween.TRANS_EXPO, Tween.EASE_OUT)
	fade($Bloom, "color:a", 0.0, 1.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	fade($Vignette, "modulate:a", 0.0, 1.8)
	for seam in [$SeamLeft, $SeamRight]:
		fade(seam, "modulate:a", 0.0, 1.3)
	await wait(openDuration)

	# The title lands once the frame has settled.
	if config.title != "":
		%TitleCard.scale = Vector2(1.07, 1.07)
		fade(%TitleCard, "scale", Vector2.ONE, titleHold + 0.6, Tween.TRANS_SINE, Tween.EASE_OUT)
		fade(%TitleCard, "modulate:a", 1.0, 0.9)
		fade(self, "ruleAmount", 1.0, 1.4, Tween.TRANS_EXPO, Tween.EASE_OUT)
		await wait(titleHold)
		fade(self, "ruleAmount", 0.0, 0.9)
		await fade(%TitleCard, "modulate:a", 0.0, 0.9)

	isPlaying = false
	visible = false
	finished.emit()

func fade(target, property : String, value, duration : float, transition := Tween.TRANS_LINEAR, easing := Tween.EASE_IN_OUT):
	var tween = create_tween()
	tween.tween_property(target, property, value, duration).set_trans(transition).set_ease(easing)
	await tween.finished

func wait(duration : float):
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout

# Places the matte for the current frame and opening. Runs from the setters and from resized,
# never from _process: whatever changes the frame, the matte is right in that same call.
func layout():
	if !is_node_ready():
		return

	var oldFrameWidth = size.y * portraitAspect
	var wing = maxf(0.0, (size.x - lerpf(oldFrameWidth, size.x, opening)) / 2)
	$WingLeft.size = Vector2(wing, size.y)
	$WingRight.position = Vector2(size.x - wing, 0)
	$WingRight.size = Vector2(wing, size.y)

	# Seam light is centered on each edge of the old frame, spilling onto the bar and the picture.
	var seamWidth = $SeamLeft.size.x
	$SeamLeft.position = Vector2(wing - seamWidth / 2, 0)
	$SeamLeft.size.y = size.y
	$SeamRight.position = Vector2(size.x - wing - seamWidth / 2, 0)
	$SeamRight.size.y = size.y

	$Vignette.position = Vector2(wing, 0)
	$Vignette.size = Vector2(size.x - wing * 2, size.y)

	for escape in [$EscapeLeft, $EscapeRight]:
		escape.emission_rect_extents = Vector2(4, size.y / 2)
	$EscapeLeft.position = Vector2(wing, size.y / 2)
	$EscapeRight.position = Vector2(size.x - wing, size.y / 2)
	$Burst.position = size / 2
	$Burst.emission_rect_extents = Vector2(oldFrameWidth / 2, size.y / 2)

	# The title card is centered on its own origin, whatever the text is: style the labels in
	# the inspector, and their placement follows from their size.
	for label in [%Title, %Subtitle]:
		label.size = label.get_minimum_size()
		label.position.x = -label.size.x / 2
	%Title.position.y = -%Title.size.y / 2
	%Subtitle.position.y = %Title.position.y - %Subtitle.size.y - 6

	# The rules grow outward from the title, echoing the frame.
	var gap = 48.0
	var reach = 320.0 * ruleAmount
	for rule in [%RuleLeft, %RuleRight]:
		rule.size = Vector2(reach, 4)
		rule.position.y = -2
	%RuleLeft.position.x = -%Title.size.x / 2 - gap - reach
	%RuleRight.position.x = %Title.size.x / 2 + gap
