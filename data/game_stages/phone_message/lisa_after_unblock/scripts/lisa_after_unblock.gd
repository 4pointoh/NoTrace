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
		"type": "player_text",
		"content": "Perfect, I'll see you there"
	},
	{
		"type": "partner_text",
		"content": "Thank you!! Sorry again :(( I can't wait!"
	},
	{
		"type": "partner_text",
		"content": "I'll be the one in orange 😉"
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
