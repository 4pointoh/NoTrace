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
		
	if actionIndex == 2:
		return getChoiceAction(["From the party?", "Uhh, nevermind."])

# "From the party?"
func actionGroupOne():
	if actionIndex == 0:
		return getPartnerTextAction("Ohhh! Duh!! Sorry!!")
		
	if actionIndex == 1:
		return getPartnerTextAction("Hi! I was waiting for your text!")
		
	if actionIndex == 2:
		return getPartnerTextAction("I gave you my number but I never got yours {facepalm}")
		
	if actionIndex == 3:
		return getPlayerTextAction("For a minute I thought you gave me a fake number")
	
	if actionIndex == 4:
		return getPartnerTextAction("Nope, It's me! Here's proof!")
	
	if actionIndex == 5:
		var image = load("res://data/game_stages/phone_message/lisa_first_phone/text_images/phone_proof.png")
		advanceActionGroup(3)
		return getImageAction(image)

func actionGroupTwo():
	if actionIndex == 0:
		return getPartnerTextAction("Wait!! Let me guess... from the party??")
		
	if actionIndex == 1:
		return getPartnerTextAction("Chad??")
		
	if actionIndex == 2:
		return getPlayerTextAction("I'm gonna go...")
		
	if actionIndex == 3:
		return getPartnerTextAction("Is it Long D Johnson?")
	
	if actionIndex == 4:
		return getDialogueAction("START1")
		
	if actionIndex == 5:
		return getPlayerTextAction("No... Poker guy? Remember? It sounds like you don't even remember our plan")
	
	if actionIndex == 6:
		return getPartnerTextAction("Ohhh!! I'm sorry! I gave you my number but I forgot to get yours!")
	
	if actionIndex == 7:
		return getPlayerTextAction("You didn't even remember I would be texting you?")
	
	if actionIndex == 8:
		return getPartnerTextAction("Sorry {crying emoji} I meet a lot of people at those parties.")
	
	if actionIndex == 9:
		return getPlayerTextAction("Well that kind of makes me feel like human garbage soo...")
	
	if actionIndex == 10:
		return getPartnerTextAction("Pleaseee give me one more chance!")
	
	if actionIndex == 11:
		return getPlayerTextAction("Fine, but I still feel like garbage.")
		
	if actionIndex == 12:
		return getPartnerTextAction("Wait!!")
	
	if actionIndex == 13:
		var image = load("res://data/game_stages/phone_message/lisa_first_phone/text_images/phone_proof.png")
		print("THis is a placeholder image for lisa in a garbage can")
		return getImageAction(image)
	
	if actionIndex == 14:
		return getPartnerTextAction("Look! I put myself in a garbage can so now we both feel like garbeg {cry emoji}")
	
	if actionIndex == 15:
		advanceActionGroup(3)
		return getPlayerTextAction("Okay you're crazy... haha, but thank you.")
	
func actionGroupThree():
	if actionIndex == 0:
		return getPlayerTextAction("Alright so I think we should meet up and talk about this training more")
		
	if actionIndex == 1:
		return getPlayerTextAction("We didn't really go over any details yet")
		
	if actionIndex == 2:
		return getPartnerTextAction("Great idea! Coffee?? I don't really drink alcohol, so let's do like a coffee shop or something?")
	
	if actionIndex == 3:
		return getPlayerTextAction("Okay, coffee works. How about McCree's coffee down on 5th ave?")
		
	if actionIndex == 4:
		return getPartnerTextAction("Ohh haven't you heard? That place is cancelled. We can do Cassidy's though. It's in the same bulding.")
	
	if actionIndex == 5:
		return getPlayerTextAction("Cassidy's? That's a terrible name for a coffee shop, but sure let's go there!")
	
	if actionIndex == 6:
		return getPartnerTextAction("<some emojis>")
	
	if actionIndex == 7:
		return getCompleteAction()

# Ideas:
# this class will return 'actions' based on the current state
# getNextAction() will return the current action and advance to the next
# actions can be a new message (you or your contact), new image, present choices, start dialogue key, etc...
# will also control who you are talking to, potentially 
# it's possible that I can have separate game stages / scripts for different phone convos
# eg if you click contact 1, it does one script. If you click contact 2, it does 2 scripts
# ^ would require separation between "phone home screen" vs "in conversation" game stages
