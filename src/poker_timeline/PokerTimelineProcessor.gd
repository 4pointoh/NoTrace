extends RefCounted
class_name PokerTimelineProcessor

# Constants matching original positioning
const NODE_WIDTH := 350
const NODE_HEIGHT := 160
const START_NODE_WIDTH := 250
const START_NODE_HEIGHT := 150
const DEPTH_SPACING := 580
const BALANCE_SPACING := 500
const MICRO_OFFSET := 250

const COLOR_PLAYER := Color.CYAN
const COLOR_OPPONENT := Color(1, 0.4, 0.7)  # Pink
const COLOR_GAME_OVER := Color.YELLOW
const COLOR_STATE := Color(0.5, 0.5, 0.5)

# CSV Headers
const COL_ROW_ID := "Row_ID"
const COL_STRIPPER := "Stripper"
const COL_STRIPPER_LOST := "Stripper_Lost"
const COL_WATCHER_LOST := "Watcher_Lost"
const COL_EVENT_ITEM := "Event_Item"
const COL_PRIORITY := "Priority"
const COL_TOOLTIP := "Tooltip"
const COL_STARTING_BACKGROUND_OVERRIDE := "Starting_Background_Override"
const COL_DIALOGUE_KEY := "Dialogue_Key"


# Processing results
var nodes: Array[PokerNodeData] = []
var nodes_by_id: Dictionary = {}  # node_id -> PokerNodeData
var nodes_by_pre_state: Dictionary = {}   # "opp,player" -> Array[PokerNodeData]
var nodes_by_post_state: Dictionary = {}  # "opp,player" -> Array[PokerNodeData]

# Config data (stored for label generation)
var _opp_id: String = ""
var _opp_stack: Array = []
var _player_stack: Array = []
var _max_lives: int = 0


func process(config_path: String, csv_path: String) -> Array[PokerNodeData]:
	nodes.clear()
	nodes_by_id.clear()
	nodes_by_pre_state.clear()
	nodes_by_post_state.clear()
	
	if not _load_config(config_path):
		return nodes
	
	if not _parse_csv(csv_path):
		return nodes
	
	_compute_connections()
	
	return nodes


func _load_config(config_path: String) -> bool:
	if not FileAccess.file_exists(config_path):
		push_error("Config file not found: " + config_path)
		return false
	
	var config = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if not config:
		push_error("Failed to parse config JSON")
		return false
	
	if config.has("settings") and config.settings.has("max_lives"):
		_max_lives = config.settings.max_lives
	
	# Identify opponent (non-PLAYER participant)
	_opp_id = "OPPONENT"
	for key in config.participants.keys():
		if key != "PLAYER":
			_opp_id = key
			break
	
	_opp_stack = config.participants[_opp_id].clothing_stack
	_player_stack = config.participants.PLAYER.clothing_stack
	
	return true


func _parse_csv(csv_path: String) -> bool:
	if not FileAccess.file_exists(csv_path):
		push_error("CSV file not found: " + csv_path)
		return false
	
	var file = FileAccess.open(csv_path, FileAccess.READ)
	var header = file.get_csv_line()
	
	# Create START node first
	_create_start_node()
	
	# Group rows by event state
	var grouped_rows = {}
	
	while !file.eof_reached():
		var row_values = file.get_csv_line()
		if row_values.size() != header.size():
			continue
		
		var row = {}
		for i in range(header.size()):
			row[header[i]] = row_values[i]
		
		var key = "%s|%s|%s" % [row[COL_STRIPPER], row[COL_STRIPPER_LOST], row[COL_WATCHER_LOST]]
		if not grouped_rows.has(key):
			grouped_rows[key] = []
		grouped_rows[key].append(row)
	
	# Process grouped rows
	for key in grouped_rows.keys():
		var rows = grouped_rows[key]
		var other_rows = []
		var main_row = rows[0]
		
		# Find priority 1 row
		for r in rows:
			if str(r.get(COL_PRIORITY, "1")) == "1":
				main_row = r
			else:
				other_rows.append(r)
		
		var conditional_count = rows.size() - 1
		_process_csv_row(main_row, conditional_count, other_rows)
	
	return true


func _create_start_node() -> void:
	var data = PokerNodeData.new()
	data.row_id = "START"
	data.node_id = "start"
	data.is_start_node = true
	data.is_opponent_strip = false
	data.is_game_over = false
	
	# State: everyone clothed
	data.pre_opp_count = 0
	data.pre_player_count = 0
	data.post_opp_count = 0
	data.post_player_count = 0
	data.current_round = 0
	
	_populate_character_info(data)
	
	# Layout
	data.position_offset = Vector2(0, 0)
	data.size = Vector2(START_NODE_WIDTH, START_NODE_HEIGHT)
	
	# Labels
	data.main_label_text = "Everyone Clothed"
	data.main_label_color = Color.WHITE
	data.state_label_text = ""
	
	# Branch labels
	var next_p = _get_item_name_at_index(_player_stack, 0)
	data.player_branch_label = "Player loses " + next_p
	data.player_branch_color = COLOR_PLAYER
	
	var next_o = _get_item_name_at_index(_opp_stack, 0)
	data.opp_branch_label = "%s loses %s" % [_opp_id, next_o]
	data.opp_branch_color = COLOR_OPPONENT
	
	# Register start node only in post_state (nothing connects TO start)
	nodes.append(data)
	nodes_by_id[data.node_id] = data
	var post_key = _get_state_key(data.post_opp_count, data.post_player_count)
	if not nodes_by_post_state.has(post_key):
		nodes_by_post_state[post_key] = []
	nodes_by_post_state[post_key].append(data)


func _process_csv_row(row: Dictionary, conditional_count: int, related_rows: Array) -> void:
	# 1. State Calculation
	var state = _compute_node_state(row)
	
	# FILTER: Impossible nodes (ghost branches) where someone is already naked before this event
	if state.pre_opp_count >= _opp_stack.size() or state.pre_player_count >= _player_stack.size():
		return
	
	# 2. Initialization
	var data = PokerNodeData.new()
	data.row_id = row[COL_ROW_ID]
	data.node_id = "node_%s_%d_%d" % [row[COL_ROW_ID], state.post_opp_count, state.post_player_count]
	data.is_start_node = false
	data.conditional_count = conditional_count
	data.starting_background_override = row[COL_STARTING_BACKGROUND_OVERRIDE]
	
	data.pre_opp_count = state.pre_opp_count
	data.pre_player_count = state.pre_player_count
	data.post_opp_count = state.post_opp_count
	data.post_player_count = state.post_player_count
	data.current_round = _calculate_current_round(data.post_opp_count, data.post_player_count)
	data.is_opponent_strip = state.stripper_is_opp
	data.dialogue_key = row[COL_DIALOGUE_KEY]

	_populate_character_info(data)

	if conditional_count > 0:
		for r in related_rows:
			data.related_row_ids.append(r[COL_ROW_ID])
			data.alternate_tooltips.append(r[COL_TOOLTIP])
			data.related_dialogue_keys.append(r[COL_DIALOGUE_KEY])
	
	# 3. Game Logic
	# Is this event the final blow?
	var opp_max = _opp_stack.size()
	var player_max = _player_stack.size()
	data.is_game_over = (data.post_opp_count >= opp_max or data.post_player_count >= player_max)
	data.stripper_id = row[COL_STRIPPER]
	data.event_item = row[COL_EVENT_ITEM]
	data.tooltip_text = row[COL_TOOLTIP]
	
	# 4. Layout & Styling
	_apply_layout(data)
	_generate_labels(data)
	
	_register_node(data)


func _compute_node_state(row: Dictionary) -> Dictionary:
	var stripper_items_lost_count = _count_items(row[COL_STRIPPER_LOST])
	var watcher_items_lost_count = _count_items(row[COL_WATCHER_LOST])
	var stripper_is_opp = (row[COL_STRIPPER] == _opp_id)
	
	var result = {
		"stripper_is_opp": stripper_is_opp,
		"pre_opp_count": 0,
		"pre_player_count": 0,
		"post_opp_count": 0,
		"post_player_count": 0
	}
	
	if stripper_is_opp:
		result.post_opp_count = stripper_items_lost_count
		result.pre_opp_count = stripper_items_lost_count - 1
		result.post_player_count = watcher_items_lost_count
		result.pre_player_count = watcher_items_lost_count
	else:
		result.post_player_count = stripper_items_lost_count
		result.pre_player_count = stripper_items_lost_count - 1
		result.post_opp_count = watcher_items_lost_count
		result.pre_opp_count = watcher_items_lost_count
		
	return result


func _apply_layout(data: PokerNodeData) -> void:
	var depth = data.post_opp_count + data.post_player_count
	var balance = data.post_opp_count - data.post_player_count
	
	# Differentiate nodes that land on the same state but from different strippers
	var micro_offset = -MICRO_OFFSET if data.is_opponent_strip else MICRO_OFFSET
	
	data.position_offset = Vector2(depth * DEPTH_SPACING, (balance * BALANCE_SPACING) + micro_offset)
	data.size = Vector2(NODE_WIDTH, NODE_HEIGHT)


func _generate_labels(data: PokerNodeData) -> void:
	# Main label
	data.main_label_text = "%s loses %s" % [data.stripper_id, data.event_item]
		
	if data.is_game_over:
		data.main_label_text += "\n(GAME OVER)"
		data.main_label_color = COLOR_GAME_OVER
	elif data.is_opponent_strip:
		data.main_label_color = COLOR_OPPONENT
	else:
		data.main_label_color = COLOR_PLAYER
	
	# State label (Debug info)
	data.state_label_text = "State: [%d, %d]" % [data.post_opp_count, data.post_player_count]
	
	# Branch labels (only if not game over)
	if not data.is_game_over:
		var next_p_item = _get_item_name_at_index(_player_stack, data.post_player_count)
		data.player_branch_label = "Player loses " + next_p_item
		data.player_branch_color = COLOR_PLAYER
		
		var next_o_item = _get_item_name_at_index(_opp_stack, data.post_opp_count)
		data.opp_branch_label = "%s loses %s" % [_opp_id, next_o_item]
		data.opp_branch_color = COLOR_OPPONENT

func _populate_character_info(data: PokerNodeData) -> void:
	var p_full: Array[String] = []
	for i in range(_player_stack.size()):
		p_full.append(_get_item_name_at_index(_player_stack, i))
	
	var o_full: Array[String] = []
	for i in range(_opp_stack.size()):
		o_full.append(_get_item_name_at_index(_opp_stack, i))
	
	data.player_full_clothes_list = p_full
	data.opponent_full_clothes_list = o_full
	
	data.player_lost_clothes_list = p_full.slice(0, data.post_player_count)
	data.opponent_lost_clothes_list = o_full.slice(0, data.post_opp_count)
	
	data.player_current_clothes_list = p_full.slice(data.post_player_count)
	data.opponent_current_clothes_list = o_full.slice(data.post_opp_count)


func _get_item_name_at_index(stack: Array, index: int) -> String:
	if index < stack.size():
		if stack[index].has("id"):
			return stack[index].id
		else:
			return "Idx " + str(index)
	return "item"


func _register_node(data: PokerNodeData) -> void:
	nodes.append(data)
	nodes_by_id[data.node_id] = data
	
	var pre_key = _get_state_key(data.pre_opp_count, data.pre_player_count)
	var post_key = _get_state_key(data.post_opp_count, data.post_player_count)
	
	if not nodes_by_pre_state.has(pre_key):
		nodes_by_pre_state[pre_key] = []
	nodes_by_pre_state[pre_key].append(data)
	
	if not nodes_by_post_state.has(post_key):
		nodes_by_post_state[post_key] = []
	nodes_by_post_state[post_key].append(data)


func _compute_connections() -> void:
	for data in nodes:
		if data.is_game_over:
			continue
		
		var post_key = _get_state_key(data.post_opp_count, data.post_player_count)
		
		if not nodes_by_pre_state.has(post_key):
			continue
		
		for target in nodes_by_pre_state[post_key]:
			if target.is_opponent_strip:
				data.next_opp_loss_ids.append(target.node_id)
			else:
				data.next_player_loss_ids.append(target.node_id)


func _get_state_key(opp_count: int, player_count: int) -> String:
	return "%d,%d" % [opp_count, player_count]


func _count_items(item_str: String) -> int:
	if item_str == "NONE" or item_str.is_empty():
		return 0
	return item_str.split(";").size()


func _calculate_current_round(post_opp_count: int, post_player_count: int) -> int:
	var opp_loss = _calculate_lives_lost(_opp_stack, post_opp_count)
	var player_loss = _calculate_lives_lost(_player_stack, post_player_count)
	return opp_loss + player_loss


func _calculate_lives_lost(stack: Array, count: int) -> int:
	if count <= 0:
		return 0
	
	# If count exceeds stack, assume max loss (or clamp to last item)
	var index = count - 1
	if index >= stack.size():
		index = stack.size() - 1
	
	var item = stack[index]
	var threshold = 0
	if item.has("lives_threshold"):
		threshold = item.lives_threshold
		
	return _max_lives - threshold
