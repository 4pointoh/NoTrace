extends RefCounted
class_name DateAction

enum TYPES {
	TOPIC,
	QUIZ,
	PLAYER_QUESTION,
	PARTNER_QUESTION,
	FAIL,
	CHOICE,
	COMPLETE,
	DIALOGUE_ONLY
}

enum CATEGORIES {
	HIDE,
	SMALL_TALK,
	PERSONAL,
	FRIENDLY,
	FLIRTY,
	DEEP,
	CORE
}

enum BUTTON_INDEX {
	TALK,
	FLIRT,
	BUSINESS,
	SMALL_TALK,
	NONE
}

var id : String = ""
var text : String

var type : DateAction.TYPES
var category : DateAction.CATEGORIES

var dialogueStartKey : String

var successFunc : Callable
var failureFunc : Callable
var loveLocked : bool = false
var progressLocked : bool = false
var buttonIndex : DateAction.BUTTON_INDEX = DateAction.BUTTON_INDEX.NONE
