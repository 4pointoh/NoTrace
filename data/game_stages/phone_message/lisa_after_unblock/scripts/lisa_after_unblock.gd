extends PhoneScript

var actions = [
	{
		"type": "dialogue",
		"content": "START1"
	},
	{
		"type": "player_text",
		"content": "Heyy ground control to Major Lisa, are you there? Over."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "player_text",
		"content": "Hello? Are we good?"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Umm sorry are you mad at me for something?"
	},
	{
		"type": "partner_text",
		"content": "Wait you thought I blocked you on accident?"
	},
	{
		"type": "player_text",
		"content": "Oh... uh oh did I do something wrong?"
	},
	{
		"type": "partner_text",
		"content": "What do you think!!?"
	},
	{
		"type": "partner_text",
		"content": "I told you several times I'm IN A RELATIONSHIP!! and you send me to learn a game where I take my clothes off for you???"
	},
	{
		"type": "partner_text",
		"content": "Golly I wonder why you got blocked!!?"
	},
	{
		"type": "player_text",
		"content": "Ohh"
	},
	{
		"type": "player_text",
		"content": "Wait wait there was a big misunderstanding here"
	},
	{
		"type": "partner_text",
		"content": "Misunderstanding?? So strip poker isn't a game where I'll strip naked in front of you??? It sure seemed like it!"
	},
	{
		"type": "player_text",
		"content": "Wait wait sorry it's totally my fault I explained everything wrong."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "... I'm listening"
	},
	{
		"type": "player_text",
		"content": "Ok so you wanted to learn poker, right? And fast?"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "I can teach poker in other ways. We can totally do it with just some hard work and long hours."
	},
	{
		"type": "player_text",
		"content": "But having something to lose, like in strip poker, it super-charges the training."
	},
	{
		"type": "player_text",
		"content": "It's like a shortcut to learning. But you don't NEED to do it."
	},
	{
		"type": "player_text",
		"content": "I was just trying to say it's one option available to you, among other options."
	},
	{
		"type": "player_text",
		"content": "I definitely didn't make that clear at the coffee shop, that's my bad."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "So you mean we don't need to do strip poker? You have other ways to teach me?"
	},
	{
		"type": "player_text",
		"content": "Absolutely! I mean we can literally just sit down and play the old-fashioned way."
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "Really?"
	},
	{
		"type": "player_text",
		"content": "Of course."
	},
	{
		"type": "player_text",
		"content": "And here's the other thing"
	},
	{
		"type": "player_text",
		"content": "Even if we did play strip poker, you're not forced to get naked."
	},
	{
		"type": "player_text",
		"content": "It's totally normal to just play for one or two pieces of clothing."
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "Well let's stick to the normal training. Old-fashioned"
	},
	{
		"type": "partner_text",
		"content": "..."
	},
	{
		"type": "partner_text",
		"content": "And {player_name} ..."
	},
	{
		"type": "partner_text",
		"content": "I'M REALLY SORRY!! I kind of totally freaked out on you haha!"
	},
	{
		"type": "partner_text",
		"content": "I was like... WTF!! Sorry sometimes I act without thinking!! I go too fast!"
	},
	{
		"type": "partner_text",
		"content": "I should have texted you first!"
	},
	{
		"type": "partner_text",
		"content": "And you're still offering to train me after that, I got really lucky to meet you at that party! Ha!"
	},
	{
		"type": "player_text",
		"content": "Ha, no problem... Y'know, I've never failed an apprentice before"
	},
	{
		"type": "player_text",
		"content": "I told you I'll train you, we're not stopping until you're the new poker queen of Chad's parties."
	},
	{
		"type": "partner_text",
		"content": "Aww haha!"
	},
	{
		"type": "partner_text",
		"content": "So... when can we start? I'm ready to learn!"
	},
	{
		"type": "player_text",
		"content": "How about tomorrow? Meet at the park?"
	},
	{
		"type": "partner_text",
		"content": "Yess! Perfect! How about right after my morning run? I can run at the park! And then we can play poker!"
	},
	{
		"type": "partner_text",
		"content": "A run then poker - double endorphins! Nothing better!"
	},
	{
		"type": "player_text",
		"content": "Perfect, I'll see you there"
	},
	{
		"type": "partner_text",
		"content": "Ooh wait one more thing!"
	},
	{
		"type": "partner_text",
		"content": "I kind of um... threw out all my poker cards when I was angry 😅"
	},
	{
		"type": "partner_text",
		"content": "Can you bring some with you? I'll pay you back!"
	},
	{
		"type": "player_text",
		"content": "Sure, I'll pick some up at the shop before I come"
	},
	{
		"type": "player_text",
		"content": "Free of charge, as an apology for the misunderstanding"
	},
	{
		"type": "partner_text",
		"content": "Ok!! See you there!"
	},
	{
		"type": "partner_text",
		"content": "I'll be the one in orange, can't miss me! 😉"
	},
	{
		"type": "partner_text",
		"content": "Firstly sir, when Miss Amy initiates contact you will address her as “Miss Amy” or “Miss Perrier” unless and until she explicitly grants you permission to do otherwise; you will not, under any circumstances, shorten her name to “Ames,” “Mimi,” “AP,” or any other vulgar diminutive. Secondly, please refrain from the use of emojis, emoticons, stickers, GIFs, memes, or what you may refer to as “reaction images”; Miss Amy prefers the written word and complete sentences, with capital letters in their proper places and punctuation that does not resemble a battlefield of exclamation marks. Thirdly, you will endeavor to respond within a timely manner: ideally within thirty seconds of receiving her message and no later than two minutes, barring emergencies of a genuinely life-threatening nature; should you once again feel compelled to “take a huge shit,” I must insist you either complete your business in advance or keep your phone within arm’s reach and your hands sufficiently sanitary to type a coherent reply. Fourth, you will not initiate topics pertaining to her net worth, family holdings, brand endorsements, or any gossip you may have absorbed from the internet or the casino floor; Miss Amy is aware that she is wealthy and does not require narration. Fifth, you will not boast of your own poverty, lack of status, or perceived unworthiness as a form of humor, self-deprecation, or court jester routine, as it is unbecoming and, quite frankly, tedious; you may assume Miss Amy has already noticed that you are “not rich,” as you put it. Sixth, you will refrain from unsolicited flirtation, romantic declarations, or offers to “shoot your shot,” unless Miss Amy herself opens the door to such topics in clear and unmistakable terms; failed attempts at charm will be silently observed and later recounted to me for filing. Seventh, you will not inquire about her love life, romantic history, or current relationship status; you will allow Miss Amy to volunteer information in her own time and on her own terms, and you will not say things such as “So, you seeing anyone?” or “A girl like you must have a boyfriend,” or indeed any variant thereof. Eighth, you will not send photographs of yourself, your food, your bedroom, your “gains,” your pets, or any other subject unless expressly requested; if Miss Amy wishes to see your face she will arrange an in-person meeting or summon you to a location of her choosing. Ninth, if Miss Amy extends such an invitation, you will arrive punctually, freshly bathed, clothed in garments that have at minimum been introduced to an iron or a hanger within the last decade, and you will avoid strong colognes, loud patterns, novelty T-shirts, and any footwear that squeaks audibly on tile. Tenth, you will not speak ill of Miss Amy’s acquaintances, staff, family, or associates (myself included), even in jest; we are all, regrettably, within earshot. Eleventh, you will not attempt to negotiate, haggle, or “banter” over the favor she may request of you; the matter of your debt to her has already been settled in principle and will not be reopened for discussion. Twelfth, during the course of your conversation you will not, without due cause, deploy phrases such as “based,” “no cap,” “low-key,” “rizz,” or any other linguistic contraband of the moment, and you will especially not attempt to explain them to her as if delivering a TED Talk. Finally, should at any point you feel overwhelmed, flustered, or inclined to say something catastrophically foolish, I advise the simple tactic of pausing for three seconds, re-reading her last message, and then choosing the least suicidal of the replies that come to mind. If you understand and accept these conditions, please respond to Miss Amy with your full and undivided attention when she reaches out, and do your utmost not to embarrass yourself, myself, or the concept of written language in the process."
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
