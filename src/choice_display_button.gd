extends Button

# One choice on the choice menu (src/vn/ChoiceDisplay.tscn). In a menu that lists its choices it is
# a row: the choice's words, and, when the menu knows which of the scenes behind it have been seen
# (ChoiceScript.getChoiceMarks), a mark for it: a medallion on the left and a caption on the right.
#
#   NEW      nothing of it seen yet: a spark in an empty ring, "NEW"
#   SOME     some of it seen: that part of the ring filled, "SEEN 1 OF 3". The scene it plays now
#            is either an unseen one (a spark, and "NEW" before the count) or not (a tick)
#   ALL      all of it seen: a tick in a full ring, "SEEN ALL" (just "SEEN" if there is only one)
#   LOCKED   a padlock, "LOCKED": picking it does nothing but shake the row
#
# What is counted is the menu's business: for Ashely Poker II's stakes, the scenes a stake can
# play from race to race; for Anna's class, the endings a route leads to. There the scene a choice
# plays isn't one of those counted, so a route can have been taken with nothing found down it
# yet: "SEEN 0 OF 4", with a tick.
#
# With no mark it is just its words, centered. In the menus that keep their choices side by side
# (sideBySide: every menu but Ashely Poker II's stakes, so far) it is a taller box of them.

enum Mark { NONE, NEW, SOME, ALL, LOCKED }

const GOLD = Color("ffd166")
const BLUE = Color("84cdff")
const GREEN = Color("8fe3a8")
const GREY = Color("b9b4c8")
const MARK_COLOURS = { Mark.NONE: GOLD, Mark.NEW: GOLD, Mark.SOME: BLUE, Mark.ALL: GREEN, Mark.LOCKED: GREY }

# The medallion: a ring this far in from the row's left edge.
const RING_LEFT = 16.0
const RING_RADIUS = 19.0
const SIDE_MARGIN = 22.0
const CAPTION_SIZE = 15
const CAPTION_GAP = 9.0	# around the dot between "NEW" and the count

var dialogueKey = ""
# One of several choices in a row across the menu, not a row of its own. Set before the label.
var sideBySide := false
var mark := Mark.NONE
# Of what there is to see behind this choice: how much has been seen, how much there is, and
# whether the scene it plays now is still unseen.
var seenCount := 0
var sceneCount := 0
var playsNew := false

var captionFont : FontVariation
var time := 0.0
var shaking : Tween

signal selected(key)

func _init():
	set_process(false)

func setLabelAndKey(labeltxt, key):
	dialogueKey = key
	text = labeltxt
	restyle()

# seen of the total there is to see behind this choice has been seen; nowNew: the scene it plays
# now has not.
func setSeen(seen : int, total : int, nowNew : bool):
	seenCount = clampi(seen, 0, total)
	sceneCount = total
	playsNew = nowNew
	if seenCount == 0 and playsNew:
		mark = Mark.NEW
	elif seenCount < sceneCount:
		mark = Mark.SOME
	else:
		mark = Mark.ALL
	# Only the spark moves.
	set_process(playsNew)
	restyle()

func setLocked():
	mark = Mark.LOCKED
	restyle()

func isLocked() -> bool:
	return mark == Mark.LOCKED

# The caption on the right, as [words, colour] parts: a dot is drawn between two.
func captionParts() -> Array:
	match mark:
		Mark.NEW:
			return [["NEW", GOLD]]
		Mark.SOME:
			var count = ["SEEN %d OF %d" % [seenCount, sceneCount], BLUE]
			return [["NEW", GOLD], count] if playsNew else [count]
		Mark.ALL:
			return [["SEEN ALL" if sceneCount > 1 else "SEEN", GREEN]]
		Mark.LOCKED:
			return [["LOCKED", GREY]]
	return []

func captionText() -> String:
	return " · ".join(captionParts().map(func(part): return part[0]))

func captionWidth() -> float:
	var parts := captionParts()
	var width := (parts.size() - 1) * CAPTION_GAP * 2
	for part in parts:
		width += captionFont.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x
	return width

# --- how the row looks

func restyle():
	if captionFont == null:
		captionFont = FontVariation.new()
		captionFont.base_font = get_theme_font("font")
		captionFont.spacing_glyph = 1

	# Lit in the colour of what picking it brings.
	var colour : Color = GOLD if playsNew else MARK_COLOURS[mark]
	var marked := mark != Mark.NONE
	custom_minimum_size.y = 96 if sideBySide else 64
	add_theme_font_size_override("font_size", 22 if sideBySide else 24)
	alignment = HORIZONTAL_ALIGNMENT_LEFT if marked else HORIZONTAL_ALIGNMENT_CENTER
	# The words keep clear of the medallion and the caption.
	var side := 14.0 if sideBySide else SIDE_MARGIN
	var left := RING_LEFT + RING_RADIUS * 2 + 16 if marked else side
	var right := SIDE_MARGIN + captionWidth() + 16 if marked else side

	var rest := box(Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.11), 1, left, right)
	var lit := box(Color(1, 1, 1, 0.17), Color(colour, 0.95), 2, left, right)
	var held := box(Color(1, 1, 1, 0.26), colour, 2, left, right)
	if isLocked():
		# Nothing to pick: it doesn't light up.
		rest = box(Color(0, 0, 0, 0.22), Color(1, 1, 1, 0.07), 1, left, right)
		lit = rest
		held = rest
	add_theme_stylebox_override("normal", rest)
	add_theme_stylebox_override("hover", lit)
	add_theme_stylebox_override("focus", lit)
	add_theme_stylebox_override("pressed", held)
	add_theme_stylebox_override("hover_pressed", held)

	# A choice seen through and through steps back a little; a locked one more.
	var words := Color(1, 1, 1, 0.96)
	if mark == Mark.ALL:
		words = Color(1, 1, 1, 0.82)
	elif isLocked():
		words = Color(1, 1, 1, 0.45)
	var wordsLit := words if isLocked() else Color.WHITE
	add_theme_color_override("font_color", words)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, wordsLit)
	queue_redraw()

func box(fill : Color, edge : Color, edgeWidth : int, left : float, right : float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(edgeWidth)
	style.set_corner_radius_all(14)
	style.content_margin_left = left
	style.content_margin_right = right
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _process(delta):
	time += delta
	queue_redraw()

# Drawn over the button's own box and words.
func _draw():
	if mark == Mark.NONE:
		return
	var lit := !isLocked() and (is_hovered() or has_focus())
	drawMedallion(Vector2(RING_LEFT + RING_RADIUS, size.y / 2), lit)
	drawCaption(lit)

func drawMedallion(centre : Vector2, lit : bool):
	var colour : Color = MARK_COLOURS[mark]
	draw_circle(centre, RING_RADIUS, Color(0, 0, 0, 0.42 if lit else 0.3), true, -1.0, true)
	if isLocked():
		# A broken ring: nothing to fill yet.
		for dash in 12:
			var from := dash * TAU / 12
			draw_arc(centre, RING_RADIUS, from, from + TAU / 24, 6, Color(colour, 0.5), 2.5, true)
		drawPadlock(centre, colour)
		return

	draw_arc(centre, RING_RADIUS, 0, TAU, 64, Color(1, 1, 1, 0.2), 3.0, true)
	if seenCount > 0:
		var sweep := TAU * seenCount / maxi(sceneCount, 1)
		draw_arc(centre, RING_RADIUS, -PI / 2, -PI / 2 + sweep, 64, colour, 3.6, true)
	if playsNew:
		# The spark breathes, and its little companion breathes against it.
		var breath := sin(time * 3.2)
		drawSpark(centre + Vector2(-1.5, 1.5), 10.0 * (1.0 + 0.1 * breath), GOLD)
		drawSpark(centre + Vector2(8.0, -7.5), 4.2 * (1.0 - 0.28 * breath), Color(GOLD, 0.9))
	else:
		drawTick(centre, colour)

# A four-pointed star.
func drawSpark(centre : Vector2, radius : float, colour : Color):
	var points := PackedVector2Array()
	for corner in 8:
		var reach := radius if corner % 2 == 0 else radius * 0.3
		points.append(centre + Vector2.UP.rotated(corner * PI / 4) * reach)
	draw_colored_polygon(points, colour)

func drawTick(centre : Vector2, colour : Color):
	var points := PackedVector2Array([centre + Vector2(-7.5, 0.5), centre + Vector2(-2.5, 5.5), centre + Vector2(7.5, -5.5)])
	draw_polyline(points, colour, 3.4, true)
	for point in points:
		draw_circle(point, 1.7, colour, true, -1.0, true)

func drawPadlock(centre : Vector2, colour : Color):
	draw_arc(centre + Vector2(0, -2.5), 5.0, PI, TAU, 16, colour, 2.6, true)
	draw_line(centre + Vector2(-5, -2.5), centre + Vector2(-5, 0), colour, 2.6, true)
	draw_line(centre + Vector2(5, -2.5), centre + Vector2(5, 0), colour, 2.6, true)
	var body := StyleBoxFlat.new()
	body.bg_color = colour
	body.set_corner_radius_all(3)
	body.draw(get_canvas_item(), Rect2(centre + Vector2(-8, -1), Vector2(16, 11.5)))
	draw_circle(centre + Vector2(0, 4.2), 1.9, Color(0, 0, 0, 0.6), true, -1.0, true)

# Right-aligned and centered on the row's height, the parts apart by a dot.
func drawCaption(lit : bool):
	var parts := captionParts()
	var ascent := captionFont.get_ascent(CAPTION_SIZE)
	var baseline := (size.y - captionFont.get_height(CAPTION_SIZE)) / 2 + ascent
	var x := size.x - SIDE_MARGIN - captionWidth()
	for i in parts.size():
		if i > 0:
			draw_circle(Vector2(x + CAPTION_GAP, size.y / 2), 1.8, Color(1, 1, 1, 0.5), true, -1.0, true)
			x += CAPTION_GAP * 2
		var colour : Color = parts[i][1]
		draw_string(captionFont, Vector2(x, baseline), parts[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE,
			colour if lit or isLocked() else Color(colour, 0.9))
		x += captionFont.get_string_size(parts[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x

# --- picking it

func _on_pressed() -> void:
	if isLocked():
		shake()
		return
	selected.emit(dialogueKey)

func shake():
	if shaking and shaking.is_running():
		return
	var rest := position.x
	shaking = create_tween()
	for offset in [-7.0, 6.0, -4.0, 2.0, 0.0]:
		shaking.tween_property(self, "position:x", rest + offset, 0.045)
