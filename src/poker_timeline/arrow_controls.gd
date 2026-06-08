extends Node2D

signal up
signal left
signal right
signal down
signal zoom_in
signal zoom_out

func _on_up_pressed() -> void:
	up.emit()


func _on_left_pressed() -> void:
	left.emit()


func _on_right_pressed() -> void:
	right.emit()


func _on_down_pressed() -> void:
	down.emit()


func _on_zoom_in_pressed() -> void:
	zoom_in.emit()


func _on_zoom_out_pressed() -> void:
	zoom_out.emit()
