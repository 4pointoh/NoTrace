@tool
extends EditorScript

# Paths - Update these to match your actual project structure
const CONFIG_PATH = "res://data/game_stages/poker/boa_poker_new_poker/boa_poker_new_poker.json"
const OUTPUT_CSV_PATH = "res://data/game_stages/poker/boa_poker_new_poker/csv/boa_poker_new_poker_generated.csv"

func _run():
	generate_csv()

func generate_csv():
	# 1. Load JSON Configuration
	if not FileAccess.file_exists(CONFIG_PATH):
		print("Error: Config not found at ", CONFIG_PATH)
		return
	
	if FileAccess.file_exists(OUTPUT_CSV_PATH):
		print("Error: output CSV already found at location, exiting to avoid accidental overwrite ", CONFIG_PATH)
		return
		
	var json_text = FileAccess.get_file_as_string(CONFIG_PATH)
	var config = JSON.parse_string(json_text)
	
	if not config:
		print("Error: Invalid JSON")
		return

	# 2. Prepare CSV Content
	var lines = []
	# Header
	lines.append("Row_ID,Trigger_Type,Stripper,Watcher,Event_Item,Stripper_Lost,Watcher_Lost,Condition_Expr,Priority,Dialogue_Key,Tooltip,Starting_Background_Override")
	
	# 3. Iterate The Matrix (Bidirectional)
	var opp_id = "OPPONENT"
	for key in config.participants.keys():
		if key != "PLAYER":
			opp_id = key
			break

	# Scenario A: Opponent loses, Player watches
	if config.participants.has(opp_id) and config.participants.has("PLAYER"):
		_generate_matchup(lines, config, opp_id, "PLAYER")
		_generate_matchup(lines, config, "PLAYER", opp_id)
			
	# 5. Write File
	var file = FileAccess.open(OUTPUT_CSV_PATH, FileAccess.WRITE)
	for line in lines:
		file.store_line(line)
	
	print("Generated CSV at ", OUTPUT_CSV_PATH, " with ", lines.size(), " rows.")

func _generate_matchup(lines: Array, config: Dictionary, actor_id: String, target_id: String):
	var actor_stack = config.participants[actor_id].clothing_stack 
	var target_stack = config.participants[target_id].clothing_stack 

	# -- Loop A: Actor Progression (What triggers the event?) --
	var actor_lost_so_far: Array = []
	
	for i in range(actor_stack.size()):
		var current_item_id = actor_stack[i].id
		actor_lost_so_far.append(current_item_id)
		var req_actor_str = ";".join(actor_lost_so_far)
		
		# -- Loop B: Target Progression (What state are they in?) --
		
		# State 0: Target has lost NOTHING
		_append_row(lines, actor_id, target_id, current_item_id, req_actor_str, [])
		
		# State 1..N: Target loses items sequentially
		var target_lost_so_far: Array = []
		for j in range(target_stack.size()):
			target_lost_so_far.append(target_stack[j].id)
			
			# FIX: If the target has lost their entire stack, the game is already over.
			# We cannot have an event occur VS a fully stripped opponent.
			if target_lost_so_far.size() >= target_stack.size():
				break
				
			_append_row(lines, actor_id, target_id, current_item_id, req_actor_str, target_lost_so_far)

func _append_row(lines: Array, actor: String, target: String, event_item: String, actor_req: String, target_list: Array):
	var target_req_str = "NONE"
	var suffix = target + "_CLOTHED" # Default suffix e.g. PLAYER_CLOTHED
	
	if target_list.size() > 0:
		# For the Logic Column: Keep the full list (SHIRT;PANTS)
		target_req_str = ";".join(target_list)
		
		# For the Naming Suffix: Use only the LAST item (LOST_PANTS)
		var last_item = target_list[-1]
		suffix = target + "_LOST_" + last_item
	
	# naming convention: LISA_LOSE_HAT_VS_PLAYER_LOST_PANTS
	var base_key = "%s_LOSE_%s_VS_%s" % [actor, event_item, suffix]
	
	# CSV Columns:
	# Row_ID, Trigger_Type, Actor, Target, Event_Item, R_Actor, R_Target, Cond, Prio, Key, Tooltip, BG_Override
	var row = "%s,ITEM_LOST,%s,%s,%s,%s,%s,,1,%s,," % [
		base_key, # Row ID
		actor,
		target,
		event_item,
		actor_req,
		target_req_str,
		base_key # Dialogue Key matches Row ID
	]
	
	lines.append(row)
