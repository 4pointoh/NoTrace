extends RefCounted
class_name PokerEval
# Define dictionaries for card ranks and hand ranks as static variables
static var card_ranks = {
	"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7,
	"8": 8, "9": 9, "T": 10, "10": 10,
	"J": 11, "Q": 12, "K": 13, "A": 14
}


static var hand_ranks = {
	"High Card": 1,
	"Pair": 2,
	"Two Pairs": 3,
	"Three of a Kind": 4,
	"Straight": 5,
	"Flush": 6,
	"Full House": 7,
	"Four of a Kind": 8,
	"Straight Flush": 9
}
static func evaluate_hand(hand):
	var values = []
	var suits = []
	var counts = {}
	var hand_rank = ""
	var hand_info = {}  # Dictionary to store detailed hand info

	# Parse the hand
	for card in hand:
		var value_len = card.length() - 1
		var value = card.substr(0, value_len)
		var suit = card[value_len]

		if not card_ranks.has(value):
			print("Invalid card value: " + value)
			continue

		values.append(card_ranks[value])
		suits.append(suit)

		if not counts.has(card_ranks[value]):
			counts[card_ranks[value]] = 1
		else:
			counts[card_ranks[value]] += 1

	# Sort the values in descending order
	values.sort()
	values.reverse()

	# Build suit to values mapping
	var suit_to_values = {}
	for i in range(suits.size()):
		var suit = suits[i]
		var value = values[i]
		if not suit_to_values.has(suit):
			suit_to_values[suit] = []
		suit_to_values[suit].append(value)

	# Remove duplicates from values to get unique_values
	var unique_values = []
	for v in values:
		if v not in unique_values:
			unique_values.append(v)

	# Check for flush
	var flush_suit = null
	var flush_values = []
	for suit in suit_to_values.keys():
		if suit_to_values[suit].size() >= 5:
			flush_suit = suit
			# Get the flush values and sort them
			flush_values = suit_to_values[suit]
			flush_values.sort()
			flush_values.reverse()
			break

	# Remove duplicates from flush_values to get flush_unique_values
	var flush_unique_values = []
	for v in flush_values:
		if v not in flush_unique_values:
			flush_unique_values.append(v)

	# Check for straight
	var is_straight = false
	var straight_high_card = null
	if unique_values.size() >= 5:
		for i in range(unique_values.size() - 4):
			var sequence = []
			for j in range(5):
				sequence.append(unique_values[i + j])
			var is_sequence = true
			for j in range(4):
				if sequence[j] - 1 != sequence[j + 1]:
					is_sequence = false
					break
			if is_sequence:
				is_straight = true
				straight_high_card = sequence[0]
				break
		# Check for Ace-low straight
		if unique_values.has(14) and unique_values.has(5) and unique_values.has(4) and unique_values.has(3) and unique_values.has(2):
			is_straight = true
			straight_high_card = 5

	# Check for straight flush
	var is_straight_flush = false
	var straight_flush_high_card = null
	if flush_suit != null and flush_unique_values.size() >= 5:
		for i in range(flush_unique_values.size() - 4):
			var sequence = []
			for j in range(5):
				sequence.append(flush_unique_values[i + j])
			var is_sequence = true
			for j in range(4):
				if sequence[j] - 1 != sequence[j + 1]:
					is_sequence = false
					break
			if is_sequence:
				is_straight_flush = true
				straight_flush_high_card = sequence[0]
				break
		# Check for Ace-low straight flush
		if flush_unique_values.has(14) and flush_unique_values.has(5) and flush_unique_values.has(4) and flush_unique_values.has(3) and flush_unique_values.has(2):
			is_straight_flush = true
			straight_flush_high_card = 5

	# Determine hand rank
	if is_straight_flush:
		hand_rank = "Straight Flush"
		hand_info['rank_values'] = [straight_flush_high_card]
	elif 4 in counts.values():
		hand_rank = "Four of a Kind"
		var quad = null
		for key in counts:
			if counts[key] == 4:
				quad = key
				break
		# Get remaining values
		var remaining_values = []
		for v in values:
			if v != quad:
				remaining_values.append(v)
		hand_info['rank_values'] = [quad, remaining_values[0]]  # The four of a kind rank and highest kicker
	elif 3 in counts.values() and 2 in counts.values():
		hand_rank = "Full House"
		var trips = null
		var pair = null
		for key in counts:
			if counts[key] == 3:
				trips = key
			elif counts[key] == 2:
				pair = key
		hand_info['rank_values'] = [trips, pair]
	elif flush_suit != null:
		hand_rank = "Flush"
		# Get the highest five cards of the flush suit
		var flush_top_values = []
		for i in range(min(5, flush_values.size())):
			flush_top_values.append(flush_values[i])
		hand_info['rank_values'] = flush_top_values
	elif is_straight:
		hand_rank = "Straight"
		hand_info['rank_values'] = [straight_high_card]
	elif 3 in counts.values():
		hand_rank = "Three of a Kind"
		var trips = null
		for key in counts:
			if counts[key] == 3:
				trips = key
				break
		# Get remaining values
		var remaining_values = []
		for v in values:
			if v != trips:
				remaining_values.append(v)
		var kickers = []
		for i in range(min(2, remaining_values.size())):
			kickers.append(remaining_values[i])
		hand_info['rank_values'] = [trips] + kickers
	elif counts.values().count(2) >= 2:
		hand_rank = "Two Pairs"
		var pairs = []
		for key in counts:
			if counts[key] == 2:
				pairs.append(key)
		pairs.sort()
		pairs.reverse()
		# Get the highest two pairs
		var top_pairs = []
		for i in range(min(2, pairs.size())):
			top_pairs.append(pairs[i])
		# Get remaining values
		var remaining_values = []
		for v in values:
			if v not in top_pairs:
				remaining_values.append(v)
		# Get the highest kicker
		var kicker = remaining_values[0] if remaining_values.size() > 0 else 0
		hand_info['rank_values'] = top_pairs + [kicker]
	elif 2 in counts.values():
		hand_rank = "Pair"
		var pair = null
		for key in counts:
			if counts[key] == 2:
				pair = key
				break
		# Get remaining values
		var remaining_values = []
		for v in values:
			if v != pair:
				remaining_values.append(v)
		var kickers = []
		for i in range(min(3, remaining_values.size())):
			kickers.append(remaining_values[i])
		hand_info['rank_values'] = [pair] + kickers
	else:
		hand_rank = "High Card"
		var high_cards = []
		for i in range(min(5, values.size())):
			high_cards.append(values[i])
		hand_info['rank_values'] = high_cards

	return [hand_rank, hand_info]


static func determine_winner(hand1, hand2):
	var hand1_info = evaluate_hand(hand1)
	var hand2_info = evaluate_hand(hand2)

	if hand1_info[0] == "":
		hand1_info[0] = "High Card"
	if hand2_info[0] == "":
		hand2_info[0] = "High Card"

	if hand_ranks[hand1_info[0]] > hand_ranks[hand2_info[0]]:
		return ["Hand 1 wins", hand1_info[0], hand2_info[0]]
	elif hand_ranks[hand1_info[0]] < hand_ranks[hand2_info[0]]:
		return ["Hand 2 wins", hand2_info[0], hand1_info[0]]
	else:
		# If the ranks are the same, compare rank_values
		var hand1_values = hand1_info[1]['rank_values']
		var hand2_values = hand2_info[1]['rank_values']

		# Sort the values in descending order
		hand1_values.sort()
		hand1_values.reverse()
		hand2_values.sort()
		hand2_values.reverse()

		for i in range(min(hand1_values.size(), hand2_values.size())):
			if hand1_values[i] > hand2_values[i]:
				return ["Hand 1 wins", hand1_info[0], hand2_info[0]]
			elif hand1_values[i] < hand2_values[i]:
				return ["Hand 2 wins", hand2_info[0], hand1_info[0]]

		# If all high card values are the same, it's a tie
		return ["It's a tie", hand1_info[0], hand2_info[0]]


static func calculate_win_probability(player_cards, cpu_cards, community_cards):
	var deck = generate_full_deck()
	var known_cards = player_cards + cpu_cards + community_cards
	var remaining_cards = remove_hand_cards(deck, known_cards)
	var total_outcomes = 0
	var player_wins = 0
	var cpu_wins = 0
	var ties = 0

	# Determine the number of community cards still to be dealt
	var cards_needed = 5 - community_cards.size()

	# Generate all possible combinations of the remaining community cards
	var community_combinations = get_combinations(remaining_cards, cards_needed)

	for combo in community_combinations:
		var final_community = community_cards + combo
		var player_hand = player_cards + final_community
		var cpu_hand = cpu_cards + final_community

		var winner = determine_winner(player_hand, cpu_hand)
		if winner[0] == "Hand 1 wins":
			player_wins += 1
		elif winner[0] == "Hand 2 wins":
			cpu_wins += 1
		else:
			ties += 1
		total_outcomes += 1

	var player_probability = float(player_wins) / total_outcomes * 100
	var cpu_probability = float(cpu_wins) / total_outcomes * 100
	var tie_probability = float(ties) / total_outcomes * 100

	return [player_probability, cpu_probability, tie_probability]
	
	
static func get_combinations(cards, n):
	if n == 0:
		return [[]]
	var combinations = []
	for i in range(cards.size()):
		var card = cards[i]
		var remaining = cards.slice(i + 1, cards.size())
		for combo in get_combinations(remaining, n - 1):
			combinations.append([card] + combo)
	return combinations

# Helper function to generate a full deck of cards
static func generate_full_deck():
	var deck = []
	var suits = ["H", "D", "C", "S"]
	var values = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]

	for suit in suits:
		for value in values:
			deck.append(value + suit)

	return deck

# Helper function to remove the cards in the hands from the deck
static func remove_hand_cards(deck, hand_cards):
	var remaining_cards = []

	for card in deck:
		if not card in hand_cards:
			remaining_cards.append(card)

	return remaining_cards

static func getWinnersFromCardLists(playerCards, cpuCards, boardCards):
	var newPlayerCards = playerCards + boardCards
	var newCpuCards = cpuCards + boardCards

	var playerHandString = []
	var cpuHandString = []
	for card in newPlayerCards:
		var value = card.value
		if value == "10":
			value = "T"  # Ensure consistent representation
		var strin = value + card.suit[0].capitalize()
		playerHandString.append(strin)
		
	for card in newCpuCards:
		var value = card.value
		if value == "10":
			value = "T"
		var strin = value + card.suit[0].capitalize()
		cpuHandString.append(strin)

	print("Hand 1 (Player): " + str(playerHandString))
	print("Hand 2 (CPU): " + str(cpuHandString))
	var winners = PokerEval.determine_winner(playerHandString, cpuHandString)
	print(str(winners[0]) + " with " + str(winners[1]))
	print("Other player had: " + str(winners[2]))
	return winners


# for use on the flop (5 total cards) only
static func getProbabilitiesFromCardLists(playerCards, cpuCards, boardCards):
	var playerHandString = []
	var cpuHandString = []
	var communityHandString = []

	for card in playerCards:
		var value = card.value
		if value == "10":
			value = "T"  # Ensure consistent representation
		var strin = value + card.suit[0].capitalize()
		playerHandString.append(strin)
		
	for card in cpuCards:
		var value = card.value
		if value == "10":
			value = "T"
		var strin = value + card.suit[0].capitalize()
		cpuHandString.append(strin)

	for card in boardCards:
		var value = card.value
		if value == "10":
			value = "T"
		var strin = value + card.suit[0].capitalize()
		communityHandString.append(strin)

	var probs = PokerEval.calculate_win_probability(playerHandString, cpuHandString, communityHandString)
	print('Player Hand / Chance To Win: ' + str(playerHandString) + ' / ' + str(probs[0]) + '%')
	print('CPU Hand / Chance To Win: ' + str(cpuHandString) + ' / ' + str(probs[1]) + '%')
	return probs

static func calculate_cpu_discard_indexes(cpu_cards, random_chance_percentage: int) -> Array:
	var cpu_indexes_to_discard = []

	# -- STEP 0) Check random chance first -- #
	# Generate a random integer 0..100, compare with random_chance_percentage
	if randi() % 101 < random_chance_percentage:
		# Completely random discard selection
		# Decide how many cards to discard, e.g. from 0 to 5
		var number_to_discard = randi() % 6
		
		# Collect random distinct indices up to 'number_to_discard'
		while cpu_indexes_to_discard.size() < number_to_discard:
			var random_index = randi() % 5
			if not cpu_indexes_to_discard.has(random_index):
				cpu_indexes_to_discard.append(random_index)
		
		# Sort in descending order for safe removal later
		cpu_indexes_to_discard.sort_custom(func(a, b): return a > b)
		return cpu_indexes_to_discard
	
	# -- STEP 1) Convert NonUiCards -> Strings for PokerEval -- #
	var cpu_hand_string = []
	for c in cpu_cards:
		var card_value = c.value
		if card_value == "10":
			card_value = "T"
		var suit_char = c.suit[0].capitalize()
		cpu_hand_string.append(card_value + suit_char)
	
	# -- STEP 2) Evaluate the hand with PokerEval -- #
	var cpu_eval = PokerEval.evaluate_hand(cpu_hand_string)
	var cpu_hand_rank = cpu_eval[0]                   # e.g. "Pair", "Two Pairs", etc.
	var cpu_rank_values = cpu_eval[1]["rank_values"]  # Detailed ranks for that hand
	
	var cpu_indexes_to_keep = []
	
	# -- STEP 3) Decide which cards to keep/discard based on hand rank -- #
	match cpu_hand_rank:
		"Straight Flush", "Straight", "Flush", "Full House":
			# Already a strong made hand -> keep all
			cpu_indexes_to_discard = []
		
		"Four of a Kind":
			var quad_rank = cpu_rank_values[0]
			for i in range(cpu_cards.size()):
				if get_card_rank_int(cpu_cards[i]) == quad_rank:
					cpu_indexes_to_keep.append(i)
			for i in range(5):
				if not cpu_indexes_to_keep.has(i):
					cpu_indexes_to_discard.append(i)
		
		"Three of a Kind":
			var triple_rank = cpu_rank_values[0]
			for i in range(cpu_cards.size()):
				if get_card_rank_int(cpu_cards[i]) == triple_rank:
					cpu_indexes_to_keep.append(i)
			for i in range(5):
				if not cpu_indexes_to_keep.has(i):
					cpu_indexes_to_discard.append(i)
		
		"Two Pairs":
			var pair1 = cpu_rank_values[0]
			var pair2 = cpu_rank_values[1]
			for i in range(cpu_cards.size()):
				var rank_int = get_card_rank_int(cpu_cards[i])
				if rank_int == pair1 or rank_int == pair2:
					cpu_indexes_to_keep.append(i)
			for i in range(5):
				if not cpu_indexes_to_keep.has(i):
					cpu_indexes_to_discard.append(i)
		
		"Pair":
			var pair_rank = cpu_rank_values[0]
			for i in range(cpu_cards.size()):
				if get_card_rank_int(cpu_cards[i]) == pair_rank:
					cpu_indexes_to_keep.append(i)
			for i in range(5):
				if not cpu_indexes_to_keep.has(i):
					cpu_indexes_to_discard.append(i)
		
		"High Card":
			# Simple heuristic: keep the top 1 or 2 high cards (Q, K, A) and discard the rest
			var sorted_indices = []
			for i in range(cpu_cards.size()):
				sorted_indices.append(i)
			
			sorted_indices.sort_custom(func(a, b):
				return get_card_rank_int(cpu_cards[a]) > get_card_rank_int(cpu_cards[b])
			)
			
			var top_card_rank = get_card_rank_int(cpu_cards[sorted_indices[0]])
			var second_card_rank = get_card_rank_int(cpu_cards[sorted_indices[1]])
			
			# If top two are Q(12) or higher, keep both
			if top_card_rank >= 12 and second_card_rank >= 12:
				cpu_indexes_to_keep.append(sorted_indices[0])
				cpu_indexes_to_keep.append(sorted_indices[1])
			else:
				# Otherwise keep just the highest card
				cpu_indexes_to_keep.append(sorted_indices[0])
			
			for i in range(5):
				if not cpu_indexes_to_keep.has(i):
					cpu_indexes_to_discard.append(i)
		
		_:
			# Fallback if something unexpected
			cpu_indexes_to_discard = []
	
	# -- STEP 4) Sort discard indices descending so removing them doesn't shift the next index -- #
	cpu_indexes_to_discard.sort_custom(func(a, b): return a > b)
	
	return cpu_indexes_to_discard


	# Small helper to convert NonUiCard -> integer rank
static func get_card_rank_int(card: NonUiCard) -> int:
		var val = card.value
		if val == "10":
			val = "T"
		return PokerEval.card_ranks[val]
	