extends PhoneScript

var actions = [
	{ "type": "player_text", "content": "Hey there" },
	{ "type": "player_text", "content": "Just checking in on my partner in crime." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "player_text", "content": "We got a hell of a snow storm this morning. That white hair must be quite a tactical advantage when hunting prey." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "player_text", "content": "Really? Nothing?" },
	{ "type": "player_text", "content": "Well I guess you don't want to talk right now." },
	{ "type": "player_text", "content": "So, I hope you have a merry christmas." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "What's so merry about it, sugar?" },
	{ "type": "player_text", "content": "Excuse me?" },
	{ "type": "partner_text", "content": "You heard me. What makes it so 'merry'?" },
	{ "type": "player_text", "content": "What makes Christmas merry?" },
	{ "type": "player_text", "content": "Well... there's food, decorations, snow, time off work, time with family and friends..." },
	{ "type": "partner_text", "content": "Wow sounds great." },
	{ "type": "partner_text", "content": "Sounds like you should go enjoy all of that." },
	{ "type": "player_text", "content": "Uh, you all good over there?" },
	{ "type": "image", "path": "res://data/wallpapers/ashely_kitchen_1.webp" },
	{ "type": "partner_text", "content": "The holidays aren't for me, sugar." },
	{ "type": "partner_text", "content": "Food? Don't care. Decorations? Whatever. Snow? Cold and makes it hard to get around." },
	{ "type": "partner_text", "content": "Time with friends and family?" },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "Enjoy your holiday sugar. Just don't try and drag me into it." },
	{ "type": "player_text", "content": "Woah, hold up." },
	{ "type": "player_text", "content": "Do we have a certified Mrs. Grinch over here?" },
	{ "type": "image", "path": "res://data/wallpapers/ashely_kitchen_2.webp" },
	{ "type": "partner_text", "content": "I'm busy sweetheart. It's about time for you to hit the saddle and leave me alone." },
	{ "type": "player_text", "content": "You don't look busy." },
	{ "type": "player_text", "content": "In fact you appear to just be sitting at your kitchen table, in the dark." },
	{ "type": "partner_text", "content": "Wow, so observant." },
	{ "type": "player_text", "content": "... Y'know I could come over there and we could both wallow alone in despair in the dark." },
	{ "type": "player_text", "content": "But, y'know, together." },
	{ "type": "partner_text", "content": "Stop trying to fix me, sweetheart." },
	{ "type": "partner_text", "content": "I'm going to bed now. And I'm turning my phone off. Talk to you again in January when Santa Clause is back at the north pole. Bye." },
	{ "type": "player_text", "content": "I don't believe you. I don't think you're going to bed." },
	{ "type": "player_text", "content": "I think you're still sitting in your kitchen being a Mrs. Grinch." },
	{ "type": "player_text", "content": "..." },
	{ "type": "player_text", "content": "Fine, if you really aren't still here reading this..." },
	{ "type": "player_text", "content": "I guess you won't mind if I write a little story for you." },
	{ "type": "player_text", "content": "For when your phone is back on, of course." },
	{ "type": "player_text", "content": "...Once upon a time" },
	{ "type": "player_text", "content": "there was a cute little winter rabbit" },
	{ "type": "player_text", "content": "she had a thick coat of white fur, perfectly suited for the cold" },
	{ "type": "player_text", "content": "and because she was so well equipped for the winter" },
	{ "type": "player_text", "content": "all of her winter friends came to her with holiday cheer" },
	{ "type": "player_text", "content": "everybody assumed it must be her favorite time of the year" },
	{ "type": "player_text", "content": "but the reality was different" },
	{ "type": "player_text", "content": "this white little winter rabbit, just wanted to stay home" },
	{ "type": "player_text", "content": "she wanted to crawl into her burrow, deep in the dark, and hibernate through the winter" },
	{ "type": "player_text", "content": "nobody knew why" },
	{ "type": "player_text", "content": "until one day, a very handsome male rabbit moved into town" },
	{ "type": "player_text", "content": "this male rabbit's name was {player_name}" },
	{ "type": "player_text", "content": "he was so strong, and so gorgeous, and all the lady rabbits loved him" },
	{ "type": "player_text", "content": "basically the Ryan Reynolds of the rabbit world, if you will" },
	{ "type": "player_text", "content": "one day this rabbit noticed the little white winter rabbit hiding in her dark burrow" },
	{ "type": "player_text", "content": "he asked her why she dislikes the winter so much" },
	{ "type": "player_text", "content": "to which the little white rabbit was so very offended" },
	{ "type": "player_text", "content": "the male rabbit didn't really know what to do at this point" },
	{ "type": "special", "content": "Ashely Kitchen Phone" },
	{ "type": "partner_text", "content": "WHAT THE FUCK" },
	{ "type": "player_text", "content": "I knew it! You were there the whole time!" },
	{ "type": "player_text", "content": "So what did you think of the story?" },
	{ "type": "partner_text", "content": "Honey, What do you want from me?" },
	{ "type": "partner_text", "content": "Do you want me to provide a deep, touching, recount of why sitting alone in the dark, is my preferred Christmas?" },
	{ "type": "partner_text", "content": "Maybe you think I just need to cry it out with you as my manly shoulder to lean on?" },
	{ "type": "partner_text", "content": "Well I'm sorry to tell you, that story doesn't exist." },
	{ "type": "partner_text", "content": "There's no holiday magic here." },
	{ "type": "partner_text", "content": "Understand?" },
	{ "type": "player_text", "content": "I understand." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "hold on, there's somebody at my door" },
	{ "type": "fade_music_out" },
	{ "type": "countdown", "content": 5, "countdownLabel": "Ashely is checking the door.", "countdownButtonLabel": "Wait for Ashely", "actualDelayInSeconds": 8 },
	{ "type": "partner_text", "content": "What the fuck did you do." },
	{ "type": "player_text", "content": "A little holiday magic." },
	{ "type": "partner_text", "content": "You..." },
	{ "type": "countdown", "content": 5, "countdownLabel": "Ashely is... doing something?", "countdownButtonLabel": "Wait for Ashely", "actualDelayInSeconds": 8 },
	{ "type": "player_text", "content": "And Ashely, I just wanted to say..." },
	{ "type": "player_text", "content": "I'm alone for the holidays too. I usually am." },
	{ "type": "player_text", "content": "I know how hard it can be. But, on the worst days, if I force myself to do the things I don't want to do..." },
	{ "type": "player_text", "content": "Put up decorations, bake some christmas cookies... wear a sweater." },
	{ "type": "player_text", "content": "Things don't feel so bad." },
	{ "type": "player_text", "content": "Just... something to think about." },
	{
		"type": "partner_delay",
		"content": "Partner is away"
	},
	{ "type": "partner_text", "content": "I can't believe..." },
	{ "type": "image", "path": "res://data/wallpapers/ashely_kitchen_3.webp" },
	{ "type": "next_message_instant" },
	{ "type": "partner_text", "content": "You fucking DoorDash'd a christmas sweater to my house." },
	{ "type": "play_music", "content": "res://data/assets/general/bespoke_scenes/christmas_fade_in.mp3" },
	{ "type": "player_text", "content": "Wow, goodbye Mrs. Grinch." },
	{ "type": "player_text", "content": "And hellllooo sexy Mrs. Clause!" },
	{ "type": "partner_text", "content": "Do not compare me to Mrs. Clause. She's probably like 4000 years old" },
	{ "type": "player_text", "content": "Well, you look great, and cozy as hell! " },
	{ "type": "player_text", "content": "But, I'll let you get back to your holiday solitude." },
	{ "type": "partner_text", "content": "... thanks." },
	{ "type": "partner_text", "content": "for the sweater, and for the mental check." },
	{ "type": "partner_text", "content": "maybe I'll bake a cookie or something..." },
	{ "type": "player_text", "content": "One cookie?" },
	{ "type": "partner_text", "content": "One." },
	{ "type": "partner_text", "content": "Now stop trying to fix me you dork." },
	{ "type": "partner_text", "content": "and... Merry Christmas {player_name}.", "wallpaperUnlock": ["ASHELY_HOLIDAY_1", "ASHELY_HOLIDAY_2", "ASHELY_HOLIDAY_3"] },
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

func getPreparedMessages():
	return [
		{ "type": "player_text", "content": "so he started talking to her" },
		{ "type": "player_text", "content": "and then she got annoyed and went deeper into her burrow" },
		{ "type": "player_text", "content": "and so the male rabbit had an idea" },
		{ "type": "player_text", "content": "he stood outside the white rabbit's burrow" },
		{ "type": "player_text", "content": "and began to tell her a story" },
		{ "type": "player_text", "content": "in this story, there was a white winter fox who hated winter" },
		{ "type": "player_text", "content": "'and because this fox was so well suited for winter, everybody assumed he loved winter' said the male rabbit" },
		{ "type": "player_text", "content": "'but the reality was different, this fox just wanted to stay home' the male rabbit continued" },
		{ "type": "player_text", "content": "and then uh..." },
		{ "type": "player_text", "content": "the rabbit soon realized..." },
		{ "type": "player_text", "content": "er, the fox, I mean" },
		{ "type": "player_text", "content": "wait, maybe it was the rabbit." },
		{ "type": "player_text", "content": "...anyway something something, now they love winter" },
		{ "type": "player_text", "content": "the white rabbit is you" },
		{ "type": "player_text", "content": "if that wasn't clear" },
		{ "type": "player_text", "content": "... wait, did you actually turn your phone off?" },
		{ "type": "player_text", "content": "I kind of expected you to respond by now." },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "asdf" },
		{ "type": "player_text", "content": "asdf" },
		{ "type": "player_text", "content": "asdf" },
		{ "type": "player_text", "content": "asdf" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "A" },
		{ "type": "player_text", "content": "AA" },
		{ "type": "player_text", "content": "AAA" },
		{ "type": "player_text", "content": "AAAA" },
		{ "type": "player_text", "content": "AAAAA" },
		{ "type": "player_text", "content": "AAAAAA" },
		{ "type": "player_text", "content": "AAAAAAA" },
		{ "type": "player_text", "content": "AAAAAAAA" },
	]

# IDEA - 2nd conversation happens afterwards. From doordash driver. He says he thinks you were cute (thinking you are ashely)
# IDEA - add 'new message from {name}' pop up to phone in ashely scene 