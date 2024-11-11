extends Node
class_name DateActionResult

var success : bool
var criticalFailure : bool
var nextGroup : Array[DateAction] = []
var dialogueStartKey : String
var scoreEntertained : int = 0
var scoreHorny : int = 0
var scoreProgression : int = 0
var particleType : Heartsplosion.TYPES
var wallpaper : Background
var addParticleRain: String

func setBackground(texture, name):
	wallpaper = Background.new()
	wallpaper.images = texture
	wallpaper.name = name
