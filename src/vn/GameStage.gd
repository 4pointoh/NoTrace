extends Resource
class_name GameStage

@export var name : String
@export var displayName : String
@export var dialogue: DialogueData
@export var dialogueStartKey : String
@export var guaranteedNextGameStage: GameStage
@export var isCompletable : bool
@export var startingBackground : Background
@export var startTransitionText : String
@export var startTransition: Transition.TransitionType
@export var endTransitionText : String
@export var endTransition: Transition.TransitionType
@export var middleTransitionText : String
@export var middleTransition: Transition.TransitionType
@export var markStagesCompleteOnDateWin : Array[String]
@export var markStagesCompleteOnSceneEnd : Array[String]
@export var unlockWallpapersOnSceneEnd: Array[String]

# Poker
@export var isPokerMatch : bool
@export var playerStartingMoney: int
@export var cpuStartingMoney: int
@export var startingAnte : int
@export var opponentName : String
@export var opponentNamePlural : bool
@export var maxRaise : int
@export var pokerType : PokerEnums.PokerType = PokerEnums.PokerType.FIVE_CARD_DRAW
@export var cheatCount : int
@export var playerLives : int
@export var cpuLives : int
@export var cpuRandomDiscardChance: int
@export var playerLivesWithEvents : Array[int]
@export var cpuLivesWithEvents : Array[int]
@export var pokerScript : Script

# Phone
@export var isPhoneScreen : bool
@export var isPhoneMessageEvent : bool
@export var phoneScript : Script
@export var contactName: String
@export var contactImage: Texture
@export var startingMusic : AudioStream
@export var delayMusicToTransition : bool = false

# SelectableGameStage
@export var stageButtonTexture : Texture
@export var stageButtonHover : Texture
@export var stageButtonLabel : String

# Date stuff
@export var isDate : bool
@export var dateScript : Script
@export var dateWinGameStage: GameStage

## When the date is completed, you must mark the 'selectable event' phone stage complete. This is the stage that triggers when the event is selected in the phone. 
@export var dateWinMarkThisStageComplete: String
@export var dateLossDialogueKey: String
@export var dateCharacter: String #LISA, ASHELY, AMY
@export var dateTitle: String
@export var dateBusinessButtonLabel: String
@export var maxProgress : int
