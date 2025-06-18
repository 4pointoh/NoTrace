extends DateScript

const FLAG_ASKED_GF = 'asked_gf'
const FLAG_ASKED_GF_HOWLONG = 'asked_gf_howlong'
const FLAG_ASKED_GF_WHATLIKE = 'asked_gf_whatlike'

func scriptId():
	return 'lisa_beach_date'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	return true

func get_alternate_loss_dialogue():
	if mainQuestionIndex < 0:
		return 'need_more_key_question_progress'
	else:
		return null

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	
	var newBackground : Background = Background.new()
	if scoreProgression <= 20:
		newBackground.images = load("res://data/background_lists/lisa_beach_date/d06.webp")
		newBackground.name = '3'
	elif scoreProgression <= 30:
		newBackground.images = load("res://data/background_lists/lisa_beach_date/d01.webp")
		newBackground.name = '4'
	elif scoreProgression <= 40:
		newBackground.images = load("res://data/background_lists/lisa_beach_date/d03.webp")
		newBackground.name = '6'
	elif scoreProgression <= 50:
		newBackground.images = load("res://data/background_lists/lisa_beach_date/d04.webp")
		newBackground.name = '8'
	elif scoreProgression <= 70:
		newBackground.images = load("res://data/background_lists/lisa_beach_date/d07.webp")
		newBackground.name = '9'
	else:
		newBackground.images = load("res://data/background_lists/lisa_beach_date/d10.webp")
		newBackground.name = '10'
	
	return newBackground

func get_possible_memory_unlocks():
	var possibleUnlocks = {}

	var progressUnlocks = []
	var questionUnlocks = []

	progressUnlocks.append('LISA_BEACH_1')
	progressUnlocks.append('LISA_BEACH_2')
	progressUnlocks.append('LISA_BEACH_3')

	possibleUnlocks['progressUnlocks'] = progressUnlocks
	possibleUnlocks['questionUnlocks'] = questionUnlocks

	return possibleUnlocks

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
		result.particleType = Heartsplosion.TYPES.ANNOYED
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
	
	result.nextGroup.append(getTopicAction('About Today',
					DateAction.CATEGORIES.FRIENDLY,
					group_topic1,
					group_topic1_fail,
					'topic_lisabeach_today',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('About Her Practice',
					DateAction.CATEGORIES.CORE,
					group_topic2,
					group_topic2_fail,
					'topic_lisabeach_practice',
					DateAction.BUTTON_INDEX.BUSINESS))
	
	result.nextGroup.append(getTopicAction('About Her Girlfriend',
					DateAction.CATEGORIES.FLIRTY,
					group_topic5,
					group_topic5,
					'topic_lisabeach_girlfriend',
					DateAction.BUTTON_INDEX.FLIRT,
					true))
	
	result.nextGroup.append(getTopicAction('[Assorted Smalltalk]',
					DateAction.CATEGORIES.SMALL_TALK,
					group_smalltalk,
					group_smalltalk,
					'topic_lisabeach_smalltalk',
					DateAction.BUTTON_INDEX.SMALL_TALK
					))
					
	return result

################################################
#            TOPIC 1
################################################
func group_topic1():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_ft'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction("'Summer Hits 2019' Playlist'",
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_top1_q1,
							group_ask_top1_q1,
							'group_ask_top1_q1'))
	
	result.nextGroup.append(getPlayerQuestionAction("Ask about the drive.",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q2,
							group_ask_top1_q2,
							'group_ask_top1_q2'))

	result.nextGroup.append(getPlayerQuestionAction("Craving sushi?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q4,
							group_ask_top1_q4,
							'group_ask_top1_q4'))

	result.nextGroup.append(getPartnerQuestionAction('Did you have fun?',
							group_ask_top1_q6, 'id_ask_top1_q6'))

	result.nextGroup.append(getPlayerQuestionAction("Is she even tired at all?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q3,
							group_ask_top1_q3,
							'group_ask_top1_q3'))
	return result
	
func group_topic1_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'group_ask_top1_fail'
	return result

func group_ask_top1_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_summer_hits'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result
	
func group_ask_top1_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_drive'
	return result

func group_ask_top1_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_tired'
	return result

func group_ask_top1_q4():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_sushi'
	return result

func group_ask_top1_q6():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_player_fun'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("I'm going to buy a van and live in the beach parking lot.",
							group_ask_top1_q6_c1))
	result.nextGroup.append(getChoiceAction("Fun? Yes. Sand in my shirt sand-papering my sunburn? Also yes.",
							group_ask_top1_q6_c2))
	return result

func group_ask_top1_q6_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_live_in_van'
	return result

func group_ask_top1_q6_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_sand_nipples'
	return result

################################################
#      PLAYER ASKS - SMALLTALK
################################################
func group_smalltalk_ask():
	var result = DateActionResult.new()
	result.success = true 
	result.dialogueStartKey = 'smalltalk'
	return result

################################################
#            SMALLTALK TOPIC
################################################
func group_smalltalk():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'smalltalk_topic'
	result.success = true
	
	result.nextGroup.append(getPlayerQuestionAction('Talk about this restaurant.',
							DateAction.CATEGORIES.SMALL_TALK,
							group_smalltalk_ask,
							group_smalltalk_ask,
							'id_smalltalk_ask'))
	
	result.nextGroup.append(getPlayerQuestionAction('Talk about the weather.',
							DateAction.CATEGORIES.SMALL_TALK,
							group_smalltalk_ask,
							group_smalltalk_ask,
							'id_smalltalk_ask')) # id so we can increment count
	
	return result


################################################
#            TOPIC2
################################################
func group_topic2():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	result.dialogueStartKey = 'about_practice'
		
	result.success = true
	result.scoreProgression = 0
	
	if mainQuestionIndex == 0:
		result.nextGroup.append(getPlayerQuestionAction('Have you really been practicing that much?',
							DateAction.CATEGORIES.DEEP,
							group_ask_top2_q1,
							group_ask_top2_q1,
							'id_askmuch'))
	elif mainQuestionIndex == 1:
		result.nextGroup.append(getPlayerQuestionAction('Have you played any real matches against other people?',
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top2_q2,
							group_ask_top2_q2,
							'id_practice'))
	elif mainQuestionIndex == 2:
		result.nextGroup.append(getPlayerQuestionAction('Was today a good break from practice?',
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top2_q3,
							group_ask_top2_q3,
							'id_likeit'))
	elif mainQuestionIndex == 3:
		result.nextGroup.append(getPartnerQuestionAction('Do you think we can... do the next step?',
							group_ask_top2_q4, 'id_ask_top2_q4'))
	
	elif mainQuestionIndex == 4:
		result.nextGroup.append(getPartnerQuestionAction('How do we... do it?',
							group_ask_top2_q5, 'id_ask_top2_q5'))

	return result

func group_topic2_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'poker_fail'
	return result

func group_ask_top2_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'id_askmuch'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'id_practice'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'id_likeit'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q4():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_player_next_step'
	result.nextGroup.append(getChoiceAction("Are you ready for that?", group_ask_top2_q4_c1))
	return result

func group_ask_top2_q4_c1():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'id_ready_for_it'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q5():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_player_next_step2'
	result.nextGroup.append(getChoiceAction("Do you want to plan it out first?", group_ask_top2_q5_c1))
	result.nextGroup.append(getChoiceAction("It's just poker but... more exciting.", group_ask_top2_q5_c2))
	return result

func group_ask_top2_q5_c1():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'id_plan_out'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q5_c2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'id_more_exciting'
	result.incrementMainQuestionIndex = true
	return result

################################################
#            TOPIC5 (FLIRTY)
################################################

func group_topic5():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_girlfriend'
		
	result.success = true
	result.scoreProgression = 10

	if !flags.has(FLAG_ASKED_GF):
		result.nextGroup.append(getPartnerQuestionAction('What do you want to ask about?',
							group_ask_top5_q4, 'id_partnerask_gf'))

	else:
		if !flags.has(FLAG_ASKED_GF_WHATLIKE):
			result.nextGroup.append(getPlayerQuestionAction('How long have you been together?',
									DateAction.CATEGORIES.FLIRTY,
									group_ask_top5_q1,
									group_ask_top5_q1,
									'id_ask_howlong_together'))

		if !flags.has(FLAG_ASKED_GF_HOWLONG):
			result.nextGroup.append(getPlayerQuestionAction('What is she like?',
								DateAction.CATEGORIES.FLIRTY,
								group_ask_top5_q2,
								group_ask_top5_q2,
								'id_ask_whatlike'))

	return result

func group_topic5_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'group_ask_top1_fail'
	return result

func group_ask_top5_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'how_long_together'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 34
	result.setFlagToTrue = FLAG_ASKED_GF_WHATLIKE
	return result

func group_ask_top5_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'what_is_she_like'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 34
	result.setFlagToTrue = FLAG_ASKED_GF_HOWLONG
	return result

func group_ask_top5_q4():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'ask_gf_status'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Well... you mention her often", group_ask_top5_q4_c1))
	result.nextGroup.append(getChoiceAction("Everything, I guess? I don't know anything about her", group_ask_top5_q4_c2))
	return result

func group_ask_top5_q4_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'mention_often'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.BLUSH
	result.progressQuantity = 34
	result.setFlagToTrue = FLAG_ASKED_GF
	return result

func group_ask_top5_q4_c2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'everything_i_guess'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 34
	result.setFlagToTrue = FLAG_ASKED_GF
	return result