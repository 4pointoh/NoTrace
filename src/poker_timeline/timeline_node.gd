extends GraphNode
class_name TimelineNode

const SLOT_HEADER := 0
const SLOT_PLAYER_OUT := 4 # Port 0 (Cyan)
const SLOT_OPP_OUT := 6    # Port 1 (Pink)

static var backgroundListsCache
static var cacheForStage
var nodeData : PokerNodeData

signal startFromNode(data: PokerNodeData)

func setupFromData(data: PokerNodeData, stage : GameStage) -> void:
	nodeData = data
	%NodeTitle.text = "Partially Complete"
	%WhoLosesWhatLabel.text = data.main_label_text
	%WhoLosesWhatLabel.modulate = data.main_label_color

	setDebugInfo(data)

	%RoundLabel.text = "Round: %d" % data.current_round

	%pfp.texture = load(NodeDataService.getProfilePicFromName(data.stripper_id))

	var nodeColor = Color.WHITE
	if data.is_opponent_strip:
		nodeColor = Color(1, 0.4, 0.7)  # Pink
	else:
		nodeColor = Color.CYAN

	set_slot(SLOT_HEADER, true, 0, nodeColor, false, 0, nodeColor)

	%PlayerLostLabel.text = data.player_branch_label
	%PlayerLostLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	%PlayerLostLabel.modulate = data.player_branch_color
	set_slot(SLOT_PLAYER_OUT, false, 0, Color.WHITE, !data.is_game_over, 0, Color.CYAN)


	%OppLostLabel.text = data.opp_branch_label
	%OppLostLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	%OppLostLabel.modulate = data.opp_branch_color
	position_offset = data.position_offset
	set_slot(SLOT_OPP_OUT, false, 0, Color.WHITE, !data.is_game_over, 0, Color(1, 0.4, 0.7))

	if backgroundListsCache == null or stage != cacheForStage:
		cacheForStage = stage
		backgroundListsCache = NodeDataService.getBackgroundListsForNode(stage)

	var previewImage 
	if data.starting_background_override:
		previewImage = load(data.starting_background_override)
	else:
		previewImage = NodeDataService.getImagePreviewForDialogueKey(data.dialogue_key, stage, backgroundListsCache)
		if previewImage != null:
			previewImage = previewImage.images

	if previewImage != null:
		%Wallpaper.texture = previewImage
	else:
		%Wallpaper.texture = null
		%WpBg.hide()

	for clothingItem in data.player_current_clothes_list:
		var label = getClothingLabel(clothingItem)
		%PlayerClothesContainer.add_child(label)
	
	for clothingItem in data.opponent_current_clothes_list:
		var label = getClothingLabel(clothingItem)
		%OppClothesContainer.add_child(label)

	if data.related_dialogue_keys.size() > 0:
		var alt_route_text = ""
		for tooltip in data.alternate_tooltips:
			alt_route_text += tooltip + "\n"
		%AltRouteHintLabel.text = alt_route_text
	else:
		%AltRoutePositioner.hide()

	var allKeys = []
	allKeys.append_array(data.related_dialogue_keys)
	allKeys.append(data.dialogue_key)

	if hasSeenAllDialogueKeys(allKeys, stage.name):
		get("theme_override_styles/titlebar").set("bg_color", Color.GREEN)
		%NodeTitle.text = 'Scene Seen!'
		%ColorRect.color = Color.GREEN
	elif hasSeenSomeDialogueKeys(allKeys, stage.name):
		get("theme_override_styles/titlebar").set("bg_color", Color.YELLOW)
		%NodeTitle.text = 'Scene Partially Seen'
		%ColorRect.color = Color.YELLOW
	else:
		get("theme_override_styles/titlebar").set("bg_color", Color.RED)
		%ColorRect.color = Color.RED
		%NodeTitle.text = 'Not Seen'
	
		# TODO - Uncomment for full release
		%Wallpaper.texture = load("res://data/assets/phone/art/wallpaper_not_unlocked2.png")

func getClothingLabel(clothingItem: String) -> Label:
	var label = Label.new()
	label.text = clothingItem
	label.set("theme_override_font_sizes/font_size",8)
	return label

func _on_alt_route_hint_button_pressed() -> void:
	%AltRouteHintLabel.show()
	%AltRouteTitle.hide()
	%AltRouteHintButton.hide()

func hasSeenAllDialogueKeys(dialogueKeys, stageName: String = "") -> bool:
	for key in dialogueKeys:
		if !GlobalGameStage.hasSeenDialogueKey(key, stageName):
			return false
	return true

func hasSeenSomeDialogueKeys(dialogueKeys, stageName: String = "") -> bool:
	for key in dialogueKeys:
		if GlobalGameStage.hasSeenDialogueKey(key, stageName):
			return true
	return false


func _on_debug_button_pressed() -> void:
	%DebugPanel.visible = !%DebugPanel.visible

func setDebugInfo(data: PokerNodeData):
	var text = ""
	text += "Dialogue Key: " + data.dialogue_key
	text += "\n"
	text += "Row ID: " + data.row_id
	%DebugText.text = text

func _on_start_from_here_button_pressed() -> void:
	startFromNode.emit(nodeData)
	backgroundListsCache = null

func highlightNode():
	%HighlightPositioner.show()

func hideStartFrom():
	%StartFromHereButton.hide()
