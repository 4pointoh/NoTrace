extends TextureButton

signal pressedButton(stage: GameStage)

var curStage : GameStage

func setStage(gameStage):
	curStage = gameStage
	texture_normal = gameStage.stageButtonTexture
	texture_hover = gameStage.stageButtonHover
	$Label.text = gameStage.stageButtonLabel


func _on_pressed():
	pressedButton.emit(curStage)
	
