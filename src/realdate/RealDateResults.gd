extends Node2D

@export var resultEntry : PackedScene

var playerChoices = []
var cpuChoices = []
var currentlyAnimating = 0
var currentPoints = 0

var currentRelationshipPoints = 0
var currentLevel = 1
var newRelationshipPoints = 0
var newLevel = 1
var perfect = false
	
func displayResults(playerChoices2 : Array, cpuChoices2 : Array, currentRelPoints : int, newRelPoints : int, currentLev : int, newLev : int, perfect2 : bool):
	playerChoices = playerChoices2
	cpuChoices = cpuChoices2

	currentRelationshipPoints = currentRelPoints
	newRelationshipPoints = newRelPoints
	currentLevel = currentLev
	newLevel = newLev
	perfect = perfect2

	%CurrentLevelLabel.text = str(currentLevel)
	%RelBar.value = GlobalGameStage.getRelationshipXpPercent(currentRelationshipPoints, currentLevel)
	
	for i in range(cpuChoices.size()):
		var nextResult = resultEntry.instantiate()
		nextResult.setup(playerChoices[i], cpuChoices[i], i)
		nextResult.finished.connect(onResultDisplayFinished)
		%ResultsContainer.add_child(nextResult)
	
	await get_tree().create_timer(1.5).timeout  # 0.5 second delay, adjust as needed
	runNextAnim()

func runNextAnim():	
	%ResultsContainer.get_child(currentlyAnimating).playAnimation()
	currentlyAnimating += 1

func onResultDisplayFinished():
	var curPlayerColor = playerChoices[currentlyAnimating]
	var curCpuColor = cpuChoices[currentlyAnimating]
	if curPlayerColor == curCpuColor:
		bumpAnimatePoints()
		
	await get_tree().create_timer(.5).timeout  # 0.5 second delay, adjust as needed
	
	if currentlyAnimating < playerChoices.size():
		# Create a timer for CPU choice delay
		runNextAnim()
	else:
		allAnimsComplete()

func allAnimsComplete():
	freeParticles()

	if perfect:
		%PerfectDate.show()
		var tween2 = get_tree().create_tween()
		tween2.tween_property(%PerfectDate, "scale", Vector2(1.2,1.2), .1)
		tween2.tween_property(%PerfectDate, "scale", Vector2(1,1), .1)
	else:
		%PerfectDate.hide()

	var tween = get_tree().create_tween()
	tween.tween_property(%RelBar, "value", GlobalGameStage.getRelationshipXpPercent(newRelationshipPoints, currentLevel), .3)

	if newLevel > currentLevel:
		bumpAnimateLevel()
	
func freeParticles():
	await get_tree().create_timer(1).timeout
	for child in %ResultsContainer.get_children():
		child.freeParticles()

func bumpAnimatePoints():
	currentPoints += 20
	%Points.text = '+' + str(currentPoints)
	var tween = get_tree().create_tween()
	tween.tween_property(%Points, "theme_override_font_sizes/font_size", 110, .1)
	tween.tween_property(%Points, "theme_override_font_sizes/font_size", 80, .1)

func bumpAnimateLevel():
	%CurrentLevelLabel.text = str(int(%CurrentLevelLabel.text) + 1)
	var tween = get_tree().create_tween()
	tween.tween_property(%CurrentLevelLabel, "theme_override_font_sizes/font_size", 60, .1)
	tween.tween_property(%CurrentLevelLabel, "theme_override_font_sizes/font_size", 32, .1)
