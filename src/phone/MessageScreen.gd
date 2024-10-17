extends ScrollContainer
var max_scroll_length = 0 
var original_max_scroll_length = 0
@onready var scrollbar = get_v_scroll_bar()

func _ready(): 
	scrollbar.changed.connect(handle_scrollbar_changed)
	max_scroll_length = scrollbar.max_value

func handle_scrollbar_changed(): 
	if max_scroll_length != scrollbar.max_value: 
		max_scroll_length = scrollbar.max_value 
	
	if original_max_scroll_length == 0:
		original_max_scroll_length = max_scroll_length
		
	if max_scroll_length == original_max_scroll_length:
		return #visual bug if we dont do thiss
		
	self.scroll_vertical = max_scroll_length

func clear():
	for child in $VBoxContainer.get_children():
		$VBoxContainer.remove_child(child)
		child.queue_free()
	scroll_vertical = 0
