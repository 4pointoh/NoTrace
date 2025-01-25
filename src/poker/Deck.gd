extends Object
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

func nextCard():
	if cards.is_empty():
		resetDeck()

	return cards.pop_front()

func deal(numCards : int):
	var dealtCards = []
	for i in range(numCards):
		dealtCards.append(nextCard())
	
	return dealtCards
