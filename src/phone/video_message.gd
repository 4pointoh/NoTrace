extends Control


func setVideo(path):
	$VideoStreamPlayer.stream = load(path)
	#$VideoStreamPlayer.play()
