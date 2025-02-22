extends ColorRect
class_name Transition

enum TransitionType {
	NONE,
	RED_CAR,
	NIGHT_CAR,
	SLEEP
}

func playTransition(transitionType: TransitionType, text: String):
	show()
	position = Vector2(0,0)
	match transitionType:
		TransitionType.NONE:
			hide()
			return
		TransitionType.RED_CAR:
			playRedCarAnimation()
		TransitionType.NIGHT_CAR:
			playNightCarAnimation()
		TransitionType.SLEEP:
			playSleepAnimation()
	setText(text)

func playRedCarAnimation():
	%TransitionSprite.play("redcar")

func playNightCarAnimation():
	%TransitionSprite.play("nightcar")

func playSleepAnimation():
	%TransitionSprite.play("sleep")

func setText(text):
	%TransitionLabel.text = text
	
func move_out():
	%AnimationPlayer.play("slide_out")
