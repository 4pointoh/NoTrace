extends PhoneScript

func getNextAction():
	actionIndex = actionIndex + 1
	
	if actionGroup == 0:
		return actionGroupZero()
	elif actionGroup == 1:
		return actionGroupOne()
	elif actionGroup == 2:
		return actionGroupTwo()
	elif actionGroup == 3:
		return actionGroupThree()
		
func handleChoice(_choice):		
	# ["From the party?", "Uhh, nevermind."]
	if actionIndex == 2 && actionGroup == 0 && _choice == 0:
		advanceActionGroup(1)
	elif actionIndex == 2 && actionGroup == 0 && _choice == 1:
		advanceActionGroup(2)

func actionGroupZero():
	if actionIndex == 0:
		return getPlayerTextAction("Hi")
		
	if actionIndex == 1:
		return getPartnerTextAction("Uhh, sorry you aren't in my phone, who is this?")
		#return getVideoAction("res://data/game_stages/phone_message/chad_unblock_lisa/videos/pool.ogv")
		
	if actionIndex == 2:
		return getChoiceAction(["From the party?", "Uhh, nevermind."])

# "From the party?"
func actionGroupOne():
	if actionIndex == 0:
		return getPartnerTextAction("Ohhh! Duh!! Sorry!!")
		
	if actionIndex == 1:
		return getPartnerTextAction("Hi! I was waiting for your text!", PhoneAction.SOUND_TYPE.HAPPY)
		
	if actionIndex == 2:
		return getPartnerTextAction("I gave you my number but I never got yours 🤦🏻‍♀️")
		
	if actionIndex == 3:
		return getPlayerTextAction("For a minute I thought you gave me a fake number")
	
	if actionIndex == 4:
		return getPartnerTextAction("Nope, It's me! Wait, I'll send you a photo I have on my phone as proof...")
	
	if actionIndex == 5:
		var image = load("res://data/game_stages/phone_message/lisa_first_phone/text_images/phone_proof.png")
		GlobalGameStage.unlockWallpaperWithDelay("LISA_PROOF", 14)
		return getImageAction(image)
	
	if actionIndex == 6:
		return getPartnerTextAction("I took that photo after I finished the Numbani marathon!", PhoneAction.SOUND_TYPE.HAPPY)
		
	if actionIndex == 7:
		return getPartnerTextAction("I came in first place 😁 I can run really fast, it's kind of my thing", PhoneAction.SOUND_TYPE.HAPPY)
	
	if actionIndex == 8:
		advanceActionGroup(3)
		return getPlayerTextAction("Nice job! But being quick on your feet won't help much when playing poker.")

func actionGroupTwo():
	if actionIndex == 0:
		return getPartnerTextAction("Wait!! Let me guess... from the party??")
		
	if actionIndex == 1:
		return getPartnerTextAction("Chad??")
		
	if actionIndex == 2:
		return getPlayerTextAction("I'm gonna go...")
		
	if actionIndex == 3:
		return getPartnerTextAction("Is this Johnson Long?? The guy who wanted to get drinks after the party?")
	
	if actionIndex == 4:
		return getDialogueAction("START1")
		
	if actionIndex == 5:
		var txt = "No... it's " + GlobalGameStage.playerName + ". Poker guy, remember? It sounds like you don't even remember our plan"
		return getPlayerTextAction(txt)
	
	if actionIndex == 6:
		return getPartnerTextAction("Ohhh!! I'm sorry! I gave you my number but I forgot to get yours!")
	
	if actionIndex == 7:
		return getPlayerTextAction("You didn't even remember I would be texting you?")
	
	if actionIndex == 8:
		return getPartnerTextAction("Sorry 😭 I meet a lot of people at those parties.")
	
	if actionIndex == 9:
		return getPlayerTextAction("Well that kind of makes me feel like human garbage soo...")
	
	if actionIndex == 10:
		return getPartnerTextAction("Pleaseee give me one more chance!")
	
	if actionIndex == 11:
		return getPlayerTextAction("Fine, but I still feel like garbage.")
		
	if actionIndex == 12:
		return getPartnerTextAction("Wait!!")
	
	if actionIndex == 13:
		return getPartnerDelay("Partner is moving")
		
	if actionIndex == 14:
		return getPartnerTextAction("1 sec...")
	
	if actionIndex == 15:
		return getPartnerDelay("Partner is running frantically")
	
	if actionIndex == 16:
		var image = load("res://data/game_stages/phone_message/lisa_first_phone/text_images/lisa_garbage.png")
		GlobalGameStage.unlockWallpaperWithDelay("LISA_GARBAGE", 14)
		return getImageAction(image)
	if actionIndex == 17:
		return getPartnerTextAction("Look! I feel garbage too 😭")
	
	if actionIndex == 18:
		return getPlayerTextAction("Are you literally feeling the garbage??")
	
	if actionIndex == 19:
		return getPartnerTextAction("😭😭")
		
	if actionIndex == 20:
		advanceActionGroup(3)
		return getPlayerTextAction("Okay you're crazy... haha, but thank you.")
	
func actionGroupThree():
	if actionIndex == 0:
		return getPlayerTextAction("Ok do you want to meet up and talk about this training more?")
		
	if actionIndex == 1:
		return getPlayerTextAction("We didn't really go over any details yet")
		
	if actionIndex == 2:
		return getPartnerTextAction("Great idea! Coffee?? I don't really drink alcohol, so let's do like a coffee shop or something?")
	
	if actionIndex == 3:
		return getPlayerTextAction("Okay, coffee works. How about McCree's coffee down on 5th ave?")
		
	if actionIndex == 4:
		return getPartnerTextAction("Ohh haven't you heard? That place is cancelled. We can do Cassidy's though. It's in the same bulding.")
	
	if actionIndex == 5:
		return getPlayerTextAction("Cassidy's? That's a weird name for a coffee shop, but alright!")
		
	if actionIndex == 6:
		return getPartnerTextAction("🙂 see you!", PhoneAction.SOUND_TYPE.HAPPY)
	
	if actionIndex == 7:
		return getCompleteAction()
