@tool
extends EditorScript

const CONFIG_PATH = "res://data/game_stages/poker/boa_poker_new_poker/boa_poker1_config.json"
const CSV_PATH = "res://data/game_stages/poker/boa_poker_new_poker/boa_poker1_generated.csv"

func _run():
	validate_coverage()

func validate_coverage():
	# 1. Load Data
	if not FileAccess.file_exists(CONFIG_PATH) or not FileAccess.file_exists(CSV_PATH):
		push_error("Files not found.")
		return
		
	var config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var csv_rows = _load_csv_as_dicts(CSV_PATH)
	
	if not config:
		push_error("Invalid JSON config")
		return

	# 2. Iterate Logic Matrix (Bidirectional)
	var errors_found = 0
	var combinations_checked = 0
	
	var opp_id = "OPPONENT"
	for key in config.participants.keys():
		if key != "PLAYER":
			opp_id = key
			break
	
	if config.participants.has(opp_id) and config.participants.has("PLAYER"):
		var r1 = _validate_matchup(config, csv_rows, opp_id, "PLAYER")
		errors_found += r1[0]
		combinations_checked += r1[1]
		
		var r2 = _validate_matchup(config, csv_rows, "PLAYER", opp_id)
		errors_found += r2[0]
		combinations_checked += r2[1]
			
	if errors_found == 0:
		print("SUCCESS: Checked ", combinations_checked, " combinations. No gaps found.")
	else:
		push_error("FAILURE: Found ", errors_found, " missing combinations in CSV.")

func _validate_matchup(config: Dictionary, csv_rows: Array, actor_id: String, target_id: String) -> Array:
	var actor_stack = config.participants[actor_id].clothing_stack 
	var target_stack = config.participants[target_id].clothing_stack 
	
	var errors = 0
	var checked = 0
	
	# -- Loop A: Actor Events --
	var actor_lost_so_far = []
	for i in range(actor_stack.size()):
		var current_item = actor_stack[i].id
		actor_lost_so_far.append(current_item)
		var req_actor_str = ";".join(actor_lost_so_far)
		
		# -- Loop B: Target States --
		# State 0: Target lost nothing
		if not _has_valid_base_row(csv_rows, current_item, req_actor_str, "NONE"):
			_print_missing_error(current_item, req_actor_str, "NONE")
			errors += 1
		checked += 1
		
		# State 1..N: Target lost items
		var target_lost_so_far = []
		for j in range(target_stack.size()):
			target_lost_so_far.append(target_stack[j].id)
			var req_target_str = ";".join(target_lost_so_far)
			
			if not _has_valid_base_row(csv_rows, current_item, req_actor_str, req_target_str):
				_print_missing_error(current_item, req_actor_str, req_target_str)
				errors += 1
			checked += 1
			
	return [errors, checked]

# Helper to scan parsed CSV data
func _has_valid_base_row(rows: Array, event_item: String, actor_req: String, target_req: String) -> bool:
	for row in rows:
		# Check Keys
		if row["Event_Item"] != event_item: continue
		if row["Stripper_Lost"] != actor_req: continue
		if row["Watcher_Lost"] != target_req: continue
		
		# Check Base Condition (Empty condition means it's the default safe route)
		# Or generic Priority 1 check
		if row["Condition_Expr"].strip_edges() == "" or row["Priority"] == "1":
			return true
			
	return false

func _print_missing_error(evt: String, actor: String, target: String):
	print("MISSING ROW: Evt='%s' | StripperState='%s' | WatcherState='%s'" % [evt, actor, target])

# Start simple CSV parser 
func _load_csv_as_dicts(path: String) -> Array:
	var rows = []
	var file = FileAccess.open(path, FileAccess.READ)
	
	# Parse Header to map columns indices
	var header = file.get_csv_line()
	var col_map = {}
	for i in range(header.size()):
		col_map[header[i].strip_edges()] = i
		
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < header.size(): continue
		
		var dict = {}
		dict["Event_Item"] = line[col_map["Event_Item"]]
		dict["Stripper_Lost"] = line[col_map["Stripper_Lost"]]
		dict["Watcher_Lost"] = line[col_map["Watcher_Lost"]]
		dict["Condition_Expr"] = line[col_map.get("Condition_Expr", -1)] if col_map.has("Condition_Expr") else ""
		dict["Priority"] = line[col_map.get("Priority", -1)] if col_map.has("Priority") else "1"
		rows.append(dict)
		
	return rows
