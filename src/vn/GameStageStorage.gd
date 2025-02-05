extends RefCounted
class_name GameStageStorage

static var currentStages = []
static var dialogueDatas = []
static var backgroundLists = []
static var backgroundList = []
static var images = []
static var actualImages = []

static func loadStages(gameStageListPath : String):
	print("Loading Game Stages for: ", gameStageListPath)
	var gsl : GameStageList = load(gameStageListPath) 
	for gs in gsl.gameStages:
		currentStages.append(ResourceLoader.load(gs.resource_path,'',ResourceLoader.CACHE_MODE_REUSE))

	for gs in currentStages:
		if(gs.dialogue):
			dialogueDatas.append(ResourceLoader.load(gs.dialogue.resource_path,'',ResourceLoader.CACHE_MODE_REUSE))

	for dd in dialogueDatas:
		if(dd.backgroundList):
			backgroundLists.append(ResourceLoader.load(dd.backgroundList,'',ResourceLoader.CACHE_MODE_REUSE))

	for bgls in backgroundLists:
		if(bgls.backgroundLists):
			for bglss in bgls.backgroundLists:
				backgroundList.append(ResourceLoader.load(bglss.resource_path,'',ResourceLoader.CACHE_MODE_REUSE))
		
	for bgl in backgroundList:
		if(bgl.images):
			for image in bgl.images:
				images.append(ResourceLoader.load(image.resource_path,'Background',ResourceLoader.CACHE_MODE_REUSE))
			
	for image in images:
		if(image.images):
			actualImages.append(ResourceLoader.load(image.images.resource_path,'Texture2D',ResourceLoader.CACHE_MODE_REUSE))
