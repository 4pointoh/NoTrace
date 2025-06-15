extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "Hey!"
	},
	{
		"type": "partner_text",
		"content": "It's been a little bit since we last talked!"
	},
	{
		"type": "player_text",
		"content": "Hey there!"
	},
	{
		"type": "player_text",
		"content": "I started to think you gave up on the training!"
	},
	{
		"type": "partner_text",
		"content": "Are you KIDDING me right now?!"
	},
	{
		"type": "partner_text",
		"content": "I've been living and breathing poker! I see cards when I close my eyes!!"
	},
	{
		"type": "player_text",
		"content": "Oh is that so? And...? Good progress?"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "Well... no, not really."
	},
	{
		"type": "partner_text",
		"content": "But I'm still working hard for it!"
	},
	{
		"type": "player_text",
		"content": "You are a machine, I know you'll get it."
	},
	{
		"type": "partner_text",
		"content": "Hahaha I know I will too!"
	},
	{
		"type": "partner_text",
		"content": "No way I'm giving up on this!"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "... And about that other thing..."
	},
	{
		"type": "partner_text",
		"content": "I think we can try it..."
	},
	{
		"type": "player_text",
		"content": "you mean...?"
	},
	{
		"type": "partner_text",
		"content": "Yeah..."
	},
	{
		"type": "partner_text",
		"content": "I'm not used to learning this slowly."
	},
	{
		"type": "partner_text",
		"content": "Usually I practice and practice and practice until I win!!"
	},
	{
		"type": "partner_text",
		"content": "But sometimes I know practice isn't enough and you have to try new things. Listen to your coach."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "What do you think?"
	},
	{
		"type": "player_text",
		"content": "Of course I'm ready to help"
	},
	{
		"type": "player_text",
		"content": "I can have a whole plan ready for you, and we can take it as slow as you want."
	},
	{
		"type": "partner_text",
		"content": "Awwww thank you!!"
	},
	{
		"type": "partner_text",
		"content": "How did I get so lucky to meet you, hahaha"
	},
	{
		"type": "partner_text",
		"content": "Buttt, I'm not quite ready right this moment."
	},
	{
		"type": "partner_text",
		"content": "I've really been training hard lately."
	},
	{
		"type": "partner_text",
		"content": "And as a runner I know how important it is to have rest days!"
	},
	{
		"type": "partner_text",
		"content": "To let your muscles rebuild, and let all the hard work sink in!"
	},
	{
		"type": "player_text",
		"content": "Poker muscles sore from all the training?"
	},
	{
		"type": "partner_text",
		"content": "Hahaha yes! I think they are!"
	},
	{
		"type": "player_text",
		"content": "So do you just want to text me in a few days when you're ready?"
	},
	{
		"type": "partner_text",
		"content": "Well.... actually I had something else in mind!"
	},
	{
		"type": "player_text",
		"content": "Oh?"
	},
	{
		"type": "partner_text",
		"content": "Yeah I couuld spend the day kicking my feet up and relaxing in the park."
	},
	{
		"type": "partner_text",
		"content": "But I have a better idea..."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "image",
		"path": "res://data/wallpapers/beach1.png",
		"wallpaperUnlock": ["lisa_beach1"]
	},
	{
		"type": "partner_text",
		"content": "BEACH DAY!!!"
	},
	{
		"type": "partner_text",
		"content": "It will be like... advanced level relaxing!!"
	},
	{
		"type": "partner_text",
		"content": "I already have all the stuff laid out!"
	},
	{
		"type": "player_text",
		"content": "Oh, you're going to go to the beach to kick back for a bit? That's a great idea!"
	},
	{
		"type": "partner_text",
		"content": "No!!"
	},
	{
		"type": "partner_text",
		"content": "Not just me!! Both of us!!"
	},
	{
		"type": "partner_text",
		"content": "... if you want to?"
	},
	{
		"type": "player_text",
		"content": "Huh, a day at the beach?"
	},
	{
		"type": "player_text",
		"content": "Well I'd have to check my schedule but maybe I can pencil you... HELL YEAH LET'S GO!"
	},
	{
		"type": "partner_text",
		"content": "YESS!!!"
	},
	{
		"type": "partner_text",
		"content": "I have it all figured out already!! Cummington beach! This weekend! Weather is supposed to be perfect!"
	},
	{
		"type": "partner_text",
		"content": "Don't worry about transporation I'll borrow my gf's car!"
	},
	{
		"type": "player_text",
		"content": "Sounds awesome!!"
	},
	{
		"type": "player_text",
		"content": "But can I ask... why me? Why not go with your gf?"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Well... you've really been helping me out a lot, and I'm not even paying you or anything."
	},
	{
		"type": "partner_text",
		"content": "... and that whole training session at the park, you spent all day there with me."
	},
	{
		"type": "partner_text",
		"content": "So I kind of owe you a little bit... but also I just think you're really fun to hang out with."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "You think so too right?"
	},
	{
		"type": "partner_text",
		"content": "I know we joke about the 'coach' thing but really we're friends right?"
	},
	{
		"type": "player_text",
		"content": "Lisa..."
	},
	{
		"type": "player_text",
		"content": "A student should never see their coach as a friend. That is rule number 1."
	},
	{
		"type": "partner_text",
		"content": "what do you mean? we can't be friends?"
	},
	{
		"type": "player_text",
		"content": "As your coach it is my job to ..."
	},
	{
		"type": "player_text",
		"content": "omg I'm sorry I can't do this to you!"
	},
	{
		"type": "player_text",
		"content": "I'm kidding! I was trying to get payback for the 'blocking me' thing. Terrible joke, I know."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Oh you are SO lucky I didn't block you again for that one!! 😭😭"
	},
	{
		"type": "partner_text",
		"content": "I thought that was real 😭😭 Hahahaha!!"
	},
	{
		"type": "partner_text",
		"content": "I was gonna buy you an ice cream at the beach but now you definitely aren't getting one!!"
	},
	{
		"type": "player_text",
		"content": "What??? Why not??"
	},
	{
		"type": "partner_text",
		"content": "Hahaha okay maybe we will still get ice cream. If you're well behaved."
	},
	{
		"type": "partner_text",
		"content": "Also, you have to drive. That's your punishment."
	},
	{
		"type": "player_text",
		"content": "I promise no more deceiving you into heartbreak over thinking that our entire friendship is a lie."
	},
	{
		"type": "partner_text",
		"content": "Well, that's a start. Lol."
	},
	{
		"type": "player_text",
		"content": "And of course we're friends! We can drop this whole 'coach' thing whenever you want. I don't care."
	},
	{
		"type": "partner_text",
		"content": "Okay 'jokes' aside (😠) I have the whole trip set up for this weekend."
	},
	{
		"type": "partner_text",
		"content": "Can I meet you at your place? We have to leave EARLY. Like 'is it even tomorrow yet?' early."
	},
	{
		"type": "player_text",
		"content": "I'll pay for the coffee."
	},
	{
		"type": "partner_text",
		"content": "Good 😁"
	},
	{
		"type": "partner_text",
		"content": "If we leave super early, we can get there in time for a whole day at the beach! And still drive back at night!"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Oh my gf just got home. I have to ask her if I can borrow the car."
	},
	{
		"type": "partner_text",
		"content": "I need to convince her that borrowing her car for a beach day with my poker coach is totally normal and not at all suspicious 😅"
	},
	{
		"type": "partner_text",
		"content": "I'll text you the details soon! This is gonna be so fun!!"
	},
	{
		"type": "partner_text",
		"content": "Byee!!! Don't forget your swimsuit!"
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
