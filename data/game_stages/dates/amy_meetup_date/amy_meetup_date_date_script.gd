extends DateScript

# Amy's meetup date: placeholder topics so the whole chain can be clicked through while the real
# content is written. Every answer counts toward the bar (10 each, 100 ends the date). The flirt
# topic opens when the business bar is full, and opening it empties that bar again; each visit
# gives one love answer, and three love answers unlock all three memories. Two business answers
# refill the bar (BUSINESS_STEP), so the best path - two answers, flirt, three times - fits in the
# date and reaches every line.
#
# Every successFunc must only build and return its result: the engine also calls them to look
# ahead when it builds the menus. State changes go through the result (setFlagToTrue,
# incrementMainQuestionIndex).
#
# Pictures come from the meetup's placeholder list, by name. To swap in art, point that entry at
# the new file.

const PICTURES = "res://data/background_lists/amy_meetup/placeholders/amy_meetup_placeholders.tres"
# How far one business answer fills the business bar (it starts at 10; the flirt topic opens at 100).
const BUSINESS_STEP = 45

func scriptId():
	return 'amy_meetup_date'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	return true

func get_alternate_loss_dialogue():
	return null

# The picture for "amy_meetup_" + key in the placeholder list.
func picture(key : String) -> Background:
	for background in load(PICTURES).images:
		if background.name == "amy_meetup_" + key:
			return background
	push_error("Amy's meetup has no picture called amy_meetup_" + key)
	return null

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	if scoreProgression < 30:
		return picture("DATE_START")
	elif scoreProgression < 70:
		return picture("DATE_MID")
	return picture("DATE_END")

func get_possible_memory_unlocks():
	return {
		'progressUnlocks': ['AMY_MEETUP_1', 'AMY_MEETUP_2', 'AMY_MEETUP_3'],
		'questionUnlocks': [],
	}

################################################
#            REPEATED ASK LOGIC
################################################
func repeated_ask(action : DateAction):
	if(not action || not action.id):
		return null

	var id = action.id
	var result = DateActionResult.new()

	if(!action.type == DateAction.TYPES.TOPIC && GlobalGameStage.getCurrentDateAskSuccessCount(id) > 0):
		result.success = false
		result.scoreProgression = 0
		result.dialogueStartKey = 'repeat_generic'
		result.annoyed = true
	elif(!action.type == DateAction.TYPES.TOPIC && GlobalGameStage.getCurrentDateAskFailureCount(id) > 1):
		result.success = false
		result.criticalFailure = true
		result.annoyed = true
		result.scoreProgression = 0
		result.dialogueStartKey = 'asked_too_many_times'
	elif(GlobalGameStage.getDateLastFailure() == id):
		result.success = false
		result.scoreProgression = 0
		result.annoyed = true
		result.dialogueStartKey = 'asked_twice_in_a_row_generic'
	else:
		result = null

	return result

################################################
#            AVAILABLE TOPICS
################################################
func group_topic_select():
	var result = DateActionResult.new()
	result.success = true

	result.nextGroup.append(getTopicAction('About tonight',
					DateAction.CATEGORIES.FRIENDLY,
					group_tonight,
					group_tonight,
					'topic_amymeetup_tonight',
					DateAction.BUTTON_INDEX.TALK))

	result.nextGroup.append(getTopicAction('About the favor',
					DateAction.CATEGORIES.CORE,
					group_favor,
					group_favor,
					'topic_amymeetup_favor',
					DateAction.BUTTON_INDEX.BUSINESS))

	result.nextGroup.append(getTopicAction('About her',
					DateAction.CATEGORIES.FLIRTY,
					group_her,
					group_her,
					'topic_amymeetup_her',
					DateAction.BUTTON_INDEX.FLIRT,
					true))

	result.nextGroup.append(getTopicAction('[Assorted Smalltalk]',
					DateAction.CATEGORIES.SMALL_TALK,
					group_smalltalk,
					group_smalltalk,
					'topic_amymeetup_smalltalk',
					DateAction.BUTTON_INDEX.SMALL_TALK))

	return result

# One answer: its dialogue, counted toward the bar.
func answer(dialogueKey : String, progressType := DateActionResult.DATE_PROGRESS_TYPE.BUSINESS) -> DateActionResult:
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.progressType = progressType
	if progressType == DateActionResult.DATE_PROGRESS_TYPE.BUSINESS:
		result.progressQuantity = BUSINESS_STEP
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = dialogueKey
	return result

# A topic: its opening dialogue, then the questions under it.
func topic(dialogueKey : String) -> DateActionResult:
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = dialogueKey
	return result

################################################
#            TALK: TONIGHT
################################################
func group_tonight():
	var result = topic('topic_tonight')
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Tonight question 1",
							DateAction.CATEGORIES.FRIENDLY, func(): return answer('tonight_q1'), func(): return answer('tonight_q1'), 'amymeetup_tonight_q1'))
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Tonight question 2",
							DateAction.CATEGORIES.FRIENDLY, func(): return answer('tonight_q2'), func(): return answer('tonight_q2'), 'amymeetup_tonight_q2'))
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Tonight question 3",
							DateAction.CATEGORIES.FRIENDLY, func(): return answer('tonight_q3'), func(): return answer('tonight_q3'), 'amymeetup_tonight_q3'))
	return result

################################################
#            BUSINESS: THE FAVOR
################################################
func group_favor():
	var result = topic('topic_favor')
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Favor question 1",
							DateAction.CATEGORIES.CORE, func(): return answer('favor_q1'), func(): return answer('favor_q1'), 'amymeetup_favor_q1'))
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Favor question 2",
							DateAction.CATEGORIES.CORE, func(): return answer('favor_q2'), func(): return answer('favor_q2'), 'amymeetup_favor_q2'))
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Favor question 3",
							DateAction.CATEGORIES.CORE, func(): return answer('favor_q3'), func(): return answer('favor_q3'), 'amymeetup_favor_q3'))
	return result

################################################
#            FLIRT: HER (fills the love bar)
################################################
func group_her():
	var love = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	var result = topic('topic_her')
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Her question 1",
							DateAction.CATEGORIES.FLIRTY, func(): return answer('her_q1', love), func(): return answer('her_q1', love), 'amymeetup_her_q1'))
	result.nextGroup.append(getPlayerQuestionAction("(Placeholder) Her question 2",
							DateAction.CATEGORIES.FLIRTY, func(): return answer('her_q2', love), func(): return answer('her_q2', love), 'amymeetup_her_q2'))
	result.nextGroup.append(getPartnerQuestionAction("(Placeholder) She asks you something", group_her_partner, 'amymeetup_her_partner'))
	return result

func group_her_partner():
	var love = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	var result = topic('her_partner')
	result.nextGroup.append(getChoiceAction("(Placeholder) Answer one way", func(): return answer('her_partner_c1', love)))
	result.nextGroup.append(getChoiceAction("(Placeholder) Answer another way", func(): return answer('her_partner_c2', love)))
	return result

################################################
#            SMALLTALK (can be repeated)
################################################
func group_smalltalk():
	var result = topic('smalltalk_topic')
	result.nextGroup.append(getPlayerQuestionAction('(Placeholder) Small talk',
							DateAction.CATEGORIES.SMALL_TALK, func(): return answer('smalltalk'), func(): return answer('smalltalk'), 'amymeetup_smalltalk'))
	return result
