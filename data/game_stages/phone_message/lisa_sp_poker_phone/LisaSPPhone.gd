extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "So..."
	},
	{
		"type": "partner_text",
		"content": "You there {player_name}?"
	},
	{
		"type": "player_text",
		"content": "Waddup?"
	},
	{
		"type": "partner_text",
		"content": "I'm ready to play some... poker."
	},
	{
		"type": "player_text",
		"content": "Oh?"
	},
	{
		"type": "player_text",
		"content": "Normal poker? Or...?"
	},
	{
		"type": "partner_text",
		"content": "Let's talk in person, is that okay?"
	},
	{
		"type": "player_text",
		"content": "Well I suppose I can clear my busy schedule of eating frozen pizza and watching youtube videos..."
	},
	{
		"type": "partner_text",
		"content": "That's how you're spending this beautiful day???"
	},
	{
		"type": "partner_text",
		"content": "It's 80 degrees and sunny! Perfect running weather!!"
	},
	{
		"type": "player_text",
		"content": "Okay now you're starting to sound like my mom."
	},
	{
		"type": "partner_text",
		"content": "Sorryyy sorry, lol!"
	},
	{
		"type": "partner_text",
		"content": "But yeah... can we meet up?"
	},
	{
		"type": "player_text",
		"content": "Sure, where at?"
	},
	{
		"type": "partner_text",
		"content": "Well... I think I would be most comfortable if you come here."
	},
	{
		"type": "player_text",
		"content": "Where is 'here'?"
	},
	{
		"type": "partner_text",
		"content": "My apartment."
	},
	{
		"type": "player_text",
		"content": "Oh. Alright."
	},
	{
		"type": "player_text",
		"content": "Where at?"
	},
	{
		"type": "partner_text",
		"content": "I'll text you an address in a sec."
	},
	{
		"type": "partner_text",
		"content": "So you're going to come over?"
	},
	{
		"type": "player_text",
		"content": "Of course."
	},
	{
		"type": "partner_text",
		"content": "Yayy!"
	},
	{
		"type": "partner_text",
		"content": "Best coach ever!"
	},
	{
		"type": "partner_text",
		"content": "Let me ummm... figure out what I'm going to... wear, I guess. Ha"
	},
	{
		"type": "partner_text",
		"content": "Come over asap! See you soon!"
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
