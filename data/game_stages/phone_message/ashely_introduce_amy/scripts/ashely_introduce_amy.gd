extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "You there?"
	},
	{
		"type": "player_text",
		"content": "mmhm"
	},
	{
		"type": "partner_text",
		"content": "You remember what we talked about?"
	},
	{
		"type": "player_text",
		"content": "Umm so basically you've got a target you want me to rizz up"
	},
	{
		"type": "player_text",
		"content": "and then convince her to play some high stakes poker and win money from her"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "If you ever say 'rizz' again, I will personally remove your tongue and serve it with sweet tea darlin'"
	},
	{
		"type": "partner_text",
		"content": "Alright honey I'm going to share the details on your target"
	},
	{
		"type": "partner_text",
		"content": "Once I do that, you're in. Do you understand that? No backing out."
	},
	{
		"type": "partner_text",
		"content": "Once you know the specifics, I'll personally fuck you up if you mess with my scheme."
	},
	{
		"type": "player_text",
		"content": "... sorry I stopped reading after 'I'll personally fuck you', which sound great btw"
	},
	{
		"type": "partner_text",
		"content": "Shut up and listen sugar."
	},
	{
		"type": "partner_text",
		"content": "This is your target"
	},
	{
		"type": "image",
		"path": "res://data/game_stages/phone_message/ashely_introduce_amy/security_footage.png"
	},
	{
		"type": "partner_text",
		"content": "Got it?"
	},
	{
		"type": "player_text",
		"content": "... the fuck is this creepy security footage style photos"
	},
	{
		"type": "player_text",
		"content": "I thought you said this was all above board"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "You said you were in. Put your big boy britches on and listen"
	},
	{
		"type": "partner_text",
		"content": "This here is a photo of Amy Perrier. One of the richest... hell, THE richest woman in Cummington."
	},
	{
		"type": "partner_text",
		"content": "She's got all the warmth of a December midnight and twice the bite of winter wind. Cold as ice."
	},
	{
		"type": "partner_text",
		"content": "And it just so happens she loves a good game of Five Card Draw."
	},
	{
		"type": "player_text",
		"content": "... alright so how exactly do I get in contact with the richest woman in Cummington?"
	},
	{
		"type": "partner_text",
		"content": "I've already got all the details figured out sugar. Just listen."
	},
	{
		"type": "partner_text",
		"content": "She hangs out at Cummington Poker Hall. An exclusive, high-end poker hall and casino."
	},
	{
		"type": "partner_text",
		"content": "You can find her there. I don't know when. But I know for a fact she's a regular."
	},
	{
		"type": "player_text",
		"content": "Ok so I go there, find her, and then...? What exactly do I do next?"
	},
	{
		"type": "partner_text",
		"content": "Honey, that's your job to figure out. I told you the plan. I figured out the target. YOU are the one who executes."
	},
	{
		"type": "partner_text",
		"content": "Get out there and earn your 20% cut."
	},
	{
		"type": "player_text",
		"content": "Alright I guess the rizzler can turn on the rizz."
	},
	{
		"type": "player_text",
		"content": "Wait 20%???"
	},
	{
		"type": "partner_text",
		"content": "Sweetheart you're damn lucky I didn't just drop it to 2% after that rizzler line."
	},
	{
		"type": "partner_text",
		"content": "Now get out there. I expect to hear from you tomorrow, got it? Any longer and I'll start to assume foul play."
	},
	{
		"type": "player_text",
		"content": "Wait wait I wanted to talk about the 20% thing"
	},
	{
		"type": "partner_text",
		"content": "Hmm let me think about it."
	},
	{
		"type": "partner_delay",
		"content": "Partner opened their camera app"
	},
	{
		"type": "image",
		"path": "res://data/game_stages/phone_message/ashely_introduce_amy/middlefinger.png",
		"wallpaperUnlock": ["ashe_middlefinger","middlefinger-alt-art"]
	},
	{
		"type": "partner_text",
		"content": "Now get out there. I expect to hear from you tomorrow, got it? Any longer and I'll start to assume foul play."
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
