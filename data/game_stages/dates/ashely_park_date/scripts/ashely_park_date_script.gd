extends DateScript

func scriptId():
	return 'ashely_park_date'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	var completedKeyQuestions = mainQuestionIndex >= 7
	var completedDate = GlobalGameStage.getDateStorage().currentDateProgressionScore > 150
	return completedKeyQuestions && completedDate

func get_alternate_loss_dialogue():
	if mainQuestionIndex < 5:
		return 'need_more_key_question_progress'
	else:
		return null;

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	
	var newBackground : Background = Background.new()
	if scoreProgression <= 40:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/13.png")
		newBackground.name = '2'
	elif scoreProgression <= 60:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/9.png")
		newBackground.name = '3'
	elif scoreProgression <= 80:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/10.png")
		newBackground.name = '4'
	elif scoreProgression <= 100:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/11.png")
		newBackground.name = '5'
	elif scoreProgression <= 120:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/12.png")
		newBackground.name = '6'
	elif scoreProgression <= 140:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/8.png")
		newBackground.name = '7'
	elif scoreProgression <= 160:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/14.png")
		newBackground.name = '8'
	elif scoreProgression <= 180:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/15.png")
		newBackground.name = '9'
	elif scoreProgression <= 200:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/16.png")
		newBackground.name = '10'
	else:
		newBackground.images = load("res://data/background_lists/dates/ashe_park_date/date/17.png")
		newBackground.name = '11'
	
	return newBackground

func get_possible_memory_unlocks():
	var possibleUnlocks = {}

	var progressUnlocks = []
	var questionUnlocks = []

	progressUnlocks.append('ASHEPARK1')
	progressUnlocks.append('ASHEPARK5')
	progressUnlocks.append('ASHEPARK4')

	questionUnlocks.append('ASHEPARK2')
	questionUnlocks.append('ASHEPARK3')

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
	
	result.nextGroup.append(getTopicAction('Ask About Ashely',
					DateAction.CATEGORIES.FRIENDLY,
					group_topic1,
					group_topic1_fail,
					'topic_ashepark_aboutashe',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('Her Poker Scheme',
					DateAction.CATEGORIES.CORE,
					group_topic2,
					group_topic2_fail,
					'topic_ashepark_poker',
					DateAction.BUTTON_INDEX.BUSINESS))
	
	result.nextGroup.append(getTopicAction("Chad's Parties",
					DateAction.CATEGORIES.FRIENDLY,
					group_topic3,
					group_topic3_fail,
					'topic_ashepark_chad',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('You single?',
					DateAction.CATEGORIES.FLIRTY,
					group_topic4,
					group_topic4_fail,
					'topic_ashepark_single',
					DateAction.BUTTON_INDEX.FLIRT,
					true))
	
	result.nextGroup.append(getTopicAction('[Assorted Smalltalk]',
					DateAction.CATEGORIES.SMALL_TALK,
					group_smalltalk,
					group_smalltalk,
					'topic_ashepark_smalltalk',
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
		result.dialogueStartKey = 'dialogue_about_ashe_common'
	else:
		result.dialogueStartKey = 'dialogue_about_ashe'
		
	result.success = true
	result.scoreProgression = 10
	
	result.nextGroup.append(getPlayerQuestionAction("What's with your southern dialect?",
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_southern,
							group_ask_southern_fail,
							'id_ashepark_southern'))
	
	result.nextGroup.append(getPlayerQuestionAction("What's with the white hair?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_hair,
							group_ask_hair_fail,
							'id_ashepark_hair'))
	
	result.nextGroup.append(getPlayerQuestionAction("Any other plans in life besides this poker thing?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_other_plans,
							group_ask_other_plans_fail,
							'id_ashepark_otherplans'))
	
	result.nextGroup.append(getPlayerQuestionAction("It sounds like you walk here often, why is that?",
							DateAction.CATEGORIES.PERSONAL,
							group_ask_whywalk,
							group_ask_whywalk_fail,
							'id_ashepark_whywalk'))
	
	return result
	
func group_topic1_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'about_ashe_fail'
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
# PLAYER ASKS - SOUTHERN
################################################
func group_ask_southern():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_ask_southern_success'
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.addParticleRain = 'heart'
	return result
	
func group_ask_southern_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'player_ask_southern_fail'
	return result

################################################
#      PLAYER ASKS - HAIR
################################################
func group_ask_hair():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_hair'
	result.addParticleRain = 'heart'
	return result
	
func group_ask_hair_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.dialogueStartKey = 'ask_hair_fail'
	return result

################################################
#      PLAYER ASKS - OTHER PLANS
################################################
func group_ask_other_plans():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_otherplans'
	result.addParticleRain = 'heart'
	result.memoryUnlockId = 'ASHEPARK2'
	return result
	
func group_ask_other_plans_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.dialogueStartKey = 'ask_otherplans_fail'
	return result

################################################
#      PLAYER ASKS - WHY WALK
################################################
func group_ask_whywalk():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_whywalk'
	result.addParticleRain = 'heart'
	return result
	
func group_ask_whywalk_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.dialogueStartKey = 'ask_whywalk_fail'
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
#            POKER SCHEME TOPIC
################################################
func group_topic2():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_pokerscheme_common'
	else:
		result.dialogueStartKey = 'dialogue_pokerscheme'
		
	result.success = true
	result.scoreProgression = 10
	
	if(mainQuestionIndex < 2):
		result.nextGroup.append(getPlayerQuestionAction('So, you basically scam people at poker?',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_poker_scam,
								group_ask_poker_scam_fail,
								'id_ashepark_poker_scam'))
		result.nextGroup.append(getPlayerQuestionAction('Is this illegal?',
							DateAction.CATEGORIES.FRIENDLY,
							group_ask_illegal,
							group_ask_illegal_fail,
							'id_ashepark_illegal'))
	elif(mainQuestionIndex < 5):
		result.nextGroup.append(getPlayerQuestionAction("How do you 'build a profile' on your targets?",
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_building_profile,
								group_ask_building_profile_fail,
								'id_ashepark_building_profile'))
		result.nextGroup.append(getPlayerQuestionAction('How do you convince them to play?',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_convince,
								group_ask_convince_fail,
								'id_ashepark_convince'))
		result.nextGroup.append(getPlayerQuestionAction('How much do you make from this?',
								DateAction.CATEGORIES.FRIENDLY,
								group_how_much_ask,
								group_how_much_ask_fail,
								'id_ashepark_how_much'))
	else:
		result.nextGroup.append(getPlayerQuestionAction('What exactly do you need more for?',
								DateAction.CATEGORIES.FRIENDLY,
								group_ask_why_need_me,
								group_ask_why_need_me_fail,
								'id_ashepark_why_need_me'))
		result.nextGroup.append(getPlayerQuestionAction('Do you... seduce them?',
								DateAction.CATEGORIES.FLIRTY,
								group_ask_seduce,
								group_ask_seduce_fail,
								'id_ashepark_seduce'))
							
	result.nextGroup.append(getPartnerQuestionAction('How did you get good at poker?',
							group_partnerask_good_at_poker, 'id_ashepark_partnerask_good_at_poker'))
	
	result.nextGroup.append(getPartnerQuestionAction('Never seen you at the poker halls?',
							group_partnerask_neverseen, 'id_ashepark_partnerask_poker_halls'))

	result.nextGroup.append(getPartnerQuestionAction("Ever play for very high stakes?",
							group_partnerask_high_stakes, 'id_ashepark_partnerask_high_stakes'))

	result.nextGroup.append(getPartnerQuestionAction("Good under pressure?",
							group_partnerask_pressure, 'id_lisamarket_partnerask_always_lived'))
	
	return result

func group_topic2_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'poker_fail'
	return result

func group_ask_poker_scam():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_poker_scam_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_poker_scam_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_poker_scam_fail'
	return result

func group_ask_building_profile():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_building_profile_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_building_profile_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_building_profile_fail'
	return result

func group_how_much_ask():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_how_much_success'
	result.incrementMainQuestionIndex = true
	return result

func group_how_much_ask_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_how_much_fail'
	return result

func group_ask_why_need_me():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_why_need_me_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_why_need_me_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_why_need_me_fail'
	return result

func group_ask_convince():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_convince_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_convince_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_convince_fail'
	return result

func group_ask_illegal():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_illegal_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_illegal_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_illegal_fail'
	return result

func group_ask_seduce():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'ask_seduce_success'
	result.incrementMainQuestionIndex = true
	return result

func group_ask_seduce_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'ask_seduce_fail'
	return result

func group_partnerask_good_at_poker():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_good_at_poker'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("You'll need to convince me to reveal that information.", group_partnerask_good_at_poker_choice1))
	result.nextGroup.append(getChoiceAction("I mean, you only actually saw me play 1 round of poker.", group_partnerask_good_at_poker_choice2))
	return result

func group_partnerask_good_at_poker_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.addParticleRain = 'heart'
	result.dialogueStartKey = 'need_to_convince'
	return result

func group_partnerask_good_at_poker_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'only_saw_one_round'
	return result

func group_partnerask_neverseen():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'never_seen_you_around'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("I mostly play on the down-low", group_partnerask_neverseen_choice1))
	result.nextGroup.append(getChoiceAction("I guess you haven't looked hard enough", group_partnerask_neverseen_choice2))
	result.nextGroup.append(getChoiceAction("I assume we play in different types of places", group_partnerask_neverseen_choice3))
	return result

func group_partnerask_neverseen_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'down_low'
	result.addParticleRain = 'heart'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_partnerask_neverseen_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = -10
	result.dialogueStartKey = 'looked_hard_enough'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_partnerask_neverseen_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = -10
	result.dialogueStartKey = 'different_places'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_partnerask_high_stakes():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_high_stakes'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("I am in crippling debt", group_partnerask_high_stakes_choice1))
	result.nextGroup.append(getChoiceAction("I have bet half my net worth on a hand of poker", group_partnerask_high_stakes_choice2))
	return result

func group_partnerask_high_stakes_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'crippling_debt'
	return result

func group_partnerask_high_stakes_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 20
	result.dialogueStartKey = 'half_net_worth'
	result.addParticleRain = 'laugh'
	result.particleType = Heartsplosion.TYPES.LAUGH
	return result

func group_partnerask_pressure():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_pressure'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Better under pressure than a potato in pressure cooker", group_partnerask_pressure_choice1))
	result.nextGroup.append(getChoiceAction("I don't feel pressure. Pressure is beneath me.", group_partnerask_pressure_choice2))
	result.nextGroup.append(getChoiceAction("One time I got so nervous I shit myself in the middle of a hand", group_partnerask_pressure_choice3))
	return result

func group_partnerask_pressure_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'heart'
	result.dialogueStartKey = 'potato_in_pressure_cooker'
	return result

func group_partnerask_pressure_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'pressure_is_beneath_me'
	return result

func group_partnerask_pressure_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'shit_self'
	return result


################################################
#            CHAD TOPIC
################################################
func group_topic3():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_chad'
		
	result.success = true
	result.scoreProgression = 10
	
	result.nextGroup.append(getPlayerQuestionAction("If you're this big time poker playing rich girl, what were you doing playing at Chad's party?",
							DateAction.CATEGORIES.PERSONAL,
							group_partnerask_why_chad_party,
							group_partnerask_why_chad_party_fail,
							'id_asheparty_whychadparty'))

	result.nextGroup.append(getPlayerQuestionAction("How do you know Chad?",
							DateAction.CATEGORIES.PERSONAL,
							group_chad_go_to_party,
							group_chad_go_to_party_fail,
							'id_ashepark_howknowchad'))
	
	result.nextGroup.append(getPartnerQuestionAction("How did you get an invite to Chad's party?",
							group_chad_party_answer, 'id_ashepark_partnerask_chad_party'))
	
	return result

func group_topic3_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'chad_fail'
	return result

func group_partnerask_why_chad_party():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'why_chad_party_success'
	return result

func group_partnerask_why_chad_party_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'why_chad_party_fail'
	return result

func group_chad_go_to_party():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'go_to_party_success'
	return result

func group_chad_go_to_party_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'go_to_party_fail'
	return result

func group_chad_party_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_chad_party'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("We're just bros, y'know, we go way back", group_chad_party_answer_choice1))
	result.nextGroup.append(getChoiceAction("I do his homework for him for free.", group_chad_party_answer_choice3))
	return result

func group_chad_party_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'chad_bros'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_chad_party_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = -20
	result.dialogueStartKey = 'chad_i_do_his_homework'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

################################################
#            YOU SINGLE?
################################################
func group_topic4():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_single'
		
	result.success = true
	result.scoreProgression = 10
	
	result.nextGroup.append(getPlayerQuestionAction('So.... are you?',
							DateAction.CATEGORIES.FLIRTY,
							group_are_you_single,
							group_are_you_single_fail,
							'id_ashepark_q_single'))
	
	result.nextGroup.append(getPlayerQuestionAction('Do I have a shot?',
							DateAction.CATEGORIES.DEEP,
							group_have_a_shot,
							group_have_a_shot_fail,
							'id_ashepark_q_shot'))
	
	result.nextGroup.append(getPlayerQuestionAction('Would I have a shot if I make you a lot of money?',
							DateAction.CATEGORIES.DEEP,
							group_make_you_money,
							group_make_you_money_fail,
							'id_ashepark_q_money'))
							
	result.nextGroup.append(getPartnerQuestionAction('On a scale of one to ten, to what extent is your reasoning for participating just to get with me?',
							group_partnerask_why_ask, 'id_ashepark_partnerask_why_ask'))
	
	return result

func group_topic4_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.scoreProgression = -10
	result.dialogueStartKey = 'relationships_fail'
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_are_you_single():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'current_relationship_success'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	result.memoryUnlockId = 'ASHEPARK3'
	return result

func group_are_you_single_fail():
	var result = DateActionResult.new()
	result.success = false
	result.scoreProgression = -10
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	result.dialogueStartKey = 'current_relationship_fail'
	return result

func group_partnerask_why_ask():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_your_relationship_status'
	result.success = true
	result.nextGroup.append(getChoiceAction("1", group_partnerask_why_ask_choice1))
	result.nextGroup.append(getChoiceAction("10", group_partnerask_why_ask_choice2))
	result.nextGroup.append(getChoiceAction("Umm, which one means 'yes'?", group_partnerask_why_ask_choice3))
	return result

func group_partnerask_why_ask_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'have_a_shot_1'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	return result

func group_partnerask_why_ask_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = -20
	result.dialogueStartKey = 'have_a_shot_10'
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	return result

func group_partnerask_why_ask_choice3():
	#impossible
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'which_one_yes'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	return result

func group_have_a_shot():
	var result = DateActionResult.new()
	result.success = false
	result.scoreProgression = -30
	result.addParticleRain = 'annoyed'
	result.dialogueStartKey = 'have_a_shot_success'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	return result

func group_have_a_shot_fail():
	var result = DateActionResult.new()
	result.success = false
	result.scoreProgression = -30
	result.addParticleRain = 'annoyed'
	result.dialogueStartKey = 'first_kiss_fail'
	return result

func group_make_you_money():
	#impossible
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'make_you_money'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	return result

func group_make_you_money_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'make_you_money_fail'
	return result
