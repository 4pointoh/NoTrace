extends Control

signal hoveringColor(currentColor : RealDateColorHelper.TopicColors)
signal notHoveringTracker

func getStates():
	var states = {}
	
	for child in %Row1.get_children():
		states[child.color] = child.currentSymbol
	
	return states

func disableIcons():
	for child in %Row1.get_children():
		if child.currentSymbol == 1:
			child.disable()


func _on_tracking_icon_hovering_tacker(currentColor):
	hoveringColor.emit(currentColor)

func _on_tracking_icon_not_hovering_tracker():
	notHoveringTracker.emit()
