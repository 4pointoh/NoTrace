extends Object
class_name PhoneScript

var actionIndex = -1
var actionGroup = 0

func getNextAction():
	assert(false, "implement PhoneScript.getNextAction")
	
func advanceActionGroup(newGroup):
	actionIndex = -1
	actionGroup = newGroup

func handleChoice(_choice):
	assert(false, "implement PhoneScript.handleChoice")
	
func getCompleteAction():
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.COMPLETE
	return action

func getPlayerTextAction(message):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.TEXT_YOU
	action.message = message
	return action

func getPartnerTextAction(message, soundType = PhoneAction.SOUND_TYPE.DEFAULT):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.TEXT_PARTNER
	action.message = message
	action.soundType = soundType
	return action

func getChoiceAction(choices):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.CHOICE
	action.choices.append_array(choices)
	return action

func getImageAction(image):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.IMAGE_PARTNER
	action.image = image
	return action

func getDialogueAction(startKey):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.DIALOGUE
	action.dialogueKey = startKey
	return action

func getPartnerDelay(message = ''):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.PARTNER_DELAY
	action.message = message
	return action
