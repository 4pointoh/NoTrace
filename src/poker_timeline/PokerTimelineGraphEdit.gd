@tool
extends GraphEdit
class_name PokerTimeline

@export var TimelineNodeScene : PackedScene

const CONFIG_PATH = "res://data/game_stages/poker/ashely_bar_poker/ashely_bar_poker_config.json"
const CSV_PATH = "res://data/game_stages/poker/ashely_bar_poker/csv/ashely_bar_poker_generated.csv"

var selectedGameStage : GameStage = load('res://data/game_stages/poker/ashely_bar_poker/gs_ashely_bar_poker.tres')

# GraphNode Slot Constants
const SLOT_HEADER := 0
const SLOT_STATE_INFO := 1
const SLOT_PLAYER_OUT := 2 # Port 0 (Cyan)
const SLOT_OPP_OUT := 3    # Port 1 (Pink)
const SLOT_BUTTON := 4

# Maps node_id -> GraphNode instance for connection lookup
var _node_instances: Dictionary = {}

signal startFromNode(nodeData : PokerNodeData, stage : GameStage)

#func _process(delta: float) -> void:
#	scroll_offset += Vector2(1,1)

func _ready():
	if not Engine.is_editor_hint():
		generate_graph()

func generate_graph():
	# 1. Cleanup
	clear_connections()
	for child in get_children():
		if child is GraphNode:
			child.queue_free()
	_node_instances.clear()
	
	# 2. Process data
	var processor = PokerTimelineProcessor.new()
	var node_datas = processor.process(CONFIG_PATH, CSV_PATH)
	if node_datas.is_empty():
		push_error("No nodes generated from processor")
		return
	
	# 3. Create GraphNode instances from data
	for data in node_datas:
		var node = _create_node_from_data(data)
		add_child(node)
		_node_instances[data.node_id] = node
	# 4. Create connections from pre-computed IDs
	for data in node_datas:
		if data.is_game_over:
			continue
		
		var source_node = _node_instances.get(data.node_id)
		if not source_node:
			continue
		
		# Player loss connections (Port 0 / Cyan)
		for target_id in data.next_player_loss_ids:
			var target_node = _node_instances.get(target_id)
			if target_node:
				connect_node(source_node.name, 0, target_node.name, 0)
		
		# Opponent loss connections (Port 1 / Pink)
		for target_id in data.next_opp_loss_ids:
			var target_node = _node_instances.get(target_id)
			if target_node:
				connect_node(source_node.name, 1, target_node.name, 0)


func _create_node_from_data(data: PokerNodeData) -> GraphNode:
	if data.is_start_node:
		var node = GraphNode.new()
		node.title = data.row_id
		node.name = "Node_" + data.node_id
		node.position_offset = data.position_offset
		node.size = data.size
		node.set_meta("node_data", data)
		node.set_meta("is_opp", data.is_opponent_strip)
		return _setup_start_node(node, data)
	else:
		return _setup_event_node(data)


func _setup_start_node(node: GraphNode, data: PokerNodeData) -> GraphNode:
	# Slot 0: Header label (no ports)
	var lbl = Label.new()
	lbl.text = data.main_label_text
	node.add_child(lbl)
	node.set_slot(SLOT_HEADER, false, 0, Color.WHITE, false, 0, Color.WHITE)
	
	# Slot 1: Output A (Player loses first item) - Blue
	# NOTE: Start node only uses output slots, forcing an index shift compared to event nodes
	# But GraphNode slots match child index. So we must be careful.
	# The original code had specific slots. Let's align with the child count.
	
	# Start Node child structure:
	# 0: Label (Header)
	# 1: Label (Player Out)
	# 2: Label (Opp Out)
	
	var lbl_p = Label.new()
	lbl_p.text = data.player_branch_label
	lbl_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_p.modulate = data.player_branch_color
	node.add_child(lbl_p)
	node.set_slot(1, false, 0, Color.WHITE, true, 0, Color.CYAN)
	
	var lbl_o = Label.new()
	lbl_o.text = data.opp_branch_label
	lbl_o.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_o.modulate = data.opp_branch_color
	node.add_child(lbl_o)
	node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.PINK)
	
	return node


func _setup_event_node(data: PokerNodeData) -> GraphNode:
	var newNode = TimelineNodeScene.instantiate()
	newNode.setupFromData(data)
	newNode.startFromNode.connect(startClicked)

	return newNode

func startClicked(data : PokerNodeData):
	startFromNode.emit(data, selectedGameStage)
