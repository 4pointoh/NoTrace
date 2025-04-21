extends RefCounted
class_name PokerUpdateActionResult

enum ACTION_RESULTS {
	NOTHING,
	START_DIALOGUE,
	GAME_END_EARLY
}

@export var actionResult : ACTION_RESULTS
@export var shouldHidePoker : bool
@export var shouldPausePoker : bool
@export var dialogueStartKey : String
@export var restoreImageOnCompletion : bool