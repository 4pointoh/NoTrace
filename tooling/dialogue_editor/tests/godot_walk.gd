extends SceneTree

# Loads dialogue files with Godot's own ResourceLoader and walks every start the way the game's
# dialogue box does (addons/dialogue_nodes/objects/dialogueBox.gd proceed): a start goes to its
# link, a line to its options' links, a signal and a set to their link, a condition to true and false.
# Checks that every link resolves or is END, that every node reached can still reach END, and that
# each line's speaker, character state, picture list and picture numbers are in range for the file's
# CharacterList and BackgroundLists (as _set_dialogue reads them). Prints one JSON line per file:
#     WALK {"path": ..., "starts": n, "nodes": n, "lines": n, "signals": n, "errors": [...]}
# then "WALK DONE files=N errors=M". Run: godot --headless --path <copy> --script <this> -- <list file> [dump]
# With "dump", each report also has "chains": every start's first path as Godot reads it (ids,
# speakers, text, picture numbers, signal values), for comparing with what the editor wrote.

var dump := false

func _initialize():
	# The copy holds no pictures, so a character's portrait can't load; that's not what this checks.
	ResourceLoader.set_abort_on_missing_resources(false)
	var args = OS.get_cmdline_user_args()
	if args.size() < 1:
		print("WALK DONE files=0 errors=1 (no list file given)")
		quit(2)
		return
	var paths = FileAccess.get_file_as_string(args[0]).split("\n", false)
	dump = args.size() > 1 and args[1] == "dump"
	var total = 0
	for path in paths:
		path = path.strip_edges()
		if path != "":
			total += check_file(path)
	print("WALK DONE files=%d errors=%d" % [paths.size(), total])
	quit(1 if total > 0 else 0)


func check_file(path: String) -> int:
	var report = {"path": path, "starts": 0, "nodes": 0, "lines": 0, "signals": 0, "errors": []}
	var data = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if data == null:
		report["errors"].append("did not load")
		print("WALK " + JSON.stringify(report))
		return 1
	if not ("starts" in data and "nodes" in data):
		report["errors"].append("not a DialogueData resource")
		print("WALK " + JSON.stringify(report))
		return 1
	var characters = null
	if data.characters != "":
		characters = ResourceLoader.load(data.characters)
		if characters == null:
			report["errors"].append("characters did not load: " + data.characters)
	var lists = null
	if data.backgroundList != "":
		lists = ResourceLoader.load(data.backgroundList)
		if lists == null:
			report["errors"].append("background lists did not load: " + data.backgroundList)
	report["starts"] = data.starts.size()
	report["nodes"] = data.nodes.size()
	report["keys"] = []
	if dump:
		report["chains"] = {}
	for key in data.starts:
		report["keys"].append(String(key))
		walk(data, String(key), String(data.starts[key]), characters, lists, report)
		if dump:
			report["chains"][String(key)] = first_path(data, String(data.starts[key]))
	print("WALK " + JSON.stringify(report))
	return report["errors"].size()


# A start's nodes along each node's first link, as Godot holds them after loading the file.
func first_path(data, start_id: String) -> Array:
	var found = []
	var seen = {}
	if not data.nodes.has(start_id):
		return found
	var idx = String(data.nodes[start_id]["link"])
	while idx != "END" and data.nodes.has(idx) and not seen.has(idx) and found.size() < 5000:
		seen[idx] = true
		var node = data.nodes[idx]
		var type = idx.split("_")[0]
		if type == "1":
			found.append({"id": idx, "kind": "line", "speaker": node["speaker"], "text": node["dialogue"],
				"backgroundList": node.get("backgroundList", -1), "background": node.get("background", -1),
				"characterState": node.get("characterState", -1)})
		elif type == "3":
			found.append({"id": idx, "kind": "signal", "value": node["signalValue"]})
		else:
			found.append({"id": idx, "kind": "other"})
		var next = next_of(node, type)
		idx = next[0] if next.size() > 0 else "END"
	return found


func next_of(node: Dictionary, type: String) -> Array:
	match type:
		"0", "3", "4":
			return [String(node["link"])]
		"1":
			var found = []
			for option in node["options"]:
				found.append(String(node["options"][option]["link"]))
			return found
		"5":
			return [String(node["true"]), String(node["false"])]
	if node.has("link"):
		return [String(node["link"])]
	return []


func walk(data, key: String, start_id: String, characters, lists, report):
	var errors = report["errors"]
	if not data.nodes.has(start_id):
		errors.append("%s: start node %s is missing" % [key, start_id])
		return
	var todo = [start_id]
	var seen = {}
	var links = {}
	while todo.size() > 0:
		var idx: String = todo.pop_back()
		if idx == "END" or seen.has(idx):
			continue
		if not data.nodes.has(idx):
			errors.append("%s: a link goes to %s, which is not in the file" % [key, idx])
			continue
		seen[idx] = true
		var node = data.nodes[idx]
		var type = idx.split("_")[0]
		if type == "1":
			report["lines"] += 1
			check_line(key, idx, node, characters, lists, errors)
		elif type == "3":
			report["signals"] += 1
			if not node.has("signalValue") or not (node["signalValue"] is String):
				errors.append("%s: signal %s has no signalValue" % [key, idx])
		var next = next_of(node, type)
		if next.is_empty():
			errors.append("%s: %s leads nowhere" % [key, idx])
		links[idx] = next
		for n in next:
			todo.append(n)
	# Every node reached must still be able to reach END (no loop with no way out).
	var ends = {}
	var changed = true
	while changed:
		changed = false
		for idx in links:
			if ends.has(idx):
				continue
			for n in links[idx]:
				if n == "END" or ends.has(n):
					ends[idx] = true
					changed = true
					break
	for idx in links:
		if not ends.has(idx):
			errors.append("%s: %s never reaches END" % [key, idx])


func check_line(key: String, idx: String, node: Dictionary, characters, lists, errors: Array):
	for field in ["speaker", "dialogue", "options"]:
		if not node.has(field):
			errors.append("%s: line %s has no %s" % [key, idx, field])
			return
	if not (node["dialogue"] is String):
		errors.append("%s: line %s's dialogue is not text" % [key, idx])
	if node["options"].size() == 0:
		errors.append("%s: line %s has no options" % [key, idx])
	var speaker = node["speaker"]
	if speaker is int:
		if characters != null:
			var count = characters.characters.size()
			if speaker < -1 or speaker >= count:
				errors.append("%s: line %s speaker %d is not one of %d characters" % [key, idx, speaker, count])
			elif speaker > -1:
				var state = node.get("characterState", -1)
				var states = characters.characters[speaker].states.size() if characters.characters[speaker] != null else 0
				if state != -1 and (state < 0 or state >= states):
					errors.append("%s: line %s character state %d is not one of %d" % [key, idx, state, states])
	elif not (speaker is String):
		errors.append("%s: line %s speaker is neither a number nor a name" % [key, idx])
	if node.has("backgroundList") and lists != null:
		var bl = node["backgroundList"]
		var count = lists.backgroundLists.size()
		# -1 is allowed: Godot arrays read [-1] as the last one, which is what the game then does.
		if not (bl is int) or bl < -1 or bl >= count:
			errors.append("%s: line %s picture list %s is not one of %d lists" % [key, idx, str(bl), count])
			return
		var list = lists.backgroundLists[bl] if count > 0 else null
		if list == null:
			if count > 0:
				errors.append("%s: line %s picture list %d did not load" % [key, idx, bl])
			return
		var images = list.images
		if node.has("background") and images:
			var bg = node["background"]
			if not (bg is int) or (bg != -1 and (bg < 0 or bg >= images.size())):
				errors.append("%s: line %s picture %s is not one of %d in %s" % [key, idx, str(bg), images.size(), list.name])
