extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "It's time. Text me when you see this."
	},
	{
		"type": "player_text",
		"content": "Time for?"
	},
	{
		"type": "partner_text",
		"content": "I've got a target."
	},
	{
		"type": "partner_text",
		"content": "And before you ask, yes, it's a real target."
	},
	{
		"type": "player_text",
		"content": "Ok, so what do we do now? What's the plan."
	},
	{
		"type": "partner_text",
		"content": "Not here. Meet me downtown. Tonight."
	},
	{
		"type": "player_text",
		"content": "Tonight?"
	},
	{
		"type": "player_text",
		"content": "Alright... but where downtown?"
	},
	{
		"type": "partner_delay",
	},
	{
		"type": "player_text",
		"content": "Hello? Downtown is huge. Where am I meeting you?"
	},
	{
		"type": "partner_delay",
		"content": "Partner has left the chat."
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "complete"
	}
]

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
	return null
