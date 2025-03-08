extends Node
class_name RealDateColorHelper

static var redColorTexture = load("res://data/assets/realdate/red_sq_two.png")
static var  greenColorTexture = load("res://data/assets/realdate/green_sq_two.png")
static var  blueColorTexture = load("res://data/assets/realdate/blue_sq_two.png")
static var  yellowColorTexture = load("res://data/assets/realdate/yellow_sq_two.png")
static var  purpleColorTexture = load("res://data/assets/realdate/purple_sq_two.png")
static var  orangeColorTexture = load("res://data/assets/realdate/orange_sq_two.png")
static var  pinkColorTexture = load("res://data/assets/realdate/pink_sq_two.png")
static var  tealColorTexture = load("res://data/assets/realdate/teal_sq_two.png")

static var  redColorIconTexture = load("res://data/assets/realdate/flame.png")
static var  greenColorIconTexture = load("res://data/assets/realdate/cup.png")
static var  yellowColorIconTexture = load("res://data/assets/realdate/smile.png")
static var  blueColorIconTexture = load("res://data/assets/realdate/feather.png")
static var  purpleColorIconTexture = load("res://data/assets/realdate/rings.png")
static var  orangeColorIconTexture = load("res://data/assets/realdate/star.png")
static var  pinkColorIconTexture = load("res://data/assets/realdate/heart.png")
static var  tealColorIconTexture = load("res://data/assets/realdate/compass.png")

static var redColorCircleTexture = load("res://data/assets/realdate/red_icon.png")
static var greenColorCircleTexture = load("res://data/assets/realdate/green_icon.png")
static var blueColorCircleTexture = load("res://data/assets/realdate/blue_icon.png")
static var yellowColorCircleTexture = load("res://data/assets/realdate/yellow_icon.png")
static var purpleColorCircleTexture = load("res://data/assets/realdate/purple_icon.png")
static var orangeColorCircleTexture = load("res://data/assets/realdate/orange_icon.png")
static var pinkColorCircleTexture = load("res://data/assets/realdate/pink_icon.png")
static var tealColorCircleTexture = load("res://data/assets/realdate/teal_icon.png")


enum TopicColors {
	TOPIC_RED,
	TOPIC_GREEN,
	TOPIC_BLUE,
	TOPIC_YELLOW,
	TOPIC_PURPLE,
	TOPIC_ORANGE,
	TOPIC_PINK,
	TOPIC_TEAL,
	TOPIC_SPICY,
	TOPIC_SPECIAL
}

static var allColors = [
	TopicColors.TOPIC_RED,
	TopicColors.TOPIC_GREEN, 
	TopicColors.TOPIC_BLUE,
	TopicColors.TOPIC_YELLOW,
	TopicColors.TOPIC_PURPLE,
	TopicColors.TOPIC_ORANGE,
	TopicColors.TOPIC_PINK,
	TopicColors.TOPIC_TEAL
]


static func getPredefinedColorCombos():
	var colors = []

	var combo1 = ColorCombo.new("Childhood Dreams", [RealDateColorHelper.TopicColors.TOPIC_YELLOW, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo2 = ColorCombo.new("First Kiss", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_RED])
	var combo3 = ColorCombo.new("Creative Projects", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo4 = ColorCombo.new("Favorite Books", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_GREEN])
	var combo5 = ColorCombo.new("Bucket List", [RealDateColorHelper.TopicColors.TOPIC_TEAL, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo6 = ColorCombo.new("Quiet Evening", [RealDateColorHelper.TopicColors.TOPIC_GREEN, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo7 = ColorCombo.new("Dance Club", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_TEAL])
	var combo8 = ColorCombo.new("Poetry Reading", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo9 = ColorCombo.new("Shared Secrets", [RealDateColorHelper.TopicColors.TOPIC_ORANGE, RealDateColorHelper.TopicColors.TOPIC_GREEN])
	var combo10 = ColorCombo.new("Mountain Climbing", [RealDateColorHelper.TopicColors.TOPIC_TEAL, RealDateColorHelper.TopicColors.TOPIC_PINK])
	var combo11 = ColorCombo.new("Art Galleries", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_YELLOW])
	var combo12 = ColorCombo.new("Morning Routine", [RealDateColorHelper.TopicColors.TOPIC_GREEN, RealDateColorHelper.TopicColors.TOPIC_RED])
	var combo13 = ColorCombo.new("Fantasy Date", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_YELLOW])
	var combo14 = ColorCombo.new("Life Goals", [RealDateColorHelper.TopicColors.TOPIC_ORANGE, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo15 = ColorCombo.new("Sunset Walk", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_GREEN])
	var combo16 = ColorCombo.new("Music Festival", [RealDateColorHelper.TopicColors.TOPIC_YELLOW, RealDateColorHelper.TopicColors.TOPIC_TEAL])
	var combo17 = ColorCombo.new("Dream Home", [RealDateColorHelper.TopicColors.TOPIC_ORANGE, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo18 = ColorCombo.new("Love Languages", [RealDateColorHelper.TopicColors.TOPIC_YELLOW, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo19 = ColorCombo.new("Spontaneous Trip", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo20 = ColorCombo.new("Creative Inspiration", [RealDateColorHelper.TopicColors.TOPIC_TEAL, RealDateColorHelper.TopicColors.TOPIC_GREEN])
	var combo21 = ColorCombo.new("Personal Heroes", [RealDateColorHelper.TopicColors.TOPIC_YELLOW, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo22 = ColorCombo.new("Future Career", [RealDateColorHelper.TopicColors.TOPIC_PURPLE, RealDateColorHelper.TopicColors.TOPIC_RED])
	var combo23 = ColorCombo.new("Favorite Memory", [RealDateColorHelper.TopicColors.TOPIC_TEAL, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo24 = ColorCombo.new("Surprise Date", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo25 = ColorCombo.new("Campfire Stories", [RealDateColorHelper.TopicColors.TOPIC_GREEN, RealDateColorHelper.TopicColors.TOPIC_TEAL])
	var combo26 = ColorCombo.new("Slow Dancing", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo27 = ColorCombo.new("Hidden Talents", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_RED])
	var combo28 = ColorCombo.new("Dream Vacation", [RealDateColorHelper.TopicColors.TOPIC_ORANGE, RealDateColorHelper.TopicColors.TOPIC_YELLOW])
	var combo29 = ColorCombo.new("First Impressions", [RealDateColorHelper.TopicColors.TOPIC_GREEN, RealDateColorHelper.TopicColors.TOPIC_YELLOW])
	var combo30 = ColorCombo.new("Perfect Gift", [RealDateColorHelper.TopicColors.TOPIC_TEAL, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo31 = ColorCombo.new("Midnight Talk", [RealDateColorHelper.TopicColors.TOPIC_PURPLE, RealDateColorHelper.TopicColors.TOPIC_PINK])
	var combo32 = ColorCombo.new("Creative Passions", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_YELLOW])
	var combo33 = ColorCombo.new("Childhood Place", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_PINK])
	var combo34 = ColorCombo.new("Future Home", [RealDateColorHelper.TopicColors.TOPIC_PURPLE, RealDateColorHelper.TopicColors.TOPIC_TEAL])
	var combo35 = ColorCombo.new("Favorite Song", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_GREEN])
	var combo36 = ColorCombo.new("Weekend Plans", [RealDateColorHelper.TopicColors.TOPIC_YELLOW, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo37 = ColorCombo.new("Shared Hobbies", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_TEAL])
	var combo38 = ColorCombo.new("Candlelit Dinner", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo39 = ColorCombo.new("Life Ambitions", [RealDateColorHelper.TopicColors.TOPIC_GREEN, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo40 = ColorCombo.new("Perfect Date", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_YELLOW])
	var combo41 = ColorCombo.new("Secret Spot", [RealDateColorHelper.TopicColors.TOPIC_PURPLE, RealDateColorHelper.TopicColors.TOPIC_RED])
	var combo42 = ColorCombo.new("Artistic Vision", [RealDateColorHelper.TopicColors.TOPIC_BLUE, RealDateColorHelper.TopicColors.TOPIC_PURPLE])
	var combo43 = ColorCombo.new("Morning Kiss", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo44 = ColorCombo.new("Future Travel", [RealDateColorHelper.TopicColors.TOPIC_ORANGE, RealDateColorHelper.TopicColors.TOPIC_BLUE])
	var combo45 = ColorCombo.new("Comfort Food", [RealDateColorHelper.TopicColors.TOPIC_GREEN, RealDateColorHelper.TopicColors.TOPIC_RED])
	var combo46 = ColorCombo.new("Romantic Fantasy", [RealDateColorHelper.TopicColors.TOPIC_PINK, RealDateColorHelper.TopicColors.TOPIC_ORANGE])
	var combo47 = ColorCombo.new("Shared Dream", [RealDateColorHelper.TopicColors.TOPIC_PURPLE, RealDateColorHelper.TopicColors.TOPIC_TEAL])
	var combo48 = ColorCombo.new("Forbidden Desire", [RealDateColorHelper.TopicColors.TOPIC_RED, RealDateColorHelper.TopicColors.TOPIC_PINK])
	
	colors.append(combo1)
	colors.append(combo2)
	colors.append(combo3)
	colors.append(combo4)
	colors.append(combo5)
	colors.append(combo6)
	colors.append(combo7)
	colors.append(combo8)
	colors.append(combo9)
	colors.append(combo10)
	colors.append(combo11)
	colors.append(combo12)
	colors.append(combo13)
	colors.append(combo14)
	colors.append(combo15)
	colors.append(combo16)
	colors.append(combo17)
	colors.append(combo18)
	colors.append(combo19)
	colors.append(combo20)
	colors.append(combo21)
	colors.append(combo22)
	colors.append(combo23)
	colors.append(combo24)
	colors.append(combo25)
	colors.append(combo26)
	colors.append(combo27)
	colors.append(combo28)
	colors.append(combo29)
	colors.append(combo30)
	colors.append(combo31)
	colors.append(combo32)
	colors.append(combo33)
	colors.append(combo34)
	colors.append(combo35)
	colors.append(combo36)
	colors.append(combo37)
	colors.append(combo38)
	colors.append(combo39)
	colors.append(combo40)
	colors.append(combo41)
	colors.append(combo42)
	colors.append(combo43)
	colors.append(combo44)
	colors.append(combo45)
	colors.append(combo46)
	colors.append(combo47)
	colors.append(combo48)
	
	return colors

# Function to get all possible color combinations and fill in gaps with new topics
static func getAllColorCombos():
	# Get predefined color combos
	var colors = getPredefinedColorCombos()
	
	# List of new topics to use for missing color combinations
	var newTopics = [
		"Personal Philosophy",
		"Family Traditions",
		"Rainy Day Activities",
		"Career Aspirations",
		"Favorite Cuisine",
		"Volunteer Work",
		"Outdoor Adventures",
		"Learning Goals",
		"Spiritual Practices",
		"Friendship Stories",
		"Urban Exploration",
		"Self-Improvement",
		"Cultural Heritage",
		"Stargazing Night",
		"Childhood Dreams",
		"Local Discoveries",
		"Inspirational Moments",
		"Skills to Master",
		"Memorable Journeys",
		"Seasonal Favorites",
		"Creative Rituals",
		"Life Lessons",
		"Nature Retreats",
		"Celebration Traditions",
		"Mindfulness Practices",
		"Historical Fascinations",
		"Community Involvement",
		"Culinary Experiments",
		"Personal Milestones",
		"Seasonal Reflections"
	]
	
	# Track which color combinations already exist
	var existingCombos = {}
	
	# Create a key for each color combination (order matters)
	for combo in colors:
		var colorCombo = combo.colors
		if colorCombo.size() >= 2:
			var key = str(colorCombo[0]) + "_" + str(colorCombo[1])
			existingCombos[key] = true
	
	# Get all possible color combinations
	var colorTypes = [
		TopicColors.TOPIC_RED,
		TopicColors.TOPIC_GREEN, 
		TopicColors.TOPIC_BLUE,
		TopicColors.TOPIC_YELLOW,
		TopicColors.TOPIC_PURPLE,
		TopicColors.TOPIC_ORANGE,
		TopicColors.TOPIC_PINK,
		TopicColors.TOPIC_TEAL
	]
	
	var newTopicIndex = 0
	
	# Generate all possible combinations of two colors
	for i in range(colorTypes.size()):
		for j in range(colorTypes.size()):
			if i != j:  # Don't combine a color with itself
				var color1 = colorTypes[i]
				var color2 = colorTypes[j]
				var key = str(color1) + "_" + str(color2)
				
				# If this combination doesn't exist, create it with a new topic
				if not existingCombos.has(key):
					if newTopicIndex < newTopics.size():
						var newCombo = ColorCombo.new(newTopics[newTopicIndex], [color1, color2])
						colors.append(newCombo)
						existingCombos[key] = true
						newTopicIndex += 1
	
	for comb in colors:
		sortColorsInCombo(comb)

	return colors

# Sort the colors within a combo according to predefined color order
static func sortColorsInCombo(combo):
	# Define the order of colors
	var colorOrder = {
		TopicColors.TOPIC_RED: 0,
		TopicColors.TOPIC_GREEN: 1,
		TopicColors.TOPIC_BLUE: 2,
		TopicColors.TOPIC_YELLOW: 3,
		TopicColors.TOPIC_PURPLE: 4,
		TopicColors.TOPIC_ORANGE: 5,
		TopicColors.TOPIC_PINK: 6,
		TopicColors.TOPIC_TEAL: 7,
		TopicColors.TOPIC_SPICY: 8,
		TopicColors.TOPIC_SPECIAL: 9
	}
	
	# Use custom sorting based on the predefined order
	combo.colors.sort_custom(func(a, b): 
		return colorOrder[a] < colorOrder[b]
	)
	
	return combo

static func getColorTexture(color: RealDateColorHelper.TopicColors):
	match color:
		RealDateColorHelper.TopicColors.TOPIC_RED:
			return redColorTexture
		RealDateColorHelper.TopicColors.TOPIC_GREEN:
			return greenColorTexture
		RealDateColorHelper.TopicColors.TOPIC_BLUE:
			return blueColorTexture
		RealDateColorHelper.TopicColors.TOPIC_YELLOW:
			return yellowColorTexture
		RealDateColorHelper.TopicColors.TOPIC_PURPLE:
			return purpleColorTexture
		RealDateColorHelper.TopicColors.TOPIC_ORANGE:
			return orangeColorTexture
		RealDateColorHelper.TopicColors.TOPIC_PINK:
			return pinkColorTexture
		RealDateColorHelper.TopicColors.TOPIC_TEAL:
			return tealColorTexture

static func getIconTexture(color: RealDateColorHelper.TopicColors):
	match color:
		RealDateColorHelper.TopicColors.TOPIC_RED:
			return redColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_GREEN:
			return greenColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_BLUE:
			return blueColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_YELLOW:
			return yellowColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_PURPLE:
			return purpleColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_ORANGE:
			return orangeColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_PINK:
			return pinkColorIconTexture
		RealDateColorHelper.TopicColors.TOPIC_TEAL:
			return tealColorIconTexture
		_:
			return redColorIconTexture

static func getColorForIndex(index: int):
	match index:
		0:
			return RealDateColorHelper.TopicColors.TOPIC_RED
		1:
			return RealDateColorHelper.TopicColors.TOPIC_GREEN
		2:
			return RealDateColorHelper.TopicColors.TOPIC_BLUE
		3:
			return RealDateColorHelper.TopicColors.TOPIC_YELLOW
		4:
			return RealDateColorHelper.TopicColors.TOPIC_PURPLE
		5:
			return RealDateColorHelper.TopicColors.TOPIC_ORANGE
		6:
			return RealDateColorHelper.TopicColors.TOPIC_PINK
		7:
			return RealDateColorHelper.TopicColors.TOPIC_TEAL

static func getColorCircleTextureForColor(color: RealDateColorHelper.TopicColors):
	match color:
		RealDateColorHelper.TopicColors.TOPIC_RED:
			return redColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_GREEN:
			return greenColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_BLUE:
			return blueColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_YELLOW:
			return yellowColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_PURPLE:
			return purpleColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_ORANGE:
			return orangeColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_PINK:
			return pinkColorCircleTexture
		RealDateColorHelper.TopicColors.TOPIC_TEAL:
			return tealColorCircleTexture


static func getRandomColorCombos(count: int, additionalColors: int = 0, excludedColors: Array = []):
	# Get all available color combinations
	var allCombos = getAllColorCombos()
	
	# Filter out combinations containing excluded colors
	var filteredCombos = []
	if excludedColors.size() > 0:
		for combo in allCombos:
			var containsExcludedColor = false
			for color in combo.colors:
				if excludedColors.has(color):
					containsExcludedColor = true
					break
			if not containsExcludedColor:
				filteredCombos.append(combo)
	else:
		filteredCombos = allCombos
	
	# If there aren't enough possible combinations after filtering, return all available
	if filteredCombos.size() < count:
		count = filteredCombos.size()
	
	# If no combos are available after filtering, return an empty array
	if filteredCombos.size() == 0:
		return []
	
	# Create a copy of the array to shuffle
	var shuffledCombos = filteredCombos.duplicate()
	
	# Shuffle the array to randomize
	shuffledCombos.shuffle()
	
	var result = []
	var selectedIndices = {}
	var colorRepresentation = {
		TopicColors.TOPIC_RED: 0,
		TopicColors.TOPIC_GREEN: 0,
		TopicColors.TOPIC_BLUE: 0,
		TopicColors.TOPIC_YELLOW: 0,
		TopicColors.TOPIC_PURPLE: 0,
		TopicColors.TOPIC_ORANGE: 0,
		TopicColors.TOPIC_PINK: 0,
		TopicColors.TOPIC_TEAL: 0
	}
	
	# First pass: select combos until we have the requested count or run out of options
	for i in range(shuffledCombos.size()):
		if result.size() >= count:
			break
			
		var combo = shuffledCombos[i]
		
		# Add this combo to the result
		result.append(combo)
		selectedIndices[i] = true
		
		# Update color representation count
		for color in combo.colors:
			if colorRepresentation.has(color):
				colorRepresentation[color] += 1
	
	# Check if all non-excluded colors are represented
	var allowedColors = []
	for color in allColors:
		if not excludedColors.has(color):
			allowedColors.append(color)
	
	var allAllowedColorsRepresented = true
	for color in allowedColors:
		if colorRepresentation[color] == 0:
			allAllowedColorsRepresented = false
			break
	
	# If not all allowed colors are represented, we need to replace some selections
	if not allAllowedColorsRepresented and count >= allowedColors.size():  # We need at least enough combos to represent all allowed colors
		# Find the missing colors
		var missingColors = []
		for color in allowedColors:
			if colorRepresentation[color] == 0:
				missingColors.append(color)
		
		# Find combos that include missing colors
		for missingColor in missingColors:
			# Look for a combo that has this missing color
			var foundReplacement = false
			
			for i in range(shuffledCombos.size()):
				if selectedIndices.has(i):
					continue  # Skip already selected combos
					
				var combo = shuffledCombos[i]
				if combo.colors.has(missingColor):
					# Find a combo to replace that doesn't reduce other color counts to zero
					var replaceIndex = -1
					
					for j in range(result.size()):
						var canReplace = true
						for color in result[j].colors:
							if colorRepresentation[color] <= 1:
								canReplace = false
								break
						
						if canReplace:
							replaceIndex = j
							break
					
					if replaceIndex != -1:
						# Update color counts
						for color in result[replaceIndex].colors:
							colorRepresentation[color] -= 1
						
						# Replace the combo
						result[replaceIndex] = combo
						selectedIndices[i] = true
						
						# Update color counts for the new combo
						for color in combo.colors:
							colorRepresentation[color] += 1
							
						foundReplacement = true
						break
			
			# If we couldn't find a suitable replacement, we can try adding a combo with the missing color
			if not foundReplacement and result.size() < count:
				for i in range(shuffledCombos.size()):
					if selectedIndices.has(i):
						continue
						
					var combo = shuffledCombos[i]
					if combo.colors.has(missingColor):
						result.append(combo)
						selectedIndices[i] = true
						
						# Update color counts
						for color in combo.colors:
							colorRepresentation[color] += 1
							
						break
	
	# If additional colors are requested, add them to each combo
	if additionalColors > 0:
		# For each combo in the result
		for combo in result:
			var availableColors = []
			
			# Find colors not already in this combo and not excluded
			for color in allColors:
				if not combo.colors.has(color) and not excludedColors.has(color):
					availableColors.append(color)
			
			# Shuffle available colors to randomize selection
			availableColors.shuffle()
			
			# Add up to the requested number of additional colors, if available
			var colorsToAdd = min(additionalColors, availableColors.size())
			for i in range(colorsToAdd):
				combo.colors.append(availableColors[i])
	
	return result

static func getRandomColorsForCPU(count : int):
	var colors = []
	
	# Shuffle the colors to randomize selection
	allColors.shuffle()
	
	# Select the first 4 colors
	for i in range(count):
		colors.append(allColors[i])
	
	return colors

static func colorIndexToColorName(index: int):
	match index:
		0:
			return "Red"
		1:
			return "Green"
		2:
			return "Blue"
		3:
			return "Yellow"
		4:
			return "Purple"
		5:
			return "Orange"
		6:
			return "Pink"
		7:
			return "Teal"
		_:
			return "Unknown"

static func colorEnumToName(color: RealDateColorHelper.TopicColors):
	match color:
		RealDateColorHelper.TopicColors.TOPIC_RED:
			return "Red"
		RealDateColorHelper.TopicColors.TOPIC_GREEN:
			return "Green"
		RealDateColorHelper.TopicColors.TOPIC_BLUE:
			return "Blue"
		RealDateColorHelper.TopicColors.TOPIC_YELLOW:
			return "Yellow"
		RealDateColorHelper.TopicColors.TOPIC_PURPLE:
			return "Purple"
		RealDateColorHelper.TopicColors.TOPIC_ORANGE:
			return "Orange"
		RealDateColorHelper.TopicColors.TOPIC_PINK:
			return "Pink"
		RealDateColorHelper.TopicColors.TOPIC_TEAL:
			return "Teal"
		_:
			return "Unknown"
