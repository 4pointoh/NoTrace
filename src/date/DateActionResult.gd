extends Node
class_name DateActionResult

var success : bool
var criticalFailure : bool
var nextGroup : Array[DateAction] = []
var dialogueStartKey : String
var scoreProgression : int = 0 # used to gate question progress
var particleType : Heartsplosion.TYPES
var wallpaper : Background
var addParticleRain: String
var progressType : DATE_PROGRESS_TYPE = DATE_PROGRESS_TYPE.BUSINESS
var progressQuantity : int = 30 # used to fill the love/business bar
var memoryUnlockId : String = ""
var annoyed : bool = false
var incrementMainQuestionIndex : bool = false
var setFlagToTrue : String

enum DATE_PROGRESS_TYPE {
	LOVE,
	BUSINESS,
	NEUTRAL
}

func setBackground(texture, name2):
	wallpaper = Background.new()
	wallpaper.images = texture
	wallpaper.name = name2
