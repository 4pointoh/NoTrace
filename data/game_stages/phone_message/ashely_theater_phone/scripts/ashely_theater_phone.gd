extends PhoneScript

var actions = [
	{
		"type": "dialogue",
		"content": "START"
	},
	{
		"type": "player_text",
		"content": "Yooo Ashley, you there?"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "How'd it go?"
	},
	{
		"type": "partner_text",
		"content": "Wait... Actually, don't answer that yet."
	},
	{
		"type": "partner_text",
		"content": "I want you to tell me in person."
	},
	{
		"type": "player_text",
		"content": "Umm, okay, why exactly?"
	},
	{
		"type": "partner_text",
		"content": "Umm, for security purposes, or whatever."
	},
	{
		"type": "partner_text",
		"content": "Something something keeping no digital records etc..."
	},
	{
		"type": "partner_text",
		"content": "So, meet me at Cummington Theater. In the little cafe in the back."
	},
	{
		"type": "player_text",
		"content": "... Wait maybe we should just talk about this over text?"
	},
	{
		"type": "partner_text",
		"content": "Absolutely not."
	},
	{
		"type": "partner_text",
		"content": "I've been looking forward to this all day."
	},
	{
		"type": "partner_text",
		"content": "I want the full theatrical experience of how you, ahem, 'charmed' the richest woman in Cummington."
	},
	{
		"type": "player_text",
		"content": "But I should probably say..."
	},
	{
		"type": "partner_text",
		"content": "Shut it honey. I want you to explain it all. In person."
	},
	{
		"type": "player_text",
		"content": "ugh... fine"
	},
	{
		"type": "partner_text",
		"content": "Cummington Theater. Little cafe in the back. Remember that."
	},
	{
		"type": "player_text",
		"content": "Right... fine."
	},
	{
		"type": "partner_text",
		"content": "I can't wait to hear the rousing story of your... success"
	},
	{
		"type": "partner_text",
		"content": "See you there sugar."
	},
	{
		"type": "dialogue",
		"content": "START2"
	},
	{
		"type": "complete"
	}
]

func getNextAction():
	actionIndex = actionIndex + 1
	if actionGroup == 0:
		return actionGroupZero()

func handleChoice(_choice):
	pass

func actionGroupZero():
	if actionIndex >= actions.size():
		return null
		
	var action = actions[actionIndex]

	if "wallpaperUnlock" in action:
		for wp in action["wallpaperUnlock"]:
			GlobalGameStage.unlockWallpaperWithDelay(wp, 14)
		
	match action["type"]:
		"dialogue":
			return getDialogueAction(action["content"])
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
	return null
