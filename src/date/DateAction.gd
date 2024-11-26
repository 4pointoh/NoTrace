extends Node
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

var id : String = ""
var text : String
var intensity : int
var luck : int

var type : DateAction.TYPES
var category : DateAction.CATEGORIES

var dialogueStartKey : String

var successFunc : Callable
var failureFunc : Callable
var successChance : int = 100
var loveLocked : bool = false
var progressLocked : bool = false
