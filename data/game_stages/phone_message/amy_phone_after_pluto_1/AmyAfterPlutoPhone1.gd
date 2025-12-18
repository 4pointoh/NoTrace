extends PhoneScript

var actions = [
	{ "type": "partner_text", "content": "Hello there." },
	{ "type": "partner_text", "content": "Thought I forgot about the favor you owe me, hm?" },
	{ "type": "player_text", "content": "No Miss Amy. I am at your disposal." },

	{ "type": "partner_text", "content": "Good, I can see Pluto sent you the list of rules." },

	{ "type": "player_text", "content": "Yes Miss Amy, Pluto made me aware of all rules." },
	{ "type": "player_text", "content": "I am following them diligently, including no asking for money, no taking huge shits, and no asking if you have a boyfriend." },

	{ "type": "partner_text", "content": "That second one isn't usually part of the list." },
	{ "type": "player_text", "content": "Pluto was very clear on that one." },

	{ "type": "partner_text", "content": "Was he now?" },
	{ "type": "player_text", "content": "Now please your majesty, bestow your desired favor upon me, a humble poor peasant. I lay down my life for thee, ask and I shall perform thy bidding." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "We're ten texts into the conversation and you're already doing peasant roleplay?" },
	{ "type": "partner_text", "content": "Okay. Drop it. Rules abolished. We have important things to discuss and you're clearly already clowning around." },

	{ "type": "player_text", "content": "You abolish the rules?" },
	{ "type": "partner_text", "content": "Yes. Forget the rules." },

	{ "type": "player_text", "content": "Ok" },
	{ "type": "player_text", "content": "So you got a boyfriend or nah? And could you spot me like $5000? I'll pay it back, promise." },
	{ "type": "partner_text", "content": "Rules re-established." },

	{ "type": "player_text", "content": "Sorry, already forgot them. Poof. Gone from memory." },
	{ "type": "partner_text", "content": "Funny." },
	{ "type": "partner_text", "content": "You do remember who you're talking to, right?" },
	{ "type": "partner_text", "content": "Rich... Powerful... Could send a hitman to dispose of you and nobody would ever know..." },

	{ "type": "player_text", "content": "Who?" },
	{ "type": "partner_text", "content": "... And so you're going to continue being crude and wasting my time with your \"jokes\"?" },

	{ "type": "player_text", "content": "Yes ma'am" },

	{ "type": "partner_text", "content": "I have meetings with nine different individuals over the next two hours." },
	{ "type": "partner_text", "content": "Top ranking government officials, leaders of trillion dollar hedge funds, heads of secret societies that you don't even know exist." },
	{ "type": "partner_text", "content": "Men who accomplish more in five seconds than your entire family tree's combined legacy" },
	{ "type": "partner_text", "content": "And you're telling me..." },

	{ "type": "player_text", "content": "Miss Amy, I've got chicken nuggets in the microwave getting cold. Can we hurry this up?" },

	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "You..." },
	{ "type": "image", "path": "res://data/wallpapers/amy_txt_1.webp" },
	{ "type": "partner_text", "content": "You made me smile. Congratulations." },
	{ "type": "partner_text", "content": "And call me Amy. Just Amy." },

	{ "type": "player_text", "content": "Oh? No more \"Miss\"?" },

	{ "type": "partner_text", "content": "\"Miss\" is for all those boring old government dorks and hedge fund clowns." },
	{ "type": "partner_text", "content": "You... clearly aren't boring. That's refreshing." },
	{ "type": "partner_text", "content": "Now, we'd better speed this along, we wouldn't want your chicken nuggets to get too cold." },

	{ "type": "player_text", "content": "Okay, I'm not sure if you're being nice to me now, or if I should expect two large men to show up at my door with a pipe wrench in the next hour." },

	{ "type": "partner_text", "content": "Don't worry, Mikey and Sal are... \"solving\" other problems for me tonight." },
	{ "type": "player_text", "content": "\"Mikey and Sal\"?" },
	{ "type": "partner_text", "content": "My pipe wrench guys." },
	{ "type": "player_text", "content": "Ah. Well, that's good news." },

	{ "type": "partner_text", "content": "And to ensure they stay busy with OTHER problems let's go ahead and get back to the topic at hand, shall we?" },
	{ "type": "player_text", "content": "About the favor, right?" },
	{ "type": "partner_text", "content": "Mmhm." },
	{ "type": "player_text", "content": "Alright, hit me with it." },

	{ "type": "partner_text", "content": "This is going to take some explaining..." },
	{ "type": "partner_text", "content": "Save all your questions to the end." },

	{ "type": "player_text", "content": "You aren't going to ask me to commit any crimes, right?" },
	{ "type": "player_text", "content": "Get the poor peasant boy to be your fall guy?" },
	{ "type": "partner_text", "content": "I said questions at the end." },

	{ "type": "partner_text", "content": "So..." },
	{ "type": "partner_text", "content": "I'm going to start this off by answering one of your previous questions." },
	{ "type": "partner_text", "content": "Am I single? Well, publicly, yes." },
	{ "type": "partner_text", "content": "A woman in my position is expected to be single at my age. It gives me an \"advantage\" in business dealings." },
	{ "type": "partner_text", "content": "But... that only applies publicly." },
	{ "type": "partner_text", "content": "Privately, well..." },

	{ "type": "partner_text", "content": "And I should remind you... classified conversation... don't tell anybody... rich enough to send a hitman... etc..." },
	{ "type": "partner_text", "content": "If any of this leaks to the public, I'll know exactly who did it. And people who leak things..." },

	{ "type": "player_text", "content": "Meet Mikey and Sal?" },
	{ "type": "partner_text", "content": "They become very close acquaintances to Mikey and Sal." },
	{ "type": "player_text", "content": "Loud and clear." },

	{ "type": "partner_text", "content": "Good." },
	{ "type": "partner_text", "content": "So, as I was saying..." },
	{ "type": "partner_text", "content": "I am in a relationship. Privately." },
	{ "type": "partner_text", "content": "But the other day..." },

	{ "type": "player_text", "content": "Trouble in paradise?" },
	{ "type": "partner_text", "content": "Trouble in paradise." },

	{ "type": "partner_text", "content": "The last time I visited, there were... signs of... infidelity." },
	{ "type": "player_text", "content": "Oh that's rough, sorry to hear that." },
	{ "type": "player_text", "content": "What signs did you find?" },
	{ "type": "partner_text", "content": "I found... a sock." },
	{ "type": "player_text", "content": "A sock?" },
	{ "type": "partner_text", "content": "That's right. A sock that didn't belong. Somebody else's sock." },
	{ "type": "player_text", "content": "Ah" },
	{ "type": "partner_text", "content": "And so for the favor you owe me, your task is simple. I want you to figure out what's going on." },
	{ "type": "partner_text", "content": "Questions?" },

	{ "type": "player_text", "content": "Umm" },
	{ "type": "player_text", "content": "Yeah about a hundred of them!" },

	{ "type": "player_text", "content": "Amy Perrier is in some secret relationship?? Who is it??" },
	{ "type": "player_text", "content": "Let me guess, it's your personal trainer! Perfect body, chiseled jaw, six and a half foot Norwegian. A man you'd NEVER be permitted to date due to being poor and totally not in your wealth class?"},

	{ "type": "partner_text", "content": "No." },
	{ "type": "partner_text", "content": "And my personal trainer is french." },

	{ "type": "player_text", "content": "Is it a politician? Somebody who would cause a huge scandal if it was figured out?" },
	{ "type": "partner_text", "content": "No." },

	{ "type": "player_text", "content": "Is it someone famous?" },
	{ "type": "partner_text", "content": "No." },

	{ "type": "player_text", "content": "Is it someone dangerous?" },
	{ "type": "partner_text", "content": "No." },

	{ "type": "player_text", "content": "Is it someone way older than you?" },
	{ "type": "partner_text", "content": "No." },

	{ "type": "player_text", "content": "Is he younger than you?" },
	{ "type": "partner_text", "content": "This is not a game of twenty questions!" },

	{ "type": "player_text", "content": "Oh my god, he is! Amy Perrier is a sugar mama to a younger man!" },
	{ "type": "partner_text", "content": "You are completely wrong, on EVERY single detail, and this line of questioning ends now." },

	{ "type": "player_text", "content": "Oh my god I feel like a secret agent, I need to buy a pair of dark aviator sunglasses. And a suit." },

	{ "type": "partner_text", "content": "When you're quite finished..." },

	{ "type": "player_text", "content": "Are you going to tell me who he is?" },

	{ "type": "partner_text", "content": "You don't need to know who THEY are." },
	{ "type": "partner_text", "content": "I will provide you an address. This is their home address." },
	{ "type": "partner_text", "content": "And you will simply perform a few investigative actions." },
	{ "type": "partner_text", "content": "You will knock on their door and tell me who answers." },
	{ "type": "partner_text", "content": "You will tell me if there is anybody else visible in the room. They live alone, there should be nobody else inside." },
	{ "type": "partner_text", "content": "And after that, you will pull up your car outside, and sit there, watching the door for the next 48 hours and reporting anybody that enters throughout the weekend." },
	{ "type": "partner_text", "content": "Simple enough, right?" },

	{ "type": "player_text", "content": "48 HOURS??" },
	{ "type": "player_text", "content": "I'll fall asleep!" },

	{ "type": "partner_text", "content": "Need I remind you that you already agreed to this favor?" },

	{ "type": "player_text", "content": "My agreement is not the issue here! I won't be able to stay awake for that long!" },

	{ "type": "partner_text", "content": "You'll figure it out, I have absolute faith in you." },
	{ "type": "partner_text", "content": "And if you don't..." },

	{ "type": "player_text", "content": "Mikey and Sal?" },
	{ "type": "partner_text", "content": "Mikey and Sal." },

	{ "type": "player_text", "content": "Ugh." },
	{ "type": "player_text", "content": "I guess I'll stock up on energy drinks..." },
	{ "type": "player_text", "content": "But I have to ask..." },
	{ "type": "player_text", "content": "Why me? Why a random dude that you met outside of the casino for 5 minutes?" },

	{ "type": "partner_text", "content": "Simple. Because you aren't part of my circle." },
	{ "type": "partner_text", "content": "And you aren't intimidating." },
	{ "type": "partner_text", "content": "I can't send anybody I know and trust. I've been dating this person for far too long, they already know everybody in my circle." },
	{ "type": "partner_text", "content": "I could hire a full on investigative team, top notch secret agents, etc..." },
	{ "type": "partner_text", "content": "But, that would be a violation of privacy and trust." },
	{ "type": "partner_text", "content": "Those investigation teams always take it way too far. Tracking every movement, taking private photos that shouldn't be taken." },

	{ "type": "player_text", "content": "And sending me isn't a violation of trust?" },

	{ "type": "partner_text", "content": "It is. But at least I know you won't be spying through the window and taking shower photos like some of those agents do." },

	{ "type": "player_text", "content": "How can you be so sure?" },

	{ "type": "partner_text", "content": "Scroll up 14 messages" },

	{ "type": "player_text", "content": "Point taken." },

	{ "type": "partner_text", "content": "Now, are we clear here? You sure have a talent of drawing out conversations way longer than they need to be." },

	{ "type": "player_text", "content": "Go to address. Knock on door. Count people. Wait in car. Avoid shower photos. Report back. Simple." },

	{ "type": "partner_text", "content": "Good." },
	{ "type": "partner_text", "content": "Now... one more thing." },
	{ "type": "partner_text", "content": "This is important to me. So, just to ensure you do it correctly." },
	{ "type": "image", "path": "res://data/wallpapers/amy_txt_2.webp" },
	{ "type": "partner_text", "content": "See this?" },
	{ "type": "partner_text", "content": "This is the key to a Vorche 911 S" },

	{ "type": "player_text", "content": "YOU'RE GOING TO GIVE ME A VORSCHE??" },

	{ "type": "partner_text", "content": "Hell no." },
	{ "type": "partner_text", "content": "If you do this properly, without any incidents, and without me getting an angry text from my sweetheart asking why I'm sending spies..." },
	{ "type": "partner_text", "content": "I'll take you for a ride in my Vorsche." },

	{ "type": "player_text", "content": "Take me for a ride? You mean...?" },

	{ "type": "partner_text", "content": "I mean take you for a literal ride in the car." },
	{ "type": "partner_text", "content": "Not whatever else your crude man brain is thinking I could have meant." },

	{ "type": "player_text", "content": "So... you aren't buying me a car?" },
	{ "type": "partner_text", "content": "Absolutely not." },

	{ "type": "player_text", "content": "Can I... at least drive the Vorsche?" },

	{ "type": "partner_text", "content": "Maybe." },
	{ "type": "partner_text", "content": "Don't get your hopes up. It's a one-of-a-kind. My favorite color. None like it anywhere else in the world." },
	{ "type": "partner_text", "content": "She's known no other hands than the man who assembled her, and my own." },
	{ "type": "partner_text", "content": "But if this all goes smoothly..." },
	{ "type": "partner_text", "content": "Well then I'm sure we'll see each other again soon." },

	{ "type": "partner_text", "content": "Now, I've missed an appointment with the ambassador of a small nation due to your excessive drawing out of this conversation." },
	{ "type": "partner_text", "content": "I have to go. And I expect you'll text me with updates. Pluto will send you the address before the weekend." },
	{ "type": "partner_text", "content": "Have fun." },


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