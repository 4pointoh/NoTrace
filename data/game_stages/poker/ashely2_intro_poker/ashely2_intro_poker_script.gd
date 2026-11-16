extends PokerScript

# The first hand, before the race: one life each, no cheats, and she always wins. You're dealt kings
# full of queens, she has four aces. The cards you can draw share no suit with enough of your hand to
# make a straight flush, the one hand that beats hers. The forfeit scene plays next.
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")

const YOUR_HAND = ["KS", "KH", "KD", "QC", "QH"]
const HER_HAND = ["AS", "AH", "AD", "AC", "KC"]
const YOUR_DRAWS = ["2C", "7D", "4S", "9H", "3C"]

static func reset_tracking_vars():
	pass

static func evaluate_poker_game(_pokerInfo : PokerInfo):
	return PokerUpdateActionResult.new()

static func stackedDeck() -> Array:
	return YOUR_HAND + HER_HAND + YOUR_DRAWS

# The picture picked for it in the dialogue editor (Race.MATCH_PICTURES).
static func startingBackground() -> Background:
	return Race.firstHandPicture()
