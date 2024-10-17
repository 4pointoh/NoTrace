extends Node2D

var time_since_last_tween: float = 0.0
const TWEEN_INTERVAL: float = 4.0
var number = 0

func _process(delta):
	time_since_last_tween += delta
	if time_since_last_tween >= TWEEN_INTERVAL and number > 0:
		animate_up(true)
		time_since_last_tween = 0.0

func setNumber(num):
	number = num
	$Label.text = str(number)

func animate_up(repeat):
	var tween = get_tree().create_tween()
	var originalpos = position
	var newpos = originalpos
	newpos.y = newpos.y - 15
	tween.tween_property(self, "position", newpos, 0.1)
	tween.tween_callback(animate_down.bind(repeat))

func animate_down(repeat):
	var tween = get_tree().create_tween()
	var originalpos = position
	var newpos = originalpos
	newpos.y = newpos.y + 15
	tween.tween_property(self, "position", newpos, 0.2).set_trans(Tween.TRANS_BACK)
	
	if(repeat):
		tween.tween_callback(animate_up.bind(false))
