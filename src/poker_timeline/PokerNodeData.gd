extends RefCounted
class_name PokerNodeData

# Identity
var row_id: String = ""
var node_id: String = ""  # Unique identifier for connections
var dialogue_key: String = ""

# State Information
var pre_opp_count: int = 0
var pre_player_count: int = 0
var post_opp_count: int = 0
var post_player_count: int = 0
var current_round: int = 0

# character info
var player_full_clothes_list: Array[String] = []
var opponent_full_clothes_list: Array[String] = []
var player_lost_clothes_list: Array[String] = []
var opponent_lost_clothes_list: Array[String] = []
var player_current_clothes_list: Array[String] = []
var opponent_current_clothes_list: Array[String] = []

# Display Data
var stripper_id: String = ""
var event_item: String = ""
var is_opponent_strip: bool = false
var is_game_over: bool = false
var is_start_node: bool = false
var conditional_count: int = 0
var tooltip_text: String = ""
var alternate_tooltips: Array[String] = []
var related_row_ids: Array[String] = []
var related_dialogue_keys: Array[String] = []
var starting_background_override: String = ""

# Layout
var position_offset: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2(350, 160)

# Connection References (by node_id)
var next_player_loss_ids: Array[String] = []  # Cyan branch targets
var next_opp_loss_ids: Array[String] = []     # Pink branch targets

# Labels (pre-computed for scene)
var main_label_text: String = ""
var state_label_text: String = ""
var player_branch_label: String = ""
var opp_branch_label: String = ""

# Colors
var main_label_color: Color = Color.WHITE
var player_branch_color: Color = Color.CYAN
var opp_branch_color: Color = Color(1, 0.4, 0.7)  # Pink
