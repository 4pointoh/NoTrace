extends Control

var endList = [
	"res://data/assets/general/art/title2.png",
	"res://data/assets/general/art/title7.png",
	"res://data/assets/general/art/title5.png",
	"res://data/assets/general/art/title6.png",
	"res://data/assets/general/art/title4.png"
]

var colors = [
	Color(Color.from_rgba8(209, 44, 255)),   # Pink
	Color(Color.from_rgba8(255, 120, 11)),   # orange
	Color(Color.from_rgba8(106, 0, 255)),   # Purple
	Color(Color.from_rgba8(194, 0, 0))    # Red
]

var animDurationPerStep = 1
var animInitialDelay = 0.7
var animDurationPassed = 0.0
var currentIndex = 0
var color_index = 0

func _ready() -> void:
	%TitleRootFill.modulate = colors[color_index]
	_tween_to_next_color()

func _process(delta: float) -> void:
	animInitialDelay -= delta
	if animInitialDelay > 0:
		return

	animDurationPassed += delta
	if animDurationPassed >= animDurationPerStep:
		animDurationPassed = 0.0
		currentIndex = (currentIndex + 1) % endList.size()

		var startingY = %TitleEnd.position.y
		var endingY = startingY - 200
		var tween = create_tween()
		tween.tween_property(%TitleEnd, "position:y", endingY, 0.06)
		tween.tween_callback(onAnimationReachTop)
		

func onAnimationReachTop():
	%TitleEnd.texture = load(endList[currentIndex])
	%TitleEnd.position.y = %TitleEnd.position.y + 400
	var tween = create_tween()
	tween.tween_property(%TitleEnd, "position:y", %TitleEnd.position.y - 200, 0.06)

func _tween_to_next_color():
	await get_tree().create_timer(3.5).timeout
	color_index = (color_index + 1) % colors.size()
	var tween = create_tween()
	tween.tween_property(%TitleRootFill, "modulate", colors[color_index], 1.5)
	tween.tween_callback(Callable(self, "_tween_to_next_color"))
