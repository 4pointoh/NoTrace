extends PhoneScript

# Ashely texts you to the park: the message that unlocks Ashely Poker II. Placeholder chat, to be
# rewritten. The intro picks up straight after it ("Ashely insists she has another target...").
var actions = [
	{ "type": "partner_text", "content": "You up?" },
	{ "type": "player_text", "content": "I am now." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "That was a joke, sugar." },
	{ "type": "partner_text", "content": "It's 2pm on a Tuesday." },
	{ "type": "player_text", "content": "Uhh..." },
	{ "type": "player_text", "content": "I was... joking too?" },
	{ "type": "partner_text", "content": "don't tell me my text message actually just woke you up..." },
	{ "type": "partner_text", "content": "What exactly do you DO all day?" },
	{ "type": "partner_text", "content": "Y'know what... don't answer that." },
	{ "type": "partner_text", "content": "You need to get to the park. Now." },
	{ "type": "player_text", "content": "The park? Why?" },
	{ "type": "partner_text", "content": "We have a target." },
	{ "type": "partner_text", "content": "A wealthy one. Very wealthy." },
	{ "type": "player_text", "content": "Is this a real target, or another one of your games?" },
	{ "type": "partner_text", "content": "Would I lie to you, sugar?" },
	{ "type": "player_text", "content": "Yes." },
	{ "type": "player_text", "content": "Constantly." },
	{ "type": "partner_text", "content": "Park. Now. Don't make me wait." },
	{ "type": "complete" }
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
			GlobalGameStage.unlockWallpaperWithDelay(wp, 1)

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
		"play_music":
			return getPlayMusicAction(action["content"])
		"fade_music_out":
			return getFadeMusicOutAction()
		"next_message_instant":
			return getNextMessageInstantAction()
	return null
