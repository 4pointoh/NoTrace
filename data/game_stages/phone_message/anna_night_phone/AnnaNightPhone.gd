extends PhoneScript

var actions = [
	{ "type": "partner_text", "content": "Hello" },
	{ "type": "partner_text", "content": "Hellooo" },
	{ "type": "partner_text", "content": "Hellooooooo" },
	{ "type": "partner_text", "content": "I have URGENT things to discuss!" },
	{ "type": "partner_text", "content": "Pick up or I'm going to add even more o's" },
	{ "type": "player_text", "content": "Impatient much. I was getting the mail" },
	{ "type": "partner_text", "content": "Oh, you get mail too??" },
	{ "type": "player_text", "content": "... is this some kind of trick question?" },
	{ "type": "player_text", "content": "Of course I get mail" },
	{ "type": "partner_text", "content": "Really?? How do you like... deal with it all?" },
	{ "type": "player_text", "content": "Well I usually just throw it in the trash, isn't that what most people do?" },
	{ "type": "partner_text", "content": "What?? That seems so rude!" },
	{ "type": "partner_text", "content": "I try to respond to as much as I can, but I still only get around to like 1% of it all!" },
	{ "type": "partner_text", "content": "Your fans take their time to write you letters of appreciation and you just throw it all out in the trash??" },
	{ "type": "player_text", "content": "I..." },
	{ "type": "player_text", "content": "think we might be talking about different types of mail." },
	{ "type": "partner_text", "content": "Oh, what kind of mail do you get?" },
	{ "type": "player_text", "content": "Hmm... well today I got ads, spam, a magazine about hip implants addressed to the old Italian grandmother who lived in this house 10 years ago" },
	{ "type": "player_text", "content": "Oh and somebody left a crumpled up candy bar wrapper in there too, so that was pretty cool" },
	{ "type": "partner_text", "content": "Oooh! You'll have to show me some time!" },
	{ "type": "player_text", "content": "Well it was a pretty interesting wrapper..." },
	{ "type": "partner_text", "content": "Noo! I mean, like... show me your mail" },
	{ "type": "partner_text", "content": "Like how you get it, and how you open it" },
	{ "type": "player_text", "content": "..." },
	{ "type": "player_text", "content": "Didn't you say you had something urgent to discuss?" },
	{ "type": "partner_text", "content": "Oh! Ummm... yes." },
	{ "type": "player_text", "content": "So... what is it?" },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "I'm bored!" },
	{ "type": "player_text", "content": "Oh, that does sound like a highly urgent problem." },
	{ "type": "player_text", "content": "Lucky for you, I'm a licensed boredom relief doctor." },
	{ "type": "player_text", "content": "I prescribe milkshakes, stat! And a movie afterwards. How does that sound?" },
	{ "type": "partner_text", "content": "Sounds AMAZING!!" },
	{ "type": "player_text", "content": "Great, pick you up in 10?" },
	{ "type": "partner_text", "content": "...No" },
	{ "type": "player_text", "content": "No?" },
	{ "type": "partner_text", "content": "It does sound amazing, but..." },
	{ "type": "partner_text", "content": "I'm kind of..." },
	{ "type": "partner_text", "content": "... at work... right now." },
	{ "type": "player_text", "content": "Wait..." },
	{ "type": "player_text", "content": "You have a job?" },
	{ "type": "player_text", "content": "I always thought you were a jobless bum" },
	{ "type": "partner_text", "content": "I'm not a bum!" },
	{ "type": "partner_text", "content": "I have a job!" },
	{ "type": "partner_text", "content": "...kind of" },
	{ "type": "player_text", "content": "Can I know what it is? Or is that off limits?" },
	{ "type": "partner_text", "content": "It's..." },
	{ "type": "partner_text", "content": "Okay I'm trying to be more open to telling you things about myself..." },
	{ "type": "partner_text", "content": "So... here..." },
	{ "type": "image", "path": "res://data/background_lists/anna_night/home/night_1.webp" },
	{ "type": "partner_text", "content": "This is me, right now, at work" },
	{ "type": "player_text", "content": "..." },
	{ "type": "player_text", "content": "Okay, I'm sorry, but" },
	{ "type": "player_text", "content": "What the FUCK??" },
	{ "type": "player_text", "content": "You're a nurse??" },
	{ "type": "partner_text", "content": "Huh?" },
	{ "type": "partner_text", "content": "A nurse?" },
	{ "type": "partner_text", "content": "Oh wait... ohhh I see why you're confused." },
	{ "type": "partner_text", "content": "Yeah I guess that photo is a little bit misleading." },
	{ "type": "partner_text", "content": "One sec..." },
	{ "type": "image", "path": "res://data/background_lists/anna_night/home/night_1_2.png" },
	{ "type": "partner_text", "content": "Does that clear it up?" },
	{ "type": "player_text", "content": "No I can't really say it did" },
	{ "type": "player_text", "content": "What am I seeing here??" },
	{ "type": "partner_text", "content": "Okay, let me explain..." },
	{ "type": "partner_text", "content": "So this isn't my main... \"thing\"" },
	{ "type": "partner_text", "content": "I sometimes have to do... sponsorships." },
	{ "type": "player_text", "content": "Sponsorships?" },
	{ "type": "partner_text", "content": "Like \"I'm Anna Blake and I love this facial cream!\" type of things" },
	{ "type": "player_text", "content": "Okay... it's becoming more clear. And you're doing one of these right now?" },
	{ "type": "partner_text", "content": "Umm, yes. Kind of." },
	{ "type": "partner_text", "content": "Actually I am doing a bunch of them today. I try to schedule them all on the same day." },
	{ "type": "partner_text", "content": "Because they're realllly boring. I can't stand doing them more than once every few months." },
	{ "type": "player_text", "content": "Alright, I think I'm getting it." },
	{ "type": "player_text", "content": "But it looks like you're in some sort of studio surrounded by lights and cool sets, is it really that boring?" },
	{ "type": "partner_text", "content": "Yes. For every shoot I have to sit here for hours and repeat the same line over and over again until they think it's 'perfect'" },
	{ "type": "partner_text", "content": "I'm Anna Blake and I LOVE this facial cream!" },
	{ "type": "partner_text", "content": "I'm Anna Blake and I love THIS facial cream!" },
	{ "type": "partner_text", "content": "I'm Anna Blake and I love this FACIAL cream!" },
	{ "type": "partner_text", "content": "And I can't move either or it messes up the lighting" },
	{ "type": "partner_text", "content": "I have to sit here for hours!! It's so boorrrrrinnnnggg!!!" },
	{ "type": "player_text", "content": "Okay I can see where you're coming from" },
	{ "type": "partner_text", "content": "So that's where you come in." },
	{ "type": "partner_text", "content": "Save me from the boredom!!" },
	{ "type": "partner_text", "content": "The studio crew is at lunch for another hour. Entertain me!" },
	{ "type": "player_text", "content": "Hmm alright..." },
	{ "type": "player_text", "content": "The boredom doctor is trained for this." },
	{ "type": "player_text", "content": "Now let me think..." },
	{ "type": "player_text", "content": "Big studio... lights..." },
	{ "type": "player_text", "content": "Oh... idea!" },
	{ "type": "player_text", "content": "Do you have like a makeup station in the studio with you?" },
	{ "type": "partner_text", "content": "Let me check if it's unoccupied" },
	{ "type": "image", "path": "res://data/background_lists/anna_night/home/night_1_3.png" },
	{ "type": "partner_text", "content": "Yep! There's one!" },
	{ "type": "partner_text", "content": "What do you have in mind?" },
	{ "type": "player_text", "content": "Ok, get this..." },
	{ "type": "player_text", "content": "Head over there to the makeup station" },
	{ "type": "player_text", "content": "And then..." },
	{ "type": "player_text", "content": "You can draw fun makeup on your face! Like clown makeup! And a big red nose!" },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "What kind of idea is that?? I thought you were a PhD in boredom relief??" },
	{ "type": "player_text", "content": "Hey I NEVER said PhD!" },
	{ "type": "player_text", "content": "Okay okay, fine... no clown cosplays." },
	{ "type": "player_text", "content": "So what else do you have in there with you?" },
	{ "type": "partner_text", "content": "Well there's a few sets. Like, one for a school. One for a bedroom. One for a home, maybe a few others." },
	{ "type": "partner_text", "content": "And then there's a big booth with a lot of expensive looking computers" },
	{ "type": "partner_text", "content": "There's the costume department, a table with an assortment of deli meats and cheeses, and a bathroom" },
	{ "type": "partner_text", "content": "And that's really about it." },
	{ "type": "player_text", "content": "Okay okay... there's a lot to work with here." },
	{ "type": "player_text", "content": "We've had enough shared bathroom time, so let's go ahead and strike that option off the list" },
	{ "type": "partner_text", "content": "{player_name}!! Stop bringing that up!" },
	{ "type": "player_text", "content": "Deli meats and cheese, delicious, but not really entertaining..." },
	{ "type": "player_text", "content": "Tell me about this costume department, what's that about?" },
	{ "type": "partner_text", "content": "It's just the room with all the outfits I have to wear for the shoots today" },
	{ "type": "partner_text", "content": "Hold on... let me send you a photo." },
	{ "type": "image", "path": "res://data/background_lists/anna_night/changing_room/studio_4.webp" },
	{ "type": "partner_text", "content": "See? Not much in here..." },
	{ "type": "player_text", "content": "Anna, I know exactly what we're doing today." },
	{ "type": "player_text", "content": "Fashion show!" },
	{ "type": "partner_text", "content": "... fashion show?" },
	{ "type": "partner_text", "content": "You mean like putting on these outfits?" },
	{ "type": "player_text", "content": "Exactly!" },
	{ "type": "partner_text", "content": "Hmm..." },
	{ "type": "partner_text", "content": "Alright! Let's try it!" },
	{ "type": "partner_text", "content": "We definitely won't have time to try all of them. Some of them take a long time to put on..." },
	{ "type": "partner_text", "content": "Let me send you a clearer photo of all the options." },
	{ "type": "player_text", "content": "Perfect!" },
	{ "type": "special", "content": "Anna Dressing Room" },
	{ "type": "partner_text", "content": "Okay I'm back!" },
	{ "type": "partner_text", "content": "That was fun!" },
	{ "type": "partner_text", "content": "Hope you... enjoyed it too 😅" },
	{ "type": "partner_text", "content": "I'm going to have to go... I have so much to do today..." },
	{ "type": "player_text", "content": "Lots of sponsorships on the schedule?" },
	{ "type": "partner_text", "content": "I have a few more hours of these." },
	{ "type": "partner_text", "content": "Then I have like... a whole other thing after it." },
	{ "type": "partner_text", "content": "Sometimes I just want to sneak out the back door, and not tell anybody where I'm going." },
	{ "type": "partner_text", "content": "... and just hang out with you for a while." },
	{ "type": "player_text", "content": "Well, if you ever do, I have plenty of mail to show you." },
	{ "type": "partner_text", "content": "Hehe" },
	{ "type": "partner_text", "content": "When can we meet again?" },
	{ "type": "partner_text", "content": "Actually I'm busy like this whole week... ugh..." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "Next week?" },
	{ "type": "player_text", "content": "I think I can pencil you in Miss Blake." },
	{ "type": "partner_text", "content": "I will pick you up. Send me your address later." },
	{ "type": "partner_text", "content": "UGH!! I have to go, they're calling me over." },
	{ "type": "player_text", "content": "Going to proudly proclaim your love for the facial cream?" },
	{ "type": "partner_text", "content": "Hey, I'm Anna Blake and I LOVVEEE this facial cream!" },
	{ "type": "partner_text", "content": "😅" },
	{ "type": "partner_text", "content": "Ok I really gotta go. I'll see you next week..." },
	{ "type": "partner_text", "content": "If I can make it that long..." },
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
	# Populated live during the Anna Dressing Room minigame so the whole
	# conversation (text + images) appears on the phone once it ends.
	return GlobalGameStage.annaDressingRoomTranscript
