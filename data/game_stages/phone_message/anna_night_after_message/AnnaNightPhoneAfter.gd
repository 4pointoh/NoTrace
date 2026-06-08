extends PhoneScript

var actions = [
	{ "type": "player_text", "content": "Oh my god. " },   
	{ "type": "partner_text", "content": "🙈 " },   
	{ "type": "partner_text", "content": "Sorry Anna can't respond right now she is asleep!! " },   
	{ "type": "player_text", "content": "Oh my god. " },   
	{ "type": "partner_text", "content": "Sleeping!!" },
	{ "type": "player_text", "content": "If you're the one sleeping, then why am I the one dreaming?" },   
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "Okay I'm turning my phone off bye!!" },
	{ "type": "partner_text", "content": "but um... just one thing" },
	{ "type": "partner_text", "content": "I really meant it when I said I've never taken a photo like that before" },
	{ "type": "partner_text", "content": "Just... understand that can never leak anywhere okay??" },
	{ "type": "partner_text", "content": "... I tried to keep my face covered but I think people would still notice." },
	{ "type": "partner_text", "content": "Promise me?" },
	{ "type": "player_text", "content": "Promise. No question." },   
	{ "type": "partner_text", "content": "Thank you ❤️❤️❤️❤️" },
	{ "type": "partner_text", "content": "Text me soon!", "wallpaperUnlock": ["ANNA_NIGHT_AFTER_1"] },
	{ "type": "complete" }
];

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
		"special":
			return getSpecialAction(action["content"])
		"play_music":
			return getPlayMusicAction(action["content"])
		"fade_music_out":
			return getFadeMusicOutAction()
		"next_message_instant":
			return getNextMessageInstantAction()
		"countdown":
			return getCountdownAction(action["content"], action["countdownLabel"], action["countdownButtonLabel"], action.get("actualDelayInSeconds", 0))
	return null

func loadPreparedMessagesAtStart():
	return true

func getPreparedMessages():
	# These messages were exchanged in the past; preload them so the whole
	# history is already on screen when this conversation opens.
	return [
		{ "type": "partner_text", "content": "Hi" },
		{ "type": "partner_text", "content": "Umm..." },
		{ "type": "partner_text", "content": "So I'm... in your bathroom right now" },
		{ "type": "partner_text", "content": "I just took a shower" },
		{ "type": "partner_text", "content": "And I've never done anything like this before..." },
		{ "type": "partner_text", "content": "But um..." },
		{ "type": "partner_text", "content": "Here" },
		{ "type": "image", "path": "res://data/background_lists/anna_night/home/night_new_4.png" },
		{ "type": "partner_text", "content": "Thanks for tonight." },
	]
