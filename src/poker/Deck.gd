extends RefCounted
class_name Deck

var cards = []
var suits = ["hearts", "diamonds", "spades", "clubs"]
var values = ["2","3","4","5","6","7","8","9","T","J","Q","K","A"]

func _init():
	resetDeck()

func shuffle():
	var shuffledCards = []
	
	while(cards.size() != 0):
		var index = randi_range(0,cards.size() - 1)
		shuffledCards.append(cards[index])
		cards.remove_at(index)
	
	cards = shuffledCards.duplicate(true)
	
func resetDeck():
	cards = []
	for suit in suits:
		for value in values:
			var card = NonUiCard.new()
			card.value = value
			card.suit = suit
			cards.append(card)
			
	shuffle()

## Puts these cards on top of the deck, the first one on top. A card is its value then its suit's
## initial: "AS" is the ace of spades, "TH" the ten of hearts. The rest stay shuffled under them.
func stack(codes : Array):
	var top = []
	for code in codes:
		var index = cards.find_custom(func(card): return card.value + card.suit[0].to_upper() == code)
		assert(index >= 0, "no " + code + " left in the deck to stack")
		top.append(cards[index])
		cards.remove_at(index)
	cards = top + cards

func nextCard():
	if cards.is_empty():
		resetDeck()

	return cards.pop_front()

func deal(numCards : int):
	var dealtCards = []
	for i in range(numCards):
		dealtCards.append(nextCard())
	
	return dealtCards
