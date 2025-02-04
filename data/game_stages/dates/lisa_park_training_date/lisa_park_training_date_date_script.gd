extends DateScript

const FLAG_ASK_UNBLOCKED = 'askedUnblocked'
const FLAG_ASK_MOTIV = 'askedMotiv'

func scriptId():
	return 'lisa_park_training_date'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	var completedKeyQuestions = mainQuestionIndex >= 5
	var completedDate = GlobalGameStage.getDateStorage().currentDateProgressionScore >= 80
	return completedKeyQuestions && completedDate

func get_alternate_loss_dialogue():
	if mainQuestionIndex < 5:
		return 'need_more_key_question_progress'
	else:
		return null;

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	
	var newBackground : Background = Background.new()
	if scoreProgression <= 20:
		newBackground.images = load("res://data/background_lists/lisa_park_training/lisa_park_training_12_date.png")
		newBackground.name = '2'
	elif scoreProgression <= 40:
		newBackground.images = load("res://data/background_lists/lisa_park_training/lisa_park_training_13_date.png")
		newBackground.name = '3'
	elif scoreProgression <= 50:
		newBackground.images = load("res://data/background_lists/lisa_park_training/lisa_park_training_14_date.png")
		newBackground.name = '4'
	elif scoreProgression <= 70:
		newBackground.images = load("res://data/background_lists/lisa_park_training/lisa_park_training_15_date.png")
		newBackground.name = '5'
	elif scoreProgression <= 90:
		newBackground.images = load("res://data/background_lists/lisa_park_training/lisa_park_training_16_date.png")
		newBackground.name = '6'
	else:
		newBackground.images = load("res://data/background_lists/lisa_park_training/lisa_park_training_17_date.png")
		newBackground.name = '7'
	
	return newBackground

func get_possible_memory_unlocks():
	var possibleUnlocks = {}

	var progressUnlocks = []
	var questionUnlocks = []

	progressUnlocks.append('lisa_training_reward1')
	progressUnlocks.append('lisa_training_reward2')
	progressUnlocks.append('lisa_training_reward3')
	progressUnlocks.append('lisa_training_reward7')

	questionUnlocks.append('lisa_training_reward6')

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
		result.scoreProgression = -30
		result.dialogueStartKey = 'repeat_generic'
		result.particleType = Heartsplosion.TYPES.ANNOYED
		result.annoyed = true
	elif(!action.type == DateAction.TYPES.TOPIC && GlobalGameStage.getCurrentDateAskFailureCount(id) > 1):
		result.success = false
		result.criticalFailure = true
		result.annoyed = true
		result.scoreProgression = -30
		result.dialogueStartKey = 'asked_too_many_times'
	elif(GlobalGameStage.getDateLastFailure() == id):
		result.success = false
		result.scoreProgression = -30
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
	
	result.nextGroup.append(getTopicAction('Strip Poker Refusal',
					DateAction.CATEGORIES.FRIENDLY,
					group_topic1,
					group_topic1_fail,
					'topic_sp_refusal',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('Poker Training',
					DateAction.CATEGORIES.CORE,
					group_topic2,
					group_topic2_fail,
					'topic_pt',
					DateAction.BUTTON_INDEX.BUSINESS))
	
	result.nextGroup.append(getTopicAction("Motivation",
					DateAction.CATEGORIES.FRIENDLY,
					group_topic3,
					group_topic3_fail,
					'topic_motiv',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('Her Workout',
					DateAction.CATEGORIES.FLIRTY,
					group_topic4,
					group_topic4_fail,
					'topic_wkt',
					DateAction.BUTTON_INDEX.FLIRT,
					true))
	
	result.nextGroup.append(getTopicAction('[Assorted Smalltalk]',
					DateAction.CATEGORIES.SMALL_TALK,
					group_smalltalk,
					group_smalltalk,
					'topic_listrn_smalltalk',
					DateAction.BUTTON_INDEX.SMALL_TALK
					))
					
	return result

################################################
#            TOPIC 1
################################################
func group_topic1():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_sp_refusal_common'
	else:
		result.dialogueStartKey = 'dialogue_sp_refusal'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction("Joke about how she blocked you",
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_top1_q1,
							group_ask_top1_q1,
							'group_ask_top1_q1'))
	
	if(flags.has(FLAG_ASK_UNBLOCKED)):
		result.nextGroup.append(getPlayerQuestionAction("Ask how Chad got her to agree to unblock you",
								DateAction.CATEGORIES.PERSONAL,
								group_ask_top1_q2,
								group_ask_top1_q2,
								'group_ask_top1_q2'))
	
	result.nextGroup.append(getPlayerQuestionAction("Is she still opposed to strip poker?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q3,
							group_ask_top1_q3,
							'group_ask_top1_q3'))
	
	result.nextGroup.append(getPlayerQuestionAction("Does she really prefer the slow training route?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q4,
							group_ask_top1_q4,
							'group_ask_top1_q4'))
	
	result.nextGroup.append(getPartnerQuestionAction('Have you ever played it before?',
							group_ask_top1_q5, 'group_ask_top1_q5'))
	
	
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
	result.dialogueStartKey = 'ask_blocked'
	result.setFlagToTrue = FLAG_ASK_UNBLOCKED
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result
	
func group_ask_top1_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_how_chad'
	return result
	
func group_ask_top1_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_still_opposed'
	return result

func group_ask_top1_q4():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_slow_training'
	return result

func group_ask_top1_q5():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_training2'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Never.", group_ask_top1_q5_c1))
	result.nextGroup.append(getChoiceAction("It's actually pretty rare for me to play with my clothes _on_.", group_ask_top1_q5_c2))
	result.nextGroup.append(getChoiceAction("Yes, with Boa at Chad's party right before you talked to me.", group_ask_top1_q5_c3))
	return result

func group_ask_top1_q5_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'neverplaed'
	return result

func group_ask_top1_q5_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'prettyrare'
	return result

func group_ask_top1_q5_c3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'yeswithboa'
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
	
	result.nextGroup.append(getPlayerQuestionAction('Talk about this park.',
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
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 3):
		result.dialogueStartKey = 'poker_training_common'
	else:
		result.dialogueStartKey = 'poker_training'
		
	result.success = true
	result.scoreProgression = 0
	
	if(mainQuestionIndex < 3):
		result.nextGroup.append(getPlayerQuestionAction("When you walk into a room, do you first notice the corners or the center?",
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_top2_q3,
								group_ask_top2_q3,
								'id_cornerorcenter'))
		result.nextGroup.append(getPlayerQuestionAction('If you were a kitchen utensil, would you be a spatula or tongs?',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_top2_q4,
								group_ask_top2_q4,
								'id_spatulaortongs'))
		result.nextGroup.append(getPlayerQuestionAction('Quick - name three types of clouds!',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_top2_q5,
								group_ask_top2_q5,
								'id_clouds'))
							
	elif(mainQuestionIndex < 5):
		result.nextGroup.append(getPlayerQuestionAction('Do you utilize the Amsterdam or Brisbane technique for chip randomization?',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_top2_q2,
								group_ask_top2_q2,
								'id_chiprandom'))
		result.nextGroup.append(getPlayerQuestionAction('When you see a King, do you mentally process it as "K" or "thirteen"?',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_top2_q1,
								group_ask_top2_q1,
								'id_king_mental'))
		
		result.nextGroup.append(getPartnerQuestionAction('What are these questions??',
								group_ask_top2_q6, 'id_partnerask_poker_training'))
	
	
	
	
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
	result.dialogueStartKey = 'ask_king_mental_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_chiprandom_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_cornerorcenter_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q4():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_spatulaortongs_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q5():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_clouds_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q6():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_training'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("These are standard questions.", group_ask_top2_q6_c1))
	result.nextGroup.append(getChoiceAction("These questions are designed to reveal key indicators.", group_ask_top2_q6_c2))
	return result

func group_ask_top2_q6_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'standard_questions'
	return result

func group_ask_top2_q6_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'key_indicators'
	return result


################################################
#            TOPIC3
################################################
func group_topic3():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'motivation'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction("What's your real motivation for learning poker?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top3_q1,
							group_ask_top3_q1,
							'id_realmotiv'))

	result.nextGroup.append(getPlayerQuestionAction("Do you see poker as a way to earn money?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top3_q2,
							group_ask_top3_q2,
							'id_earnmoney'))
	
	if flags.has(FLAG_ASK_MOTIV):
		result.nextGroup.append(getPartnerQuestionAction("What was YOUR motivation for learning poker?",
								group_ask_top3_q3, 'id_partnerask_motivation'))
	
	return result

func group_topic3_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'motivfail'
	return result

func group_ask_top3_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'realmotiv_success'
	result.memoryUnlockId = 'lisa_training_reward6'
	return result

func group_ask_top3_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'earnmoney_success'
	result.setFlagToTrue = FLAG_ASK_MOTIV
	return result

func group_ask_top3_q3():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_motivation'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Money", group_ask_top3_q3_c1))
	result.nextGroup.append(getChoiceAction("It's just so much fun", group_ask_top3_q3_c2))
	result.nextGroup.append(getChoiceAction("Just an excuse to strip girls naked in strip poker.", group_ask_top3_q3_c3))
	return result

func group_ask_top3_q3_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'motivation_money'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_ask_top3_q3_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'motivation_fun'
	return result

func group_ask_top3_q3_c3():
	var result = DateActionResult.new()
	result.criticalFailure = true
	result.scoreProgression = -20
	result.dialogueStartKey = 'motivation_strip'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	result.setBackground(load("res://data/background_lists/lisa_park_training/lisa_park_training_25_poker.png"), 'wtfpoker')
	return result

################################################
#            TOPIC4 (FLIRT)
################################################
func group_topic4():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_flirt'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction('Did you say you ran 27 miles!?',
							DateAction.CATEGORIES.FLIRTY,
							group_ask_top4_q1,
							group_ask_top4_q1,
							'id_twentyseven'))
	
	result.nextGroup.append(getPlayerQuestionAction('I like your leggings.',
							DateAction.CATEGORIES.DEEP,
							group_ask_top4_q2,
							group_ask_top4_q2,
							'id_leggings'))
	
	result.nextGroup.append(getPlayerQuestionAction('Are your boobs inconvenient when running?',
							DateAction.CATEGORIES.DEEP,
							group_ask_top4_q3,
							group_ask_top4_q3,
							'id_boobs'))
							
	result.nextGroup.append(getPartnerQuestionAction('What is your workout of choice?',
							group_ask_top4_q4, 'id_partnerask_workout'))
	
	return result

func group_topic4_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.scoreProgression = -10
	result.dialogueStartKey = 'flirt_fail'
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_ask_top4_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.BLUSH
	result.dialogueStartKey = 'ask_twentyseven'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 50
	return result

func group_ask_top4_q4():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_workout'
	result.success = true
	result.nextGroup.append(getChoiceAction("(Lie) I'm a runner, just like you.", group_ask_top4_q4_c1))
	result.nextGroup.append(getChoiceAction("I stay home and ride on the 🅱️eloton exercise bike", group_ask_top4_q4_c2))
	result.nextGroup.append(getChoiceAction("You know, they say the brain burns more calories than any workout", group_ask_top4_q4_c3))
	return result

func group_ask_top4_q4_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'runner'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.progressQuantity = 0
	return result

func group_ask_top4_q4_c2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'beloton'
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.LAUGH
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 50
	return result

func group_ask_top4_q4_c3():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'brain'
	result.particleType = Heartsplosion.TYPES.CONFUSED
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 10
	return result

func group_ask_top4_q2():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'leggings'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 50
	result.setBackground(load("res://data/background_lists/lisa_park_training/lisa_park_training_reward3.png"), 'leggings2')
	return result

func group_ask_top4_q3():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'boobs'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 10
	result.particleType = Heartsplosion.TYPES.PISSED
	return result
