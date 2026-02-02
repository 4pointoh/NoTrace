class_name NodeDataService
extends Node

static var LISA_PFP = "res://data/characters/lisa/phone_icons/default.png"
static var ANNA_PFP = "res://data/characters/anna/phone_icons/default.png"
static var ASHELY_PFP = "res://data/characters/ashely/phone_icons/default.png"
static var AMY_PFP = "res://data/characters/amy/phone_icons/default.png"
static var PLAYER_PFP = "res://data/characters/you/phone_icon.png"

static func getProfilePicFromName(name: String):
	if name.to_lower() == "lisa":
		return LISA_PFP
	elif name.to_lower() == "anna":
		return ANNA_PFP
	elif name.to_lower() == "ashely":
		return ASHELY_PFP
	elif name.to_lower() == "amy":
		return AMY_PFP
	elif name.to_lower() == "player":
		return PLAYER_PFP
	else:
		return ""

static func getBackgroundListsForNode(gameStage: GameStage):
	return load(gameStage.dialogue.backgroundList)

static func getImagePreviewForDialogueKey(key: String, gameStage: GameStage, backgroundLists: BackgroundLists):
	var dialogue = gameStage.dialogue
	var startNode = dialogue.starts[key]
	var nextNodeKey = dialogue.nodes[startNode].link
	var nextNode = dialogue.nodes[nextNodeKey]
	var relevantBackgroundList = backgroundLists.backgroundLists[nextNode.backgroundList]

	if nextNode.background == -1:
		return getNextNodeWithImage(nextNode, dialogue, backgroundLists)

	var relevantImage = relevantBackgroundList.images[nextNode.background]
	return relevantImage

# If the first node didnt have an image, recursively find the next node that does
static func getNextNodeWithImage(nextNode, dialogue, backgroundLists: BackgroundLists):
	var relevantImage
	if nextNode.options != null and nextNode.options.size() > 0:
		var nextNextNodeKey = nextNode.options[0].link
		var nextNextNode = dialogue.nodes[nextNextNodeKey]

		if nextNextNode.background == -1:
			relevantImage = getNextNodeWithImage(nextNextNode, dialogue, backgroundLists)
		else:
			var relevantBackgroundList = backgroundLists.backgroundLists[nextNextNode.backgroundList]
			relevantImage = relevantBackgroundList.images[nextNextNode.background]
	else: 
		return null

	return relevantImage

static func getCompletionStatus():
	pass
	
