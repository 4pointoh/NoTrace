class_name PokerCSVEventEvaluator
extends RefCounted

# Processed node data from CSV
var _nodes: Array[PokerNodeData] = []
var _nodes_by_post_state: Dictionary = {}  # "opp_count,player_count" -> Array[PokerNodeData]
var _already_triggered: Array[String] = []

# Config data for lives threshold lookups
var _opp_stack: Array = []
var _player_stack: Array = []
var _max_lives: int = 0

# Track the number of items lost in the previous check
# This ensures we only trigger events on the specific turn an item is lost
var _last_opp_items_lost: int = 0
var _last_player_items_lost: int = 0


func initialize(config_path: String, csv_path: String) -> void:
	_already_triggered.clear()
	_nodes_by_post_state.clear()
	_last_opp_items_lost = 0
	_last_player_items_lost = 0
	
	# Load config for lives threshold data
	if FileAccess.file_exists(config_path):
		var config = JSON.parse_string(FileAccess.get_file_as_string(config_path))
		if config:
			if config.has("settings") and config.settings.has("max_lives"):
				_max_lives = config.settings.max_lives
			
			# Identify opponent (non-PLAYER participant)
			var opp_id = "OPPONENT"
			for key in config.participants.keys():
				if key != "PLAYER":
					opp_id = key
					break
			
			_opp_stack = config.participants[opp_id].clothing_stack
			_player_stack = config.participants.PLAYER.clothing_stack
	
	# Process CSV using existing processor
	var processor = PokerTimelineProcessor.new()
	_nodes = processor.process(config_path, csv_path)
	
	# Index nodes by post-state for quick lookup during gameplay
	for node in _nodes:
		var key = _get_state_key(node.post_opp_count, node.post_player_count)
		if not _nodes_by_post_state.has(key):
			_nodes_by_post_state[key] = []
		_nodes_by_post_state[key].append(node)


func reset() -> void:
	_already_triggered.clear()
	_last_opp_items_lost = 0
	_last_player_items_lost = 0


func evaluate(poker_info: PokerInfo) -> PokerUpdateActionResult:
	var result = PokerUpdateActionResult.new()
	result.actionResult = PokerUpdateActionResult.ACTION_RESULTS.NOTHING
	
	print("\n--- PokerCSVEventEvaluator: Evaluating ---")
	
	# 1. Calculate current items lost based on live count
	var current_opp_items_lost = _calculate_items_lost_from_lives(poker_info.cpuLives, _opp_stack, "Opponent")
	var current_player_items_lost = _calculate_items_lost_from_lives(poker_info.playerLives, _player_stack, "Player")
	
	print("Items Lost | Prev: Opp %d, Player %d | Curr: Opp %d, Player %d" % [_last_opp_items_lost, _last_player_items_lost, current_opp_items_lost, current_player_items_lost])
	
	# 2. Determine who actually lost an item this turn
	var opp_lost_new_item = current_opp_items_lost > _last_opp_items_lost
	var player_lost_new_item = current_player_items_lost > _last_player_items_lost
	
	# Update history for next time
	_last_opp_items_lost = current_opp_items_lost
	_last_player_items_lost = current_player_items_lost
	
	# If nobody crossed a threshold this specific turn, do nothing.
	# This prevents "Lisa lost Round 1" events playing when "Player loses Round 1" later.
	if not opp_lost_new_item and not player_lost_new_item:
		print("  -> No new items lost this turn. Skipping evaluation.")
		return result

	# 3. Look up nodes for the CURRENT state (post-loss)
	var state_key = _get_state_key(current_opp_items_lost, current_player_items_lost)
	print("  -> New Item Lost! Checking nodes for StateKey: [%s]" % state_key)
	
	if not _nodes_by_post_state.has(state_key):
		print("  -> No nodes found for state key: " + state_key)
		return result
	
	var matching_nodes = _nodes_by_post_state[state_key] as Array
	
	for node in matching_nodes:
		if node.is_start_node or _already_triggered.has(node.row_id):
			continue
		
		# CRITICAL: Only match nodes where the stripper is the person who actually lost the item this turn
		if opp_lost_new_item:
			# If Opponent lost an item, we ONLY want nodes where 'is_opponent_strip' is true
			if not node.is_opponent_strip:
				continue
		elif player_lost_new_item:
			# If Player lost an item, we ONLY want nodes where 'is_opponent_strip' is false (Player strip)
			if node.is_opponent_strip:
				continue
		
		# Found a matching event
		print("  -> MATCH FOUND! Dialogue Key: %s (Row: %s)" % [node.dialogue_key, node.row_id])
		_already_triggered.append(node.row_id)
		
		if node.dialogue_key and not node.dialogue_key.is_empty():
			result.dialogueStartKey = node.dialogue_key
			result.actionResult = PokerUpdateActionResult.ACTION_RESULTS.START_DIALOGUE
			result.shouldPausePoker = true
			result.shouldHidePoker = true
		
		break
	
	return result


func _calculate_items_lost_from_lives(current_lives: int, stack: Array, debug_name: String = "") -> int:
	var items_lost = 0
	# Note: Assuming config uses 'safe at X' logic, so losing requires dropping BELOW or AT threshold depending on config.
	# Based on typical settings:
	# If threshold is 8, and lives are 8 -> Has the item been stripped?
	# User config usually implies: "At 8 lives, you lose the item defined at 8".
	for i in range(stack.size()):
		var item = stack[i]
		var threshold = item.get("lives_threshold", 0)
		if current_lives <= threshold:
			items_lost += 1
	return items_lost


func _get_state_key(opp_count: int, player_count: int) -> String:
	return "%d,%d" % [opp_count, player_count]
