extends Resource
class_name GameStage

@export var name : String
@export var dialogue: DialogueData
@export var dialogueStartKey : String
@export var guaranteedNextGameStage: GameStage
@export var isCompletable : bool
@export var startingBackground : Background

# Poker
@export var isPokerMatch : bool
@export var playerStartingMoney: int
@export var cpuStartingMoney: int
@export var startingAnte : int
@export var opponentName : String
@export var opponentNamePlural : bool
@export var maxRaise : int
@export var pokerScript : Script

# Phone
@export var isPhoneScreen : bool
@export var isPhoneMessageEvent : bool
@export var phoneScript : Script
@export var contactName: String
@export var contactImage: Texture
@export var startingMusic : AudioStream

# SelectableGameStage
@export var stageButtonTexture : Texture
@export var stageButtonHover : Texture
@export var stageButtonLabel : String

# Date stuff
@export var isDate : bool
@export var dateScript : Script
@export var dateWinGameStage: GameStage
@export var dateLossDialogueKey: String
@export var dateCharacter: String #LISA, ASHELY, AMY
@export var dateTitle: String
