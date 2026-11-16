extends PokerScript

# The match itself has no events yet. It opens on the picture picked for the race as it stands (the score
# and what Ashely still has on: Race.MATCH_PICTURES, set in the dialogue editor).
const Race = preload("res://data/scripts/ashely_poker2/ashely2_race.gd")

static func reset_tracking_vars():
	pass

static func evaluate_poker_game(_pokerInfo : PokerInfo):
	return PokerUpdateActionResult.new()

static func startingBackground() -> Background:
	return Race.matchPicture()
