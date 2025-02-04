extends Node2D

var dateScript : DateScript
var currentResult : DateActionResult

var dateProgress : int
var maxProgress : int = 100 # in the future could make this configurable per date
var loveProgress : int = 10
var businessProgress : int = 10

var unlockedQuestionMemories : Array[String] = []

var firstLoad = true

signal dialogueStart(startKey : String)
signal setWallpaper(background : Background)
signal dateComplete(success : bool, dialogueKey : String)

func initFromGameStage(stage : GameStage):
	dateScript = stage.dateScript.new()
	currentResult = dateScript.start()
	maxProgress = stage.maxProgress;
	dateProgress = 0
	loveProgress = 10
	businessProgress = 10
	setUnlockStatusBadges()
	processResultDialogue()

func processResultDialogue():
	if currentResult.wallpaper:
		setWallpaper.emit(currentResult.wallpaper)
	else:
		setWallpaper.emit(dateScript.getCurrentBackground())
	
	if currentResult.dialogueStartKey:
		$DateMinigameDisplay.hideUi()
		dialogueStart.emit(currentResult.dialogueStartKey)
	else:
		processDialogueComplete()

func processDialogueComplete():
	$DateMinigameDisplay.showUi()
	
	if firstLoad:
		firstLoad = false
		$DateMinigameDisplay.firstLoad()
		
	if currentResult.criticalFailure:
		GlobalGameStage.resetDate()
		processDateComplete(false, null)
	elif dateProgress >= maxProgress:  
		if dateScript.date_was_successful():
			processDateComplete(true, null)
		else:
			processDateComplete(false, dateScript.get_alternate_loss_dialogue())
		GlobalGameStage.resetDate()
	elif $DateMinigameDisplay.isMaximumAnnoyance():
		GlobalGameStage.resetDate()
		processDateComplete(false, null)
	elif currentResult.nextGroup.size() > 0:
		processNextActionOrGroup()
	else:
		currentResult = dateScript.group_topic_select()
		processNextActionOrGroup()

func processNextActionOrGroup():
	# Remove any topics with nothing left in them
	var thisIsATopic = false 
	
	if currentResult.nextGroup.size() > 0:
		thisIsATopic = currentResult.nextGroup[0].type == DateAction.TYPES.TOPIC

	if thisIsATopic:
		currentResult.nextGroup = currentResult.nextGroup.filter(func(action):
			var groupResult = action.successFunc.call()

			# Remove any questions asked by the partner which have already been asked
			var filteredNextGroup = groupResult.nextGroup.filter(func(action2):
				if action2.type == DateAction.TYPES.QUIZ or action2.type == DateAction.TYPES.PARTNER_QUESTION:
					return not GlobalGameStage.hasDatePartnerAsked(action2.id)
				return true
			)

			# If we filtered everything out, go back to topic selection
			if(filteredNextGroup.is_empty()):
				return false

			return true
		)

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

	# If any of the next choices are progress locked, mark it as progress locked
	if thisIsATopic:
		for action in currentResult.nextGroup:
			action.progressLocked = false
			var groupResult = action.successFunc.call()

			for result in groupResult.nextGroup:
				if result.progressLocked:
					action.progressLocked = true
					break
	
	filterActionsToSingleRandomType()
	var nextType = currentResult.nextGroup[0].type

	var allowLoveLocked = false
	if(nextType == DateAction.TYPES.TOPIC):
		if(businessProgress >= 100):
			allowLoveLocked = true
		else:
			allowLoveLocked = false
	else:
		allowLoveLocked = true

	#$DateMinigameDisplay.showBackButton()
	if nextType == DateAction.TYPES.TOPIC:
		$DateMinigameDisplay.showBackButton()
		displayChoices(currentResult.nextGroup, allowLoveLocked)
	elif nextType == DateAction.TYPES.PLAYER_QUESTION:
		$DateMinigameDisplay.showBackButton()
		displayChoices(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.CHOICE:
		displayChoices(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.PARTNER_QUESTION:
		$DateMinigameDisplay.hideBackButton()
		displayDialogueFirst(currentResult.nextGroup)
	elif nextType == DateAction.TYPES.QUIZ:
		$DateMinigameDisplay.hideBackButton()
		displayDialogueFirst(currentResult.nextGroup)

func filterActionsToSingleRandomType():
	var allAvailableActions = currentResult.nextGroup
	var type_map = {}

	# 1. Group all actions by their type without filtering them out.
	for action in allAvailableActions:
		if not type_map.has(action.type):
			type_map[action.type] = []
		type_map[action.type].append(action)
	
	# 2. Determine which types still have *at least one* uncompleted action
	var partially_completed_types = []
	for t in type_map.keys():
		var actions_for_type = type_map[t]
		var has_uncompleted_action = false

		for action in actions_for_type:
			# Check if this action has never been completed before
			if GlobalGameStage.getCurrentDateAskSuccessCount(action.id) == 0:
				has_uncompleted_action = true
				break

		# If there's at least one uncompleted action for this type,
		# we mark it as "partially completed" (i.e., still selectable).
		if has_uncompleted_action:
			partially_completed_types.append(t)

	# 3. Decide which set of types to pick from
	var types_to_pick_from: Array
	# If *no* type has uncompleted actions, all are "fully completed"
	if partially_completed_types.size() == 0:
		# → revert to selecting from all types again
		types_to_pick_from = type_map.keys()
	else:
		# → otherwise, only select from partially-completed types
		types_to_pick_from = partially_completed_types

	# 4. Randomly choose one type from our final pool
	var random_type = types_to_pick_from[randi() % types_to_pick_from.size()]

	# 5. Build the "nextGroup" output array
	var out: Array[DateAction] = []
	out.assign(type_map[random_type])

	# (Optional) Keep logic for ensuring TOPIC type is included if needed.
	# Just be aware that `out.assign(...)` overwrites the array, whereas
	# `out.append_array(...)` will combine them.
	if type_map.has(DateAction.TYPES.TOPIC):
		# If you want to OVERWRITE out with topic actions:
		out.assign(type_map[DateAction.TYPES.TOPIC])

	currentResult.nextGroup = out


func displayDialogueFirst(actionList):
	var randomAction = actionList[randi() % actionList.size()]
	completeAction(randomAction)

func displayChoices(actionList, allowLoveLocked = true):
	$DateMinigameDisplay.setActions(actionList, allowLoveLocked)
	
func updateProgress():
	dateProgress += 10
	$DateMinigameDisplay.setProgress(dateProgress, maxProgress)

func _on_date_minigame_display_option_selected(index):
	var selected_action = currentResult.nextGroup[index]
	GlobalGameStage.setCurrentAsk(selected_action.id)
	completeAction(selected_action)

func completeAction(action : DateAction):
	var repeated_result = dateScript.repeated_ask(action)
	
	# If we already had a success, and its not a topic, skip
	if ((GlobalGameStage.getCurrentDateAskSuccessCount(action.id) == 0) or (action.type == DateAction.TYPES.TOPIC)):
		currentResult = action.successFunc.call()
		if(action.id):
			GlobalGameStage.addDateAsk(action.id, true)
		
		if(action.type != DateAction.TYPES.TOPIC and action.type != DateAction.TYPES.PARTNER_QUESTION):
			if(currentResult.progressType == DateActionResult.DATE_PROGRESS_TYPE.BUSINESS):
				businessProgress += currentResult.progressQuantity
			elif(currentResult.progressType == DateActionResult.DATE_PROGRESS_TYPE.LOVE):
				loveProgress += currentResult.progressQuantity

		if(currentResult.memoryUnlockId):
			unlockedQuestionMemories.append(currentResult.memoryUnlockId)

	# Play the 'repeated result' logic unless it is smalltalk
	elif( repeated_result and action.category != DateAction.CATEGORIES.SMALL_TALK):
		currentResult = repeated_result
		if(action.id):
			GlobalGameStage.addDateAsk(action.id, false)
		
		businessProgress -= 30
	else:
		currentResult = action.failureFunc.call()
		if(action.id):
			GlobalGameStage.addDateAsk(action.id, false)
		
		businessProgress -= 30
	
	if(currentResult.particleType):
		$DateMinigameDisplay.add_particle(currentResult.addParticleRain);
	

	if(action.loveLocked):
		businessProgress = 10

	if(loveProgress < 10):
		loveProgress = 10
	if(businessProgress < 10):
		businessProgress = 10

	if(currentResult.annoyed):
		$DateMinigameDisplay.reduceAnnoyanceBar()
	
	if(currentResult.incrementMainQuestionIndex):
		dateScript.mainQuestionIndex += 1
	
	if(currentResult.setFlagToTrue):
		dateScript.flags.append(currentResult.setFlagToTrue)

	$DateMinigameDisplay.setLoveProgress(loveProgress)
	$DateMinigameDisplay.setBusinessProgress(businessProgress)
	$DateMinigameDisplay.set_particle_count(min(20, round((GlobalGameStage.getDateStorage().currentDateProgressionScore / 10) * 1.2)))
	setUnlockStatusBadges()

	if(currentResult.particleType):
		$DateMinigameDisplay.displayEmoji(currentResult.particleType)
	GlobalGameStage.modifyDateScore(currentResult.scoreProgression)
	
	if(action.type != DateAction.TYPES.TOPIC and action.type != DateAction.TYPES.PARTNER_QUESTION):
		updateProgress()
		if(!currentResult.success):
			$DateMinigameDisplay.playFailSound()
			
	print(str(GlobalGameStage.getDateStorage().currentDateProgressionScore))
	processResultDialogue()

func processDateComplete(success, dialogueKey):
	if(!success):
		dateComplete.emit(success, dialogueKey)
		return
	var unlocks = evaluateMemoryUnlocks()
	$DateMinigameDisplay.showSuccess(unlocks)

	for memory in unlocks.keys():
		if(unlocks[memory]):
			GlobalGameStage.unlockWallpaper(memory)

func evaluateMemoryUnlocks():
	var possibleUnlocks = dateScript.get_possible_memory_unlocks()

	var progressUnlocks = possibleUnlocks['progressUnlocks']
	var questionUnlocks = possibleUnlocks['questionUnlocks']

	var progressNeededPerUnlock = 100 / progressUnlocks.size()

	var unlockThreshold = progressNeededPerUnlock

	var unlockedmemories = []
	for i in range(progressUnlocks.size()):
		if(loveProgress >= unlockThreshold):
			unlockedmemories.append(progressUnlocks[i])
			unlockThreshold += progressNeededPerUnlock
	
	unlockedmemories.append_array(unlockedQuestionMemories)

	var allPossibleUnlocks = progressUnlocks + questionUnlocks
	var finalMemoryUnlocks = {}
	for memory in allPossibleUnlocks:
		if unlockedmemories.has(memory):
			finalMemoryUnlocks[memory] = true
		else:
			finalMemoryUnlocks[memory] = false
	
	# print out the status of all memories
	for memory in finalMemoryUnlocks.keys():
		print(memory + ' : ' + str(finalMemoryUnlocks[memory]))
	
	return finalMemoryUnlocks

func _on_date_minigame_display_proceed_from_complete():
	GlobalGameStage.playParticleEffect(Heartsplosion.TYPES.HAPPY, Heartsplosion.ANIM_TYPE.RAIN)
	await get_tree().create_timer(3).timeout
	dateComplete.emit(true, null)

func setUnlockStatusBadges():
	var talkMemories = [];
	var businessMemories = [];
	var flirtMemories = [];

	for action in dateScript.group_topic_select().nextGroup:
		var groupResult = action.successFunc.call()
		for result2 in groupResult.nextGroup:
			var result = result2.successFunc.call()
			if result.memoryUnlockId != "":
				if action.buttonIndex == DateAction.BUTTON_INDEX.TALK:
					talkMemories.append(result.memoryUnlockId)
				elif action.buttonIndex == DateAction.BUTTON_INDEX.BUSINESS:
					businessMemories.append(result.memoryUnlockId)
				elif action.buttonIndex == DateAction.BUTTON_INDEX.FLIRT:
					flirtMemories.append(result.memoryUnlockId)

	var loveCgsAvailable = false;
	var talkCgsAvailable = false;
	var businessCgsAvailable = false;

	if(loveProgress < 100):
		loveCgsAvailable = true
	else:
		loveCgsAvailable = false

	for memory in talkMemories:
		if !unlockedQuestionMemories.has(memory):
			talkCgsAvailable = true
			break
	
	for memory in businessMemories:
		if !unlockedQuestionMemories.has(memory):
			businessCgsAvailable = true
			break
	
	for memory in flirtMemories:
		if !unlockedQuestionMemories.has(memory):
			loveCgsAvailable = true
			break
	
	$DateMinigameDisplay.setCgsAvailable(loveCgsAvailable, talkCgsAvailable, businessCgsAvailable)

func goBack():
	currentResult = dateScript.group_topic_select()
	processNextActionOrGroup()

func _on_date_minigame_display_go_back():
	goBack()
