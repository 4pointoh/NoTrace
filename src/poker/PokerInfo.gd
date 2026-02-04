extends RefCounted
class_name PokerInfo

# Legacy fields (kept for compatibility)
@export var playerMoney : int
@export var cpuMoney : int
@export var stage : PokerEnums.PokerStage
@export var pot: int
@export var amountLost: int

# Core state
@export var playerLost: bool
@export var playerLives: int
@export var cpuLives: int
@export var maxPlayerLives: int
@export var maxCpuLives: int

# Round tracking
@export var totalRounds: int = 0

# Loss/win counts
@export var playerTotalLosses: int = 0
@export var cpuTotalLosses: int = 0
@export var playerTotalWins: int = 0
@export var cpuTotalWins: int = 0

# Streak tracking
@export var playerLossesInARow: int = 0
@export var cpuLossesInARow: int = 0
@export var playerCurrentWinStreak: int = 0
@export var cpuCurrentWinStreak: int = 0
@export var playerHighestWinStreak: int = 0
@export var cpuHighestWinStreak: int = 0
@export var playerMostRecentLossStreak: int = 0
@export var cpuMostRecentLossStreak: int = 0

# Life advantage tracking
@export var playerLifeAdvantage: int = 0
@export var cpuLifeAdvantage: int = 0
@export var highestPlayerLifeAdvantage: int = 0
@export var highestCpuLifeAdvantage: int = 0

# Clothing state (items lost by each player)
@export var playerItemsLost: Array[String] = []
@export var cpuItemsLost: Array[String] = []

# Most recent item lost
@export var playerMostRecentlyLostItem: String = "NOTHING"
@export var cpuMostRecentlyLostItem: String = "NOTHING"


# Helper methods for checking clothing state
func playerHasLost(item: String) -> bool:
	return playerItemsLost.has(item.to_upper())


func cpuHasLost(item: String) -> bool:
	return cpuItemsLost.has(item.to_upper())


func playerItemCount() -> int:
	return playerItemsLost.size()


func cpuItemCount() -> int:
	return cpuItemsLost.size()