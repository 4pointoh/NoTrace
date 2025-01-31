extends PhoneScript

var actions = [
	{
		"type": "player_text",
		"content": "Yooooo Chad what's up my dude"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "player_text",
		"content": "Yo it's {player_name}"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_text",
		"content": "who dis?"
	},
	{
		"type": "player_text",
		"content": "Loool bro it's {player_name}"
	},
	{
		"type": "partner_text",
		"content": "???"
	},
	{
		"type": "player_text",
		"content": "From uh... well I'm the guy who took your entire calculus class last semester"
	},
	{
		"type": "partner_text",
		"content": "Bruh"
	},
	{
		"type": "partner_text",
		"content": "There's like 3 people who did that"
	},
	{
		"type": "partner_text",
		"content": "Nvm it doesn't matter, what u want?"
	},
	{
		"type": "player_text",
		"content": "I was wondering if I could ask for a favor"
	},
	{
		"type": "partner_delay",
		"content": "Partner is browsing their photos app"
	},
	{
		"type": "partner_text",
		"content": "favor?"
	},
	{
		"type": "partner_delay",
		"content": "Partner is browsing their photos app"
	},
	{
		"type": "partner_text",
		"content": "Bro I got some crazy photos from that party last night"
	},
	{
		"type": "player_text",
		"content": "Chad that's really cool but I was wondering if you could do me a favor"
	},
	{
		"type": "partner_delay"
	},
	{
		"type": "partner_delay",
		"content": "Partner is browsing their photos app"
	},
	{
		"type": "partner_text",
		"content": "Yoo check this one out"
	},
	{
		"type": "image",
		"path": "res://data/game_stages/phone_message/chad_unblock_lisa/pool1.png"
	},
	{
		"type": "player_text",
		"content": "Chad I'm trying to get back in touch with a friend who accidentally blocked me"
	},
	{
		"type": "partner_delay",
		"content": "Partner is viewing photo in fullscreen"
	},
	{
		"type": "player_text",
		"content": "Chad..."
	},
	{
		"type": "partner_delay",
		"content": "Partner is viewing photo in fullscreen"
	},
	{
		"type": "partner_text",
		"content": "Bro do you know these chicks?"
	},
	{
		"type": "player_text",
		"content": "What? No, I don't know them"
	},
	{
		"type": "partner_text",
		"content": "They're both on the CSU swim team"
	},
	{
		"type": "partner_text",
		"content": "Bro I've been trying to get them together for so long"
	},
	{
		"type": "partner_text",
		"content": "I knew they would hit it off"
	},
	{
		"type": "partner_text",
		"content": "But they both have boyfriends, it was so complicated"
	},
	{
		"type": "player_text",
		"content": "Chad, I need"
	},
	{
		"type": "partner_text",
		"content": "But man I nailed the perfect mood at that party"
	},
	{
		"type": "partner_text",
		"content": "Convinced them to hang out in the pool..."
	},
	{
		"type": "partner_text",
		"content": "and check out what happened not even an hour later"
	},
	{
		"type": "image",
		"path": "res://data/game_stages/phone_message/chad_unblock_lisa/pool2.png"
	},
	{
		"type": "player_text",
		"content": "CHAD, I NEED YOUR HELP"
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Wait that's actually hot as fuck"
	},
	{
		"type": "player_text",
		"content": "They just... did this? On their own?"
	},
	{
		"type": "partner_text",
		"content": "I'm telling you, I know chemistry when I see it"
	},
	{
		"type": "partner_text",
		"content": "... well not real chemistry, I pay Greg to do my chemistry school work"
	},
	{
		"type": "partner_text",
		"content": "but you know what I mean"
	},
	{
		"type": "partner_text",
		"content": "yo I even got this too"
	},
	{
		"type": "video",
		"path": "res://data/game_stages/phone_message/chad_unblock_lisa/videos/pool.ogv"
	},
	{
		"type": "player_text",
		"content": "Holy shit"
	},
	{
		"type": "partner_text",
		"content": "Bro I'm like cupid but with better abs"
	},
	{
		"type": "player_text",
		"content": "Chad that stuff is really cool and all but I need a favor"
	},
	{
		"type": "player_text",
		"content": "You know that Lisa chick who goes to your parties?"
	},
	{
		"type": "player_text",
		"content": "Super energetic and way too optimistic and wears a lot of orange?"
	},
	{
		"type": "player_text",
		"content": "Do you have her number?"
	},
	{
		"type": "partner_text",
		"content": "Huh, Lisa?"
	},
	{
		"type": "partner_text",
		"content": "...wait Lisa? Orange Lisa? The one who's like basically a human traffic cone?"
	},
	{
		"type": "partner_text",
		"content": "uhhh yeah maybe I have her number don't know, why?"
	},
	{
		"type": "player_text",
		"content": "I think she accidentally blocked my number and I can't contact her"
	},
	{
		"type": "player_text",
		"content": "Can you just text her and tell her to unblock me?"
	},
	{
		"type": "partner_text",
		"content": "... ugh i don't know, whatever, who is this anyway?"
	},
	{
		"type": "player_text",
		"content": "Chad it's..."
	},
	{
		"type": "player_text",
		"content": "Y'know what just please tell her to 'unblock {player_name}'"
	},
	{
		"type": "player_text",
		"content": "That's all you gotta do alright?"
	},
	{
		"type": "partner_delay",
		"content": "Partner is watching a video"
	},
	{
		"type": "partner_text",
		"content": "uhh right sure, maybe, I gotta go, bye"
	},
	{
		"type": "dialogue",
		"content": "START1"
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
			return getPartnerTextAction(action["content"])
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