@tool
extends GraphEdit

const CONFIG_PATH = "res://data/game_stages/poker/boa_poker_new_poker/boa_poker1_config.json"
const CSV_PATH = "res://data/game_stages/poker/boa_poker_new_poker/boa_poker1_generated.csv"

# Storage for connectivity
# Key: "lisa_idx,player_idx" (The state RESULTING from an event)
# Value: Array of GraphNode names that led to this state
var nodes_by_post_state = {}

# Key: "lisa_idx,player_idx" (The state REQUIRED for an event)
# Value: Array of GraphNode names that start at this state
var nodes_by_pre_state = {}

func _ready():
	if not Engine.is_editor_hint():
		generate_graph()

func generate_graph():
	# 1. Cleanup
	clear_connections()
	for child in get_children():
		if child is GraphNode:
			child.queue_free()
	nodes_by_post_state.clear()
	nodes_by_pre_state.clear()
	
	# 2. Load Data
	if not FileAccess.file_exists(CONFIG_PATH) or not FileAccess.file_exists(CSV_PATH):
		print("Missing files.")
		return

	var config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not config: return
	
	# Identify participants
	var opp_id = "OPPONENT"
	for key in config.participants.keys():
		if key != "PLAYER":
			opp_id = key
			break

	var opp_stack = config.participants[opp_id].clothing_stack
	var player_stack = config.participants.PLAYER.clothing_stack
	var opp_stack_size = opp_stack.size()
	var player_stack_size = player_stack.size()

	# 3. Parse CSV and Create Nodes
	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	var header = file.get_csv_line()
	
	# Create START Node
	var start_node = _create_start_node(opp_id, opp_stack, player_stack)
	
	var grouped_rows = {}
	
	while !file.eof_reached():
		var row_values = file.get_csv_line()
		if row_values.size() != header.size(): continue
		
		# Map simplified dict
		var row = {}
		for i in range(header.size()):
			row[header[i]] = row_values[i]
			
		# Group by event state logic
		var key = "%s|%s|%s" % [row["Stripper"], row["Stripper_Lost"], row["Watcher_Lost"]]
		if not grouped_rows.has(key):
			grouped_rows[key] = []
		grouped_rows[key].append(row)
		
	for key in grouped_rows.keys():
		var rows = grouped_rows[key]
		var main_row = rows[0]
		
		# Find priority 1 row
		for r in rows:
			if str(r.get("Priority", "1")) == "1":
				main_row = r
				break
				
		var conditional_count = rows.size() - 1
		_process_csv_row(main_row, opp_id, opp_stack, player_stack, conditional_count)

	# 4. Connect Nodes
	
	# Connect START Node
	if nodes_by_pre_state.has("0,0"):
		var destinations = nodes_by_pre_state["0,0"]
		# We expect typically 2 destinations: Oppponent first loss, Player first loss
		# We want to map them to distinct slots on the Start node for clarity.
		# Start Node Slots:
		# 0: Label
		# 1: Player Output (Cyan)
		# 2: Opponent Output (Pink)
		
		for dest_name in destinations:
			var dest_node = get_node(NodePath(str(dest_name)))
			
			# Identify if this destination is a Player Loss or Opponent Loss
			# We can check the text of its label, or use a metadata/naming convention.
			# But since we built the node, we know the label matches the stripper.
			
			# Crude detection via children labels
			var is_opp_strip = false
			for child in dest_node.get_children():
				if child is Label:
					if child.text.contains("loses"):
						# If label is pink, it's opp. If cyan, it's player.
						if child.modulate == Color(1, 0.4, 0.7): # Pink
							is_opp_strip = true
						break
			
			if is_opp_strip:
				connect_node(start_node.name, 1, dest_name, 0) # Slot 2 (Index 1 of ports?) -> Wait, Slot indices are 0-based index of children
				# In set_slot, we used index 1 and 2.
				# connect_node uses 'port' index.
				# If slot 1 has enabled right port, is that port 0?
				# Godot GraphEdit: "ports are numbered starting from 0... based on the enabled ports"
				# So Slot 1 is Port 0. Slot 2 is Port 1.
				connect_node(start_node.name, 1, dest_name, 0) # Opponent -> Port 1 -> Slot 2
			else:
				connect_node(start_node.name, 0, dest_name, 0) # Player -> Port 0 -> Slot 1

	
	# Connect Events to Next Events
	# Iterate all known "Post States" that we have reached
	for state_key in nodes_by_post_state.keys():
		var sources = nodes_by_post_state[state_key] # Nodes that ended up here
		
		# Do we have subsequent events starting from here?
		if nodes_by_pre_state.has(state_key):
			var destinations = nodes_by_pre_state[state_key]
			
			for src_node in sources:
				for dest_name in destinations:
					# Use helper to determine if destination is Opponent or Player strip
					var dest_node = get_node(NodePath(str(dest_name)))
					var is_opp_strip = _is_opp_strip_node(dest_node)
					
					if is_opp_strip:
						# Connect to Port 1 (Opponent Branch / Slot 4 / Pink)
						connect_node(src_node, 1, dest_name, 0)
					else:
						# Connect to Port 0 (Player Branch / Slot 3 / Cyan)
						connect_node(src_node, 0, dest_name, 0)

func _is_opp_strip_node(node: GraphNode) -> bool:
	if node.has_meta("is_opp"):
		return node.get_meta("is_opp")
		
	# Fallback (mostly for Start Node logic if used there)
	for child in node.get_children():
		if child is Label:
			if child.text.contains("loses"):
				if child.modulate == Color(1, 0.4, 0.7): # Pink color check
					return true
	return false

func _process_csv_row(row: Dictionary, opp_id: String, opp_stack: Array, player_stack: Array, conditional_count: int = 0):
	var opp_max = opp_stack.size()
	var player_max = player_stack.size()
	
	# Calculate Indices based on CSV data
	var opp_lost_count = 0
	var player_lost_count = 0
	
	# Parse state from the semicolon lists in CSV
	# "Stripper_Lost" is the NEW state of the stripper
	# "Watcher_Lost" is the EXISTING state of the watcher
	
	var stripper_items_lost_count = _count_items(row["Stripper_Lost"])
	var watcher_items_lost_count = _count_items(row["Watcher_Lost"])
	
	var pre_opp_count = 0
	var pre_player_count = 0
	var post_opp_count = 0
	var post_player_count = 0
	
	var stripper_is_opp = (row["Stripper"] == opp_id)
	
	if stripper_is_opp:
		post_opp_count = stripper_items_lost_count
		pre_opp_count = stripper_items_lost_count - 1 # Logic: If I lost HAT;TOP (2), I previously lost HAT (1)
		post_player_count = watcher_items_lost_count
		pre_player_count = watcher_items_lost_count
	else:
		post_player_count = stripper_items_lost_count
		pre_player_count = stripper_items_lost_count - 1
		post_opp_count = watcher_items_lost_count
		pre_opp_count = watcher_items_lost_count
		
	# FILTER: Impossible Nodes
	# If the PRE-state implies someone has already lost everything, 
	# this event can never actually trigger in a game (it's a ghost branch).
	if pre_opp_count >= opp_max or pre_player_count >= player_max:
		return 

	# Create Node
	var node = GraphNode.new()
	node.title = row["Row_ID"]
	node.name = "Node_" + str(node.get_instance_id())
	node.set_meta("is_opp", stripper_is_opp)
	
	# visual styling
	var is_game_over = (post_opp_count >= opp_max or post_player_count >= player_max)
	
	# Layout (Pachinko)
	# Use POST state for positioning, so we see where we ended up
	var depth = post_opp_count + post_player_count
	var balance = post_opp_count - post_player_count

	# Refined Positioning
	# We differentiate nodes that land on the SAME state but from DIFFERENT strippers.
	# If Stripper = Opponent (post_opp_count increased), we shift slightly UP (-Y)
	# If Stripper = Player (post_player_count increased), we shift slightly DOWN (+Y)
	# This prevents exact overlap when paths converge.
	
	var micro_offset = -100 if stripper_is_opp else 100
	
	node.position_offset = Vector2(depth * 580, (balance * 400) + micro_offset)
	node.size = Vector2(350, 160)
	
	# Content
	
	# Slot 0: Main Info & Input (no output here anymore)
	var lbl = Label.new()
	lbl.text = "%s loses %s" % [row["Stripper"], row["Event_Item"]]
	if conditional_count > 0:
		lbl.text += "\nHas %d conditional routes" % conditional_count

	if is_game_over:
		lbl.modulate = Color.YELLOW
		lbl.text += "\n(GAME OVER)"
	elif stripper_is_opp:
		lbl.modulate = Color(1, 0.4, 0.7) # Pink
	else:
		lbl.modulate = Color.CYAN
		
	node.add_child(lbl)
	node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	
	# Slot 1: State Info
	var state_lbl = Label.new()
	state_lbl.text = "State: [%d, %d]" % [post_opp_count, post_player_count]
	state_lbl.modulate = Color(0.5, 0.5, 0.5)
	node.add_child(state_lbl)
	node.set_slot(1, false, 0, Color.WHITE, false, 0, Color.WHITE)
	
	# Slots 3 & 4: Distinct Outputs
	if not is_game_over:
		# Output A: Player Branch (Cyan) -> Port 0
		var next_p_item = "item"
		if post_player_count < player_stack.size():
			if player_stack[post_player_count].has("id"):
				next_p_item = player_stack[post_player_count].id
			else:
				next_p_item = "Idx " + str(post_player_count)
				
		var p_out = Label.new()
		p_out.text = "Player loses " + next_p_item
		p_out.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p_out.modulate = Color.CYAN
		node.add_child(p_out)
		node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.CYAN)

		# Output B: Opponent Branch (Pink) -> Port 1
		var next_o_item = "item"
		if post_opp_count < opp_stack.size():
			if opp_stack[post_opp_count].has("id"):
				next_o_item = opp_stack[post_opp_count].id
			else:
				next_o_item = "Idx " + str(post_opp_count)
				
		var o_out = Label.new()
		o_out.text = "%s loses %s" % [opp_id, next_o_item]
		o_out.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		o_out.modulate = Color(1, 0.4, 0.7)
		node.add_child(o_out)
		node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.PINK)

		# Slot 2: Button
		var btn = Button.new()
		btn.text = "Play from here"
		node.add_child(btn)
		node.set_slot(4, false, 0, Color.WHITE, false, 0, Color.WHITE)
	
	add_child(node)
	
	# Register for connections
	var pre_key = "%d,%d" % [pre_opp_count, pre_player_count]
	var post_key = "%d,%d" % [post_opp_count, post_player_count]
	
	if not nodes_by_pre_state.has(pre_key): nodes_by_pre_state[pre_key] = []
	nodes_by_pre_state[pre_key].append(node.name)
	
	if not nodes_by_post_state.has(post_key): nodes_by_post_state[post_key] = []
	nodes_by_post_state[post_key].append(node.name)

func _create_start_node(opp_id: String, opp_stack: Array, player_stack: Array):
	var node = GraphNode.new()
	node.title = "START"
	node.name = "Node_Start"
	node.position_offset = Vector2(0, 0)
	node.size = Vector2(250, 150)
	
	var lbl = Label.new()
	lbl.text = "Everyone Clothed"
	node.add_child(lbl)
	
	# Slot 0: Header (No ports)
	node.set_slot(0, false, 0, Color.WHITE, false, 0, Color.WHITE)
	
	# Slot 1: Output A (Player loses first item) - Blue
	var next_p = "first item"
	if player_stack.size() > 0 and player_stack[0].has("id"):
		next_p = player_stack[0].id
		
	var lbl_p = Label.new()
	lbl_p.text = "Player loses " + next_p
	lbl_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_p.modulate = Color.CYAN
	node.add_child(lbl_p)
	node.set_slot(1, false, 0, Color.WHITE, true, 0, Color.CYAN)
	
	# Slot 2: Output B (Opponent loses first item) - Pink
	var next_o = "first item"
	if opp_stack.size() > 0 and opp_stack[0].has("id"):
		next_o = opp_stack[0].id
		
	var lbl_o = Label.new()
	lbl_o.text = "%s loses %s" % [opp_id, next_o]
	lbl_o.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_o.modulate = Color(1, 0.4, 0.7)
	node.add_child(lbl_o)
	node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.PINK)
	
	add_child(node)
	return node

func _connect_state(state_key, source_node_name, source_port):
	pass # Logic moved to main loop to handle many-to-many

func _count_items(item_str: String) -> int:
	if item_str == "NONE" or item_str.is_empty():
		return 0
	return item_str.split(";").size()
