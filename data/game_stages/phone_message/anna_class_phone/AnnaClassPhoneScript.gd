extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "Heyyyy how have you been?"
	},
	{
		"type": "player_text",
		"content": "Good good..."
	},
	{
		"type": "player_text",
		"content": "And you?"
	},
	{
		"type": "partner_text",
		"content": "Good..."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Everything good there? What's with all the dots?"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "Okay, I'm a little bored actually..."
	},
	{
		"type": "partner_text",
		"content": "What are you up to? Anything I can help with?"
	},
	{
		"type": "player_text",
		"content": "Unfortunately the things I'm working on will probably bore you even more."
	},
	{
		"type": "partner_text",
		"content": "Oh really? Try me."
	},
	{
		"type": "player_text",
		"content": "Well I'm trying to figure out what classes I am going to take next semester at Cummington State."
	},
	{
		"type": "player_text",
		"content": "Do I take 'Advanced Theoretical Calculus' at 8am with Professor Cockburn? Or..."
	},
	{
		"type": "player_text",
		"content": "Maybe 'Theoretical Introduction To Advanced Calculusology' at 9am with Professor Dickwell?"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Yeah..."
	},
	{
		"type": "player_text",
		"content": "Not very exciting stuff."
	},
	{
		"type": "partner_text",
		"content": "THAT SOUNDS LIKE SO MUCH FUN!!"
	},
	{
		"type": "player_text",
		"content": "Excuse me?"
	},
	{
		"type": "partner_text",
		"content": "Well, not the scheduling part. But you get to go to school? Meet people? Learn stuff?"
	},
	{
		"type": "partner_text",
		"content": "That sounds amazing!"
	},
	{
		"type": "player_text",
		"content": "Going into my 5th year... the novelty has worn off a bit."
	},
	{
		"type": "player_text",
		"content": "But you sound pretty excited about it."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "What if...?"
	},
	{
		"type": "player_text",
		"content": "Don't say it."
	},
	{
		"type": "partner_text",
		"content": "What if I...?"
	},
	{
		"type": "player_text",
		"content": "Do not suggest it."
	},
	{
		"type": "player_text",
		"content": "Under no circumstances will I allow you to take my place in my classes, acting as my doppleganger."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "Why not??!!"
	},
	{
		"type": "player_text",
		"content": "Well, first of all, you're a woman."
	},
	{
		"type": "partner_text",
		"content": "I have disguises!"
	},
	{
		"type": "player_text",
		"content": "Haven't we already run into like 3 different situations where your disguise didn't work?"
	},
	{
		"type": "player_text",
		"content": "Which is crazy because we've only met like 3 times total."
	},
	{
		"type": "partner_text",
		"content": "Fine."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "But what if I just came to class with you? As your friend?"
	},
	{
		"type": "player_text",
		"content": "Hmmm"
	},
	{
		"type": "player_text",
		"content": "No that wouldn't work. Class is not a vacation, I actually have to pay attention and learn stuff."
	},
	{
		"type": "player_text",
		"content": "Like advanced theoretical calcushitology or whatever it's called."
	},
	{
		"type": "partner_text",
		"content": "Awww... really?"
	},
	{
		"type": "partner_text",
		"content": "So there's no way?"
	},
	{
		"type": "player_text",
		"content": "Well..."
	},
	{
		"type": "partner_text",
		"content": "...well?!"
	},
	{
		"type": "player_text",
		"content": "I guess you don't need to attend my REAL classes with me."
	},
	{
		"type": "player_text",
		"content": "In fact, we don't even need to wait until next semester."
	},
	{
		"type": "player_text",
		"content": "There are summer classes going right now."
	},
	{
		"type": "partner_text",
		"content": "What? REALLY?!"
	},
	{
		"type": "partner_text",
		"content": "So we can crash a class together?"
	},
	{
		"type": "player_text",
		"content": "I suppose so, but we will need to be careful."
	},
	{
		"type": "partner_text",
		"content": "Careful is my middle name!"
	},
	{
		"type": "player_text",
		"content": "Okay Anna Careful Blake, I guess we can try it out."
	},
	{
		"type": "partner_text",
		"content": "Yayyy!"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "I'm like... really bored, I've been trapped inside for so long, can we do it soon?"
	},
	{
		"type": "player_text",
		"content": "Well they have classes every day, so we can go tomorrow."
	},
	{
		"type": "partner_text",
		"content": "Tomorrow? Omg I can't wait! I have to put a whole outfit together!"
	},
	{
		"type": "partner_text",
		"content": "What do people wear to class these days? I think I saw a movie where they all had uniforms before..."
	},
	{
		"type": "player_text",
		"content": "People don't really wear..."
	},
	{
		"type": "partner_text",
		"content": "Thanks so much, I have to go get ready! Let's meet at the campus tomorrow morning!"
	},
	{
		"type": "player_text",
		"content": "Umm, okay, do you know how to get there?"
	},
	{
		"type": "partner_text",
		"content": "Of course! Cummington State University! CSU! I have always dreamt of going there!"
	},
	{
		"type": "partner_text",
		"content": "I really have to go now, I have to go get a whole outfit!"
	},
	{
		"type": "partner_text",
		"content": "I'll see you there, bye!!!"
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
