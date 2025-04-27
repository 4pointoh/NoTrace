extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "Heyy!!"
	},
	{
		"type": "player_text",
		"content": "What's up?"
	},
	{
		"type": "partner_text",
		"content": "Remember how you asked about Lyric? I promised I would send a photo of him!!"
	},
	{
		"type": "partner_text",
		"content": "Wait a minute... he's right next to me! I just need to get a photo"
	},
	{
		"type": "partner_delay",
		"content": "Partner is looking for her cat"
	},
	{
		"type": "partner_delay",
		"content": "Partner struggling with her cat"
	},
	{
		"type": "partner_delay",
		"content": "Partner is trying to take a photo"
	},
	{
		"type": "partner_delay",
		"content": "Partner's cat is not cooperating"
	},
	{
		"type": "partner_delay",
		"content": "Partner is cursing at her cat"
	},
	{
		"type": "partner_delay",
		"content": "Partner has cornered her cat"
	},
	{
		"type": "partner_delay",
		"content": "Partner is taking a photo"
	},
	{
		"type": "partner_delay",
		"content": "The cat escaped again. It fucking got away again."
	},
	{
		"type": "partner_delay",
		"content": "Partner is chasing her cat."
	},
	{
		"type": "partner_delay",
		"content": "Oh shit... I think she got it"
	},
	{
		"type": "partner_delay",
		"content": "Partner is taking a photo"
	},
	{
		"type": "partner_text",
		"content": "Sorry I was just trying to get a good angle, he's right here just cuddling with me!"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ana_lyric.png",
		"wallpaperUnlock": ["ANA_LYRIC"]
	},
	{
		"type": "player_text",
		"content": "Wow he's a cutie"
	},
	{
		"type": "partner_text",
		"content": "He really gets me through a lot."
	},
	{
		"type": "partner_text",
		"content": "OMG wait he's doing something cute"
	},
	{
		"type": "partner_delay",
		"content": "Partner is taking a photo"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ana_lyric2.png",
		"wallpaperUnlock": ["ANA_LYRIC2"]
	},
	{
		"type": "partner_text",
		"content": "Look at him!!"
	},
	{
		"type": "partner_text",
		"content": "He's all the way up on me LOL!"
	},
	{
		"type": "player_text",
		"content": "This is reaching dangerous levels of cuteness 😭"
	},
	{
		"type": "partner_text",
		"content": "I know right? I love him so much 😭"
	},
	{
		"type": "partner_text",
		"content": "I don't know what I would do without him."
	},
	{
		"type": "partner_text",
		"content": "But it's nice to have a human I can talk to also ^.^"
	},
	{
		"type": "partner_text",
		"content": "Okay I gotta go!! Just wanted to send that because I promised!"
	},
	{
		"type": "partner_text",
		"content": "Byee!!"
	},
	{
		"type": "partner_text",
		"content": "OOH WAIT!!"
	},
	{
		"type": "partner_text",
		"content": "Lyric wants to say goodbye too!!"
	},
	{
		"type": "partner_delay",
		"content": "Partner is taking a photo"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ana_lyric3.png",
		"wallpaperUnlock": ["ANA_LYRIC3"]
	},
	{
		"type": "player_text",
		"content": "Give him a kiss for me, I already miss him 😭"
	},
	{
		"type": "partner_text",
		"content": "I'll give him a hundred kisses! From both of us!!"
	},
	{
		"type": "partner_text",
		"content": "Okay bye for real this time!!"
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
