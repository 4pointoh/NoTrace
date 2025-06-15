extends TextureRect

var index: int
var unlocked: bool
var hasVideo: bool

signal selected(index: int)
signal view(index: int)
signal hovered(index: int)
signal video(index: int)

func _on_mouse_entered() -> void:
	hovered.emit(index)
	
	if unlocked:
		%Set.show()
		%View.show()

		if hasVideo:
			%Video.show()
		else:
			%Video.hide()

func _on_mouse_exited() -> void:
	%Set.hide()
	%View.hide()
	%Video.hide()

func _on_set_pressed() -> void:
	selected.emit(index)

func _on_view_pressed() -> void:
	view.emit(index)

func _on_video_pressed() -> void:
	video.emit(index)
