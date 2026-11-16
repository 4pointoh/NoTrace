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
@export var markStagesCompleteOnPokerWin : Array[String]
@export var unlockWallpapersOnSceneEnd: Array[String]
@export var cacheItems : Array[String]
@export var repositionDialogueBoxTo : DialogueManager.DboxPosition = DialogueManager.DboxPosition.NO_CHANGE
@export var endOnlyOnSpecificDialogueKey : bool = false
@export var endingDialogueKeys : Array[String]
@export var choicesScript : Script
## For a stage played many times with different dialogue each time (eg: the result of each match in
## a race): quick skip passes over only the lines already read, not everything once it's been played.
@export var skipsOnlySeenDialogue : bool = false

# Display
## Starts this stage in the landscape frame (1920x1080). Every stage of the landscape story ticks it.
## Left off, the stage runs in the original portrait frame (896x1152), as every older stage does,
## replayed or not. Dialogue can still change frame mid-stage: landscape_next, portrait_next, and
## the reveal_landscape set-piece. A stage that ends in landscape takes the story there, and the
## phone is landscape from then on.
@export var isLandscape : bool
## What the reveal_landscape set-piece shows and plays: its title card, the atmosphere it leaves,
## the focus point it holds on and its music. Left empty: the default title, petals, no music.
@export var reveal : LandscapeRevealConfig

# Poker
@export var isPokerMatch : bool
@export var isStripPoker : bool
@export var playerStartingMoney: int
@export var cpuStartingMoney: int
@export var startingAnte : int
@export var opponentName : String
@export var opponentNamePlural : bool
@export var maxRaise : int
@export var pokerType : PokerEnums.PokerType = PokerEnums.PokerType.FIVE_CARD_DRAW
@export var cheatCount : int
## While one of these flags is set, each match gets that many cheats instead of cheatCount: flag ->
## cheats (Ashely Poker II's replay modes, data/game_stages/vn/ashely2_replay). See currentCheatCount().
@export var cheatCountByFlag : Dictionary[String, int]
@export var playerLives : int
@export var cpuLives : int
## Where the story goes when this match is lost. Left empty, a lost match is played again, as every
## older match does.
@export var pokerLossGameStage : GameStage
@export var cpuRandomDiscardChance: int
@export var playerLivesWithEvents : Array[int]
@export var cpuLivesWithEvents : Array[int]
@export var allowProPlus: bool
@export var allowProPlusMax: bool
@export var proPlusCheats: int
@export var proPlusMaxCheats: int
@export var pokerScript : Script
@export var useNewPokerSystem : bool
@export var pokerConfigJsonPath : String
@export var pokerCSVPath : String
@export var sceneLeadsToAPokerMatch : bool
@export var pokerMatchGameStage : Array[GameStage]
## Picking this event again on the phone, once it has been played, starts this stage instead, in place of
## the poker timeline (Ashely Poker II: its replay menu, which picks the cheats and gives the hints).
@export var replayGameStage : GameStage

# Phone
@export var isPhoneScreen : bool
@export var isPhoneMessageEvent : bool
@export var phoneScript : Script
@export var contactName: String
@export var contactImage: Texture
@export var startingMusic : AudioStream
@export var randomMusic: Array[AudioStream]
@export var musicList: Array[AudioStream]
var musicIndex : int = -1
@export var delayMusicToTransition : bool = false
@export var soundEffectList: Array[AudioStream]
var soundEffectIndex: int = -1

# SelectableGameStage
@export var stageButtonTexture : Texture
@export var stageButtonHover : Texture
@export var stageButtonLabel : String
@export var heartLevel : int

# RealDate
@export var isRealDate : bool
@export var numberOfSelections : int
@export var firstRoundGuesses : int = 6
@export var secondRoundGuesses : int = 4
@export var characterArt : Texture2D
@export var characterArtScale : Vector2
@export var characterArtPosition : Vector2
@export var character : GlobalGameStage.CHARACTERS
@export var perfectDateGameStage : GameStage
@export var midDateGameStage : GameStage
@export var lostDateStartKey : String
@export var touchDialogues : Array[String] # These are the dialogues that will be shown when the player touches the character during the date.

# Date stuff
@export var isDate : bool
@export var dateScript : Script
@export var dateWinGameStage: GameStage
@export var cantLose: bool = false # If true, the date cannot be lost. The player can only win or skip.

## When the date is completed, you must mark the 'selectable event' phone stage complete. This is the stage that triggers when the event is selected in the phone. 
@export var dateWinMarkThisStageComplete: String
@export var dateLossDialogueKey: String
@export var dateCharacter: String #LISA, ASHELY, AMY
@export var dateTitle: String
@export var dateBusinessButtonLabel: String
@export var maxProgress : int

## The cheats each match of this stage gets in its regular mode: cheatCount, unless one of
## cheatCountByFlag's flags is set.
func currentCheatCount() -> int:
	for flag in cheatCountByFlag:
		if GlobalGameStage.hasFlag(flag):
			return cheatCountByFlag[flag]
	return cheatCount

#Hints
@export var oneStarHints : Array[String]
@export var twoStarHints : Array[String]
@export var threeStarHints : Array[String]
