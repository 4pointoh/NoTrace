extends PhoneScript

var actions = [
	{ "type": "partner_text", "content": "SNOW DAY!!" },
	{ "type": "partner_text", "content": "Can you believe it?? It actually snowed in Cummington!" },
	{ "type": "player_text", "content": "Doesn't it snow every year?" },
	{ "type": "partner_text", "content": "Yes! What are the odds of it snowing every single year and not missing a single one?? It's unbelievable!" },
	{ "type": "player_text", "content": "... Honestly, I can't really find a flaw in that logic." },
	{ "type": "player_text", "content": "You sure are awake early. It's 5:30am." },
	{ "type": "player_text", "content": "Getting ready for a day out in the snow?" },
	{ "type": "partner_text", "content": "I've already been out here for an hour! Look what I made!" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0001.webp" },
	{ "type": "partner_text", "content": "A cute little snowman!" },
	{ "type": "player_text", "content": "That's the smallest snowman I've ever seen, it certainly is cute." },
	{ "type": "partner_text", "content": "..." },
	{ "type": "partner_text", "content": "You're right. It's way too small." },
	{ "type": "player_text", "content": "No, that's not..." },
	{ "type": "countdown", "content": 20, "countdownLabel": "Lisa is building a snowman", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "partner_text", "content": "Back!" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0002.webp" },
	{ "type": "partner_text", "content": "Here you go!" },
	{ "type": "player_text", "content": "It's great, but I thought you were making a bigger one?" },
	{ "type": "partner_text", "content": "What?? It is bigger! It's like 20% bigger!" },
	{ "type": "player_text", "content": "Oh, I suppose it is." },
	{ "type": "player_text", "content": "It looks great. Nice job." },
	{ "type": "partner_text", "content": "No!" },
	{ "type": "player_text", "content": "No?" },
	{ "type": "countdown", "content": 20, "countdownLabel": "Where did she go now?", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0003.webp" },
	{ "type": "partner_text", "content": "Et voilà!" },
	{ "type": "partner_text", "content": "My best work!" },
	{ "type": "partner_text", "content": "I brought an extra hat and scarf for it!" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0004.webp" },
	{ "type": "player_text", "content": "It's perfect." },
	{ "type": "player_text", "content": "So now that you've made a snowman, what's next?" },
	{ "type": "player_text", "content": "Are you planning some skiing? Snowboarding?" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0005.webp" },
	{ "type": "partner_text", "content": "Somebody else's was bigger." },
	{ "type": "player_text", "content": "What?" },
	{ "type": "partner_text", "content": "Their snowman." },
	{ "type": "partner_text", "content": "Theirs had three balls. Mine only has two." },
	{ "type": "player_text", "content": "... Are you turning snowman construction into a competition?" },
	{ "type": "partner_text", "content": "No!" },
	{ "type": "partner_text", "content": "This is a relaxing holiday snow day activity!" },
	{ "type": "partner_text", "content": "Now brb while I figure out how to make a three-ball snowman." },
	{ "type": "countdown", "content": 30, "countdownLabel": "Lisa is experimenting", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0007.webp" },
	{ "type": "partner_text", "content": "Boom!" },
	{ "type": "partner_text", "content": "One, two, three, count 'em!" },
	{ "type": "player_text", "content": "Yep, definitely three." },
	{ "type": "partner_text", "content": "Just one final finishing touch..." },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0008.webp" },
	{ "type": "partner_text", "content": "Done!" },
	{ "type": "partner_text", "content": "I win!" },
	{ "type": "player_text", "content": "What exactly did you win?" },
	{ "type": "partner_text", "content": "I won the snow day!" },
	{ "type": "player_text", "content": "Well, congratulations on winning." },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0009.webp" },
	{ "type": "partner_text", "content": "He's perfect, I just had to hug him!" },
	{ "type": "countdown", "content": 60, "countdownLabel": "Where did she go?", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "partner_text", "content": "He wasn't perfect. I made a new one." },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0010.webp" },
	{ "type": "partner_text", "content": "Wider base." },
	{ "type": "partner_text", "content": "More structurally stable." },
	{ "type": "player_text", "content": "It's certainly wide." },
	{ "type": "partner_text", "content": "Look, I can even sit on it!" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0011.webp" },
	{ "type": "player_text", "content": "It's truly a remarkable, cutting-edge snowman." },
	{ "type": "player_text", "content": "The forefront of snowman technology." },
	{ "type": "partner_text", "content": "I can go wider" },
	{ "type": "player_text", "content": "What?" },
	{ "type": "partner_text", "content": "I can go wider." },
	{ "type": "partner_text", "content": "An even wider base. At least 2x as wide." },
	{ "type": "player_text", "content": "Lisa, I'm sorry, but there's no way you can go wider than that." },
	{ "type": "partner_text", "content": "I. Can. Go. Wider." },
	{ "type": "player_text", "content": "Lisa, this is getting out of hand!" },
	{ "type": "partner_text", "content": "No!" },
	{ "type": "countdown", "content": 60, "countdownLabel": "She's going wider!", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0012.webp" },
	{ "type": "partner_text", "content": "Just some finishing touches..." },
	{ "type": "countdown", "content": 20, "countdownLabel": "Finishing touches", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0013.webp" },
	{ "type": "partner_text", "content": "See it and weep." },
	{ "type": "player_text", "content": "Wow." },
	{ "type": "player_text", "content": "You did, in fact, go wider." },
	{ "type": "partner_text", "content": "Not only is it the most structurally secure snowman in all of Cummington..." },
	{ "type": "partner_text", "content": "My little chubby boy is so cute!!" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0014.webp" },
	{ "type": "player_text", "content": "You've really built something special here." },
	{ "type": "partner_text", "content": "Thank you ^^" },
	{ "type": "partner_text", "content": "And to think, I only have one left to build!" },
	{ "type": "player_text", "content": "Lisa... you can't" },
	{ "type": "player_text", "content": "There is no way you can possible go wider than that." },
	{ "type": "player_text", "content": "You're already pushing up against the bounds of physics." },
	{ "type": "partner_text", "content": "No no." },
	{ "type": "partner_text", "content": "Not wider." },
	{ "type": "partner_text", "content": "Taller." },
	{ "type": "player_text", "content": "You can't mean..." },
	{ "type": "partner_text", "content": "Yes." },
	{ "type": "partner_text", "content": "I will combine the three ball technique with chubby extra wide base." },
	{ "type": "partner_text", "content": "It will never be defeated." },
	{ "type": "player_text", "content": "Godspeed Lisa. I'm praying for you." },
	{ "type": "countdown", "content": 120, "countdownLabel": "Devising the perfect snowman", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 3 },
	{ "type": "player_text", "content": "So, how it's going?" },
	{ "type": "player_text", "content": "It's been 2 hours, just making sure you aren't trapped under the collapsed remnants of an extra wide snowman." },
	{ "type": "partner_text", "content": "The project has encountered a few delays." },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0019.webp" },
	{ "type": "partner_text", "content": "Taking a little break!" },
	{ "type": "partner_text", "content": "I've been running into issue with optimal 3rd to 2nd layer ratios." },
	{ "type": "partner_text", "content": "I've had to experiment... but I think I'm nearing a breakthrough." },
	{ "type": "partner_text", "content": "Anyway... breaks over! Gotta get back to it!" },
	{ "type": "countdown", "content": 180, "countdownLabel": "Break's over!", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 4 },
	{ "type": "partner_text", "content": "Almost done!" },
	{ "type": "countdown", "content": 240, "countdownLabel": "Almost done?", "countdownButtonLabel": "Wait for Lisa", "actualDelayInSeconds": 6 },
	{ "type": "partner_text", "content": "You there {player_name}?" },
	{ "type": "player_text", "content": "Yep." },
	{ "type": "partner_text", "content": "I've done it." },
	{ "type": "player_text", "content": "Wait... you were still working on it?" },
	{ "type": "player_text", "content": "Holy shit Lisa, it's been like 12 hours!" },
	{ "type": "player_text", "content": "It's starting to get dark out!" },
	{ "type": "player_text", "content": "I thought you quit hours ago." },
	{ "type": "partner_text", "content": "Absolutely not!" },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0015.webp" },
	{ "type": "partner_text", "content": "There it is." },
	{ "type": "player_text", "content": "Oh. My. God." },
	{ "type": "player_text", "content": "Lisa... how many of those snowmen did you build?" },
	{ "type": "partner_text", "content": "Huh?" },
	{ "type": "player_text", "content": "That army of snowmen in the back. It looks like we're being invaded by a sentient snowman army!" },
	{ "type": "partner_text", "content": "Oh those?" },
	{ "type": "partner_text", "content": "I built all of those. They were imperfect." },
	{ "type": "player_text", "content": "Holy shit." },
	{ "type": "player_text", "content": "How are you not dead from exhaustion?" },
	{ "type": "partner_text", "content": "Psh. Like I'd go inside early on the first snow day of the year!" },
	{ "type": "partner_text", "content": "But I did make one mistake, haha..." },
	{ "type": "image", "path": "res://data/background_lists/lisa_winter/lisa_winter_0016.webp" },
	{ "type": "partner_text", "content": "Note to self, leggings are not sufficient for extended snowman building sessions!" },
	{ "type": "partner_text", "content": "They're soaked through and FREEZING!" },
	{ "type": "partner_text", "content": "I'm gonna run inside and warm up!" },
	{ "type": "partner_text", "content": "Chat later!" },
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
