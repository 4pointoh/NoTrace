extends DateScript

const FLAG_ASK_HOBBIES = 'askedHobbies'
const FLAG_ASK_BOYFRIEND = 'askedBoyfriend'
const FLAG_ASK_STUDENT = 'askedStudent'
const FLAG_ASKED_ASKED_BF = 'askedEverBoyfriend'

func scriptId():
	return 'anna_burger_date'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	var completedKeyQuestions = mainQuestionIndex >= 5
	return completedKeyQuestions

func get_alternate_loss_dialogue():
	if mainQuestionIndex < 5:
		return 'need_more_key_question_progress'
	else:
		return null;

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	
	var newBackground : Background = Background.new()
	if scoreProgression <= 30:
		newBackground.images = load("res://data/background_lists/anna_burger/6_d.webp")
		newBackground.name = '3'
	elif scoreProgression <= 50:
		newBackground.images = load("res://data/background_lists/anna_burger/7.webp")
		newBackground.name = '4'
	elif scoreProgression <= 70:
		newBackground.images = load("res://data/background_lists/anna_burger/8.webp")
		newBackground.name = '6'
	elif scoreProgression <= 110:
		newBackground.images = load("res://data/background_lists/anna_burger/9.webp")
		newBackground.name = '7'
	elif scoreProgression <= 130:
		newBackground.images = load("res://data/background_lists/anna_burger/10.webp")
		newBackground.name = '8'
	elif scoreProgression <= 150:
		newBackground.images = load("res://data/background_lists/anna_burger/11.webp")
		newBackground.name = '9'
	else:
		newBackground.images = load("res://data/background_lists/anna_burger/12_end_date.webp")
		newBackground.name = '10'
	
	return newBackground

func get_possible_memory_unlocks():
	var possibleUnlocks = {}

	var progressUnlocks = []
	var questionUnlocks = []

	progressUnlocks.append('ANNA_REST1')
	progressUnlocks.append('ANNA_REST2')
	progressUnlocks.append('ANNA_REST3')
	progressUnlocks.append('ANNA_REST4')

	questionUnlocks.append('ANNA_REST5')
	questionUnlocks.append('ANNA_REST6')

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
	
	result.nextGroup.append(getTopicAction('Free Time',
					DateAction.CATEGORIES.FRIENDLY,
					group_topic1,
					group_topic1_fail,
					'topic_ft',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('About Her',
					DateAction.CATEGORIES.CORE,
					group_topic2,
					group_topic2_fail,
					'topic_ah',
					DateAction.BUTTON_INDEX.BUSINESS))
	
	result.nextGroup.append(getTopicAction("Why Is She Here?",
					DateAction.CATEGORIES.FRIENDLY,
					group_topic3,
					group_topic3_fail,
					'topic_whyshe',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction("Making A Living",
					DateAction.CATEGORIES.FRIENDLY,
					group_topic6,
					group_topic6_fail,
					'topic_makingliving',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('Her Outfit',
					DateAction.CATEGORIES.FLIRTY,
					group_topic4,
					group_topic4_fail,
					'topic_fash',
					DateAction.BUTTON_INDEX.FLIRT,
					true))
	
	result.nextGroup.append(getTopicAction('Personal Life',
					DateAction.CATEGORIES.FLIRTY,
					group_topic5,
					group_topic5_fail,
					'topic_personalife',
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
		result.dialogueStartKey = 'dialogue_ft_common'
	else:
		result.dialogueStartKey = 'dialogue_ft'
		
	result.success = true
	result.scoreProgression = 0
	
	if(!flags.has(FLAG_ASK_HOBBIES)):
		result.nextGroup.append(getPlayerQuestionAction("What occupies your free time?",
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_top1_q1,
								group_ask_top1_q1,
								'group_ask_top1_q1'))
	
	if(flags.has(FLAG_ASK_HOBBIES)):
		result.nextGroup.append(getPlayerQuestionAction("You have six cats?",
								DateAction.CATEGORIES.PERSONAL,
								group_ask_top1_q2,
								group_ask_top1_q2,
								'group_ask_top1_q2'))
		result.nextGroup.append(getPlayerQuestionAction("You sing?",
								DateAction.CATEGORIES.PERSONAL,
								group_ask_top1_q4,
								group_ask_top1_q4,
								'group_ask_top1_q4'))
		result.nextGroup.append(getPartnerQuestionAction('How about you? What are your hobbies?',
								group_ask_top1_q6, 'id_ask_top1_q6'))

	result.nextGroup.append(getPlayerQuestionAction("You don't know what a burger is? What do you eat?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q3,
							group_ask_top1_q3,
							'group_ask_top1_q3'))
	
	result.nextGroup.append(getPlayerQuestionAction("How did you end up at Chad's party?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top1_q5,
							group_ask_top1_q5,
							'group_ask_top1_q5'))
	
	
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
	result.dialogueStartKey = 'ask_free_time'
	result.setFlagToTrue = FLAG_ASK_HOBBIES
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.memoryUnlockId = 'ANNA_REST6'
	return result
	
func group_ask_top1_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_six_cats'
	result.memoryUnlockId = 'ANNA_REST5'
	return result
	
func group_ask_top1_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_burger'
	return result

func group_ask_top1_q4():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_sing'
	return result

func group_ask_top1_q5():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'ask_chad'
	result.success = true
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.scoreProgression = 10
	return result

func group_ask_top1_q6():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_player_hobbies'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("I'm pretty good at poker.",
							group_ask_top1_q6_c1))
	result.nextGroup.append(getChoiceAction("I'm kind of a bum, I don't really do anything.",
							group_ask_top1_q6_c2))
	return result

func group_ask_top1_q6_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_hobbies_poker'
	return result

func group_ask_top1_q6_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_hobbies_bum'
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
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'about_her_common'
	else:
		result.dialogueStartKey = 'about_her'
		
	result.success = true
	result.scoreProgression = 0
		
	result.nextGroup.append(getPartnerQuestionAction('Do you go to school here?',
							group_ask_top2_q1, 'id_partnerask_scool'))
	
	if(flags.has(FLAG_ASK_STUDENT)):
		result.nextGroup.append(getPartnerQuestionAction('What is it like being a college student?',
							group_ask_top2_q2, 'group_ask_top2_q2'))
	
	result.nextGroup.append(getPartnerQuestionAction('What are Chad\'s parties like?',
							group_ask_top2_q3, 'id_partnerask_chad'))
	
	result.nextGroup.append(getPartnerQuestionAction('What other things do you guys do for fun?',
							group_ask_top2_q4, 'id_partnerask_fun'))
	
	result.nextGroup.append(getPartnerQuestionAction('Do you get to eat food like this all the time?',
							group_ask_top2_q5, 'id_partnerask_food'))

	if mainQuestionIndex > 4:
		result.nextGroup.append(getPlayerQuestionAction('You\'re asking so much!',
							DateAction.CATEGORIES.DEEP,
							group_ask_top2_q6,
							group_ask_top2_q6,
							'id_askmuch'))
	
	return result

func group_topic2_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'poker_fail'
	return result

func group_ask_top2_q1():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_school'
	result.setFlagToTrue = FLAG_ASK_STUDENT

	result.nextGroup.append(getChoiceAction("I crave knowledge", group_ask_top2_q1_c1))
	result.nextGroup.append(getChoiceAction("Yeah, but just for the parties", group_ask_top2_q1_c2))
	return result

func group_ask_top2_q1_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'school_great'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_ask_top2_q1_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'school_sucks'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_ask_top2_q2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_college'
	
	result.nextGroup.append(getChoiceAction("So. Much. Homework.", group_ask_top2_q2_c1))
	result.nextGroup.append(getChoiceAction("It's great, AI does all my school work", group_ask_top2_q2_c2))
	result.nextGroup.append(getChoiceAction("I spend my student loans on poker and alcohol", group_ask_top2_q2_c3))
	return result

func group_ask_top2_q2_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'college_blast'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_ask_top2_q2_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'college_drag'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.CONFUSED
	return result

func group_ask_top2_q2_c3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'college_broke'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

func group_ask_top2_q3():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_chad'
	
	result.nextGroup.append(getChoiceAction("Fucking. Incredible.", group_ask_top2_q3_c1))
	result.nextGroup.append(getChoiceAction("Not that great (Lie)", group_ask_top2_q3_c2))
	return result

func group_ask_top2_q3_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'chad_best'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q3_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'chad_worst'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

func group_ask_top2_q4():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_fun'
	
	result.nextGroup.append(getChoiceAction("We play poker", group_ask_top2_q4_c1))
	result.nextGroup.append(getChoiceAction("We play strip poker", group_ask_top2_q4_c2))
	result.nextGroup.append(getChoiceAction("Alcohol", group_ask_top2_q4_c3))
	return result

func group_ask_top2_q4_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'fun_poker'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_ask_top2_q4_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'fun_strip'
	result.setBackground(load("res://data/background_lists/anna_burger/special2.webp"), 'sdfsfd')
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.BLUSH
	return result

func group_ask_top2_q4_c3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'fun_alcohol'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result


func group_ask_top2_q5():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_eat_food'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("This is barely food.", group_ask_top2_q5_c1))
	result.nextGroup.append(getChoiceAction("Oh yeah it's like half my diet", group_ask_top2_q5_c2))
	return result

func group_ask_top2_q5_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'food_bad'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q5_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'food_half'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_top2_q6():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'asking_so_much'
	result.incrementMainQuestionIndex = true
	return result

################################################
#            TOPIC3
################################################
func group_topic3():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'why_she_here'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction("Why are you in Cummington?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top3_q1,
							group_ask_top3_q1,
							'id_cmtn'))

	result.nextGroup.append(getPlayerQuestionAction("Why are we at this restaraunt?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_top3_q2,
							group_ask_top3_q2,
							'id_rest'))
	
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
	result.dialogueStartKey = 'ask_cmtn'
	return result

func group_ask_top3_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_rest'
	return result


################################################
#            TOPIC4 (FLIRT)
################################################
func group_topic4():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_outfit'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction('Why are you always so covered up?',
							DateAction.CATEGORIES.FLIRTY,
							group_ask_top4_q1,
							group_ask_top4_q1,
							'id_covered'))
	
	result.nextGroup.append(getPlayerQuestionAction('Pink is a good color on you.',
							DateAction.CATEGORIES.DEEP,
							group_ask_top4_q2,
							group_ask_top4_q2,
							'id_pink'))
	
	result.nextGroup.append(getPlayerQuestionAction('What are you wearing underneath?',
							DateAction.CATEGORIES.DEEP,
							group_ask_top4_q3,
							group_ask_top4_q3,
							'id_underneaath'))
	
	return result

func group_topic4_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.scoreProgression = 0
	result.dialogueStartKey = 'flirt_fail'
	result.particleType = Heartsplosion.TYPES.BLUSH
	return result

func group_ask_top4_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_covered'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.progressQuantity = 34
	return result

func group_ask_top4_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_pink'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.progressQuantity = 34
	return result

func group_ask_top4_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 0
	result.dialogueStartKey = 'ask_underneath'
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.annoyed = true
	return result


################################################
#            TOPIC5 (FLIRTY)
################################################

func group_topic5():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_personal'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction('Do you have a boyfriend?',
							DateAction.CATEGORIES.FLIRTY,
							group_ask_top5_q1,
							group_ask_top5_q1,
							'id_boyfriend'))
	
	if flags.has(FLAG_ASK_BOYFRIEND):
		result.nextGroup.append(getPlayerQuestionAction('Have you ever had a boyfriend?',
							DateAction.CATEGORIES.FLIRTY,
							group_ask_top5_q2,
							group_ask_top5_q2,
							'id_ever_boyfriend'))	
		result.nextGroup.append(getPartnerQuestionAction('What about you... do you have a girlfriend?',
								group_ask_top5_q4, 'id_partnerask_gf'))
	
	if flags.has(FLAG_ASKED_ASKED_BF):
		result.nextGroup.append(getPartnerQuestionAction('What kind of girls do you like?',
								group_ask_top5_q5, 'id_partnerask_girls_like'))
	
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
	result.dialogueStartKey = 'ask_boyfriend'
	result.setFlagToTrue = FLAG_ASK_BOYFRIEND
	result.particleType = Heartsplosion.TYPES.BLUSH
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.setBackground(load("res://data/background_lists/anna_burger/special1.webp"), 'sdfsfd')
	result.progressQuantity = 34
	return result

func group_ask_top5_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_ever_boyfriend'
	result.particleType = Heartsplosion.TYPES.BLUSH
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 34
	return result

func group_ask_top5_q4():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_gf'
	result.success = true
	result.setFlagToTrue = FLAG_ASKED_ASKED_BF
	
	result.nextGroup.append(getChoiceAction("Totally single", group_ask_top5_q4_c1))
	result.nextGroup.append(getChoiceAction("It's complicated", group_ask_top5_q4_c2))
	return result

func group_ask_top5_q4_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'single_mingle'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.BLUSH
	result.progressQuantity = 34
	return result

func group_ask_top5_q4_c2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'committed'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 34
	return result

func group_ask_top5_q5():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'girls_you_like'
	result.nextGroup.append(getChoiceAction("Talented girls.", group_ask_top5_q5_c1))
	result.nextGroup.append(getChoiceAction("Girls like you.", group_ask_top5_q5_c2))
	result.nextGroup.append(getChoiceAction("Bad girls.", group_ask_top5_q5_c3))

	return result

func group_ask_top5_q5_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'talented'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.progressQuantity = 34
	return result

func group_ask_top5_q5_c2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'girls_like_you'
	result.scoreProgression = 10
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.particleType = Heartsplosion.TYPES.LAUGH
	result.progressQuantity = 34
	return result

func group_ask_top5_q5_c3():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'bad_girls'
	result.scoreProgression = 10
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 34
	return result

################################################
#            TOPIC6
################################################

func group_topic6():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_makingliving'
		
	result.success = true
	result.scoreProgression = 0
	
	result.nextGroup.append(getPlayerQuestionAction('Did you ever go to school?',
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_top6_q1,
							group_ask_top6_q1,
							'id_scoo'))
	
	result.nextGroup.append(getPlayerQuestionAction('Do you have a job?',
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_top6_q2,
							group_ask_top6_q2,
							'id_job'))
	
	result.nextGroup.append(getPlayerQuestionAction('Any aspirations?',
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_top6_q3,
							group_ask_top6_q3,
							'id_aspire'))
	
	result.nextGroup.append(getPartnerQuestionAction('How about you, what do you do for a living?',
								group_ask_top6_q4, 'id_partnerask_living'))
	
	return result

func group_topic6_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'group_ask_top1_fail'
	return result

func group_ask_top6_q1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_scoo'
	return result

func group_ask_top6_q2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_job'
	return result

func group_ask_top6_q3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ask_aspire'
	return result

func group_ask_top6_q4():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'dialogue_player_living'
	
	result.nextGroup.append(getChoiceAction("I'm a professional poker player.",
							group_ask_top6_q4_c1))
	result.nextGroup.append(getChoiceAction("Odds and ends.",
							group_ask_top6_q4_c2))
	result.nextGroup.append(getChoiceAction("Working sucks.",
							group_ask_top6_q4_c3))
	return result


func group_ask_top6_q4_c1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'player_living_poker'
	return result

func group_ask_top6_q4_c2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_living_odds'
	return result

func group_ask_top6_q4_c3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_living_sucks'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result
