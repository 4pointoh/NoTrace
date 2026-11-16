extends Resource
class_name Checkpoint

@export var checkpointName: String
@export var checkpointDescription: String
@export var completedStages : Array[String]
@export var character : String # Lisa, Anna, Ashely, Amy - used to determine font color
## The story has turned landscape by this point: the phone it lands on, and every phone after, is
## landscape, as in a real save made here.
@export var storyIsLandscape : bool
## Left out of Scene Select, eg: its content is cut from this update and comes in a later one.
@export var hidden : bool
# @export var currentGameStage: GameStage always phone

# Poker With Ashely
# Beach With Lisa
# Class With Anna
# Poker With Lisa
