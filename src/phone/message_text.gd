extends NinePatchRect

func setMessage(isPlayerMessage, text, contactName = ""):
	if isPlayerMessage:
		texture = load("res://data/assets/phone/art/message_text_bg2_shadow.png")
	elif contactName == "Lisa":
		texture = load("res://data/assets/phone/art/message_text_bg3_shadow.png")
	elif contactName == "Ashely":
		texture = load("res://data/assets/phone/art/message_text_bg5_shadow.png")
	elif contactName == "Amy":
		texture = load("res://data/assets/phone/art/message_text_bg6_shadow.png")
	else:
		texture = load("res://data/assets/phone/art/message_text_bg1_shadow.png")
		
	$Label.append_text(replaceEmoji(text))
	
	call_deferred("setNewBoxSize")
	
func replaceEmoji(text):
	text = text.replace("🤦🏻‍♀️", "[font_size=23]🤦🏻‍♀️[/font_size]")
	text = text.replace("😁", "[font_size=23]😁[/font_size]")
	text = text.replace("😭", "[font_size=23]😭[/font_size]")
	text = text.replace("🙂", "[font_size=23]🙂[/font_size]")
	text = text.replace("🙄", "[font_size=23]🙄[/font_size]")
	return text

func setNewBoxSize():
	custom_minimum_size.y = $Label.size.y + 31
	
	var originalSize = custom_minimum_size
	custom_minimum_size.x = 0
	$Label.visible = false
	var tween = get_tree().create_tween()
	tween.tween_property(self, "custom_minimum_size", originalSize, 0.1)
	tween.tween_callback(labelVisible)

func enableReadReceipt():
	$Check1.visible = true
	$Check2.visible = true

func labelVisible():
	$Label.visible = true
