extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "Heyyy whats up?"
	},
	{
		"type": "dialogue",
		"content": "START1"
	},
	{
		"type": "partner_text",
		"content": "Helloo?? You remember me right?"
	},
	{
		"type": "choice",
		"content": ["How could I forget?","New phone who dis?"]
	}
]

var actionsOne = [
	{
		"type": "player_text",
		"content": "You're the one who dragged me into the women's bathroom stall"
	},
	{
		"type": "partner_text",
		"content": "Right"
	},
	{
		"type": "partner_text",
		"content": "😅"
	},
	{
		"type": "partner_text",
		"content": "I was uhh... well kind of really pissed off at you haha"
	},
	{
		"type": "partner_text",
		"content": "Because of the whole \"misunderstanding\" at Chad's party"
	},
	{
		"type": "partner_text",
		"content": "I had this whole fantasy in my head about how I was going to confront you if I ever saw you again"
	},
	{
		"type": "player_text",
		"content": "Did that fantasy involve dragging me into the women's bathroom?"
	},
	{
		"type": "partner_text",
		"content": "Nooo haha"
	},
	{
		"type": "partner_text",
		"content": "Needless to say, things didn't go how I fantasized"
	},
	{
		"type": "partner_text",
		"content": "I had this whole plan... I was going to walk up to you and say..." 
	},
	{
		"type": "partner_text",
		"content": "\"Hey, you!\""
	},
	{
		"type": "partner_text",
		"content": "And like... shake my fist and stuff"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_delay",
		"content": "Partner is taking a photo"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ana_phone_intro_selfie_angry.png",
		"wallpaperUnlock": ["ANA_PHONE_INTRO_SELFIE_ANGRY"]
	},
	{
		"type": "partner_text",
		"content": "Sorry I'm still in my pj's haha, I practiced this face in the mirror for hours"
	},
	{
		"type": "partner_text",
		"content": "I didn't want it to go to waste"
	},
	{
		"type": "partner_text",
		"content": "Scary right? You would have been so scared. Admit it."	
	},
	{
		"type": "player_text",
		"content": "Wow, nightmare fuel"	
	},
	{
		"type": "partner_text",
		"content": "Wait, it's more menacing if I sit up"	
	},
	{
		"type": "partner_delay"	
	},
	{
		"type": "partner_delay",
		"content": "Partner is moving"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ana_phone_intro_selfie_angry2.png",
		"wallpaperUnlock": ["ANA_PHONE_INTRO_SELFIE_ANGRY2"]
	},
	{
		"type": "partner_text",
		"content": "See that? That's the face of someone who's about to kick your butt!"
	},
	{
		"type": "player_text",
		"content": "Absolutely terrifying"
	},
	{
		"type": "partner_text",
		"content": "Hahahahaha"
	},
	{
		"type": "partner_text",
		"content": "Well it all sounded better in my head"
	},
	{
		"type": "partner_text",
		"content": "😅",
		"advanceActionGroup": 3
	}
]

var actionsTwo = [
	{
		"type": "partner_text",
		"content": "Very funny..."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "... you [i]are[/i] joking, right?"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Helloo??"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_delay",
		"content": "Partner is taking a photo"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/ana_phone_intro_selfie.png",
		"wallpaperUnlock": ["ANA_PHONE_INTRO_SELFIE"]
	},
	{
		"type": "partner_text",
		"content": "It's meeee"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Respond!!"
	},
	{
		"type": "player_text",
		"content": "Haha sorry I'm just messing with you"
	},
	{
		"type": "partner_text",
		"content": "Rude!!"
	},
	{
		"type": "player_text",
		"content": "Sorry sorry haha, I had to get back at you, for the bathroom thing",
	},
	{
		"type": "player_text",
		"content": "And all the accusations and weird questions"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "Fair enough 😅",
		"advanceActionGroup": 3
	},
]

var actionsThree = [
	
	{
		"type": "player_text",
		"content": "Y'know I gotta be honest, I still have no idea what the misunderstanding was"
	},
	{
		"type": "partner_text",
		"content": "Well..."
	},
	{
		"type": "partner_text",
		"content": "Sometimes it's okay to not understand everything"
	},
	{
		"type": "partner_text",
		"content": "Right?"
	},
	{
		"type": "player_text",
		"content": "I mean... wouldn't it be better if I did understand?"
	},
	{
		"type": "partner_text",
		"content": "No"
	},
	{
		"type": "partner_text",
		"content": "😅"
	},
	{
		"type": "partner_text",
		"content": "If I told you, it would ruin everything..."
	},
	{
		"type": "player_text",
		"content": "So you aren't going to explain anything about all the suspicious questions you asked me?"
	},
	{
		"type": "player_text",
		"content": "Something about a disguise..."
	},
	{
		"type": "player_text",
		"content": "That girl screaming your name in the supermarket..."
	},
	{
		"type": "partner_text",
		"content": "Oh yeah I saw you trip her by the way, haha, you didn't have to do that, but thanks!"
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "So... nothing? None of that? You're just going to leave me hanging?"
	},
	{
		"type": "partner_text",
		"content": "... sorry"
	},
	{
		"type": "partner_text",
		"content": "How about this, some day I promise you will know everything"
	},
	{
		"type": "partner_text",
		"content": "But for now, can you just promise me to ignore it?"
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "... Well I guess I doesn't really matter, all things considered"
	},
	{
		"type": "player_text",
		"content": "Your name really is Anna right? Or is that something else I shouldn't question?"
	},
	{
		"type": "partner_text",
		"content": "Yeah, that's my name."
	},
	{
		"type": "partner_text",
		"content": "Or... well, nickname I guess"
	},
	{
		"type": "partner_text",
		"content": "Sorry this all probably seems so weird 😅"
	},
	{
		"type": "partner_text",
		"content": "I PROMISE some day I'll tell you... everything"
	},
	{
		"type": "partner_text",
		"content": "But for now, you promise, right? To ignore it? You never said you promised..."
	},
	{
		"type": "player_text",
		"content": "Sure, I promise."
	},
	{
		"type": "partner_text",
		"content": "Thank you 😅"
	},
	{
		"type": "partner_text",
		"content": "And um... that also means searching up my name on the internet"
	},
	{
		"type": "partner_text",
		"content": "Please don't do that. Until... well, until I tell you"
	},
	{
		"type": "player_text",
		"content": "Damn girl, you're making it sound like you're a wanted criminal. Or international superstar."
	},
	{
		"type": "partner_text",
		"content": "Nooo I promise I'm not a wanted criminal, haha"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "So umm... we can hang out, right? Like friends?"
	},
	{
		"type": "player_text",
		"content": "Yeah sure, I'm down for that"
	},
	{
		"type": "player_text",
		"content": "Hang out how? Like, what do you want to do?"
	},
	{
		"type": "partner_text",
		"content": "Ummm... Just stuff that normal people do I guess"
	},
	{
		"type": "partner_text",
		"content": "Like... burger? Normal people do burger right?"
	},
	{
		"type": "player_text",
		"content": "\"Normal people\"? ... do burger?"
	},
	{
		"type": "player_text",
		"content": "I mean, yeah \"normal people\" [i]eat[/i] burgers"
	},
	{
		"type": "player_text",
		"content": "You want to go out for a burger?"
	},
	{
		"type": "partner_text",
		"content": "Yes!! That sounds great!"
	},
	{
		"type": "player_text",
		"content": "Ok, I can arrange that... what kind of burgers are you thinking about?"
	},
	{
		"type": "partner_text",
		"content": "There are different kinds of burgers?"
	},
	{
		"type": "player_text",
		"content": "Well there's like... fast food burgers, and then there's like... gourmet burgers"
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Am I really explaining burgers to you right now?"
	},
	{
		"type": "player_text",
		"content": "Girl what are you an alien???"
	},
	{
		"type": "partner_text",
		"content": "Sorrryy haha!! Just normal burgers!"
	},
	{
		"type": "player_text",
		"content": "Alright I guess most people would consider 'normal burgers' to be like.. fast food burgers"
	},
	{
		"type": "player_text",
		"content": "We can meet up at McBurgerBomb, tomorrow? Afternoon? Does that work?"
	},
	{
		"type": "partner_text",
		"content": "Perfect!!!"
	},
	{
		"type": "partner_text",
		"content": "McBurgerBomb! I'll have my driver take me there!"
	},
	{
		"type": "partner_text",
		"content": "I'm so excited!! See you there!!!"
	},
	{
		"type": "partner_text",
		"content": "Bye!!!"
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
	if actionGroup == 1:
		return actionGroupOne()
	if actionGroup == 2:
		return actionGroupTwo()
	if actionGroup == 3:
		return actionGroupThree()
	
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


func actionGroupOne():
	if actionIndex >= actionsOne.size():
		return null
		
	var action = actionsOne[actionIndex]

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
	return null


func actionGroupTwo():
	if actionIndex >= actionsTwo.size():
		return null
		
	var action = actionsTwo[actionIndex]

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
	return null


func actionGroupThree():
	if actionIndex >= actionsThree.size():
		return null
		
	var action = actionsThree[actionIndex]

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
	return null
