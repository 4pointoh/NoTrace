@tool
extends EditorScript

# A helper function to run a single test comparison
func test_poker_eval(hand1: Array, hand2: Array, expected_winner: String, test_name: String) -> void:
	# hand1 and hand2 should each be an array of 5 card strings, e.g. ["2H", "2D", "3C", "4S", "5D"]
	var result = PokerEval.determine_winner(hand1, hand2)

	# The result[0] is either "Hand 1 wins", "Hand 2 wins", or "It's a tie"
	var actual_winner = result[0]
	var outcome = "PASS"
	
	if actual_winner != expected_winner:
		outcome = "FAIL"
		# Print detailed info if it fails
		printerr("TEST FAILED: %s\n  Hand1: %s => %s\n  Hand2: %s => %s\n  Got: %s, Expected: %s\n"
			% [test_name, str(hand1), str(result[1]), str(hand2), str(result[2]), actual_winner, expected_winner])
	else:
		print("TEST PASSED: %s (winner: %s)" % [test_name, actual_winner])

func _run_tests():
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

func _run():
	_run_tests()

# Called when you run the script from the Editor > File > Run
func _ready():
	_run_tests()
