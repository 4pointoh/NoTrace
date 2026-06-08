extends RefCounted
class_name PhoneScript

var actionIndex = -1
var actionGroup = 0

func getNextAction():
	assert(false, "implement PhoneScript.getNextAction")

func getPreparedMessages():
	assert(false, "Implement PhoneScript.getPreparedMessages if you want to use prepared messages")

func loadPreparedMessagesAtStart():
	return false
	
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

func getSpecialAction(content):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.SPECIAL
	action.message = content
	return action

func getPartnerLongTypingAction():
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.TEXT_PARTNER_LONG_TYPING
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

func getPlayMusicAction(musicPath):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.PLAY_MUSIC
	action.message = musicPath
	return action

func getFadeMusicOutAction():
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.FADE_MUSIC_OUT
	return action

func getPartnerDelay(message = ''):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.PARTNER_DELAY
	action.message = message
	return action

func getBlockedMessage():
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.BLOCKED
	return action

func getVideoAction(videoPath):
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.VIDEO
	action.videoPath = videoPath
	return action

func getNextMessageInstantAction():
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.NEXT_MESSAGE_INSTANT
	return action

func getCountdownAction(minutes: int, countdownLabel: String = "", countdownButtonLabel: String = "", actualDelayInSeconds: int = 0) -> PhoneAction:
	var action = PhoneAction.new()
	action.action = PhoneAction.ACTIONS.COUNTDOWN
	action.countdownMinutes = minutes
	action.countdownLabel = countdownLabel
	action.countdownButtonLabel = countdownButtonLabel
	action.actualDelayInSeconds = actualDelayInSeconds
	return action
