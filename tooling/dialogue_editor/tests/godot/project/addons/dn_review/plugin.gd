@tool
extends EditorPlugin

# Review driver for the dialogue_nodes outside-edit patch. Runs only with
# `-- --run-review[=sections]` on the command line. Prints "R:" lines.

const A = 'res://test/d_a.tres'
const B = 'res://test/d_b.tres'
const V = 'res://test/d_v.tres'
const BIG = 'res://data/game_stages/vn/anna_class/d_anna_class.tres'
const ASH = 'res://data/game_stages/vn/ashely2_intro/d_ashely2_intro.tres'
const BACKUP_ROOT = 'res://tooling/dialogue_editor/backups/'

var dn
var files
var dn_plugin
var sections = []
var big_path = BIG


func _enter_tree():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with('--run-review'):
			var s = arg.trim_prefix('--run-review').trim_prefix('=')
			sections = s.split(',', false) if s != '' else []
			_run.call_deferred()
		if arg.begins_with('--big='):
			big_path = arg.trim_prefix('--big=')


func r(msg):
	print('R: ', msg)


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
		r('!! outside edit: "%s" not found in %s' % [old, path])
		return text
	text = text.replace(old, new)
	write(path, text)
	return text


func node(id):
	return dn.graph.get_node_or_null(NodePath(id))


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


func reset_files():
	# close everything without asking, put fresh fixtures on disk
	if files.reloadDialogue and files.reloadDialogue.visible:
		files.reloadDialogue.hide()
	files.asking = []
	if files.confirmDialogue.visible:
		files.confirmDialogue.hide()
	files.queued.clear()
	# close_file still prompts for modified files even when forced: clear the flags
	for i in range(files.get_item_count()):
		var m = files.get_item_metadata(i)
		m['modified'] = false
		files.set_item_metadata(i, m)
	files.close_all(true)
	if files.confirmDialogue.visible:
		files.confirmDialogue.hide()
	files.queued.clear()
	await frames()
	if files.get_item_count() != 0:
		r('!! reset_files: %d files still open' % files.get_item_count())
	for f in ['d_a.tres', 'd_b.tres', 'bgs.tres', 'characters.tres']:
		DirAccess.copy_absolute(ProjectSettings.globalize_path('res://fixtures/' + f), ProjectSettings.globalize_path('res://test/' + f))
	var v = disk('res://fixtures/d_a.tres').replace('variables = {}', 'variables = {\n"FOO": {\n"type": 4,\n"value": "x"\n}\n}').replace('ORIGINAL a', 'ORIGINAL v')
	write(V, v)
	await frames()


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


func key_combo(ctrl : Control, keycode, ctrl_down = true, shift = false):
	ctrl.grab_focus()
	var ev = InputEventKey.new()
	ev.pressed = true
	ev.keycode = keycode
	ev.ctrl_pressed = ctrl_down
	ev.shift_pressed = shift
	get_tree().root.push_input(ev)
	var up = ev.duplicate()
	up.pressed = false
	get_tree().root.push_input(up)
	await frames(2)


func confirm_cancel_button() -> Button:
	for c in files.confirmDialogue.get_ok_button().get_parent().get_children():
		if c is Button and c.text == 'Cancel':
			return c
	return null


func mods() -> String:
	var out = []
	for i in range(files.get_item_count()):
		out.append('%s:%s' % [files.get_item_text(i), files.get_item_metadata(i)['modified']])
	return ', '.join(out) + ' current=%d' % files.current


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
		r('!! dialogue_nodes editor/plugin not found')
		get_tree().quit(1)
		return
	files = dn.files
	EditorInterface.set_main_screen_editor('Dialogue Nodes')
	get_tree().root.size = Vector2i(1920, 1080)
	await frames(5)
	r('INFO main screen visible=%s graph size=%s' % [dn.is_visible_in_tree(), dn.graph.size])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path('res://test'))

	if want('edits'):
		await edits()
	if want('spurious'):
		await spurious()
	if want('dialog'):
		await dialog_tests()
	if want('confirm'):
		await confirm_tests()
	if want('saveas'):
		await saveas_tests()
	if want('cache'):
		await cache_tests()
	if want('cache2'):
		await cache2_tests()
	if want('single'):
		await single_tests()
	if want('closeother'):
		await closeother_tests()
	if want('big'):
		await big_tests()
	if want('roundtrip'):
		await roundtrip_tests()
	r('DONE')
	get_tree().quit(0)


# ---------------------------------------------------------------- edit paths
# For each kind of graph edit: open a clean A, make the edit the way the UI
# does, check the file is marked modified, then change A outside Godot and
# save. A graph edit that isn't marked would be dropped by the reload.
func edit_case(name : String, do_edit : Callable, check_saved : Callable, prep = null):
	await reset_files()
	files.open_file(A)
	await frames()
	if prep:
		await prep.call()
		await frames()
		if meta()['modified']:
			save()
			await frames()
	var before_mod = meta()['modified']
	await do_edit.call()
	await frames(3)
	var marked = meta()['modified']
	outside_replace(A, 'ORIGINAL a', 'OUTSIDE a')
	save()
	await frames()
	var saved = load_disk(A)
	var kept = check_saved.call(saved)
	r('EDIT %-22s modified before=%s after=%s  edit on disk after outside change+save=%s' % [name, before_mod, marked, 'KEPT' if kept else 'DROPPED'])


func edits():
	r('--- edits')
	# arrange (GraphEdit's own Arrange Nodes button)
	var moves = [0]
	var cb = func(): moves[0] += 1
	dn.graph.end_node_move.connect(cb)
	await edit_case('arrange_nodes', func():
		dn.graph.arrange_nodes(),
		func(d): return d.nodes[&'1_1']['offset'] != Vector2(380, 0) or d.nodes[&'3_1']['offset'] != Vector2(740, 0))
	r('INFO arrange_nodes emitted end_node_move %d times; offsets now %s' % [moves[0], [node('0_1').position_offset, node('1_1').position_offset, node('3_1').position_offset, node('1_2').position_offset]])
	dn.graph.end_node_move.disconnect(cb)

	await edit_case('type_in_line', func():
		var n = node('1_1'); n.dialogue.set_caret_column(0); n.dialogue.insert_text_at_caret('TYPED '),
		func(d): return d.nodes[&'1_1']['dialogue'].begins_with('TYPED'))

	await edit_case('undo_in_line_ctrlz', func():
		await key_combo(node('1_1').dialogue, KEY_Z),
		func(d): return not 'TYPED' in d.nodes[&'1_1']['dialogue'],
		func():
			await type_keys(node('1_1').dialogue, 'TYPED '))

	await edit_case('type_signal_value', func():
		await type_keys(node('3_1').value, '_quick'),
		func(d): return d.nodes[&'3_1']['signalValue'] == 'fade_next_quick')

	await edit_case('undo_signal_value', func():
		await key_combo(node('3_1').value, KEY_Z),
		func(d): return d.nodes[&'3_1']['signalValue'] == 'fade_next',
		func():
			await type_keys(node('3_1').value, '_quick'))

	await edit_case('custom_speaker', func():
		await type_keys(node('1_2').customSpeaker, 'Bob'),
		func(d): return d.nodes[&'1_2']['speaker'] == 'Bob')

	await edit_case('speaker_select', func():
		var n = node('1_1'); n.speaker.select(0); n.speaker.item_selected.emit(0),
		func(d): return d.nodes[&'1_1']['speaker'] == 0)

	await edit_case('picture_select', func():
		var n = node('1_1'); n.background.select(2); n.background.item_selected.emit(2),
		func(d): return d.nodes[&'1_1']['background'] == 2)

	await edit_case('reset_picture_list', func():
		node('1_1').get_node('HBoxContainer5/ResetBackgroundList').pressed.emit(),
		func(d): return d.nodes[&'1_1']['backgroundList'] == -1)

	await edit_case('expanded_text', func():
		var n = node('1_1'); n.dialogue_expanded.text = n.dialogue.text; n.dialogue_expanded.set_caret_column(0); n.dialogue_expanded.insert_text_at_caret('EXP '),
		func(d): return d.nodes[&'1_1']['dialogue'].begins_with('EXP'))

	await edit_case('resize_line_node', func():
		node('1_1').resize_request.emit(Vector2(420, 700)),
		func(d): return d.nodes[&'1_1']['size'] == Vector2(420, 700))

	await edit_case('option_text', func():
		await type_keys(node('1_1').options[0].line_edit, 'Choice'),
		func(d): return d.nodes[&'1_1']['options'][0]['text'] == 'Choice')

	await edit_case('start_id', func():
		await type_keys(node('0_1').get_node('HBoxContainer/ID'), '2'),
		func(d): return d.starts.has('START2'))

	await edit_case('characters_reset', func():
		dn.characters.resetButton.pressed.emit(),
		func(d): return d.characters == '')

	await edit_case('bglists_path_typed', func():
		await type_keys(dn.backgroundLists.filePath, 'x'),
		func(d): return d.backgroundList.ends_with('x'))

	await edit_case('add_variable', func():
		dn.variables.add_variable('NEWVAR'),
		func(d): return d.variables.has('NEWVAR'))

	await edit_case('delete_node_key', func():
		dn.graph.delete_nodes_request.emit([&'3_1']),
		func(d): return not d.nodes.has(&'3_1'))

	await edit_case('disconnect', func():
		dn.graph.disconnection_request.emit(&'1_1', 0, &'3_1', 0),
		func(d): return d.nodes[&'1_1']['options'][0]['link'] == 'END')

	await edit_case('duplicate', func():
		dn.workspace._select_all_nodes(false); node('1_2').selected = true; dn.graph.duplicate_nodes_request.emit(),
		func(d): return d.nodes.size() > 4)


# ------------------------------------------------- spurious "modified" flags
func spurious():
	r('--- spurious')
	# closing a file that has variables (popup menu Close) while another is open
	await reset_files()
	files.open_file(A)
	files.open_file(V)
	await frames()
	r('INFO open: %s current=%d' % [[files.get_item_text(0), files.get_item_text(1)], files.current])
	files.close_file(1)
	await frames()
	r('SPUR close d_v (popup Close): d_a (untouched) modified=%s text=%s' % [meta(0)['modified'], files.get_item_text(0)])
	var nb = backups_count()
	var out = outside_replace(A, 'ORIGINAL a', 'OUTSIDE a')
	focus_in()
	await frames()
	r('SPUR   then outside change + focus-in: reload dialog shown=%s' % files.reloadDialogue.visible)
	if files.reloadDialogue.visible:
		files.reloadDialogue.get_cancel_button().pressed.emit()
		await frames()
	save()
	await frames()
	r('SPUR   then Keep mine + save: outside edit survived on disk=%s, backups made=%d' % [disk(A) == out, backups_count() - nb])

	# File menu > Close (editor.gd also clears the variables after the close)
	await reset_files()
	files.open_file(V)
	files.open_file(A)
	files.select_file(0)
	await frames()
	r('INFO current=%s vars in panel=%s' % [files.get_item_text(files.current), dn.variables.to_dict().keys()])
	files.select_file(1)
	await frames()
	dn._on_file_menu_pressed(4) # File > Close on d_a; d_v becomes current
	await frames()
	r('SPUR File>Close d_a: d_v now current=%s modified=%s vars in panel=%s' % [files.get_item_text(files.current), meta()['modified'], dn.variables.to_dict().keys()])
	save()
	await frames()
	r('SPUR   then save: d_v variables on disk=%s' % [load_disk(V).variables.keys()])

	# File menu > Close All with an edited file, then Cancel
	await reset_files()
	files.open_file(V)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GV ')
	await frames()
	dn._on_file_menu_pressed(5)
	await frames()
	r('SPUR File>Close All with edited d_v: prompt=%s vars in panel=%s' % [files.confirmDialogue.visible, dn.variables.to_dict().keys()])
	confirm_cancel_button().pressed.emit()
	await frames()
	save()
	await frames()
	r('SPUR   then Cancel + save: d_v variables on disk=%s, graph edit on disk=%s' % [load_disk(V).variables.keys(), 'GV ' in disk(V)])


# -------------------------------------------------------------- the dialog
func dialog_tests():
	r('--- dialog')
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	# both edited in the graph, both changed outside
	files.select_file(0)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	files.select_file(1)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	r('INFO modified A=%s B=%s current=%d' % [meta(0)['modified'], meta(1)['modified'], files.current])
	outside_replace(A, 'Line two ORIGINAL a', 'Line two OUTSIDE a')
	outside_replace(B, 'Line two ORIGINAL b', 'Line two OUTSIDE b')
	focus_in()
	await frames()
	r('DLG visible=%s exclusive=%s title=%s' % [files.reloadDialogue.visible, files.reloadDialogue.exclusive, files.reloadDialogue.title])
	r('DLG text=<<%s>>' % files.reloadDialogue.dialog_text)
	r('DLG buttons ok=%s cancel=%s' % [files.reloadDialogue.get_ok_button().text, files.reloadDialogue.get_cancel_button().text])
	# while it is open, a third file changes outside: quiet reload?
	files.reloadDialogue.get_ok_button().pressed.emit()
	await frames()
	r('DLG Reload: A modified=%s A data line2=%s ; B(current) modified=%s graph line2=%s' % [meta(0)['modified'], meta(0)['data'].nodes[&'1_2']['dialogue'], meta(1)['modified'], node('1_2').dialogue.text])

	# dialog open blocks quiet reloads of other files
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	outside_replace(B, 'Line two ORIGINAL b', 'Line two OUTSIDE b')
	focus_in()
	await frames()
	var vis1 = files.reloadDialogue.visible
	outside_replace(A, 'Line two ORIGINAL a', 'Line two OUTSIDE a')
	focus_in()
	await frames()
	r('DLG while asking about B, A (clean) changed + focus-in: A reloaded=%s (dialog visible=%s)' % [meta(0)['data'].nodes[&'1_2']['dialogue'] == 'Line two OUTSIDE a', vis1])
	# closing the dialog with the window X = canceled?
	files.reloadDialogue.notification(Window.NOTIFICATION_WM_CLOSE_REQUEST)
	await frames()
	r('DLG window X (WM_CLOSE_REQUEST): visible=%s B still modified=%s asking=%s' % [files.reloadDialogue.visible, meta(1)['modified'], files.asking])


# ------------------------------------------- close dialog (pre-existing bug)
func confirm_tests():
	r('--- confirm')
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
	r('CONF before close_all: ' + mods())
	files.close_all()
	await frames()
	r('CONF close_all: dialog visible=%s queued=%s' % [files.confirmDialogue.visible, files.queued])
	files.confirmDialogue.custom_action.emit('save_file')
	await frames(5)
	r('CONF after Save: open files=%d dialog visible=%s queued=%s; A on disk has GA=%s; B on disk has GB=%s' % [files.get_item_count(), files.confirmDialogue.visible, files.queued, 'GA ' in disk(A), 'GB ' in disk(B)])
	confirm_cancel_button().pressed.emit()
	await frames()
	r('CONF after Cancel: dialog visible=%s queued=%s (not cleared => stale)' % [files.confirmDialogue.visible, files.queued])

	# stale queue: cancel the close-all prompt, then close an edited file
	files.queued.clear()
	files.close_all(true)
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
	r('CONF Cancel on close-all prompt: queued now=%s' % [files.queued])
	var before = files.get_item_count()
	files.close_file(1) # the edited B
	await frames()
	r('CONF then close edited B: prompt shown=%s, files open %d -> %d, B graph edit on disk=%s' % [files.confirmDialogue.visible, before, files.get_item_count(), 'GB ' in disk(B)])


# ---------------------------------------------------------- Save As / New
func saveas_tests():
	r('--- saveas')
	# Save As onto a file that is already open, which the outside editor changed
	await reset_files()
	files.open_file(B)
	files.open_file(A)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	r('SAVEAS before: ' + mods())
	var outb = outside_replace(B, 'Line two ORIGINAL b', 'Line two OUTSIDE b')
	dn.saveDialogue.current_dir = 'res://test'
	dn.saveDialogue.current_file = 'd_b.tres'
	dn.save_file('res://test/d_b.tres')
	await frames()
	r('SAVEAS onto open d_b: current=%s graph line1=%s; d_b disk == outside=%s' % [files.get_item_text(files.current), node('1_1').dialogue.text, disk(B) == outb])
	save()
	await frames()
	r('SAVEAS   then save: d_b disk line1=%s line2=%s ; outside edit survived=%s backups=%d' % [load_disk(B).nodes[&'1_1']['dialogue'], load_disk(B).nodes[&'1_2']['dialogue'], 'OUTSIDE b' in disk(B), backups_count()])

	# Save As to a new file / New: no ghost strays from the previous graph
	await reset_files()
	files.open_file(A)
	await frames()
	dn.saveDialogue.current_dir = 'res://test'
	dn.saveDialogue.current_file = 'd_c.tres'
	dn.save_file('res://test/d_c.tres')
	await frames()
	var c = load_disk('res://test/d_c.tres')
	r('SAVEAS new d_c: nodes=%s strays=%s' % [c.nodes.keys(), c.strays])
	dn.newDialogue.current_dir = 'res://test'
	dn.newDialogue.current_file = 'd_new.tres'
	dn.new_file('res://test/d_new.tres')
	await frames()
	var nw = load_disk('res://test/d_new.tres')
	r('NEW d_new: nodes=%s strays=%s' % [nw.nodes.keys() if nw else 'null', nw.strays if nw else 'null'])


# ----------------------------------------- Inspector / ResourceLoader cache
func find_prop(root : Node, prop : StringName):
	for c in root.get_children():
		if c is EditorProperty and c.get_edited_property() == prop:
			return c
		var f = find_prop(c, prop)
		if f:
			return f
	return null


func find_line_edit(root : Node):
	for c in root.get_children():
		if c is LineEdit:
			return c
		var f = find_line_edit(c)
		if f:
			return f
	return null


func cache_tests():
	r('--- cache')
	await reset_files()
	write('res://s.tscn', '[gd_scene format=3]

[node name="S" type="Node"]
')
	var fs = EditorInterface.get_resource_filesystem()
	fs.scan()
	await frames(5)
	while fs.is_scanning():
		await frames(1)
	EditorInterface.open_scene_from_path('res://s.tscn')
	await frames(5)
	r('CACHE scene open: %s' % EditorInterface.get_edited_scene_root())
	# does Ctrl+S (save_scene) reach the addon? a graph edit in d_b tells
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('VIA_SAVE_SCENE ')
	await frames()
	EditorInterface.mark_scene_as_unsaved()
	EditorInterface.save_scene()
	await frames(5)
	r('CACHE save_scene() wrote the addon edit (plugin _save_external_data called)=%s' % ('VIA_SAVE_SCENE' in disk(B)))
	node('1_1').dialogue.insert_text_at_caret('VIA_SAVE_ALL ')
	await frames()
	EditorInterface.save_all_scenes()
	await frames(5)
	r('CACHE save_all_scenes() wrote the addon edit=%s' % ('VIA_SAVE_ALL' in disk(B)))
	await reset_files()

	var res = load(A) # what a FileSystem-dock double-click loads (cached)
	EditorInterface.edit_resource(res)
	await frames(5)
	r('CACHE after edit_resource: addon files open=%d (%s), inspector shows it=%s, same object as addon copy=%s' % [files.get_item_count(), files.get_item_text(0) if files.get_item_count() else '-', EditorInterface.get_inspector().get_edited_object() == res, files.get_item_count() > 0 and meta(0)['data'] == res])
	var out = outside_replace(A, 'Line one ORIGINAL a', 'Line one OUTSIDE a')
	focus_in()
	fs.scan()
	await frames(5)
	while fs.is_scanning():
		await frames(1)
	await frames(10)
	r('CACHE after outside change + focus-in + scan: cached copy line1=%s; addon graph line1=%s' % [res.nodes[&'1_1']['dialogue'], node('1_1').dialogue.text if node('1_1') else '-'])
	EditorInterface.mark_scene_as_unsaved()
	EditorInterface.save_scene()
	await frames(5)
	r('CACHE untouched cached copy, save_scene: disk still the outside version=%s' % (disk(A) == out))
	# a real Inspector edit of the cached copy (type into its "characters" field)
	var prop = find_prop(EditorInterface.get_inspector(), &'characters')
	var le = find_line_edit(prop) if prop else null
	r('CACHE inspector property editor for characters: %s / %s' % [prop, le])
	if le:
		await type_keys(le, 'Z')
		var ev = InputEventKey.new(); ev.pressed = true; ev.keycode = KEY_ENTER
		get_tree().root.push_input(ev)
		await frames(3)
		r('CACHE after typing in the inspector: cached copy characters=%s' % res.characters)
	var out2 = outside_replace(A, 'Line two ORIGINAL a', 'Line two OUTSIDE a')
	EditorInterface.mark_scene_as_unsaved()
	EditorInterface.save_scene()
	await frames(5)
	var d = disk(A)
	r('CACHE inspector-edited cached copy + outside change + save_scene: outside edit survived=%s; inspector edit on disk=%s' % ['Line two OUTSIDE a' in d, '.tresZ' in d])
	EditorInterface.edit_resource(null)


# ---------------------------------------------------------------- big file
func big_tests():
	var BIGP = big_path
	r('--- big ' + BIGP)
	await reset_files()
	var t = Time.get_ticks_usec()
	for i in range(10):
		FileAccess.get_md5(BIGP)
	r('BIG md5 of %d bytes: %d us' % [FileAccess.get_file_as_bytes(BIGP).size(), (Time.get_ticks_usec() - t) / 10])
	t = Time.get_ticks_msec()
	files.open_file(BIGP)
	var open_ms = Time.get_ticks_msec() - t
	await frames()
	var n = 0
	for c in dn.graph.get_children():
		if c is GraphNode:
			n += 1
	r('BIG open: %d ms, %d graph nodes, graph size %s' % [open_ms, n, dn.graph.size])
	t = Time.get_ticks_msec()
	var gd = dn.get_data()
	r('BIG editor.get_data(): %d ms (%d nodes)' % [Time.get_ticks_msec() - t, gd.nodes.size()])
	dn.graph.zoom = 0.6
	await frames(2)
	dn.graph.scroll_offset = Vector2(2000, 800)
	await frames(3)
	var z0 = dn.graph.zoom
	var s0 = dn.graph.scroll_offset
	var text = disk(BIGP)
	var m = RegEx.create_from_string('"dialogue": "([^"\n]{8,40})"').search(text)
	var old_line = m.get_string(1)
	outside_replace(BIGP, '"dialogue": "' + old_line + '"', '"dialogue": "WEB ' + old_line + '"')
	t = Time.get_ticks_msec()
	files.reload_changed_files()
	var reload_ms = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	await frames(1)
	var free_ms = Time.get_ticks_msec() - t
	await frames(3)
	r('BIG focus-in reload: %d ms (+ %d ms for the next frame, which frees the old graph); zoom %s -> %s; scroll %s -> %s' % [reload_ms, free_ms, z0, dn.graph.zoom, s0, dn.graph.scroll_offset])
	var found = false
	for c in dn.graph.get_children():
		if c is GraphNode and c.has_method('_set_syntax_color') and c.dialogue.text == 'WEB ' + old_line:
			found = true
	r('BIG graph shows the web edit=%s, modified=%s' % [found, meta()['modified']])
	var before = disk(BIGP)
	t = Time.get_ticks_msec()
	save()
	r('BIG Godot save (no graph edits, disk unchanged): %d ms; file byte-identical afterwards=%s' % [Time.get_ticks_msec() - t, disk(BIGP) == before])
	write('res://out_big_before.txt', before)
	write('res://out_big_after.txt', disk(BIGP))
	t = Time.get_ticks_usec()
	files.reload_changed_files()
	r('BIG focus-in with nothing changed: %d us' % (Time.get_ticks_usec() - t))
	# save while the web editor's change is still unseen (Ctrl+S right after alt-tab)
	outside_replace(BIGP, '"dialogue": "WEB ' + old_line + '"', '"dialogue": "WEB2 ' + old_line + '"')
	t = Time.get_ticks_msec()
	save()
	r('BIG save with an unseen outside change: %d ms; outside edit kept=%s' % [Time.get_ticks_msec() - t, ('WEB2 ' + old_line) in disk(BIGP)])
	await frames(3)


func roundtrip_tests():
	r('--- roundtrip')
	for p in [ASH, 'res://data/game_stages/vn/ashely2_win/d_ashely2_win.tres', 'res://data/game_stages/vn/anna_night/d_anna_night.tres', 'res://data/game_stages/vn/lisa_beach_beach/d_lisa_beach_beach.tres']:
		await reset_files()
		var before = disk(p)
		files.open_file(p, true)
		await frames()
		save()
		await frames()
		var after = disk(p)
		r('RT %s: Godot save of an unedited, unchanged open file: byte-identical=%s (len %d -> %d)' % [p, after == before, before.length(), after.length()])
		write('res://out_rt_' + p.get_file() + '.before', before)
		write('res://out_rt_' + p.get_file() + '.after', after)


# Which Godot saves write a cached DialogueData (FileSystem-dock double-click)?
func cache2_tests():
	r('--- cache2')
	await reset_files()
	write('res://s.tscn', '[gd_scene format=3]

[node name="S" type="Node"]
')
	var fs = EditorInterface.get_resource_filesystem()
	fs.scan()
	await frames(5)
	while fs.is_scanning():
		await frames(1)
	EditorInterface.open_scene_from_path('res://s.tscn')
	await frames(5)
	var names = ['V1 load() only', 'V2 load()+edit_resource, addon copy closed', 'V3 edit_resource, addon copy kept open']
	for v in range(3):
		await reset_files()
		fs.scan()
		await frames(3)
		while fs.is_scanning():
			await frames(1)
		var res = load(A)
		if v >= 1:
			EditorInterface.edit_resource(res)
			await frames(3)
		if v == 1:
			files.close_file(0)
			await frames()
		var before = disk(A)
		var md0 = FileAccess.get_md5(A)
		EditorInterface.mark_scene_as_unsaved()
		EditorInterface.save_scene()
		await frames(3)
		r('C2 %s: no outside change, save_scene rewrote the file=%s' % [names[v], FileAccess.get_md5(A) != md0])
		# outside change, then save before any scan / focus-in
		var out = outside_replace(A, 'Line one ORIGINAL a', 'Line one OUTSIDE a')
		EditorInterface.mark_scene_as_unsaved()
		EditorInterface.save_scene()
		await frames(3)
		var d = disk(A)
		r('C2 %s: outside change then save_scene (no scan yet): disk byte-identical to outside=%s, outside text still there=%s, backups=%d' % [names[v], d == out, 'Line one OUTSIDE a' in d, backups_count()])
		if d != out:
			write('res://out_c2_%d_outside.txt' % v, out)
			write('res://out_c2_%d_after.txt' % v, d)
		# and after a scan
		var out2 = outside_replace(A, 'Line two ORIGINAL a', 'Line two OUTSIDE a')
		focus_in()
		fs.scan()
		await frames(3)
		while fs.is_scanning():
			await frames(1)
		await frames(5)
		r('C2 %s: after second outside change + scan: cached copy line2=%s' % [names[v], res.nodes[&'1_2']['dialogue']])
		EditorInterface.mark_scene_as_unsaved()
		EditorInterface.save_scene()
		await frames(3)
		d = disk(A)
		r('C2 %s:   then save_scene: outside texts still there=%s/%s' % [names[v], 'Line one OUTSIDE a' in d, 'Line two OUTSIDE a' in d])
		EditorInterface.edit_resource(null)
		res = null
		await frames(3)


# anna_class: does a single graph build fit, and does a reload (old graph still alive) crash?
func single_tests():
	r('--- single ' + big_path)
	await reset_files()
	var t = Time.get_ticks_msec()
	files.open_file(big_path, true) # internal: one graph build instead of two
	r('SINGLE open (one build): %d ms' % (Time.get_ticks_msec() - t))
	await frames(3)
	var n = 0
	for c in dn.graph.get_children():
		if c is GraphNode:
			n += 1
	r('SINGLE graph nodes=%d' % n)
	var items = 0
	var controls = 0
	var windows = 0
	var stack = [dn.graph]
	while stack.size() > 0:
		var x = stack.pop_back()
		if x is OptionButton:
			items += x.item_count
		if x is Control:
			controls += 1
		if x is Window:
			windows += 1
		for ch in x.get_children(true):
			stack.append(ch)
	r('SINGLE OptionButton items in the graph=%d, Controls=%d, Windows=%d' % [items, controls, windows])
	if '--count-only' in OS.get_cmdline_user_args():
		return
	var text = disk(big_path)
	var m = RegEx.create_from_string('"dialogue": "([^"\n]{8,40})"').search(text)
	outside_replace(big_path, '"dialogue": "' + m.get_string(1) + '"', '"dialogue": "WEB ' + m.get_string(1) + '"')
	r('SINGLE reloading after an outside change...')
	t = Time.get_ticks_msec()
	files.reload_changed_files()
	r('SINGLE reload: %d ms' % (Time.get_ticks_msec() - t))
	await frames(3)


# closing another file while the shown one has unsaved graph edits
func closeother_tests():
	r('--- closeother')
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	files.select_file(0)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GA ')
	await frames()
	r('CLOSE before: ' + mods() + ' graph line1=' + node('1_1').dialogue.text)
	files.close_file(1) # popup Close on the other (clean) file d_b
	await frames()
	r('CLOSE after closing d_b: ' + mods() + ' graph line1=' + node('1_1').dialogue.text)
	save()
	await frames()
	r('CLOSE   then save: d_a on disk has GA=%s' % ('GA ' in disk(A)))
	# closing a file listed before the shown one
	await reset_files()
	files.open_file(A)
	files.open_file(B)
	await frames()
	node('1_1').dialogue.insert_text_at_caret('GB ')
	await frames()
	r('CLOSE before: ' + mods() + ' graph line1=' + node('1_1').dialogue.text)
	files.close_file(0) # close d_a (listed first) while d_b is shown
	await frames()
	r('CLOSE after closing d_a: ' + mods() + ' graph line1=' + node('1_1').dialogue.text)
