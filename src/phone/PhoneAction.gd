extends Node
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
	VIDEO
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
