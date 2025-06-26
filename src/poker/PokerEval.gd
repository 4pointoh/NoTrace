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
		# We already sorted `values` descending, so `remaining_values` is also descending
		
		var kickers = []
		for i in range(min(3, remaining_values.size())):
			kickers.append(remaining_values[i])
		
		# Put the pair rank first, then the kickers in descending order
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

	var descriptive_text = PokerEval.describe_hand(hand1_info)
	var descriptive_text2 = PokerEval.describe_hand(hand2_info)

	if hand1_info[0] == "":
		hand1_info[0] = "High Card"
	if hand2_info[0] == "":
		hand2_info[0] = "High Card"

	if hand_ranks[hand1_info[0]] > hand_ranks[hand2_info[0]]:
		return ["Hand 1 wins", hand1_info[0], hand2_info[0], descriptive_text, descriptive_text2]
	elif hand_ranks[hand1_info[0]] < hand_ranks[hand2_info[0]]:
		return ["Hand 2 wins", hand2_info[0], hand1_info[0], descriptive_text2, descriptive_text]
	else:
		# If the ranks are the same, compare rank_values
		var hand1_values = hand1_info[1]['rank_values']
		var hand2_values = hand2_info[1]['rank_values']

		for i in range(min(hand1_values.size(), hand2_values.size())):
			if hand1_values[i] > hand2_values[i]:
				return ["Hand 1 wins", hand1_info[0], hand2_info[0], descriptive_text, descriptive_text2]
			elif hand1_values[i] < hand2_values[i]:
				return ["Hand 2 wins", hand2_info[0], hand1_info[0], descriptive_text2, descriptive_text]


		# If all high card values are the same, it's a tie
		return ["It's a tie", hand1_info[0], hand2_info[0], descriptive_text, descriptive_text2]


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


# A helper function to run a single test comparison
static func test_poker_eval(hand1: Array, hand2: Array, expected_winner: String, test_name: String) -> void:
	# hand1 and hand2 should each be an array of 5 card strings, e.g. ["2H", "2D", "3C", "4S", "5D"]
	var result = PokerEval.determine_winner(hand1, hand2)

	# The result[0] is either "Hand 1 wins", "Hand 2 wins", or "It's a tie"
	var actual_winner = result[0]
	
	if actual_winner != expected_winner:
		# Print detailed info if it fails
		printerr("TEST FAILED: %s\n  Hand1: %s => %s\n  Hand2: %s => %s\n  Got: %s, Expected: %s\n"
			% [test_name, str(hand1), str(result[1]), str(hand2), str(result[2]), actual_winner, expected_winner])
	else:
		print("TEST PASSED: %s (winner: %s)" % [test_name, actual_winner])

static func _run_tests():
	# A collection of test cases.
	# Each test has:
	#   hand1: e.g. ["2H","2D","5S","7C","9D"]
	#   hand2: e.g. ["3H","3D","2C","4D","9H"]
	#   expected: "Hand 1 wins" / "Hand 2 wins" / "It's a tie"
	#   name: string describing the test
	var tests = [
		# 1) Pair (lower) vs Pair (higher)
		{
			"hand1": ["2H", "2D", "5S", "7C", "9D"], 
			"hand2": ["3H", "3D", "2C", "4D", "9H"], 
			"expected": "Hand 2 wins",
			"name": "Pair of 2s vs Pair of 3s"
		},
		# 2) Pair with higher kicker
		{
			"hand1": ["5H", "5D", "8C", "2S", "9D"], # Pair of 5's with 9 kicker
			"hand2": ["5C", "5S", "7D", "2H", "8S"], # Pair of 5's with 8 kicker
			"expected": "Hand 1 wins",
			"name": "Same Pair, higher kicker"
		},
		# 3) Two Pairs vs Single Pair
		{
			"hand1": ["4H", "4D", "7S", "7C", "9D"], # Two Pairs (7's & 4's)
			"hand2": ["8C", "8D", "5H", "2C", "9H"], # One Pair (8's)
			"expected": "Hand 1 wins",
			"name": "Two Pairs vs One Pair"
		},
		# 4) Two Pairs vs Two Pairs (kicker decides)
		{
			"hand1": ["9H", "9D", "2S", "2C", "QH"], # Two Pairs: 9's & 2's, Kicker Q
			"hand2": ["9C", "9S", "2H", "2D", "JH"], # Two Pairs: 9's & 2's, Kicker J
			"expected": "Hand 1 wins",
			"name": "Two Pairs w/ better kicker"
		},
		# 5) Straight vs Flush
		{
			"hand1": ["2H", "3H", "4H", "5D", "6C"], # Straight (6-high)
			"hand2": ["2S", "5S", "7S", "KS", "9S"], # Flush (Spades)
			"expected": "Hand 2 wins", # Flush beats Straight
			"name": "Straight vs Flush"
		},
		# 6) Straight vs higher Straight
		{
			"hand1": ["2C", "3D", "4D", "5H", "6S"], # 6-high Straight
			"hand2": ["3H", "4H", "5D", "6H", "7C"], # 7-high Straight
			"expected": "Hand 2 wins",
			"name": "Straight vs higher Straight"
		},
		# 7) Full House vs Flush
		{
			"hand1": ["3H", "3S", "3C", "9D", "9H"], # Full House (3's over 9's)
			"hand2": ["2D", "4D", "8D", "TD", "KD"],  # Flush (Diamonds)
			"expected": "Hand 1 wins", # Full House beats Flush
			"name": "Full House vs Flush"
		},
		# 8) Four of a Kind vs Full House
		{
			"hand1": ["5H", "5D", "5C", "5S", "9H"], # Four of a Kind (5's)
			"hand2": ["9C", "9D", "9S", "7H", "7C"], # Full House (9's over 7's)
			"expected": "Hand 1 wins", # 4 of a Kind beats Full House
			"name": "Four of a Kind vs Full House"
		},
		# 9) Straight Flush vs Four of a Kind
		{
			"hand1": ["5D", "6D", "7D", "8D", "9D"], # 9-high Straight Flush
			"hand2": ["KH", "KS", "KC", "KD", "2D"], # Four of a Kind (Kings)
			"expected": "Hand 1 wins",
			"name": "Straight Flush vs Four of a Kind"
		},
		# 10) Ties: identical High Card
		{
			"hand1": ["AH", "KD", "QC", "7S", "4D"], # A, K, Q, 7, 4
			"hand2": ["AC", "KS", "QD", "7C", "4S"], # A, K, Q, 7, 4
			"expected": "It's a tie",
			"name": "Identical High Card"
		},
		# 11) Ties: same Pair, same kickers
		{
			"hand1": ["8H", "8D", "3S", "2C", "AH"], # Pair of 8s, Kickers A,3,2
			"hand2": ["8C", "8S", "AS", "3H", "2D"], # Same pair, same kickers
			"expected": "It's a tie",
			"name": "Exact same Pair + Kickers"
		},

		############################
		# More In-Depth / Edge Cases
		############################

		# 12) Ace-low straight vs normal straight
		{
			"hand1": ["AH", "2D", "3C", "4H", "5S"], # A-2-3-4-5 (5-high straight)
			"hand2": ["2S", "3H", "4D", "5H", "6C"], # 6-high straight
			"expected": "Hand 2 wins", # 6-high beats 5-high
			"name": "Ace-Low Straight vs higher Straight"
		},
		# 13) Ace-low straight flush vs higher straight flush
		{
			# A-2-3-4-5 of hearts => 5-high straight flush
			"hand1": ["AH", "2H", "3H", "4H", "5H"],
			# 2-3-4-5-6 of hearts => 6-high straight flush
			"hand2": ["2H", "3H", "4H", "5H", "6H"],
			"expected": "Hand 2 wins", 
			"name": "Ace-low SF vs 6-high SF"
		},
		# 14) Ace-high flush vs King-high flush
		{
			"hand1": ["AH", "KH", "8H", "4H", "2H"], # Ace-high flush
			"hand2": ["KD", "QD", "JD", "7D", "3D"], # King-high flush
			"expected": "Hand 1 wins", # Ace-high flush > King-high flush
			"name": "Ace-high Flush vs King-high Flush"
		},
		# 15) Full House vs Full House (compare three-of-a-kind ranks)
		{
			# Full house: 6's over 2's
			"hand1": ["6H","6D","6C","2C","2H"], 
			# Full house: 4's over A's (No, that doesn't make sense. Full House is "three of a kind + pair". 
			# We'll do 7's over 2's or 6's over 3's. Let's do 7's over 2's:
			"hand2": ["7H","7D","7C","2S","2D"], 
			"expected": "Hand 2 wins", # 7's full > 6's full
			"name": "Full House vs Full House"
		},
		# 16) Three-of-a-kind vs Three-of-a-kind (compare top kicker)
		{
			# Trips of 9, Kickers: A, 2
			"hand1": ["9H","9D","9C","AH","2D"],
			# Trips of 9, Kickers: K, Q
			"hand2": ["9S","9C","9D","KH","QH"],
			"expected": "Hand 1 wins", # Ace kicker outranks K
			"name": "Trips vs Trips (kicker test)"
		},
		# 17) Two Pairs vs Two Pairs (same top pair, bigger second pair)
		{
			# 9,9 + 5,5
			"hand1": ["9H","9D","5S","5C","7D"],
			# 9,9 + 8,8
			"hand2": ["9C","9S","8C","8D","4H"],
			"expected": "Hand 2 wins",
			"name": "Two Pairs w/ same top pair, bigger second pair"
		},
		# 18) Straight Flush vs "Royal Flush" (Ace-high SF)
		{
			# 9 to King (9,T,J,Q,K) -> K-high straight flush of clubs
			"hand1": ["9C","TC","JC","QC","KC"], 
			# Royal flush: T,J,Q,K,A of diamonds => Ace-high straight flush
			"hand2": ["TD","JD","QD","KD","AD"],
			"expected": "Hand 2 wins",
			"name": "K-high SF vs Royal Flush"
		}
	]

	for test in tests:
		test_poker_eval(test.hand1, test.hand2, test.expected, test.name)

static func rank_to_name(rank: int) -> String:
	match rank:
		14:
			return "Ace"
		13:
			return "King"
		12:
			return "Queen"
		11:
			return "Jack"
		10:
			return "10"
		_:
			return str(rank)

static func describe_hand(hand_result: Array) -> String:
	# hand_result is what evaluate_hand() returns: [hand_rank, hand_info]
	var hand_rank = hand_result[0]
	var rank_values = hand_result[1]["rank_values"]
		
	match hand_rank:
		"Straight Flush":
			# rank_values[0] is the top card of the straight flush.
			if rank_values[0] == 14:
				# If top is 14 and we also have "10, J, Q, K, A", 
				# that’s a royal flush in common parlance:
				# but you can just say "Ace-high straight flush" or "Royal Flush."
				return "Royal Flush"  # or "Ace-high Straight Flush"
			elif rank_values[0] == 5:
				# Ace-low
				return "5-high Straight Flush (Ace-low)"
			else:
				return "%s-high Straight Flush" % rank_to_name(rank_values[0])
		
		"Four of a Kind":
			# rank_values = [quad_rank, kicker]
			return "Four of a Kind of %ss" % [rank_to_name(rank_values[0])]
		
		"Full House":
			# rank_values = [trips_rank, pair_rank]
			return "Full House (%ss over %ss)" % [rank_to_name(rank_values[0]), rank_to_name(rank_values[1])]
		
		"Flush":
			# rank_values are the top 5 cards, in descending order
			# rank_values[0] is the highest card in the flush
			if rank_values[0] == 14:
				return "Ace-high Flush"
			else:
				return "%s-high Flush" % rank_to_name(rank_values[0])
		
		"Straight":
			# rank_values = [top_card]
			if rank_values[0] == 5:
				return "5-high Straight (Ace-low)"
			else:
				return "%s-high Straight" % rank_to_name(rank_values[0])
		
		"Three of a Kind":
			# rank_values = [trip_rank, kicker1, kicker2]
			return "Three of a Kind of %ss" % [
				rank_to_name(rank_values[0])
			]
		
		"Two Pairs":
			# rank_values = [pair1, pair2, kicker]
			return "Two Pairs: %ss and %ss" % [
				rank_to_name(rank_values[0]),
				rank_to_name(rank_values[1])
			]
		
		"Pair":
			# rank_values = [pair_rank, kicker1, kicker2, kicker3]
			var desc = "Pair of %ss" % rank_to_name(rank_values[0])
			return desc
		
		"High Card":
			# rank_values are just the top cards in descending order
			var desc = "High Card %s" % rank_to_name(rank_values[0])
			return desc
		
		_:
			# Fallback if something unexpected
			return hand_rank
