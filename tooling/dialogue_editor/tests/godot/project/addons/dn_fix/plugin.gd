@tool
extends EditorPlugin

# Regression tests for the review findings on the dialogue_nodes outside-edit
# patch (SAFE-6, ADDON-1..9). Runs only with `-- --run-fix[=sections]`.
# Prints PASS/FAIL lines and a RESULT line.

const A = 'res://test/d_a.tres'
const B = 'res://test/d_b.tres'
const V = 'res://test/d_v.tres'
const BACKUP_ROOT = 'res://tooling/dialogue_editor/backups/'
const WIN = 'res://data/game_stages/vn/ashely2_win/d_ashely2_win.tres'
const INTRO = 'res://data/game_stages/vn/ashely2_intro/d_ashely2_intro.tres'
const NIGHT = 'res://data/game_stages/vn/anna_night/d_anna_night.tres'
const BEACH = 'res://data/game_stages/vn/lisa_beach_beach/d_lisa_beach_beach.tres'
const CLASS = 'res://data/game_stages/vn/anna_class/d_anna_class.tres'

var dn
var files
var dn_plugin
var sections = []
var passed = 0
var failed = 0


func _enter_tree():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with('--run-fix'):
			var s = arg.trim_prefix('--run-fix').trim_prefix('=')
			sections = s.split(',', false) if s != '' else []
			_run.call_deferred()


func check(name, ok, detail = ''):
	if ok:
		passed += 1
		print('PASS: ', name)
	else:
		failed += 1
		print('FAIL: ', name, ('  -- ' + str(detail)) if str(detail) != '' else '')


func info(msg):
	print('INFO: ', msg)


func frames(n = 3):
	for i in range(n):
		await get_tree().process_frame


func disk(path) -> String:
	return FileAccess.get_file_as_string(path)


func write(path, text):
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func outside_replace(path, old, new) -> String:
	var text = disk(path)
	if not old in text:
		check('outside edit finds "%s" in %s' % [old, path], false, 'text not found')
		return text
	text = text.replace(old, new)
	write(path, text)
	return text


func node(id):
	return dn.graph.get_node_or_null(NodePath(id))


func graph_text(id) -> String:
	var n = node(id)
	return n.dialogue.text if n else '<missing>'


func meta(idx = -1) -> Dictionary:
	if idx < 0:
		idx = files.current
	return files.get_item_metadata(idx)


func load_disk(path) -> DialogueData:
	return ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE)


func focus_in():
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)


func save():
	dn_plugin._save_external_data()


func graph_nodes() -> int:
	var n = 0
	for c in dn.graph.get_children():
		if c is GraphNode:
			n += 1
	return n


func backups_count() -> int:
	var n = 0
	var root = ProjectSettings.globalize_path(BACKUP_ROOT)
	if not DirAccess.dir_exists_absolute(root):
		return 0
	var stack = [root]
	while stack.size() > 0:
		var d = stack.pop_back()
		for f in DirAccess.get_files_at(d):
			if f.ends_with('.bak'):
				n += 1
		for sub in DirAccess.get_directories_at(d):
			stack.append(d.path_join(sub))
	return n


func newest_backup(path) -> String:
	var dir = ProjectSettings.globalize_path(BACKUP_ROOT + path.trim_prefix('res://'))
	if not DirAccess.dir_exists_absolute(dir):
		return ''
	var names = Array(DirAccess.get_files_at(dir))
	names.sort()
	return FileAccess.get_file_as_string(dir + '/' + names[-1]) if names.size() else ''


func dialog() -> ConfirmationDialog:
	return files.reloadDialogue


func dialog_visible() -> bool:
	return files.reloadDialogue != null and files.reloadDialogue.visible


func confirm_cancel_button() -> Button:
	for c in files.confirmDialogue.get_ok_button().get_parent().get_children():
		if c is Button and c.text == 'Cancel' and c.visible:
			return c
	return null


func mods() -> String:
	var out = []
	for i in range(files.get_item_count()):
		out.append('%s:%s' % [files.get_item_text(i), files.get_item_metadata(i)['modified']])
	return ', '.join(out) + ' current=%d' % files.current


func reset_files():
	if dialog_visible():
		files.reloadDialogue.hide()
	files.asking = []
	if files.confirmDialogue.visible:
		files.confirmDialogue.hide()
	files.queued.clear()
	for i in range(files.get_item_count()):
		var m = files.get_item_metadata(i)
		m['modified'] = false
		files.set_item_metadata(i, m)
	files.close_all(true)
	files.queued.clear()
	await frames()
	if files.get_item_count() != 0:
		check('reset: all files closed', false, files.get_item_count())
	for f in ['d_a.tres', 'd_b.tres', 'bgs.tres', 'characters.tres']:
		DirAccess.copy_absolute(ProjectSettings.globalize_path('res://fixtures/' + f), ProjectSettings.globalize_path('res://test/' + f))
	var v = disk('res://fixtures/d_a.tres').replace('variables = {}', 'variables = {\n"FOO": {\n"type": 4,\n"value": "x"\n}\n}').replace('ORIGINAL a', 'ORIGINAL v')
	write(V, v)
	for p in [WIN, INTRO, NIGHT, BEACH, CLASS]:
		var src = 'res://fixtures_big/' + p.trim_prefix('res://')
		if FileAccess.file_exists(src):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(src), ProjectSettings.globalize_path(p))
	if EditorInterface.get_editor_main_screen() and not dn.is_visible_in_tree():
		EditorInterface.set_main_screen_editor('Dialogue Nodes')
	await frames()


func want(section) -> bool:
	return sections.is_empty() or section in sections


func _run():
	var fs = EditorInterface.get_resource_filesystem()
	await frames(10)
	while fs.is_scanning():
		await frames(1)
	await frames(10)
	for c in EditorInterface.get_editor_main_screen().get_children():
		if c.get_script() and c.get_script().resource_path == 'res://addons/dialogue_nodes/editor/editor.gd':
			dn = c
	for c in get_parent().get_children():
		if c is EditorPlugin and c.get_script() and c.get_script().resource_path == 'res://addons/dialogue_nodes/plugin.gd':
			dn_plugin = c
	if dn == null or dn_plugin == null:
		check('found the dialogue_nodes editor and plugin', false)
		_finish()
		return
	files = dn.files
	EditorInterface.set_main_screen_editor('Dialogue Nodes')
	get_tree().root.size = Vector2i(1920, 1080)
	await frames(5)

	if want('edits'):
		await edits()
	if want('safe6'):
		await safe6()
	if want('dialog'):
		await dialog_tests()
	if want('spurious'):
		await spurious()
	if want('confirm'):
		await confirm_tests()
	if want('close'):
		await close_tests()
	if want('saveas'):
		await saveas_tests()
	if want('stale'):
		await stale_tests()
	if want('newvars'):
		await newvars_tests()
	if want('roundtrip'):
		await roundtrip_tests()
	if want('big'):
		await big_tests()
	_finish()


# real typing: key events into the focused control
func type_keys(ctrl : Control, text : String):
	ctrl.grab_focus()
	if ctrl is LineEdit:
		ctrl.caret_column = ctrl.text.length()
	for ch in text:
		var ev = InputEventKey.new()
		ev.pressed = true
		ev.unicode = ch.unicode_at(0)
		ev.keycode = OS.find_keycode_from_string(ch.to_upper()) if ch != '_' else KEY_UNDERSCORE
		get_tree().root.push_input(ev)
		var up = ev.duplicate()
		up.pressed = false
		get_tree().root.push_input(up)
	await frames(2)


func key_combo(ctrl : Control, keycode):
	ctrl.grab_focus()
	var ev = InputEventKey.new()
	ev.pressed = true
	ev.keycode = keycode
	ev.ctrl_pressed = true
	get_tree().root.push_input(ev)
	var up = ev.duplicate()
	up.pressed = false
	get_tree().root.push_input(up)
	await frames(2)


# ADDON-1 makes Godot's saves write only files marked modified: every kind of
# graph edit must mark it, or it would never be saved.
func edit_case(name : String, do_edit : Callable, check_saved : Callable, prep = null):
	await reset_files()
	files.open_file(A)
	await frames()
	if prep:
		await prep.call()
		await frames()
		save()
		await frames()
	var before = meta()['modified']
	await do_edit.call()
	await frames(3)
	var marked = meta()['modified']
	save()
	await frames()
	var saved = load_disk(A)
	check('E1 %s: marks the file modified and a Godot save writes it' % name, not before and marked and check_saved.call(saved), [before, marked])


func edits():
	print('--- edits (ADDON-1: every edit is marked, so it is saved)')
	var arranged = [null]
	await edit_case('arrange nodes', func():
		node('1_2').position_offset = Vector2(3000, 900)
		dn.graph.arrange_nodes()
		await frames()
		arranged[0] = node('1_2').position_offset
		info('arrange: 1_2 now at %s' % arranged[0]),
		func(d): return d.nodes[&'1_2']['offset'] == arranged[0])
	await edit_case('drag a node', func():
		node('1_2').position_offset = Vector2(1500, 300)
		dn.graph.end_node_move.emit(),
		func(d): return d.nodes[&'1_2']['offset'] == Vector2(1500, 300))
	await edit_case('type in a line', func():
		var n = node('1_1'); n.dialogue.set_caret_column(0); n.dialogue.insert_text_at_caret('TYPED '),
		func(d): return d.nodes[&'1_1']['dialogue'].begins_with('TYPED'))
	await edit_case('undo in a line (Ctrl+Z)', func():
		await key_combo(node('1_1').dialogue, KEY_Z),
		func(d): return not 'TYPED' in d.nodes[&'1_1']['dialogue'],
		func():
			await type_keys(node('1_1').dialogue, 'TYPED '))
	await edit_case('type a signal value', func():
		await type_keys(node('3_1').value, '_quick'),
		func(d): return d.nodes[&'3_1']['signalValue'] == 'fade_next_quick')
	await edit_case('custom speaker', func():
		await type_keys(node('1_2').customSpeaker, 'Bob'),
		func(d): return d.nodes[&'1_2']['speaker'] == 'Bob')
	await edit_case('pick a speaker', func():
		var n = node('1_1'); n.speaker.select(0); n.speaker.item_selected.emit(0),
		func(d): return d.nodes[&'1_1']['speaker'] == 0)
	await edit_case('pick a picture', func():
		var n = node('1_1'); n.background.select(2); n.background.item_selected.emit(2),
		func(d): return d.nodes[&'1_1']['background'] == 2)
	await edit_case('reset the picture list', func():
		node('1_1').get_node('HBoxContainer5/ResetBackgroundList').pressed.emit(),
		func(d): return d.nodes[&'1_1']['backgroundList'] == -1)
	await edit_case('expanded text box', func():
		var n = node('1_1'); n.dialogue_expanded.text = n.dialogue.text; n.dialogue_expanded.set_caret_column(0); n.dialogue_expanded.insert_text_at_caret('EXP '),
		func(d): return d.nodes[&'1_1']['dialogue'].begins_with('EXP'))
	await edit_case('resize a line node', func():
		node('1_1').resize_request.emit(Vector2(420, 700)),
		func(d): return d.nodes[&'1_1']['size'] == Vector2(420, 700))
	await edit_case('option text', func():
		await type_keys(node('1_1').options[0].line_edit, 'Choice'),
		func(d): return d.nodes[&'1_1']['options'][0]['text'] == 'Choice')
	await edit_case('start id', func():
		await type_keys(node('0_1').get_node('HBoxContainer/ID'), '2'),
		func(d): return d.starts.has('START2'))
	await edit_case('reset characters', func():
		dn.characters.resetButton.pressed.emit(),
		func(d): return d.characters == '')
	await edit_case('add a variable', func():
		dn.variables.add_variable('NEWVAR'),
		func(d): return d.variables.has('NEWVAR'))
	await edit_case('delete a node', func():
		dn.graph.delete_nodes_request.emit([&'3_1']),
		func(d): return not d.nodes.has(&'3_1'))
	await edit_case('disconnect', func():
		dn.graph.disconnection_request.emit(&'1_1', 0, &'3_1', 0),
		func(d): return d.nodes[&'1_1']['options'][0]['link'] == 'END')
	await edit_case('duplicate', func():
		dn.workspace._select_all_nodes(false); node('1_2').selected = true; dn.graph.duplicate_nodes_request.emit(),
		func(d): return d.nodes.size() > 4)


# ------------------------------------------------------------------ SAFE-6
func safe6():
	print('--- safe6')
	# a: only dragged a node, then the web editor saved: no question, disk wins
	await reset_files()
	files.open_file(A)
	await frames()
	node('1_2').position_offset += Vector2(40, 40)
	dn.graph.end_node_move.emit()
	await frames()
	check('S6a dragging a node marks the file modified (so a plain Godot save still keeps the move)', meta()['modified'] == true)
	var out = outside_replace(A, 'Line one ORIGINAL a', 'Line one WEB a')
	focus_in()
	await frames()
	check('S6a node moved only + outside change + focus-in: no question asked', not dialog_visible())
	check('S6a ... the graph shows the outside text', graph_text('1_1') == 'Line one WEB a', graph_text('1_1'))
	save()
	await frames()
	check('S6a ... and a save leaves the outside version on disk', disk(A) == out)
	# a2: same, but F5 before the focus check ran
	node('1_2').position_offset += Vector2(40, 40)
	dn.graph.end_node_move.emit()
	var out2 = outside_replace(A, 'Line one WEB a', 'Line one WEB2 a')
	save()
	await frames()
	check('S6a2 node moved only + outside change + save: outside version kept', disk(A) == out2)
	# a3: a move without an outside change is still saved
	node('1_2').position_offset = Vector2(1500, 300)
	dn.graph.end_node_move.emit()
	save()
	await frames()
	check('S6a3 a node move with no outside change is saved', load_disk(A).nodes[&'1_2']['offset'] == Vector2(1500, 300), load_disk(A).nodes[&'1_2']['offset'])
	# a4: a move, then a text edit: a real edit, so it asks
	node('1_2').position_offset += Vector2(40, 40)
	dn.graph.end_node_move.emit()
	node('1_1').dialogue.insert_text_at_caret('G ')
	await frames()
	outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB a')
	focus_in()
	await frames()
	check('S6a4 a move then a text edit + outside change: asks', dialog_visible())

	# b: text edit + outside change; dismissing the question must not lead to a write
	# (Esc isn't sent here: AcceptDialog takes it in _input_from_window, which
	# push_input skips. Esc, the window's X and Cancel all end in the same
	# AcceptDialog._cancel_pressed, which emits canceled.)
	for how in ['window X', 'Decide later']:
		await reset_files()
		files.open_file(A)
		await frames()
		node('1_1').dialogue.insert_text_at_caret('GODOT ')
		await frames()
		var o = outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB a')
		focus_in()
		await frames()
		check('S6b[%s] asks' % how, dialog_visible())
		var nb = backups_count()
		match how:
			'window X':
				dialog().notification(Window.NOTIFICATION_WM_CLOSE_REQUEST)
			'Decide later':
				dialog().get_cancel_button().pressed.emit()
		await frames()
		check('S6b[%s] dialog closed' % how, not dialog_visible())
		check('S6b[%s] graph edit kept in Godot, still modified' % how, graph_text('1_1').begins_with('GODOT') and meta()['modified'] == true, [graph_text('1_1'), meta()['modified']])
		save()
		await frames()
		check('S6b[%s] then a save (F5) does not write: disk is still the outside version' % how, disk(A) == o)
		check('S6b[%s] ... no backup made, file still modified' % how, backups_count() == nb and meta()['modified'] == true)
		check('S6b[%s] ... and the question comes back' % how, dialog_visible())
		focus_in()
		await frames()
		check('S6b[%s] ... graph edit still there' % how, graph_text('1_1').begins_with('GODOT'))

	# c: explicit overwrite writes now, after a backup
	await reset_files()
	files.open_file(A)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GODOT ')
	await frames()
	var oc = outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB a')
	focus_in()
	await frames()
	var buttons = []
	for c in dialog().get_ok_button().get_parent().get_children():
		if c is Button and c.visible:
			buttons.append(c.text)
	info('dialog buttons: %s' % [buttons])
	info('dialog text: <<%s>>' % dialog().dialog_text)
	var nbc = backups_count()
	dialog().custom_action.emit('overwrite')
	await frames()
	check('S6c Overwrite: dialog closed', not dialog_visible())
	var dc = load_disk(A)
	check('S6c Overwrite: graph copy written now', dc.nodes[&'1_1']['dialogue'].begins_with('GODOT') and dc.nodes[&'1_2']['dialogue'] == 'Line two ORIGINAL a', [dc.nodes[&'1_1']['dialogue'], dc.nodes[&'1_2']['dialogue']])
	check('S6c Overwrite: outside version backed up', backups_count() == nbc + 1 and newest_backup(A) == oc)
	check('S6c Overwrite: not modified any more', meta()['modified'] == false)

	# d: Use the file on disk
	node('1_1').dialogue.insert_text_at_caret('AGAIN ')
	await frames()
	var od = outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB d')
	focus_in()
	await frames()
	dialog().get_ok_button().pressed.emit()
	await frames()
	check('S6d Use the file on disk: graph shows it, not modified, disk untouched', graph_text('1_2') == 'Line two WEB d' and meta()['modified'] == false and disk(A) == od, [graph_text('1_2'), meta()['modified']])

	# e: F5 before the focus check: refuses and asks
	await reset_files()
	files.open_file(A)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GODOT ')
	await frames()
	var oe = outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB e')
	save()
	await frames()
	check('S6e edited + outside change + save with no focus check yet: not written, asks', disk(A) == oe and dialog_visible() and A in dialog().dialog_text)

	# f: an edited file in another tab (not in the graph)
	await reset_files()
	files.open_file(A)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GODOT ')
	await frames()
	files.open_file(B)
	await frames()
	var of = outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB f')
	save()
	await frames()
	check('S6f edited file in another tab + outside change + save: not written, asks', disk(A) == of and dialog_visible() and meta(0)['modified'] == true)
	dialog().custom_action.emit('overwrite')
	await frames()
	var df = load_disk(A)
	check('S6f ... Overwrite writes its stored graph copy', df.nodes[&'1_1']['dialogue'].begins_with('GODOT') and newest_backup(A) == of and meta(0)['modified'] == false)
	check('S6f ... the shown file (d_b) is untouched in the graph', files.current == 1 and graph_text('1_1') == 'Line one ORIGINAL b')


# -------------------------------------------------------------- ADDON-4
func dialog_tests():
	print('--- dialog (ADDON-4)')
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	files.open_file(V)
	await frames()
	files.select_file(1)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	outside_replace(B, 'Line two ORIGINAL b', 'Line two OUTSIDE b')
	focus_in()
	await frames()
	check('D4 asks about d_b', dialog_visible() and B in dialog().dialog_text)
	outside_replace(A, 'Line two ORIGINAL a', 'Line two OUTSIDE a')
	focus_in()
	await frames()
	check('D4 while asking: a clean file changed outside still reloads', meta(0)['data'].nodes[&'1_2']['dialogue'] == 'Line two OUTSIDE a', meta(0)['data'].nodes[&'1_2']['dialogue'])
	# a second edited file joins the question
	files.select_file(2)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GV ')
	await frames()
	outside_replace(V, 'Line two ORIGINAL v', 'Line two OUTSIDE v')
	focus_in()
	await frames()
	check('D4 while asking: a second edited file joins the question', dialog_visible() and B in dialog().dialog_text and V in dialog().dialog_text and files.asking.size() == 2, [files.asking, dialog().dialog_text])
	dialog().get_ok_button().pressed.emit()
	await frames()
	check('D4 Use the file on disk applies to both', meta(1)['modified'] == false and meta(2)['modified'] == false and meta(1)['data'].nodes[&'1_2']['dialogue'] == 'Line two OUTSIDE b' and graph_text('1_2') == 'Line two OUTSIDE v', mods())


# -------------------------------------------------------------- ADDON-6
func spurious():
	print('--- spurious (ADDON-6)')
	await reset_files()
	files.open_file(A)
	files.open_file(V)
	await frames()
	files.close_file(1)
	await frames()
	check('V6a closing d_v (with variables) leaves d_a unmodified', meta(0)['modified'] == false, files.get_item_text(0))
	var out = outside_replace(A, 'ORIGINAL a', 'OUTSIDE a')
	focus_in()
	await frames()
	check('V6a ... so its outside change just reloads', not dialog_visible() and disk(A) == out and graph_text('1_1') == 'Line one OUTSIDE a')

	await reset_files()
	files.open_file(V)
	files.open_file(A)
	await frames()
	dn._on_file_menu_pressed(4) # File > Close on d_a; d_v becomes current
	await frames()
	check('V6b File > Close: d_v shown, unmodified, variables kept', files.get_item_count() == 1 and meta()['modified'] == false and dn.variables.to_dict().keys() == ['FOO'], [mods(), dn.variables.to_dict().keys()])
	dn._on_file_menu_pressed(2) # File > Save
	await frames()
	check('V6b ... and saved with its variables', load_disk(V).variables.keys() == ['FOO'], load_disk(V).variables.keys())

	await reset_files()
	files.open_file(V)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GV ')
	await frames()
	dn._on_file_menu_pressed(5) # File > Close All, then Cancel
	await frames()
	check('V6c Close All with an edited file asks', files.confirmDialogue.visible)
	confirm_cancel_button().pressed.emit()
	await frames()
	check('V6c ... Cancel keeps the variables in the panel', dn.variables.to_dict().keys() == ['FOO'], dn.variables.to_dict().keys())
	save()
	await frames()
	check('V6c ... and the save keeps them', load_disk(V).variables.keys() == ['FOO'] and 'GV ' in disk(V), load_disk(V).variables.keys())


# -------------------------------------------------------------- ADDON-7
func confirm_tests():
	print('--- confirm (ADDON-7)')
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	files.select_file(0)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	files.close_all()
	await frames()
	check('C7 close all with edited files asks', files.confirmDialogue.visible)
	files.confirmDialogue.custom_action.emit('save_file')
	await frames(5)
	check('C7 Save: all saved and closed, dialog gone, queue empty', files.get_item_count() == 0 and not files.confirmDialogue.visible and files.queued.is_empty(), [files.get_item_count(), files.confirmDialogue.visible, files.queued])
	check('C7 Save: both files hold their graph edits', 'GA ' in disk(A) and 'GB ' in disk(B), ['GA ' in disk(A), 'GB ' in disk(B)])

	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	files.close_all()
	await frames()
	confirm_cancel_button().pressed.emit()
	await frames()
	check('C7 Cancel clears the queue', files.queued.is_empty(), files.queued)
	files.close_file(1)
	await frames()
	check('C7 then closing the edited file asks again', files.confirmDialogue.visible and files.get_item_count() == 2)
	files.confirmDialogue.custom_action.emit('discard_file')
	await frames()
	check('C7 Discard closes just that file', files.get_item_count() == 1 and not 'GB ' in disk(B) and not files.confirmDialogue.visible)

	# Save in the close prompt while the file also changed outside: not closed, asks
	await reset_files()
	files.open_file(A)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	var out = outside_replace(A, 'Line two ORIGINAL a', 'Line two WEB a')
	files.close_file()
	await frames()
	files.confirmDialogue.custom_action.emit('save_file')
	await frames()
	check('C7 Save + close of a file changed outside: not written, kept open, asks', disk(A) == out and files.get_item_count() == 1 and meta(0)['modified'] == true and dialog_visible(), [files.get_item_count(), dialog_visible()])


# -------------------------------------------------------------- ADDON-8
func close_tests():
	print('--- close (ADDON-8)')
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	files.select_file(0)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	files.close_file(1)
	await frames()
	check('X8 closing another file keeps the shown file\'s unsaved edit', graph_text('1_1').begins_with('GA ') and meta(0)['modified'] == true and files.current == 0, [graph_text('1_1'), mods()])
	save()
	await frames()
	check('X8 ... and the save writes it', 'GA ' in disk(A))

	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	files.close_file(0)
	await frames()
	check('X8 closing a file listed above the shown one: d_b still shown with its edit', files.get_item_count() == 1 and files.current == 0 and meta(0)['path'] == B and graph_text('1_1').begins_with('GB '), [mods(), graph_text('1_1')])
	check('X8 ... the list selection follows', files.is_selected(0))
	save()
	await frames()
	check('X8 ... and the save writes it', 'GB ' in disk(B))


# -------------------------------------------------------------- ADDON-9
func saveas_tests():
	print('--- saveas (ADDON-9)')
	await reset_files()
	files.open_file(B)
	files.open_file(A)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	var outb = outside_replace(B, 'Line two ORIGINAL b', 'Line two OUTSIDE b')
	var nb = backups_count()
	dn.saveDialogue.current_dir = 'res://test'
	dn.saveDialogue.current_file = 'd_b.tres'
	dn.save_file('res://test/d_b.tres')
	await frames()
	var db = load_disk(B)
	check('A9 Save As onto open d_b: written straight away', db.nodes[&'1_1']['dialogue'].begins_with('GA ') and db.nodes[&'1_2']['dialogue'] == 'Line two ORIGINAL a', [db.nodes[&'1_1']['dialogue'], db.nodes[&'1_2']['dialogue']])
	check('A9 ... d_b shown with the Save As copy, not modified', files.get_item_text(files.current) == 'd_b.tres' and graph_text('1_1').begins_with('GA ') and meta()['modified'] == false, [mods(), graph_text('1_1')])
	check('A9 ... d_b\'s outside version backed up first', backups_count() == nb + 1 and newest_backup(B) == outb)
	check('A9 ... d_a keeps its own unsaved edit', meta(1)['modified'] == true)

	await reset_files()
	files.open_file(A)
	await frames()
	dn.saveDialogue.current_dir = 'res://test'
	dn.saveDialogue.current_file = 'd_c.tres'
	dn.save_file('res://test/d_c.tres')
	await frames()
	var c = load_disk('res://test/d_c.tres')
	check('A9 Save As to a new file: written, no ghost strays', c and c.nodes.size() == 4 and c.strays.is_empty(), [c.nodes.keys() if c else null])


# -------------------------------------------------------------- ADDON-3
func stale_tests():
	print('--- stale (ADDON-3)')
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	EditorInterface.set_main_screen_editor('Script')
	await frames()
	check('S3 dialogue screen hidden', not dn.is_visible_in_tree())
	var out = outside_replace(B, 'Line one ORIGINAL b', 'Line one WEB b')
	focus_in()
	await frames()
	check('S3 shown file changed outside while the dialogue screen is hidden: graph not rebuilt yet', graph_text('1_1') == 'Line one ORIGINAL b', graph_text('1_1'))
	check('S3 ... open copy is the disk one', meta(1)['data'].nodes[&'1_1']['dialogue'] == 'Line one WEB b')
	save()
	await frames()
	check('S3 ... a save leaves it alone', disk(B) == out)
	files.save_file(1) # File > Save on it
	await frames()
	check('S3 ... even an explicit Save writes the disk copy, not the old graph', load_disk(B).nodes[&'1_1']['dialogue'] == 'Line one WEB b')
	EditorInterface.set_main_screen_editor('Dialogue Nodes')
	await frames()
	check('S3 back on the dialogue screen: graph shows the outside text', graph_text('1_1') == 'Line one WEB b', graph_text('1_1'))
	# switching files while stale
	EditorInterface.set_main_screen_editor('Script')
	await frames()
	outside_replace(B, 'Line one WEB b', 'Line one WEB2 b')
	focus_in()
	await frames()
	files.select_file(0)
	await frames()
	files.select_file(1)
	await frames()
	check('S3 switching away and back while stale shows the disk copy', graph_text('1_1') == 'Line one WEB2 b', graph_text('1_1'))
	EditorInterface.set_main_screen_editor('Dialogue Nodes')
	await frames()


# --------------------------------------- variables don't leak into a new file
func newvars_tests():
	print('--- newvars')
	await reset_files()
	files.open_file(V)
	await frames()
	dn.newDialogue.current_dir = 'res://test'
	dn.newDialogue.current_file = 'd_new.tres'
	dn.new_file('res://test/d_new.tres')
	await frames()
	var nw = load_disk('res://test/d_new.tres')
	check('NV New file after a file with variables: no variables, no strays', nw and nw.variables.is_empty() and nw.strays.is_empty(), [nw.variables if nw else null])


# -------------------------------------------------------------- ADDON-1
func roundtrip_tests():
	print('--- roundtrip (ADDON-1)')
	for p in [WIN, INTRO, NIGHT, BEACH]:
		await reset_files()
		var before = disk(p)
		files.open_file(p)
		await frames()
		var t = Time.get_ticks_msec()
		save()
		var ms = Time.get_ticks_msec() - t
		await frames()
		check('R1 %s: Godot save of an unedited file leaves it byte for byte (%d ms)' % [p.get_file(), ms], disk(p) == before)
	# an edited one is still written
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	var a0 = disk(A)
	save()
	await frames()
	check('R1 edited d_b written, unedited d_a left alone', 'GB ' in disk(B) and disk(A) == a0)


# -------------------------------------------------------------- ADDON-2
func big_tests():
	print('--- big (ADDON-2)')
	await reset_files()
	var t = Time.get_ticks_msec()
	files.open_file(CLASS)
	info('open d_anna_class: %d ms, %d graph nodes' % [Time.get_ticks_msec() - t, graph_nodes()])
	await frames(3)
	var text = disk(CLASS)
	var m = RegEx.create_from_string('"dialogue": "([^"\n]{8,40})"').search(text)
	var old_line = m.get_string(1)
	outside_replace(CLASS, '"dialogue": "' + old_line + '"', '"dialogue": "WEB ' + old_line + '"')
	t = Time.get_ticks_msec()
	files.reload_changed_files()
	var reload_ms = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	await frames(1)
	info('reload: %d ms (+ %d ms next frame)' % [reload_ms, Time.get_ticks_msec() - t])
	var found = false
	for c in dn.graph.get_children():
		if c is GraphNode and c.has_method('_set_syntax_color') and c.dialogue.text == 'WEB ' + old_line:
			found = true
	check('B2 d_anna_class reload after an outside change completes and shows it', found and graph_nodes() == 2018, graph_nodes())
	# hidden screen: the reload is only a load
	EditorInterface.set_main_screen_editor('Script')
	await frames()
	outside_replace(CLASS, '"dialogue": "WEB ' + old_line + '"', '"dialogue": "WEB2 ' + old_line + '"')
	t = Time.get_ticks_msec()
	files.reload_changed_files()
	info('reload with the dialogue screen hidden: %d ms' % (Time.get_ticks_msec() - t))
	EditorInterface.set_main_screen_editor('Dialogue Nodes')
	await frames()
	await reset_files()


func _finish():
	print('RESULT: %d passed, %d failed' % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
