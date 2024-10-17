extends Node2D

var dateScript : DateScript
var currentResult : DateActionResult

var dateProgress : int
var MAX_PROGRESS : int = 100 # in the future could make this configurable per date

var firstLoad = true

signal dialogueStart(startKey : String)
signal setWallpaper(background : Background)
signal dateComplete(success : bool)

func initFromGameStage(stage : GameStage):
	dateScript = stage.dateScript.new()
	currentResult = dateScript.start()
	dateProgress = 0
	processResultDialogue()

func processResultDialogue():
	if currentResult.wallpaper:
		setWallpaper.emit(currentResult.wallpaper)
	else:
		setWallpaper.emit(dateScript.getCurrentBackground())
	
	if currentResult.dialogueStartKey:
		hide()
		dialogueStart.emit(currentResult.dialogueStartKey)
	else:
		processDialogueComplete()

func processDialogueComplete():
	show()
	
	if firstLoad:
		firstLoad = false
		$DateMinigameDisplay.firstLoad()
		
	if currentResult.criticalFailure:
		GlobalGameStage.resetDate()
		processDateComplete(false)
	elif dateProgress >= MAX_PROGRESS:
		if dateScript.date_was_successful():
			processDateComplete(true)
		else:
			processDateComplete(false)
		GlobalGameStage.resetDate()
	elif currentResult.nextGroup.size() > 0:
		processNextActionOrGroup()
	else:
		currentResult = dateScript.group_topic_select()
		processNextActionOrGroup()

func processNextActionOrGroup():
	# Remove any questions asked by the partner which have already been asked
	var filteredGroup = currentResult.nextGroup.filter(func(action):
		if action.type == DateAction.TYPES.QUIZ or action.type == DateAction.TYPES.PARTNER_QUESTION:
			return not GlobalGameStage.hasDatePartnerAsked(action.id)
		return true
	)
	
	# If we filtered everything out, go back to topic selection
	if(filteredGroup.is_empty()):
		currentResult = dateScript.group_topic_select()
	else:
		currentResult.nextGroup = filteredGroup
	
	filterActionsToSingleRandomType()
	var nextType = currentResult.nextGroup[0].type
	
	if nextType == DateAction.TYPES.TOPIC:
		displayChoices(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.PLAYER_QUESTION:
		displayChoices(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.CHOICE:
		displayChoices(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.PARTNER_QUESTION:
		displayDialogueFirst(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.QUIZ:
		displayDialogueFirst(currentResult.nextGroup)

func filterActionsToSingleRandomType():
	var allAvailableActions = currentResult.nextGroup
	var type_map = {}
	
	for action in allAvailableActions:
		if not type_map.has(action.type):
			type_map[action.type] = []
		type_map[action.type].append(action)
	
	var types = type_map.keys()
	
	# Select a random type
	var random_type = types[randi() % types.size()]
	
	var out : Array[DateAction] = []
	out.assign(type_map[random_type])
	
	if type_map.has(DateAction.TYPES.TOPIC):
		out.assign(type_map[DateAction.TYPES.TOPIC])
	
	currentResult.nextGroup = out

func displayDialogueFirst(actionList):
	var randomAction = actionList[randi() % actionList.size()]
	completeAction(randomAction)

func displayChoices(actionList):
	$DateMinigameDisplay.setActions(actionList)
	
func updateProgress():
	dateProgress += 10
	$DateMinigameDisplay.setProgress(dateProgress)

func _on_date_minigame_display_option_selected(index):
	var selected_action = currentResult.nextGroup[index]
	GlobalGameStage.setCurrentAsk(selected_action.id)
	completeAction(selected_action)

func completeAction(action : DateAction):
	var success_chance = action.successChance

	var random_roll = randf() * 100
	
	# Apply repeat-question bonus
	random_roll += GlobalGameStage.getCompleteDateAskFailureCount(action.id) * 5
	
	var repeated_result = dateScript.repeated_ask(action.id)
	
	# If we already had a success, and its not a topic, skip
	if (random_roll < success_chance) and ((GlobalGameStage.getCurrentDateAskSuccessCount(action.id) == 0) or (action.type == DateAction.TYPES.TOPIC)):
		currentResult = action.successFunc.call()
		if(action.id):
			GlobalGameStage.addDateAsk(action.id, true)
	# Play the 'repeated result' logic unless it is smalltalk
	elif( repeated_result and action.category != DateAction.CATEGORIES.SMALL_TALK):
		currentResult = repeated_result
		if(action.id):
			GlobalGameStage.addDateAsk(action.id, false)
	else:
		currentResult = action.failureFunc.call()
		if(action.id):
			GlobalGameStage.addDateAsk(action.id, false)
	
	GlobalGameStage.playParticleEffect(currentResult.particleType, Heartsplosion.ANIM_TYPE.EXPLODE)
	GlobalGameStage.modifyDateScore(currentResult.scoreProgression, currentResult.scoreEntertained, currentResult.scoreHorny)
	
	if(action.type != DateAction.TYPES.TOPIC):
		updateProgress()
		if(!currentResult.success):
			$DateMinigameDisplay.playFailSound()
			
	print(str(GlobalGameStage.getDateStorage().currentDateProgressionScore))
	processResultDialogue()

func processDateComplete(success):
	if(!success):
		dateComplete.emit(success)
		return
	$DateMinigameDisplay.showSuccess()
	GlobalGameStage.playParticleEffect(Heartsplosion.TYPES.PISSED, Heartsplosion.ANIM_TYPE.RAIN)
	await get_tree().create_timer(3).timeout
	dateComplete.emit(success)
