extends PhoneScript

func getNextAction():
	actionIndex = actionIndex + 1
	
	if actionGroup == 0:
		return actionGroupZero()
		
func handleChoice(_choice):		
	# ["From the party?", "Uhh, nevermind."]
	if actionIndex == 2 && actionGroup == 0 && _choice == 0:
		advanceActionGroup(1)
	elif actionIndex == 2 && actionGroup == 0 && _choice == 1:
		advanceActionGroup(2)

func actionGroupZero():
	if actionIndex == 0:
		return getPartnerTextAction("...")
		
	if actionIndex == 1:
		return getPartnerDelay("She\'s waiting...")
		
	if actionIndex == 2:
		return getPartnerTextAction("??")
		
	if actionIndex == 3:
		return getDialogueAction("START1")
		
	if actionIndex == 4:
		return getPartnerTextAction("I know you can see my texts. You have read receipts turned on 🙄")
		
	if actionIndex == 5:
		return getPlayerTextAction("Ummm... hello? Who is this?")
	
	if actionIndex == 6:
		return getPartnerTextAction("From the party.")
		
	if actionIndex == 7:
		return getDialogueAction("START2")
	
	if actionIndex == 8:
		return getPlayerTextAction("Uhh...")
		
	if actionIndex == 9:
		return getPartnerTextAction("Are you really that dense?")
		
	if actionIndex == 10:
		return getPartnerTextAction("sigh")
		
	if actionIndex == 11:
		return getPartnerTextAction("Hold on.")
	
	if actionIndex == 12:
		return getPartnerDelay()
	
	if actionIndex == 13:
		var image = load("res://data/game_stages/phone_message/poker_girls_first_phone/text_images/ashe_selfie.png")
		return getImageAction(image)
	
	if actionIndex == 14:
		return getPartnerTextAction("If this doesn't remind you, then fuck off.")
	
	if actionIndex == 15:
		return getPlayerTextAction("Ohh. Sheesh you could have just told me that we played poker or something.")
	
	if actionIndex == 16:
		return getPartnerTextAction("Oh please. Don't pretend like you met sooo many people last night that you can't remember.")
	
	if actionIndex == 17:
		return getPartnerTextAction("I was there too, sweetheart. I saw you spend half the night awkwardly staring at Chad trying to get him to notice you.")
	
	if actionIndex == 18:
		return getPlayerTextAction("No I didn't!")
	
	if actionIndex == 19:
		return getDialogueAction("START3")
	
	if actionIndex == 20:
		return getPlayerTextAction("So I assume you aren't just texting me to be a bitch right?")
	
	if actionIndex == 21:
		return getPlayerTextAction("Also how the hell did you even get my number?")
		
	if actionIndex == 22:
		return getPartnerTextAction("Douse your fuse honey, I got your number from Chad. And I have something to talk about that benefits both of us.")
	
	if actionIndex == 23:
		return getPlayerTextAction("You have not made a good first impression, but I suppose I'll listen...")
	
	if actionIndex == 24:
		return getPartnerTextAction("Not now. I'm enjoying my walk in the park and you're fucking it up. We need to meet up later.")
	
	if actionIndex == 25:
		return getPlayerTextAction("You're the one who texted me first!")
	
	if actionIndex == 26:
		return getPartnerTextAction("What did I say about that fuse and giving it a douse?")
		
	if actionIndex == 27:
		return getPartnerTextAction("We'll meet at the park downtown, tomorrow at noon.")
	
	if actionIndex == 28:
		return getPlayerTextAction("I don't even know your name, can I at least get that?")
		
	if actionIndex == 29:
		return getPartnerTextAction("Damn you're needy. Fine.")
	
	if actionIndex == 30:
		return getPartnerTextAction("It's Ashely.")
		
	if actionIndex == 31:
		return getPlayerTextAction("Alright, Ashely. I know I'm going to regret this but I'll be there to chat.")
		
	if actionIndex == 32:
		return getPartnerTextAction("One more thing.")
		
	if actionIndex == 33:
		return getPartnerTextAction("Delete that photo I sent you. I don't need you having photos of me saved on your phone.")
	
	if actionIndex == 34:
		return getPlayerTextAction("Of course.")
	
	if actionIndex == 35:
		GlobalGameStage.unlockWallpaperWithDelay("ASHE_SELFIE", 2, 'Photo Downloaded!')
		return getCompleteAction()
