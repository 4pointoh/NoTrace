extends PhoneScript

var actions = [
	{ "type": "partner_text", "content": "Hey!" },
	{ "type": "partner_text", "content": "Okay... this is kind of weird..." },
	{ "type": "partner_text", "content": "But, I'm the guy who just delivered that sweater to you" },
	{ "type": "partner_text", "content": "And, well..." },
	{ "type": "partner_text", "content": "" },
	{ "type": "complete" }
];

func loadPreparedMessagesAtStart():
	return true

func getNextAction():
	actionIndex = actionIndex + 1
	if actionGroup == 0:
		return actionGroupZero()
	
func setActionGroup(group):
	actionGroup = group
	actionIndex = -1

func handleChoice(_choice):
	if actionGroup == 0 && _choice == 0:
		setActionGroup(1)
	elif actionGroup == 0 && _choice == 1:
		setActionGroup(2)

func actionGroupZero():
	if actionIndex >= actions.size():
		return null
		
	var action = actions[actionIndex]

	if action.has("advanceActionGroup"):
		advanceActionGroup(action["advanceActionGroup"])

	if "wallpaperUnlock" in action:
		for wp in action["wallpaperUnlock"]:
			GlobalGameStage.unlockWallpaperWithDelay(wp, 14)
		
	match action["type"]:
		"player_text":
			var content = action["content"]
			content = content.replace("{player_name}", GlobalGameStage.playerName)
			return getPlayerTextAction(content)
		"partner_text":
			var content = action["content"]
			content = content.replace("{player_name}", GlobalGameStage.playerName)
			return getPartnerTextAction(content)
		"partner_delay":
			if "content" in action:
				return getPartnerDelay(action["content"])
			return getPartnerDelay()
		"image":
			var img = load(action["path"])
			return getImageAction(img)
		"video":
			return getVideoAction(action["path"])
		"dialogue":
			return getDialogueAction(action["content"])
		"complete":
			return getCompleteAction()
		"choice":
			return getChoiceAction(action["content"])
		"special":
			return getSpecialAction(action["content"])
		"play_music":
			return getPlayMusicAction(action["content"])
		"fade_music_out":
			return getFadeMusicOutAction()
	return null

func getPreparedMessages():
	return [
		{ "type": "partner_text", "content": "Thank you for placing a delivery order from Cumco Fashion!" },
		{ "type": "partner_text", "content": "Your order summary is below:" },
		{ "type": "partner_text", "content": "1x Red Holiday Sweater - $49.99" },
		{ "type": "partner_text", "content": "Delivery Fee - $14.99" },
		{ "type": "partner_text", "content": "Service Fee - $12.87" },
		{ "type": "partner_text", "content": "Taxes - $9.42" },
		{ "type": "partner_text", "content": "Bad Weather Fee [SNOW] - $19.45" },
		{ "type": "partner_text", "content": "Express Priority Delivery [15 MINUTE DELIVERY] - $87.99" },
		{ "type": "partner_text", "content": "Driver Tip - $0.00" },
		{ "type": "partner_text", "content": "==================================" },
		{ "type": "partner_text", "content": "Status Update: Your driver is on the way!" },
		{ "type": "partner_text", "content": "==================================" },
		{ "type": "partner_text", "content": "Status Update: Your driver is nearby, be ready to accept the delivery!" },
		{ "type": "partner_text", "content": "==================================" },
		{ "type": "partner_text", "content": "Status Update: Your delivery is complete! Have a happy holidays!" },
		{ "type": "partner_text", "content": "==================================" },
		{ "type": "partner_text", "content": "[CUMCO DELIVERY IS CONNECTING YOU WITH YOUR DRIVER]" },
		{ "type": "partner_text", "content": "[COMMUNICATION WITH YOUR DRIVER IS STRICTLY MONITORED]" },
		{ "type": "partner_text", "content": "==================================" },

	]

# IDEA - 2nd conversation happens afterwards. From doordash driver. He says he thinks you were cute (thinking you are ashely)
# IDEA - add 'new message from {name}' pop up to phone in ashely scene 
