extends PhoneScript

func getNextAction():
	actionIndex = actionIndex + 1
	
	if actionGroup == 0:
		return actionGroupZero()
		
func handleChoice(_choice):		
	pass

func actionGroupZero():
	if actionIndex == 0:
		return getDialogueAction("START")

	if actionIndex == 1:
		return getPlayerTextAction("Hey uhh... it's been a minute since we talked.")
		
	if actionIndex == 2:
		return getPlayerTextAction("You all good over there?")
		
	if actionIndex == 3:
		return getBlockedMessage()

	if actionIndex == 4:
		return getDialogueAction("START1")
	
	if actionIndex == 5:
		return getCompleteAction()
