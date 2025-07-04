extends RefCounted
class_name DateScript

var initFunction : Callable
var mainQuestionIndex : int = 0
var flags : Array[String] = []

const MAX_LUCK = 6

func scriptId():
	assert(false, "override me")
	
func start():
	assert(false, "override me")

func group_topic_select():
	assert(false, 'override me')

func getCurrentBackground():
	assert(false, 'override me')

func repeated_ask(action : DateAction):
	assert(false, 'override me' + str(action))

func date_was_successful():
	assert(false, 'override me')

func get_possible_memory_unlocks():
	assert(false, 'override me')
	
func getStandardLuck(luck):
	return luck

func getActionKey(id, dialogueKey):
	if id != null:
		return id
	elif dialogueKey != null:
		return dialogueKey
	else:
		assert(false, 'no unique key assigned for dialogue branch')

func processSuccess(action : DateAction):
	action.successFunc.call()

func processFailure(action : DateAction):
	action.failureFunc.call()

func getDialogueOnlyAction(successFunc : Callable):
	var startAction = DateAction.new()
	startAction.type = DateAction.TYPES.DIALOGUE_ONLY
	startAction.successFunc = successFunc
	return startAction

func getTopicAction(text : String,
					category : DateAction.CATEGORIES, 
					successFunc : Callable, failFunc: Callable, id : String, buttonIndex : DateAction.BUTTON_INDEX, loveLocked : bool = false):
	var topicAction = DateAction.new()
	
	topicAction.id = id
	topicAction.text = text
	topicAction.category = category
	topicAction.type = DateAction.TYPES.TOPIC
	topicAction.successFunc = successFunc
	topicAction.failureFunc = failFunc
	topicAction.buttonIndex = buttonIndex
	topicAction.loveLocked = loveLocked
	return topicAction

func getQuizAction(text : String, dialogueKey : String, successFunc : Callable, failFunc: Callable):
	var quizAction = DateAction.new()
	quizAction.dialogueStartKey = dialogueKey
	quizAction.text = text
	quizAction.type = DateAction.TYPES.QUIZ
	quizAction.successFunc = successFunc
	quizAction.failureFunc = failFunc
	return quizAction
	
func getPlayerQuestionAction(text : String, category : DateAction.CATEGORIES, 
							successFunc : Callable, failFunc: Callable, id : String, progressLocked : bool = false):
	var questionAction = DateAction.new()
	
	questionAction.id = id
	questionAction.text = text
	questionAction.category = category
	questionAction.type = DateAction.TYPES.PLAYER_QUESTION
	questionAction.successFunc = successFunc
	questionAction.failureFunc = failFunc
	questionAction.progressLocked = progressLocked
	return questionAction
	
func getPartnerQuestionAction(text : String, 
							 successFunc : Callable,
							 id : String):
								
	var questionAction = DateAction.new()
	questionAction.text = text
	questionAction.type = DateAction.TYPES.PARTNER_QUESTION
	questionAction.successFunc = successFunc
	questionAction.id = id
	return questionAction

func getChoiceAction(text : String, successFunc : Callable):
	var choiceAction = DateAction.new()
	
	choiceAction.text = text
	choiceAction.type = DateAction.TYPES.CHOICE
	choiceAction.successFunc = successFunc
	return choiceAction
