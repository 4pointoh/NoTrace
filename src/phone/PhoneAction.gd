extends RefCounted
class_name PhoneAction

enum ACTIONS {
	TEXT_YOU,
	TEXT_PARTNER,
	IMAGE_PARTNER,
	CHOICE,
	DIALOGUE,
	COMPLETE,
	PARTNER_DELAY,
	BLOCKED,
	VIDEO,
	TEXT_PARTNER_LONG_TYPING,
	SPECIAL,
	PLAY_MUSIC,
	FADE_MUSIC_OUT,
	NEXT_MESSAGE_INSTANT,
	COUNTDOWN
}

enum SOUND_TYPE {
	DEFAULT,
	HAPPY
}

var action : PhoneAction.ACTIONS
var message : String
var image : Texture
var choices : Array[String] = []
var dialogueKey : String
var videoPath : String
var soundType : PhoneAction.SOUND_TYPE = SOUND_TYPE.DEFAULT
var countdownMinutes : int = 0
var countdownLabel : String = ""
var countdownButtonLabel : String = ""
var actualDelayInSeconds : int = 0