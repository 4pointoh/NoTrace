extends NinePatchRect

func _ready():
	playAnim()

func playAnim():
	position.x = 1000
	var viewport_size = get_viewport_rect().size
	var tween = create_tween()
	tween.tween_property(self, "position:x", -20, 0.4)
	tween.tween_property(self, "position:x", -20, 3)
	tween.tween_property(self, "position:x", -1000, 0.4)
