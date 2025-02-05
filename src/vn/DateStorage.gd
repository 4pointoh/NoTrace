extends RefCounted
class_name DateStorage

var currentAsk : String
var lastAsked : String
var lastFailure : String
var askHistoryComplete : Dictionary
var askHistoryCurrentDate : Dictionary

var currentDateHornyScore : int = 0
var currentDateProgressionScore : int = 0
var currentDateEntertainmentScore : int = 0

func addAsk(id: String, successful: bool):
	lastAsked = id
	
	if not askHistoryComplete.has(id):
		askHistoryComplete[id] = {"successful": 0, "unsuccessful": 0}
	if not askHistoryCurrentDate.has(id):
		askHistoryCurrentDate[id] = {"successful": 0, "unsuccessful": 0}
	
	if successful:
		askHistoryComplete[id]["successful"] += 1
		askHistoryCurrentDate[id]["successful"] += 1
	else:
		askHistoryComplete[id]["unsuccessful"] += 1
		askHistoryCurrentDate[id]["unsuccessful"] += 1
		lastFailure = id

func clearCurrentDate():
	askHistoryCurrentDate.clear()
	currentDateHornyScore = 0
	currentDateProgressionScore = 0
	currentDateEntertainmentScore = 0
	lastAsked = ''
	lastFailure = ''
	currentAsk = ''

func getTotalAsks(id: String) -> int:
	if askHistoryComplete.has(id):
		return askHistoryComplete[id]["successful"] + askHistoryComplete[id]["unsuccessful"]
	return 0

func getCompleteDateSuccessCount(id: String) -> int:
	if askHistoryComplete.has(id):
		return askHistoryComplete[id]["successful"]
	return 0

func getCompleteDateFailureCount(id: String) -> int:
	if askHistoryComplete.has(id):
		return askHistoryComplete[id]["unsuccessful"]
	return 0

func getCurrentDateSuccessCount(id: String) -> int:
	if askHistoryCurrentDate.has(id):
		return askHistoryCurrentDate[id]["successful"]
	return 0

func getCurrentDateFailureCount(id: String) -> int:
	if askHistoryCurrentDate.has(id):
		return askHistoryCurrentDate[id]["unsuccessful"]
	return 0
