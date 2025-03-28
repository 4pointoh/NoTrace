extends DateScript
const FLAG_ASKED_ABOUT_REL = 'askedAboutRelationships'
const FLAG_ASKED_ABOUT_COLOR = 'askedAboutColor'

func scriptId():
	return 'lisa_market_date'

func start():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'START'
	result.success = true
	return result

func date_was_successful():
	var completedPokerDialgue = mainQuestionIndex == 5
	var completedDate = GlobalGameStage.getDateStorage().currentDateProgressionScore > 150
	return completedPokerDialgue && completedDate

func get_alternate_loss_dialogue():
	if mainQuestionIndex < 5:
		return 'need_more_poker_progress'
	else:
		return null;

func getCurrentBackground():
	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
	
	var newBackground : Background = Background.new()
	if scoreProgression <= 30:
		newBackground.images = load("res://data/background_lists/lisa_market_new/10.png")
		newBackground.name = '2'
	elif scoreProgression <= 60:
		newBackground.images = load("res://data/background_lists/lisa_market_new/11.png")
		newBackground.name = '3'
	elif scoreProgression <= 90:
		newBackground.images = load("res://data/background_lists/lisa_market_new/12.png")
		newBackground.name = '4'
	elif scoreProgression <= 140:
		newBackground.images = load("res://data/background_lists/lisa_market_new/13.png")
		newBackground.name = '5'
	elif scoreProgression <= 180:
		newBackground.images = load("res://data/background_lists/lisa_market_new/14.png")
		newBackground.name = '7'
	elif scoreProgression <= 220:
		newBackground.images = load("res://data/background_lists/lisa_market_new/15.png")
		newBackground.name = '9'
	else:
		newBackground.images = load("res://data/background_lists/lisa_market_new/17.png")
		newBackground.name = '10'
	
	return newBackground

func get_possible_memory_unlocks():
	var possibleUnlocks = {}

	var progressUnlocks = []
	var questionUnlocks = []

	progressUnlocks.append('LISA_MARKET_REW_2')
	progressUnlocks.append('LISA_MARKET_REW_3')

	questionUnlocks.append('LISA_MARKET_REW_1')

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
		result.annoyed = true
		result.particleType = Heartsplosion.TYPES.ANNOYED
	elif(!action.type == DateAction.TYPES.TOPIC && GlobalGameStage.getCurrentDateAskFailureCount(id) > 1):
		result.success = false
		result.criticalFailure = true
		result.scoreProgression = 0
		result.annoyed = true
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
	
	result.nextGroup.append(getTopicAction('Ask About Lisa',
					DateAction.CATEGORIES.FRIENDLY,
					group_about_lisa,
					group_about_lisa_fail,
					'topic_lisamarket_aboutlisa',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('Poker',
					DateAction.CATEGORIES.CORE,
					group_poker,
					group_poker_fail,
					'topic_lisamrket_poker',
					DateAction.BUTTON_INDEX.BUSINESS))
	
	result.nextGroup.append(getTopicAction('The City of Cummington',
					DateAction.CATEGORIES.FRIENDLY,
					group_cummington,
					group_cummington_fail,
					'topic_lisamarket_cummington',
					DateAction.BUTTON_INDEX.TALK))
					
	result.nextGroup.append(getTopicAction('Chad',
					DateAction.CATEGORIES.PERSONAL,
					group_chad,
					group_chad_fail,
					'topic_lisamarket_chad',
					DateAction.BUTTON_INDEX.TALK))
	
	result.nextGroup.append(getTopicAction('Flirt',
					DateAction.CATEGORIES.FLIRTY,
					group_relationships,
					group_relationships_fail,
					'topic_lisamarket_relationships',
					DateAction.BUTTON_INDEX.FLIRT,
					true))
	
	result.nextGroup.append(getTopicAction('[Assorted Smalltalk]', 
					DateAction.CATEGORIES.SMALL_TALK,
					group_smalltalk,
					group_smalltalk,
					'topic_lisamarket_smalltalk',
					DateAction.BUTTON_INDEX.SMALL_TALK))
					
	return result

################################################
#            ABOUT LISA TOPIC
################################################
func group_about_lisa():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_about_lisa_common'
	else:
		result.dialogueStartKey = 'dialogue_about_lisa'
		
	result.success = true
	result.scoreProgression = 10
	result.nextGroup.append(getPartnerQuestionAction('Why are you so interested in my interests?',
							group_why_interest_in_lisa_answer, 'id_lisamarket_partnerask_favcolor'))
	
	result.nextGroup.append(getPlayerQuestionAction('What is your favorite color?',
							DateAction.CATEGORIES.FRIENDLY,
							group_favorite_color_question,
							group_favorite_color_question_fail,
							'id_lisamarket_q_favcolor'))
	
	result.nextGroup.append(getPlayerQuestionAction('How old are you?',
							DateAction.CATEGORIES.PERSONAL,
							group_how_old_question,
							group_how_old_question_fail,
							'id_lisamarket_q_howold'))
	
	if(flags.has(FLAG_ASKED_ABOUT_COLOR)):
		result.nextGroup.append(getPartnerQuestionAction('Do you remember my favorite color?',
							group_remember_favorite_color_answer, 'id_lisamarket_partnerask_favcolor_rem'))

	return result
	
func group_about_lisa_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'about_lisa_fail'
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
func group_why_interest_in_lisa_answer(): 
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_why_interested_in_lisa_q'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("It's all part of the training process", group_why_interested_in_lisa_answer_choice1))
	result.nextGroup.append(getChoiceAction('No reason, just small talk', group_why_interested_in_lisa_answer_choice2))
	result.nextGroup.append(getChoiceAction("I think you're cute and I'm trying to flirt", group_why_interested_in_lisa_answer_choice3))
	return result
	
func group_why_interested_in_lisa_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'training_process'
	result.addParticleRain = 'smile'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result
	
func group_why_interested_in_lisa_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'asking_for_no_reason'
	return result
	
func group_why_interested_in_lisa_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.annoyed = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'think_youre_cute'
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

################################################
# PLAYER ASKS - FAVORITE COLOR
################################################
func group_favorite_color_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'player_ask_fav_color_success'
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.addParticleRain = 'heart'
	result.setFlagToTrue = FLAG_ASKED_ABOUT_COLOR
	return result
	
func group_favorite_color_question_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'player_ask_fav_color_fail'
	return result

func group_remember_favorite_color_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'partner_remember_fav_color'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Red", group_remember_favorite_color_choice1))
	result.nextGroup.append(getChoiceAction("Yellow", group_remember_favorite_color_choice2))
	result.nextGroup.append(getChoiceAction("Orange", group_remember_favorite_color_choice3))
	return result

func group_remember_favorite_color_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'rem_color_red'
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.annoyed = true
	return result

func group_remember_favorite_color_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'rem_color_yellow'
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.annoyed = true
	return result

func group_remember_favorite_color_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'rem_color_orange'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

################################################
#      PLAYER ASKS - HOW OLD
################################################
func group_how_old_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.dialogueStartKey = 'ask_how_old'
	result.addParticleRain = 'heart'
	return result
	
func group_how_old_question_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.particleType = Heartsplosion.TYPES.ANNOYED
	result.dialogueStartKey = 'ask_how_old_fail'
	return result

################################################
#      PLAYER ASKS - SMALLTALK
################################################
func group_smalltalk_ask():
	var result = DateActionResult.new()
	result.success = true 
	result.dialogueStartKey = 'smalltalk'
	result.progressQuantity = 10
	return result


################################################
#            CUMMINGTON TOPIC
################################################
func group_cummington():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_cummington_common'
	else:
		result.dialogueStartKey = 'dialogue_cummington'
		
	result.success = true
	result.scoreProgression = 10
	
	result.nextGroup.append(getPlayerQuestionAction('How long have you lived here?',
							DateAction.CATEGORIES.FRIENDLY,
							group_cummington_lived_here,
							group_cummington_lived_here_fail,
							'id_lisamarket_q_lived_here'))
	
	result.nextGroup.append(getPlayerQuestionAction('What do you think of the city?',
							DateAction.CATEGORIES.FRIENDLY,
							group_cummington_thoughts,
							group_cummington_thoughts_fail,
							'id_lisamarket_q_city_thoughts'))

	result.nextGroup.append(getPlayerQuestionAction('Do you come to the weekly farmers market often?',
							DateAction.CATEGORIES.FRIENDLY,
							group_cummington_farmer,
							group_cummington_farmer_fail,
							'id_lisamarket_q_farmarket'))

	result.nextGroup.append(getPlayerQuestionAction('Do you go to school at Cummington State?',
							DateAction.CATEGORIES.FRIENDLY,
							group_cummington_state,
							group_cummington_state_fail,
							'id_lisamarket_q_city_cstate'))
							
	result.nextGroup.append(getPartnerQuestionAction('Do you plan to stay in Cummington after college?',
							group_staying_in_city_answer, 'id_lisamarket_partnerask_staying'))
	
	result.nextGroup.append(getPartnerQuestionAction('What do you think about Cummington?',
							group_think_about_cummington_answer, 'id_lisamarket_partnerask_think_cummington'))

	result.nextGroup.append(getPartnerQuestionAction("Favorite meat pie from Chuck's?",
							group_favorite_meat_pie_answer, 'id_lisamarket_partnerask_meat_pie'))

	result.nextGroup.append(getPartnerQuestionAction("Have you always lived in Cummington?",
							group_always_lived_here_answer, 'id_lisamarket_partnerask_always_lived'))

	result.nextGroup.append(getPartnerQuestionAction("Where do you think the name Cummington came from?",
							group_name_origin_answer, 'id_lisamarket_partnerask_name_origin'))
	
	return result

func group_cummington_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'cummington_fail'
	return result

func group_cummington_lived_here():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'lived_here_success'
	return result

func group_cummington_lived_here_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'lived_here_fail'
	return result

func group_cummington_thoughts():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'city_thoughts_success'
	return result

func group_cummington_thoughts_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'city_thoughts_fail'
	return result

func group_cummington_farmer():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'farmers_market_success'
	return result

func group_cummington_farmer_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'farmers_market_fail'
	return result

func group_cummington_state():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'cummington_state_success'
	return result

func group_cummington_state_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'cummington_state_fail'
	return result

func group_staying_in_city_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_think_about_cummington'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Definitely", group_staying_in_city_choice1))
	result.nextGroup.append(getChoiceAction("Absolutely not", group_staying_in_city_choice2))
	return result

func group_staying_in_city_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.addParticleRain = 'heart'
	result.dialogueStartKey = 'definitely_staying'
	result.nextGroup.append(getPartnerQuestionAction('Oh? Is there something you really like about it?',
															group_why_staying_answer,
															'id_partnerask_whystaying'))
	return result

func group_staying_in_city_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'definitely_leving'
	result.nextGroup.append(getPartnerQuestionAction('Oh? Is there something you really dislike about it?',
															group_why_leaving_answer,
															'id_partnerask_whyleacing'))
	return result

func group_why_staying_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'is_there_something_you_like_about_it'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("I want to get a job and raise a family here", group_why_staying_choice1))
	result.nextGroup.append(getChoiceAction("Lots of really attractive women here", group_why_staying_choice2))
	return result

func group_why_leaving_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'is_there_something_you_dislike_about_it'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("I just think there are more opportunities elsewhere", group_why_leaving_choice1))
	result.nextGroup.append(getChoiceAction("Yeah too many women here are bitches", group_why_leaving_choice2))
	return result

func group_why_staying_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'job_raise_family'
	result.addParticleRain = 'heart'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_why_staying_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'attractive_women'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_why_leaving_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'more_opportunities'
	return result

func group_why_leaving_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 20
	result.dialogueStartKey = 'bitches'
	result.addParticleRain = 'laugh'
	result.particleType = Heartsplosion.TYPES.LAUGH
	result.setBackground(load("res://data/background_lists/lisa_market_new/18.png"), 'answerbitches')
	return result

func group_think_about_cummington_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_think_about_cummington'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("It's fun. It's a college town", group_think_about_cummington_choice1))
	result.nextGroup.append(getChoiceAction("It's kind of boring. Where's all the huge parties?", group_think_about_cummington_choice2))
	return result

func group_think_about_cummington_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'heart'
	result.dialogueStartKey = 'great_college_town'
	return result

func group_think_about_cummington_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'okay_but_small'
	return result

func group_favorite_meat_pie_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_favorite_meat_pie'
	result.success = true
	result.setBackground(load("res://data/background_lists/lisa_market_new/16.png"), 'milker')
	result.nextGroup.append(getChoiceAction("Chuck's Mega Milker Meat (Beef)", group_favorite_meat_pie_choice1))
	result.nextGroup.append(getChoiceAction("Chicken Giggler Special", group_favorite_meat_pie_choice2))
	result.nextGroup.append(getChoiceAction("I'm a vegan, meat is murder", group_favorite_meat_pie_choice3))
	return result

func group_favorite_meat_pie_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'mega_milker'
	return result

func group_favorite_meat_pie_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 20
	result.dialogueStartKey = 'chicken_giggler'
	result.addParticleRain = 'heart'
	result.progressQuantity = 60
	result.particleType = Heartsplosion.TYPES.HEARTS
	return result

func group_favorite_meat_pie_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.annoyed = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'vegan'
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_always_lived_here_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_always_lived_here'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Born and raised.", group_always_lived_here_choice1))
	result.nextGroup.append(getChoiceAction("Moved here for college.", group_always_lived_here_choice2))
	result.nextGroup.append(getChoiceAction("I'm not sure, my consciousness only goes back until just before Chad's party", group_always_lived_here_choice3))
	return result

func group_always_lived_here_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'born_and_raised'
	return result

func group_always_lived_here_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'moved_for_college'
	result.addParticleRain = 'heart'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_always_lived_here_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'consciousness'
	result.addParticleRain = 'laugh'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

func group_name_origin_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_name_origin'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Named after founder John Cumming", group_name_origin_choice1))
	result.nextGroup.append(getChoiceAction("No idea, but it sounds pretty funny", group_name_origin_choice3))
	return result

func group_name_origin_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'laugh'
	result.particleType = Heartsplosion.TYPES.LAUGH
	result.dialogueStartKey = 'named_after_founder'
	return result

func group_name_origin_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.dialogueStartKey = 'no_idea_but_funny'
	return result

################################################
#            CHAD TOPIC
################################################
func group_chad():
	var result = DateActionResult.new()
	
	result.dialogueStartKey = 'dialogue_chad'
		
	result.success = true
	result.scoreProgression = 10
	
	result.nextGroup.append(getPlayerQuestionAction('How do you know Chad?',
							DateAction.CATEGORIES.PERSONAL,
							group_chad_know_how,
							group_chad_know_how_fail,
							'id_lisamarket_q_know_chad'))

	result.nextGroup.append(getPlayerQuestionAction("How often do you go to Chad's parties?",
							DateAction.CATEGORIES.PERSONAL,
							group_chad_go_to_party,
							group_chad_go_to_party_fail,
							'id_lisamarket_q_how_often_go'))
							
	result.nextGroup.append(getPartnerQuestionAction('What do you think of Chad?',
							group_chad_thoughts_answer, 'id_lisamarket_partnerask_chad_thoughts'))
	
	result.nextGroup.append(getPartnerQuestionAction("How did you get an invite to Chad's party?",
							group_chad_party_answer, 'id_lisamarket_partnerask_chad_party'))
	
	return result

func group_chad_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'chad_fail'
	return result

func group_chad_know_how():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'know_chad_success'
	return result

func group_chad_know_how_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'know_chad_fail'
	return result

func group_chad_thoughts_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_chad_thoughts'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("We're so tight. BFFs for sure.", group_chad_thoughts_answer_choice1))
	result.nextGroup.append(getChoiceAction("We hang out sometimes, we're chill like that.", group_chad_thoughts_answer_choice2))
	result.nextGroup.append(getChoiceAction("I do his homework for him for free.", group_chad_thoughts_answer_choice3))
	return result

func group_chad_thoughts_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'chad_good_friend'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_chad_thoughts_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'smile'
	result.dialogueStartKey = 'chad_chill'
	return result

func group_chad_thoughts_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'chad_i_do_his_homework'
	result.particleType = Heartsplosion.TYPES.CONFUSED
	return result

func group_chad_party_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_chad_party'
	result.success = true
	result.addParticleRain = 'smile'
	result.nextGroup.append(getChoiceAction("I'm a friend of Chad's", group_chad_party_answer_choice1))
	result.nextGroup.append(getChoiceAction("I'm a friend of a friend of Chad's", group_chad_party_answer_choice2))
	result.nextGroup.append(getChoiceAction("I'm a friend of a friend of a friend of Chad's", group_chad_party_answer_choice3))
	result.nextGroup.append(getChoiceAction("I'm a friend of a friend of a friend of... she goes to another school, you wouldn't know her.", group_chad_party_answer_choice4))

	return result

func group_chad_party_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'friend_of_chad'
	return result

func group_chad_party_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'friend_of_friend'
	return result

func group_chad_party_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'friend_of_friend_of_friend'
	return result

func group_chad_party_answer_choice4():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'friend_of_friend_of_friend_of_friend'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_chad_go_to_party():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'go_to_party_success'
	result.addParticleRain = 'smile'
	return result

func group_chad_go_to_party_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'go_to_party_fail'
	return result

################################################
#            FLIRT TOPIC
################################################
func group_relationships():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_relationships_common'
	else:
		result.dialogueStartKey = 'dialogue_relationships'
		
	result.success = true
	result.scoreProgression = 10
	
	result.nextGroup.append(getPlayerQuestionAction('Are you seeing anyone?',
							DateAction.CATEGORIES.FLIRTY,
							group_relationships_current,
							group_relationships_current_fail,
							'id_lisamarket_q_current_relationship'))
	
	result.nextGroup.append(getPlayerQuestionAction("Compliment her outfit",
							DateAction.CATEGORIES.FLIRTY,
							group_relationships_kiss,
							group_relationships_kiss_fail,
							'id_lisamarket_q_first_kiss'))
	
	result.nextGroup.append(getPlayerQuestionAction('Compliment her hair',
							DateAction.CATEGORIES.FLIRTY,
							group_relationships_ever_had,
							group_relationships_ever_had_fail,
							'id_lisamarket_q_ever_had'))
	
	result.nextGroup.append(getPlayerQuestionAction("Compliment her body",
							DateAction.CATEGORIES.FLIRTY,
							group_relationships_fit,
							group_relationships_fit_fail,
							'id_lisamarket_q_fit'))
	
	if(flags.has(FLAG_ASKED_ABOUT_REL)):
		result.nextGroup.append(getPartnerQuestionAction('Why do you need to know about my relationships?',
								group_relationships_why_ask, 'id_lisamarket_partnerask_why_asking_relationships'))
	
	return result

func group_relationships_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.scoreProgression = 0
	result.dialogueStartKey = 'relationships_fail'
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_relationships_current():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 40
	result.dialogueStartKey = 'current_relationship_success'
	result.setFlagToTrue = FLAG_ASKED_ABOUT_REL
	return result

func group_relationships_current_fail():
	var result = DateActionResult.new()
	result.success = false
	result.scoreProgression = 0
	result.addParticleRain = 'annoyed'
	result.particleType = Heartsplosion.TYPES.PISSED
	result.dialogueStartKey = 'current_relationship_fail'
	return result

func group_relationships_why_ask():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_your_relationship_status'
	result.success = true
	result.nextGroup.append(getChoiceAction("It's for training purposes.", group_relationships_you_answer_choice1))
	result.nextGroup.append(getChoiceAction("Maybe I want to know if I have a shot?", group_relationships_you_answer_choice2))
	return result

func group_relationships_you_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	result.dialogueStartKey = 'rel_training_purposes'
	return result

func group_relationships_you_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.annoyed = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'have_a_shot'
	result.addParticleRain = 'annoyed'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 10
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

func group_relationships_kiss():
	#impossible
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'first_kiss_success'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	return result

func group_relationships_kiss_fail():
	var result = DateActionResult.new()
	result.success = false
	result.scoreProgression = 0
	result.addParticleRain = 'annoyed'
	result.dialogueStartKey = 'first_kiss_fail'
	return result

func group_relationships_ever_had():
	#impossible
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'ever_had_success'
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 30
	result.memoryUnlockId = 'LISA_MARKET_REW_1'
	return result

func group_relationships_ever_had_fail():
	var result = DateActionResult.new()
	result.success = false
	result.criticalFailure = true
	result.dialogueStartKey = 'ever_had_fail'
	return result

func group_relationships_fit():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.progressType = DateActionResult.DATE_PROGRESS_TYPE.LOVE
	result.progressQuantity = 10
	result.particleType = Heartsplosion.TYPES.PISSED
	result.dialogueStartKey = 'fit_success'
	result.annoyed = true
	return result

func group_relationships_fit_fail():
	var result = DateActionResult.new()
	result.success = false
	result.dialogueStartKey = 'fit_fail'
	return result

################################################
#           POKER TOPIC
################################################
func group_poker():
	var result = DateActionResult.new()
	
	var id = GlobalGameStage.getCurrentAsk()
	if (GlobalGameStage.getCurrentDateAskSuccessCount(id) > 2):
		result.dialogueStartKey = 'dialogue_poker_common'
	else:
		result.dialogueStartKey = 'dialogue_poker'

	var scoreProgression = GlobalGameStage.getDateStorage().currentDateProgressionScore
		
	result.success = true
	result.scoreProgression = 10

	result.nextGroup.append(getPartnerQuestionAction('How did you learn to be such an expert at poker?',
							group_poker_expert_answer, 'id_lisamarket_partnerask_pokerexpert'))
	
	result.nextGroup.append(getPartnerQuestionAction("Was it hard to beat those girls at Chad's party?",
						group_party_girls_answer, 'id_lisamarket_partnerask_beatgirlsatparty'))
	
	result.nextGroup.append(getPartnerQuestionAction("What's the most you've ever lost in a poker game?",
							group_poker_lost_answer, 'id_lisamarket_partnerask_pokerlost'))
	result.nextGroup.append(getPartnerQuestionAction("Do you play for high stakes often?",
							group_poker_stakes_answer, 'id_lisamarket_partnerask_poker_stakes'))
	
	result.nextGroup.append(getPartnerQuestionAction("How long will it take me to learn to play poker like you?",
							group_poker_how_long_answer, 'id_lisamarket_partnerask_poker_how_long'))
	result.nextGroup.append(getPartnerQuestionAction("Have you ever trained anybody else?",
							group_poker_trained_other_answer, 'id_lisamarket_partnerask_poker_trained_other'))
	
	var progressionLocked = false
	if(mainQuestionIndex == 0):
		result.nextGroup.append(getPlayerQuestionAction('How did you learn to play poker?',
								DateAction.CATEGORIES.FRIENDLY,
								group_player_learn_poker_question,
								group_player_learn_poker_question,
								'id_lisamarket_player_learn_poker',
								progressionLocked))
	
	if(mainQuestionIndex == 1):
		result.nextGroup.append(getPlayerQuestionAction("What's the most you've ever lost in poker?",
								DateAction.CATEGORIES.PERSONAL,
								group_player_most_lost_poker,
								group_player_most_lost_poker,
								'id_lisamarket_player_most_lost_poker',
								progressionLocked))

	if(mainQuestionIndex == 2):
		if(scoreProgression < 140):
			progressionLocked = true
		result.nextGroup.append(getPlayerQuestionAction("What would you be willing to lose in a poker game? If it meant getting better?",
								DateAction.CATEGORIES.DEEP,
								group_player_willing_to_lose,
								group_player_willing_to_lose,
								'id_lisamarket_player_willingtolose',
								progressionLocked))
	
	if(mainQuestionIndex == 3):
		if(scoreProgression < 150):
			progressionLocked = true

		result.nextGroup.append(getPlayerQuestionAction("Would you be more motivated to learn if you stood to lose a lot?",
								DateAction.CATEGORIES.FLIRTY,
								group_player_motivation,
								group_player_motivation,
								'id_lisamarket_player_motivatedtowin',
								progressionLocked))
	
	if(mainQuestionIndex == 4):
		if(scoreProgression < 160):
			progressionLocked = true

		result.nextGroup.append(getPlayerQuestionAction("Have you ever played strip poker?",
								DateAction.CATEGORIES.FLIRTY,
								group_player_strip_poker,
								group_player_strip_poker,
								'id_lisamarket_player_strp_poker',
								progressionLocked))
		
	return result

func group_poker_fail():
	var result = DateActionResult.new()
	result.success = false 
	result.dialogueStartKey = 'lismarket_poker_fail'
	return result


func group_poker_expert_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_expert'
	result.success = true
	result.addParticleRain = 'poker'
	result.nextGroup.append(getChoiceAction("Practice!", group_poker_expert_answer_choice1))
	result.nextGroup.append(getChoiceAction("I sometimes play in extremely high stakes games.", group_poker_expert_answer_choice2))
	return result

func group_poker_expert_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'poker_practice'
	return result

func group_poker_expert_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'high_stakes_games'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_party_girls_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_party_girls'
	result.success = true
	result.addParticleRain = 'poker'
	result.nextGroup.append(getChoiceAction("I had to reload the save repeatedly. It took like 15 tries tbh", group_party_girls_answer_choice2))
	result.nextGroup.append(getChoiceAction("It was easy, I'm just really good.", group_party_girls_answer_choice3))
	return result

func group_party_girls_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'clicked_win_button'
	result.particleType = Heartsplosion.TYPES.LAUGH
	return result

func group_party_girls_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.dialogueStartKey = 'reload_save'
	result.particleType = Heartsplosion.TYPES.LAUGH
	return result

func group_party_girls_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'really_good'
	result.particleType = Heartsplosion.TYPES.HAPPY
	return result

func group_poker_lost_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_lost'
	result.success = true
	result.addParticleRain = 'poker'
	result.nextGroup.append(getChoiceAction("I simply have never lost.", group_poker_lost_answer_choice1))
	result.nextGroup.append(getChoiceAction("One time, at band camp, my punishment for losing was... well it was rough.", group_poker_lost_answer_choice2))
	result.nextGroup.append(getChoiceAction("I've won much more than I've lost", group_poker_lost_answer_choice3))
	return result

func group_poker_lost_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.annoyed = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'never_lose_big'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_poker_lost_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'at_band_camp'
	result.particleType = Heartsplosion.TYPES.LAUGH
	return result

func group_poker_lost_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'won_more_than_lost'
	return result

func group_player_learn_poker_question():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'poker'
	result.dialogueStartKey = 'learn_poker_success'
	result.particleType = Heartsplosion.TYPES.HAPPY
	result.incrementMainQuestionIndex = true
	return result

func group_player_most_lost_poker():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'poker'
	result.dialogueStartKey = 'most_lost_poker_success'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.incrementMainQuestionIndex = true
	return result

func group_player_willing_to_lose():
	var result = DateActionResult.new()
	result.success = true
	result.addParticleRain = 'poker'
	result.scoreProgression = 10
	result.dialogueStartKey = 'willing_to_lose_success'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	result.incrementMainQuestionIndex = true
	return result

func group_player_motivation():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'poker'
	result.dialogueStartKey = 'motivation_success'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.INNOCENT
	return result

func group_player_strip_poker():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.addParticleRain = 'poker'
	result.dialogueStartKey = 'strip_poker_success'
	result.incrementMainQuestionIndex = true
	result.particleType = Heartsplosion.TYPES.HORNY
	return result

func group_poker_stakes_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_stakes'
	result.success = true
	result.addParticleRain = 'poker'
	result.nextGroup.append(getChoiceAction("I used to. Not anymore.", group_poker_stakes_answer_choice1))
	result.nextGroup.append(getChoiceAction("I regularly gamble my entire paycheck on a single hand.", group_poker_stakes_answer_choice2))
	result.nextGroup.append(getChoiceAction("I am in crippling life long debt", group_poker_stakes_answer_choice3))
	return result

func group_poker_stakes_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'used_to_gamble'
	return result

func group_poker_stakes_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'gamble_entire_paycheck'
	result.particleType = Heartsplosion.TYPES.CONFUSED
	return result

func group_poker_stakes_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'crippling_debt'
	result.particleType = Heartsplosion.TYPES.CONCERNED
	return result

func group_poker_how_long_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_how_long'
	result.success = true
	result.addParticleRain = 'poker'
	result.nextGroup.append(getChoiceAction("Never. But I can make you ALMOST as good as me.", group_poker_how_long_answer_choice1))
	result.nextGroup.append(getChoiceAction("It depends how much you're willing to commit", group_poker_how_long_answer_choice2))
	result.nextGroup.append(getChoiceAction("Years. Maybe longer.", group_poker_how_long_answer_choice3))
	return result

func group_poker_how_long_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'never_learn'
	result.particleType = Heartsplosion.TYPES.LAUGH
	return result

func group_poker_how_long_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'depends_on_commitment'
	result.particleType = Heartsplosion.TYPES.INNOCENT
	return result

func group_poker_how_long_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'years_maybe_longer'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_poker_trained_other_answer():
	var result = DateActionResult.new()
	result.dialogueStartKey = 'dialogue_poker_trained_other'
	result.success = true
	
	result.nextGroup.append(getChoiceAction("Nobody", group_poker_trained_other_answer_choice1))
	result.nextGroup.append(getChoiceAction("I used to run a class back in Boise, Idaho. Trained lots of people.", group_poker_trained_other_answer_choice2))
	result.nextGroup.append(getChoiceAction("I cannot reveal that information. I am very picky about who I train.", group_poker_trained_other_answer_choice3))
	return result

func group_poker_trained_other_answer_choice1():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 0
	result.dialogueStartKey = 'nobody_trained'
	result.particleType = Heartsplosion.TYPES.PISSED
	return result

func group_poker_trained_other_answer_choice2():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'ran_class'
	result.particleType = Heartsplosion.TYPES.SURPRISED
	return result

func group_poker_trained_other_answer_choice3():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'cannot_reveal'
	return result

func group_player_where_im_going():
	var result = DateActionResult.new()
	result.success = true
	result.scoreProgression = 10
	result.dialogueStartKey = 'where_im_going_success'
	result.incrementMainQuestionIndex = true
	return result
