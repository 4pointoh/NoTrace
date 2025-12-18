extends PhoneScript

var actions = [
	{
		"type": "partner_text",
		"content": "Hello sir, please respond to this message at your convenience."
	},
	{
		"type": "player_text",
		"content": "...Hello?"
	},
	{
		"type": "partner_text",
		"content": "Hello, thank you for your time sir."
	},
	{
		"type": "partner_text",
		"content": "I apologize for the unsolicited messaage. My name is Pluto, you may remember me from the casino."
	},
	{
		"type": "player_text",
		"content": "Pluto..."
	},
	{
		"type": "player_text",
		"content": "Oh, you're the bouncer who stopped me from talking to Amy Perrier back at the casino."
	},
	{
		"type": "partner_text",
		"content": "Correct sir. And allow me to apologize again for that inconvenience."
	},
	{
		"type": "partner_text",
		"content": "But you must understand that Miss Amy is a wealthy and powerful woman. "
	},
	{
		"type": "partner_text",
		"content": "She employs me both for her own security and to ensure she does not experience any unwanted interactions. "
	},
	{
		"type": "player_text",
		"content": "So I was an 'unwanted interaction'?"
	},
	{
		"type": "partner_text",
		"content": "Correct sir."
	},
	{
		"type": "player_text",
		"content": "Okay... rude."
	},
	{
		"type": "partner_text",
		"content": "But, as you may remember, I was able to arrange a meeting between you two outside of the casino afterwards."
	},
	{
		"type": "partner_text",
		"content": "At her request, of course."
	},
	{
		"type": "player_text",
		"content": "Oh, you did that?"
	},
	{
		"type": "partner_text",
		"content": "Of course sir. You would not have been able to chat with her, if I had not allowed it."
	},
	{
		"type": "player_text",
		"content": "Oh really? You would have stopped me?"
	},
	{
		"type": "partner_text",
		"content": "Respectfully, sir."
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Y'know what, fair enough."
	},
	{
		"type": "player_text",
		"content": "So... As much as I'm enjoying this conversation..."
	},
	{
		"type": "partner_text",
		"content": "Yes I too am enjoying this conversation, sir. But I must shift the matters back to business."
	},
	{
		"type": "partner_text",
		"content": "I am messaging you to inform you that you will soon receive a message from Miss Amy. "
	},
	{
		"type": "player_text",
		"content": "...Huh?"
	},
	{
		"type": "player_text",
		"content": "You are messaging me... to tell me I'm going to receive a message?"
	},
	{
		"type": "partner_text",
		"content": "Indeed sir."
	},
	{
		"type": "partner_text",
		"content": "Miss Amy is a very busy woman and she does not have time for the trivialties of casual messaging"
	},
	{
		"type": "partner_text",
		"content": "At her request, I inform all contacts beforehand that they will receive a message from her."
	},
	{
		"type": "partner_text",
		"content": "This is to ensure that her time is not wasted waiting for your response. "
	},
	{
		"type": "player_text",
		"content": "Wait. Hold up."
	},
	{
		"type": "player_text",
		"content": "She pays you..."
	},
	{
		"type": "player_text",
		"content": "To ensure her text message doesn't get ghosted??"
	},
	{
		"type": "partner_text",
		"content": "This is one of my many responsibilities sir."
	},
	{
		"type": "player_text",
		"content": "And what exactly is this message going to be about?"
	},
	{
		"type": "partner_text",
		"content": "Miss Amy has informed me that you have agreed to a favor on her behalf, during the evening outside of the casino."
	},
	{
		"type": "player_text",
		"content": "I remember..."
	},
	{
		"type": "player_text",
		"content": "So what's the favor?"
	},
	{
		"type": "partner_text",
		"content": "The favor is Miss Amy's personal matter. She will inform you herself."
	},
	{
		"type": "player_text",
		"content": "Okay, so when is she going to 'inform' me?"
	},
	{
		"type": "partner_text",
		"content": "She will message you when I inform her that you are ready to receive her message."
	},
	{
		"type": "player_text",
		"content": "Ok so you will inform her after I inform you that I am ready for her to inform me? "
	},
	{
		"type": "partner_text",
		"content": "Indeed, sir. "
	},
	{
		"type": "player_text",
		"content": "And what if I ignore her text?"
	},
	{
		"type": "partner_text",
		"content": "I would highly advise against that sir."
	},
	{
		"type": "partner_text",
		"content": "Please, be available to receive her message."
	},
	{
		"type": "player_text",
		"content": "And what if I suddenly have to take a huge shit right after we stop talking and I can't reach my phone?"
	},
	{
		"type": "partner_text",
		"content": "I would highly advise against that as well sir."
	},
	{
		"type": "player_text",
		"content": "You're saying that you advise against me taking a shit?"
	},
	{
		"type": "partner_text",
		"content": "Sir, why must you make this difficult? May I inform Amy that you will be available to receive her message?"
	},
	{
		"type": "player_text",
		"content": "You can inform her."
	},
	{
		"type": "partner_text",
		"content": "And can you confirm for me that you will not choose that moment to 'take a huge shit', as you put it? "
	},
	{
		"type": "player_text",
		"content": "..."
	},
	{
		"type": "player_text",
		"content": "Fine."
	},
	{
		"type": "partner_text",
		"content": "Please explicitly confirm."
	},
	{
		"type": "player_text",
		"content": "Confirmed. No shits."
	},
	{
		"type": "partner_text",
		"content": "Excellent sir, I appreciate your cooperation."
	},
	{
		"type": "partner_text",
		"content": "Now, before we start sir, please understand the following rules:"
	},
	{
		"type": "partner_long_typing",
	},
	{
		"type": "partner_text",
		"content": "Firstly sir, when Miss Amy initiates contact you will address her as “Miss Amy” or “Miss Perrier” unless and until she explicitly grants you permission to do otherwise. You will not, under any circumstances, shorten her name to 'Amy', 'Ames', 'Sweetheart', or any other vulgar diminutive. Secondly, please refrain from the use of emojis, emoticons, stickers, GIFs, memes, or what you may refer to as “reaction images”. Miss Amy prefers the written word and complete sentences, with capital letters in their proper places and punctuation that does not resemble a battlefield of punctuation. Thirdly, you will endeavor to respond within a timely manner, ideally within thirty seconds of receiving her message and no later than two minutes. Should you once again feel compelled to “take a huge shit,” I must insist you either complete your business in advance or keep your phone within arm’s reach and your hands sufficiently sanitary to type a coherent reply. Fourth, you will not initiate topics pertaining to her net worth, family holdings, brand endorsements, or any gossip you may have absorbed from the internet or the casino floor. Miss Amy is aware that she is wealthy and does not require narration on the topic. Fifth, you will not boast of your own poverty or unworthiness as a form of humor, self-deprecation, or court jester routine, as it is unbecoming and, quite frankly, tedious. Sixth, you will refrain from unsolicited flirtation, romantic declarations, or offers to “shoot your shot.” Failed attempts at charm will be silently observed and later recounted to me for filing. Seventh, you will not inquire about her love life, romantic history, or current relationship status, and you will not say things such as “So, you seeing anyone?” or “A girl like you must have a boyfriend,” or indeed any variant thereof. Eighth, you will not send photographs to Miss Amy. This includes photos of yourself, your food, your bedroom, your “gains,” your pets, or any other subject. If Miss Amy wishes to visually see your face she will arrange an in-person meeting or summon you to a location of her choosing. Ninth, if Miss Amy extends such an invitation, you will arrive punctually, freshly bathed, clothed in garments that have at minimum been introduced to an iron or a hanger within the last decade, and you will avoid strong colognes, loud patterns, novelty T-shirts, and any footwear that squeaks audibly on tile. Tenth, you will not make satirical jokes in regards to myself (Pluto) or any of the rules mentioned herein, such jokes put both my employment and my emotional state at risk of termination. Eleventh, you will not attempt to negotiate the favor she will request of you. The matter of your debt to her has already been settled and will not be reopened for discussion. Twelfth, during the course of your conversation you will not, without due cause, deploy phrases such as 'six seven', 'based,' 'no cap,' 'low-key,' 'rizz,' or any other linguistic contraband of the moment, and you will especially not attempt to explain the meanings of such phrases to her. Finally, I must insist that you be yourself and respond naturally as if talking to any one of your other 'chums' or 'pals' (while strictly adhereing to the aforementioned rules.)"
	},
	{
		"type": "partner_text",
		"content": "Can you confirm that you understand the guidelines I have provided?"
	},
	{
		"type": "player_text",
		"content": "What the fuck"
	},
	{
		"type": "player_text",
		"content": "You have got to be joking"
	},
	{
		"type": "partner_text",
		"content": "Please confirm."
	},
	{
		"type": "player_text",
		"content": "confirmed... whatever."
	},
	{
		"type": "partner_text",
		"content": "Please stay near your device, she will be messaging you shortly."
	},
	{
		"type": "complete"
	}
]


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
		"partner_long_typing":
			return getPartnerLongTypingAction()
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
