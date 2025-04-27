extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "Text me when you're home from the bar."
	},
	{
		"type": "player_text",
		"content": "I'm home. Did you get back safe and sound?"
	},
	{
		"type": "partner_text",
		"content": "I wouldn't be texting you if I didn't."
	},
	{
		"type": "player_text",
		"content": "Ok... you can tone down the bitch levels at least three notches."
	},
	{
		"type": "player_text",
		"content": "So why are you texting me? It's 3am. You stil have energy after the night we had?"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "player_text",
		"content": "Hello?"
	},
	{
		"type": "partner_text",
		"content": "Tonight was fun."
	},
	{
		"type": "player_text",
		"content": "Umm, yeah I thought so too."
	},
	{
		"type": "player_text",
		"content": "Your scheme went off without a hitch. Totally sucked that guy in."
	},
	{
		"type": "player_text",
		"content": "It felt like we were undercover. It was fun."
	},
	{
		"type": "partner_text",
		"content": "... you are actually clueless. I wasn't talking about the scheme."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Ugh... I'm going to regret this when I wake up."
	},
	{
		"type": "partner_text",
		"content": "And even if I don't regret it, you're never going to mention it."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Just look."
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ashely_selfie1.png",
		"wallpaperUnlock": ["ASHELY_SELFIE1"]
	},
	{
		"type": "player_text",
		"content": "Holy. Shit."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "When I wake up, this never happened."
	},
	{
		"type": "dialogue",
		"content": "START1"
	},
	{ 
		"type": "partner_text",
		"content": "And don't you dare text me a dick pic."
	},
	{ 
		"type": "player_text",
		"content": "Of course not, wouldn't even think of it"
	},
	{ 
		"type": "partner_text",
		"content": "... You are such a clown"
	},
	{ 
		"type": "partner_text",
		"content": "And I'm still going to crush you in our rematch."
	},
	{ 
		"type": "partner_text",
		"content": "I'll text you soon."
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
