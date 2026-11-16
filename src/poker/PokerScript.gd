extends RefCounted
class_name PokerScript

static func evaluate_poker_game(_pokerInfo : PokerInfo):
	assert(false, "implement evaluate_poker_game")

static func evaluate_poker_game_ambient_only(_pokerInfo : PokerInfo):
	assert(false, "implement evaluate_poker_game_ambient_only")

static func reset_tracking_vars():
	assert(false, "implement reset_tracking_vars")

## The picture a match opens on, when that depends on the story (eg: what she still has on).
## null opens on the stage's startingBackground.
static func startingBackground() -> Background:
	return null

## For a hand the story decides: the cards on top of the deck each round, the first one on top (see
## Deck.stack). Five-card draw deals you the first 5 and her the next 5, and redraws come off the
## top after that, yours first. Empty deals a fair, shuffled deck.
static func stackedDeck() -> Array:
	return []
