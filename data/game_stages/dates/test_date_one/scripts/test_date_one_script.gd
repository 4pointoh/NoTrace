extends DateScript

func scriptId():
	return 'test_date_one'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	return GlobalGameStage.getDateStorage().currentDateProgressionScore > 50

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	var scoreEntertained = GlobalGameStage.getDateStorage().currentDateEntertainmentScore
	var scoreHorny = GlobalGameStage.getDateStorage().currentDateHornyScore
	
	var newBackground : Background = Background.new()
	if scoreProgression < 20:
		newBackground.images = load("res://data/background_lists/dates/test_date_one/1.png")
		newBackground.name = '1'
	elif scoreProgression < 40:
		newBackground.images = load("res://data/background_lists/dates/test_date_one/2.png")
		newBackground.name = '2'
	elif scoreProgression <= 60:
		newBackground.images = load("res://data/background_lists/dates/test_date_one/3.png")
		newBackground.name = '3'
	elif scoreProgression > 60 and scoreHorny > 10:
		newBackground.images = load("res://data/background_lists/dates/test_date_one/4.png")
		newBackground.name = '4'
	elif scoreProgression > 60:
		newBackground.images = load("res://data/background_lists/dates/test_date_one/5.png")
		newBackground.name = '5'
	
	return newBackground


################################################
#            AVAILABLE TOPICS
################################################
func repeated_ask(action : DateAction):
	if(not action || not action.id):
		return null
	
	var id = action.ids
	
	var result = DateActionResult.new()
	
	if(GlobalGameStage.getCurrentDateAskSuccessCount(id) > 0):
		result.success = false
		result.scoreProgression = -20
		result.dialogueStartKey = 'repeat_generic'
		result.particleType = Heartsplosion.TYPES.ANNOYED
	elif(GlobalGameStage.getCurrentDateAskFailureCount(id) > 1):
		result.success = false
		result.criticalFailure = true
		result.scoreProgression = -20
		result.dialogueStartKey = 'asked_too_many_times'
	elif(id == 'id_firstsex' and GlobalGameStage.getCurrentDateAskFailureCount(id) > 0):
		result.success = false
		result.scoreProgression = -20
		result.dialogueStartKey = 'asked_twice_in_a_row_sex'
	elif(GlobalGameStage.getDateLastFailure() == id):
		result.success = false
		result.scoreProgression = -20
		result.dialogueStartKey = 'asked_twice_in_a_row_generic'
		result.particleType = Heartsplosion.TYPES.ANNOYED
	else:
		result = null
	
	return result

################################################
#            AVAILABLE TOPICS
################################################
func group_topic_select():
	var result = DateActionResult.new()
	result.success = true
	
	result.nextGroup.append(getTopicAction('Past Relationships', 
					DateAction.CATEGORIES.FRIENDLY,
					group_past_relationships,
					group_past_relationships_fail,
					'topic_pastrel',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('[Assorted Smalltalk]', 
					DateAction.CATEGORIES.SMALL_TALK,
					group_smalltalk,
					group_smalltalk,
					'topic_1stdat_smalltalk',
					DateAction.BUTTON_INDEX.SMALL_TALK))
	
	result.nextGroup.append(getTopicAction('Current Relationship (NOT IMPLEMENTED)', 
					DateAction.CATEGORIES.PERSONAL,
					group_current_relationships,
					group_current_relationships_fail,
					'topic_currl',
					DateAction.BUTTON_INDEX.FLIRT))
					
	return result

################################################
#            PAST RELATIONSHIPS TOPIC
################################################
func group_past_relationships():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_past_rel_topic_common'
	else:
		result.dialogueStartKey = 'dialogue_past_rel_topic'
		
	result.success = true
	result.scoreEntertained = 10
	result.scoreProgression = 10
	result.nextGroup.append(getPartnerQuestionAction('Tell me about your past girlfriends?',
							group_past_girlfriends_answer, 'id_partnerask_pastgf'))
	
	result.nextGroup.append(getPartnerQuestionAction('Why are you wondering about my past relationships?',
							group_why_past_relationships_answer, 'id_partnerask_pastrel'))
	
	result.nextGroup.append(getPlayerQuestionAction('Tell me about your past boyfriends?',
							DateAction.CATEGORIES.PERSONAL,
							group_past_boyfriends_question,
							group_past_boyfriends_question_fail,
							'id_pastboyfriends'))
	
	result.nextGroup.append(getPlayerQuestionAction('Whats your body count?',
							DateAction.CATEGORIES.PERSONAL,
							group_body_count_question,
							group_body_count_question_fail,
							'id_bodycount')) # id so we can increment count
	
	result.nextGroup.append(getPlayerQuestionAction('First sex',
							DateAction.CATEGORIES.PERSONAL,
							group_first_sex_question,
							group_first_sex_question_fail,
							'id_firstsex')) # id so we can increment count
	
	result.nextGroup.append(getPlayerQuestionAction('First kiss',
							DateAction.CATEGORIES.PERSONAL,
							group_first_kiss_question,
							group_first_kiss_question_fail,
							'id_firstkiss')) # id so we can increment count
	
	return result
	
func group_past_relationships_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'past_relationships_fail'
	return result


################################################
#            CURRENT RELATIONSHIPS TOPIC
################################################
func group_current_relationships():
	pass

func group_current_relationships_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'current_relationships_fail'
	return result

################################################
#            SMALLTALK TOPIC
################################################
func group_smalltalk():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'smalltalk_topic'
	result.success = true
	
	result.nextGroup.append(getPlayerQuestionAction('Talk about the weather',
							DateAction.CATEGORIES.SMALL_TALK,
							group_smalltalk_ask,
							group_smalltalk_ask,
							'id_smalltalk_ask'))
	
	result.nextGroup.append(getPlayerQuestionAction('Talk about hobbies',
							DateAction.CATEGORIES.SMALL_TALK,
							group_smalltalk_ask,
							group_smalltalk_ask,
							'id_smalltalk_ask')) # id so we can increment count
	
	result.nextGroup.append(getPlayerQuestionAction('Talk about a dream you had last night',
							DateAction.CATEGORIES.SMALL_TALK,
							group_smalltalk_ask,
							group_smalltalk_ask,
							'id_smalltalk_ask')) # id so we can increment count
							
	result.nextGroup.append(getPlayerQuestionAction('Talk about school',
							DateAction.CATEGORIES.SMALL_TALK,
							group_smalltalk_ask,
							group_smalltalk_ask,
							'id_smalltalk_ask')) # id so we can increment count
	
	return result

################################################
#      PARTNER ASKS - PAST GIRLFRIENDS
################################################
func group_past_girlfriends_answer(): 
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_past_girlfriends_q'
	result.success = true
	
	result.nextGroup.append(getChoiceAction('Ive had a lot of girlfriends', group_past_girlfriends_answer_choice1))
	result.nextGroup.append(getChoiceAction('Ive never had a girlfriend', group_past_girlfriends_answer_choice2))
	result.nextGroup.append(getChoiceAction('Id prefer not to answer', group_past_girlfriends_answer_choice3))
	return result
	
func group_past_girlfriends_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 30
	result.dialogueStartKey = 'lots_of_girlfriends'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result
	
func group_past_girlfriends_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = -10
	result.dialogueStartKey = 'no_girlfriends'
	result.particleType = Heartsplosion.TYPES.LAUGH
	return result
	
func group_past_girlfriends_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'no_girlfriends_prefer_not_to_answer'
	return result

################################################
# PARTNER ASKS - WHY ARE YOU WONDERING ABOUT PAST RELATIONSHIPS
################################################
func group_why_past_relationships_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_why_ask_past_q'
	result.success = true
	
	result.nextGroup.append(getChoiceAction('No reason, just some small talk', group_past_rel_answer_choice1))
	result.nextGroup.append(getChoiceAction('The thought of you ever having been with another man makes me want to puke', group_past_rel_answer_choice2))
	result.nextGroup.append(getChoiceAction('Oof, sensitive subject?', group_past_rel_answer_choice3))
	
	return result

func group_past_rel_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'no_reason_for_asking'
	return result

func group_past_rel_answer_choice2():
	var result = DateActionResult.new()
	result.success = false
	result.criticalFailure = true
	result.setBackground(load("res://data/background_lists/dates/test_date_one/6.png"), 'answer2')
	result.dialogueStartKey = 'crazy_jealousy_response'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

func group_past_rel_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = -10
	result.dialogueStartKey = 'past_rel_sensitive_subject'
	return result

################################################
#      PLAYER ASKS - PAST BOYFRIENDS
################################################
func group_past_boyfriends_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'past_boyfriends_success'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result
	
func group_past_boyfriends_question_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'past_boyfriends_fail'
	return result

################################################
#      PLAYER ASKS - BODY COUNT
################################################
func group_body_count_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreHorny = 10
	result.particleType = Heartsplosion.TYPES.HORNY
	result.dialogueStartKey = 'body_count_success'
	result.nextGroup.append(getPartnerQuestionAction('Why are you wondering about my past relationships?',
															group_why_past_relationships_answer,
															'id_partnerask_whyaskrel'))
	return result
	
func group_body_count_question_fail():
	var result = DateActionResult.new()
	result.success = false
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.dialogueStartKey = 'dialogue_body_count_fail'
	return result

################################################
#      PLAYER ASKS - FIRST KISS
################################################
func group_first_kiss_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreHorny = 10
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'first_kiss_success'
	
	return result
	
func group_first_kiss_question_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.dialogueStartKey = 'first_kiss_fail'
	return result

################################################
#      PLAYER ASKS - FIRST SEX
################################################
func group_first_sex_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreHorny = 10
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'first_sex_success'
	return result
	
func group_first_sex_question_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.scoreProgression = -20
	result.scoreHorny = -10
	result.particleType = Heartsplosion.TYPES.PISSED
	result.dialogueStartKey = 'first_sex_fail'
	return result

################################################
#      PLAYER ASKS - SMALLTALK
################################################
func group_smalltalk_ask():
	var result = DateActionResult.new()
	result.success = true 
	result.dialogueStartKey = 'smalltalk'
	return result
