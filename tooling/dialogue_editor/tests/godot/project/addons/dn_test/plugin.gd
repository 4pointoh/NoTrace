@tool
extends EditorPlugin

# Drives the dialogue_nodes editor in a headless editor run and checks that
# files changed outside Godot are reloaded / backed up instead of overwritten.
# Runs only with `-- --run-dn-test` on the command line.

const A = 'res://test/d_a.tres'
const B = 'res://test/d_b.tres'
const BACKUP_DIR = 'res://tooling/dialogue_editor/backups/test/d_a.tres'
const BACKUP_ROOT = 'res://tooling/dialogue_editor/backups/'

var dn # the dialogue_nodes NodeEditor control
var files
var dn_plugin
var passed = 0
var failed = 0


func _enter_tree():
	if '--run-dn-test' in OS.get_cmdline_user_args():
		_run.call_deferred()


func check(name, ok, detail = ''):
	if ok:
		passed += 1
		print('PASS: ', name)
	else:
		failed += 1
		print('FAIL: ', name, ('  -- ' + str(detail)) if str(detail) != '' else '')


func frames(n = 3):
	for i in range(n):
		await get_tree().process_frame


func disk(path) -> String:
	return FileAccess.get_file_as_string(path)


# what an outside editor does: rewrite the file with one string replaced
func outside_replace(path, old, new) -> String:
	var text = disk(path)
	if not old in text:
		check('outside edit finds "%s" in %s' % [old, path], false, 'text not found')
		return text
	text = text.replace(old, new)
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return text


func node(id):
	return dn.graph.get_node_or_null(NodePath(id))


func graph_text(id) -> String:
	var n = node(id)
	return n.dialogue.text if n else '<missing>'


# a graph edit the way the UI makes it: text set, then text_changed
func graph_edit(id, text):
	var n = node(id)
	n.dialogue.text = text
	n.dialogue.text_changed.emit()


func meta(idx = 0) -> Dictionary:
	return files.get_item_metadata(idx)


func load_disk(path) -> DialogueData:
	return ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE)


func backups() -> PackedStringArray:
	var dir = ProjectSettings.globalize_path(BACKUP_DIR)
	if not DirAccess.dir_exists_absolute(dir):
		return PackedStringArray()
	return DirAccess.get_files_at(dir)


func focus_in():
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)


func save():
	# what F5 / Ctrl+S end up calling
	if dn_plugin:
		dn_plugin._save_external_data()
	else:
		files.save_all()


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
	check('found the dialogue_nodes editor', dn != null)
	if dn == null:
		_finish()
		return
	files = dn.files
	EditorInterface.set_main_screen_editor('Dialogue Nodes')
	await frames()
	print('INFO: saving through ', 'plugin._save_external_data()' if dn_plugin else 'files.save_all()')

	var patched = files.get_script().get_script_constant_map().get('EXTERNAL_EDIT_SAFE', false)
	print('INFO: files.gd EXTERNAL_EDIT_SAFE = ', patched)

	files.open_file(A)
	await frames()
	check('opened d_a, graph shows it', graph_text('1_1') == 'Line one ORIGINAL a', graph_text('1_1'))
	check('characters loaded (2)', dn.characters.characterList.size() == 2, dn.characters.characterList.size())
	check('picture lists loaded (1)', dn.backgroundLists.bgLists.size() == 1, dn.backgroundLists.bgLists.size())

	if not patched:
		# baseline: show the hazard the patch fixes
		var outside = outside_replace(A, 'Line one ORIGINAL a', 'Line one OUTSIDE-1')
		save()
		check('BASELINE unpatched: outside edit survives a save', disk(A) == outside, 'disk now says: ' + ('OUTSIDE-1 kept' if 'OUTSIDE-1' in disk(A) else 'OUTSIDE-1 gone (overwritten)'))
		await frames()
		node('1_1').background.select(2)
		node('1_1').background.item_selected.emit(2)
		print('INFO: BASELINE unpatched: picking a picture marks the file modified = ', meta()['modified'])
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with('--hotswap='):
				await _hotswap(arg.trim_prefix('--hotswap='))
		_finish()
		return

	check('marker Files.EXTERNAL_EDIT_SAFE is true', patched == true)

	# --- 1: no graph edits, file changed outside, Godot saves -------------
	var out1 = outside_replace(A, 'Line one ORIGINAL a', 'Line one OUTSIDE-1')
	save()
	check('1 clean+changed: disk file left exactly as the outside editor wrote it', disk(A) == out1)
	check('1 clean+changed: graph reloaded with the outside text', graph_text('1_1') == 'Line one OUTSIDE-1', graph_text('1_1'))
	check('1 clean+changed: open copy is the outside one', meta()['data'].nodes[&'1_1']['dialogue'] == 'Line one OUTSIDE-1')
	check('1 clean+changed: not marked modified', meta()['modified'] == false and not files.get_item_text(0).ends_with('(*)'), files.get_item_text(0))
	check('1 clean+changed: no backup made', backups().size() == 0, backups())

	# same frame as the reload: the graph still holds the nodes it's freeing
	var ghosts = dn.get_data().strays.size()
	print('INFO: editor.get_data() lists ', ghosts, ' freed-but-not-yet-deleted nodes as strays this frame')
	save()
	var saved1 = load_disk(A)
	check('1b save in the reload frame writes no ghost strays', saved1.strays.size() == 0 and saved1.nodes.size() == 4, 'strays=%s nodes=%s' % [saved1.strays, saved1.nodes.keys()])
	check('1b save in the reload frame keeps the outside text', saved1.nodes[&'1_1']['dialogue'] == 'Line one OUTSIDE-1')
	await frames()

	# --- 2: graph edits AND file changed outside, Godot saves -------------
	graph_edit('1_2', 'Line two GRAPH')
	check('2 graph edit marks the file modified', meta()['modified'] == true and files.get_item_text(0).ends_with('(*)'))
	var out2 = outside_replace(A, 'Line one OUTSIDE-1', 'Line one OUTSIDE-2')
	save()
	await frames()
	check('2 modified+changed: a save does not write it', disk(A) == out2 and backups().size() == 0 and meta()['modified'] == true)
	check('2 modified+changed: a save asks instead', files.reloadDialogue.visible and A in files.reloadDialogue.dialog_text)
	files.reloadDialogue.custom_action.emit('overwrite')
	await frames()
	var b = backups()
	check('2 Overwrite: one backup made', b.size() == 1, b)
	if b.size() > 0:
		check('2 modified+changed: backup name is <timestamp>-outside-godot.tres.bak', b[0].ends_with('-outside-godot.tres.bak') and b[0].length() == len('20261019-120000-000-outside-godot.tres.bak'), b[0])
		check('2 modified+changed: backup holds the outside version byte for byte', disk(BACKUP_DIR + '/' + b[0]) == out2)
	check('2 backups folder has .gdignore', FileAccess.file_exists(BACKUP_ROOT + '.gdignore'))
	check('2 backups folder has .gitignore with *', disk(BACKUP_ROOT + '.gitignore').strip_edges() == '*', disk(BACKUP_ROOT + '.gitignore'))
	var saved2 = load_disk(A)
	check('2 Overwrite: graph edits written', saved2.nodes[&'1_2']['dialogue'] == 'Line two GRAPH', saved2.nodes[&'1_2']['dialogue'])
	check('2 Overwrite: rest of the file is the graph copy', saved2.nodes[&'1_1']['dialogue'] == 'Line one OUTSIDE-1')
	check('2 after Overwrite: not modified, dialog closed', meta()['modified'] == false and not files.reloadDialogue.visible)
	await frames()

	# --- 3: no graph edits, file changed outside, Godot regains focus ------
	var out3 = outside_replace(A, 'Line two GRAPH', 'Line two OUTSIDE-3')
	focus_in()
	await frames()
	check('3 focus-in clean+changed: graph shows the outside text', graph_text('1_2') == 'Line two OUTSIDE-3', graph_text('1_2'))
	check('3 focus-in clean+changed: disk untouched', disk(A) == out3)
	check('3 focus-in clean+changed: no question asked', not files.reloadDialogue.visible)
	await frames()

	# --- 4: graph edits AND outside change, focus-in, answer "Decide later" ---
	graph_edit('1_1', 'Line one GRAPH-4')
	var out4 = outside_replace(A, 'Line two OUTSIDE-3', 'Line two OUTSIDE-4')
	focus_in()
	await frames()
	check('4 focus-in modified+changed: asks', files.reloadDialogue.visible and A in files.reloadDialogue.dialog_text, files.reloadDialogue.dialog_text)
	check('4 while asking: graph edit still there', graph_text('1_1') == 'Line one GRAPH-4')
	files.reloadDialogue.get_cancel_button().pressed.emit()
	await frames()
	check('4 Decide later: dialog closed, graph edit kept, still modified', not files.reloadDialogue.visible and graph_text('1_1') == 'Line one GRAPH-4' and meta()['modified'] == true)
	check('4 Decide later: disk untouched', disk(A) == out4)
	focus_in()
	await frames()
	check('4 Decide later: not asked again on focus-in for the same outside version', not files.reloadDialogue.visible)
	save()
	await frames()
	check('4 save after Decide later: not written, no backup, asks again', disk(A) == out4 and backups().size() == 1 and files.reloadDialogue.visible)
	files.reloadDialogue.custom_action.emit('overwrite')
	await frames()
	b = backups()
	check('4 then Overwrite: second backup, holding the outside version', b.size() == 2 and disk(BACKUP_DIR + '/' + b[b.size() - 1]) == out4, b)
	var saved4 = load_disk(A)
	check('4 then Overwrite: graph copy written', saved4.nodes[&'1_1']['dialogue'] == 'Line one GRAPH-4' and saved4.nodes[&'1_2']['dialogue'] == 'Line two OUTSIDE-3')
	await frames()

	# --- 5: graph edits AND outside change, focus-in, "Reload from disk" ---
	graph_edit('1_1', 'Line one GRAPH-5')
	var out5 = outside_replace(A, 'Line two OUTSIDE-3', 'Line two OUTSIDE-5')
	focus_in()
	await frames()
	check('5 focus-in modified+changed: asks', files.reloadDialogue.visible)
	files.reloadDialogue.get_ok_button().pressed.emit()
	await frames()
	check('5 Reload from disk: graph shows the disk copy', graph_text('1_1') == 'Line one GRAPH-4' and graph_text('1_2') == 'Line two OUTSIDE-5', [graph_text('1_1'), graph_text('1_2')])
	check('5 Reload from disk: not modified, disk untouched', meta()['modified'] == false and disk(A) == out5)
	await frames()

	# --- 6: line edits the node scene never reported now mark modified ----
	var n = node('1_1')
	check('6 picture options present (3)', n.background.item_count == 3, n.background.item_count)
	n.background.select(2)
	n.background.item_selected.emit(2)
	check('6 picking a picture marks modified', meta()['modified'] == true)
	var out6 = outside_replace(A, 'Line two OUTSIDE-5', 'Line two OUTSIDE-6')
	save()
	await frames()
	check('6 picture change + outside change: a save asks, does not drop or write it', files.reloadDialogue.visible and disk(A) == out6 and meta()['modified'] == true)
	files.reloadDialogue.custom_action.emit('overwrite')
	await frames()
	var saved6 = load_disk(A)
	check('6 ... Overwrite: picture change written', saved6.nodes[&'1_1']['background'] == 2, saved6.nodes[&'1_1']['background'])
	b = backups()
	check('6 ... Overwrite: outside version backed up', b.size() == 3 and disk(BACKUP_DIR + '/' + b[b.size() - 1]) == out6, b)
	await frames()
	n = node('1_1')
	check('6 character states present (2)', n.characterState.item_count == 2, n.characterState.item_count)
	n.characterState.select(1)
	n.characterState.item_selected.emit(1)
	check('6 picking a character state marks modified', meta()['modified'] == true)
	save()
	check('6 character state saved', load_disk(A).nodes[&'1_1']['characterState'] == 1)
	await frames()
	node('1_1').get_node('HBoxContainer5/ResetBackgroundList').pressed.emit()
	check('6 resetting the picture list marks modified', meta()['modified'] == true)
	save()
	await frames()
	node('1_1').get_node('HBoxContainer4/ResetCharacterState').pressed.emit()
	check('6 resetting the character state marks modified', meta()['modified'] == true)
	save()
	await frames()

	# --- 7: a clean file that isn't in the graph -------------------------
	files.open_file(B)
	await frames()
	check('7 d_b open and current', files.current == 1 and graph_text('1_1') == 'Line one ORIGINAL b', [files.current, graph_text('1_1')])
	# (step 6 kept the graph's line two, OUTSIDE-5; OUTSIDE-6 went to the backup)
	var out7 = outside_replace(A, 'Line two OUTSIDE-5', 'Line two OUTSIDE-7')
	save()
	check('7 background file changed outside: not written over', disk(A) == out7)
	check('7 background file changed outside: open copy reloaded', meta(0)['data'].nodes[&'1_2']['dialogue'] == 'Line two OUTSIDE-7')
	check('7 the graph file (d_b, no graph edits) not written', disk(B) == FileAccess.get_file_as_string('res://fixtures/d_b.tres'))
	files.select_file(0)
	await frames()
	check('7 switching to it shows the outside text', graph_text('1_2') == 'Line two OUTSIDE-7', graph_text('1_2'))
	await frames()

	# --- 8: an edited file that isn't in the graph, changed outside -------
	graph_edit('1_1', 'Line one GRAPH-8')
	files.select_file(1)
	await frames()
	check('8 d_a edited then left: still modified, d_b in the graph', meta(0)['modified'] == true and files.current == 1)
	var out8 = outside_replace(A, 'Line two OUTSIDE-7', 'Line two OUTSIDE-8')
	var before8 = backups().size()
	save()
	await frames()
	check('8 edited background file changed outside: a save asks, does not write it', files.reloadDialogue.visible and disk(A) == out8 and backups().size() == before8)
	files.reloadDialogue.custom_action.emit('overwrite')
	await frames()
	b = backups()
	check('8 ... Overwrite: backed up', b.size() == before8 + 1 and disk(BACKUP_DIR + '/' + b[b.size() - 1]) == out8, b)
	var saved8 = load_disk(A)
	check('8 ... Overwrite: its graph edits written', saved8.nodes[&'1_1']['dialogue'] == 'Line one GRAPH-8' and saved8.nodes[&'1_2']['dialogue'] == 'Line two OUTSIDE-7', [saved8.nodes[&'1_1']['dialogue'], saved8.nodes[&'1_2']['dialogue']])
	check('8 after save: not modified', meta(0)['modified'] == false)

	_finish()


# Install the patched scripts while the editor runs with d_a open (old code),
# the way copying the patch into an open project would.
func _hotswap(from_dir):
	for f in ['files.gd', 'editor.gd']:
		var err = DirAccess.copy_absolute(from_dir + '/' + f, ProjectSettings.globalize_path('res://addons/dialogue_nodes/editor/' + f))
		check('HOT copied patched ' + f + ' over the running one', err == OK, err)
	focus_in()
	var fs = EditorInterface.get_resource_filesystem()
	await frames(5)
	while fs.is_scanning():
		await frames(1)
	await frames(10)
	var live = files.get_script().get_script_constant_map().get('EXTERNAL_EDIT_SAFE', false)
	print('INFO: HOT after focus-in, the running Files script has EXTERNAL_EDIT_SAFE = ', live)
	if not live:
		fs.scan()
		await frames(5)
		while fs.is_scanning():
			await frames(1)
		await frames(10)
		live = files.get_script().get_script_constant_map().get('EXTERNAL_EDIT_SAFE', false)
		print('INFO: HOT after a filesystem scan(), the running Files script has EXTERNAL_EDIT_SAFE = ', live)
	if not live:
		return
	check('HOT d_a (opened before the swap) has no recorded disk version', meta().get('md5') == null)
	var outside = outside_replace(A, 'Line two ORIGINAL a', 'Line two OUTSIDE-H1')
	save()
	await frames()
	check('HOT first save of an unedited pre-swap file: takes the disk copy, writes nothing', disk(A) == outside and backups().size() == 0 and graph_text('1_2') == 'Line two OUTSIDE-H1', graph_text('1_2'))
	check('HOT first save then records the disk version', meta().get('md5') == FileAccess.get_md5(A))
	await frames()
	# (the baseline save above wrote the graph's line one back over OUTSIDE-1)
	var out2 = outside_replace(A, 'Line one ORIGINAL a', 'Line one OUTSIDE-H2')
	focus_in()
	await frames()
	check('HOT focus-in after that works (no dialog made in _ready)', graph_text('1_1') == 'Line one OUTSIDE-H2' and disk(A) == out2, graph_text('1_1'))
	var out3 = outside_replace(A, 'Line one OUTSIDE-H2', 'Line one OUTSIDE-H3')
	save()
	check('HOT later saves: clean+changed file reloaded, not written', disk(A) == out3 and graph_text('1_1') == 'Line one OUTSIDE-H3')
	await frames()
	graph_edit('1_2', 'Line two GRAPH-H4')
	var out4 = outside_replace(A, 'Line one OUTSIDE-H3', 'Line one OUTSIDE-H4')
	focus_in()
	await frames()
	check('HOT edited+changed focus-in: the dialog made on first use shows', files.reloadDialogue != null and files.reloadDialogue.is_inside_tree() and files.reloadDialogue.visible)
	files.reloadDialogue.get_ok_button().pressed.emit()
	await frames()
	check('HOT Reload from disk works', graph_text('1_1') == 'Line one OUTSIDE-H4' and disk(A) == out4 and meta()['modified'] == false, graph_text('1_1'))


func _finish():
	print('RESULT: %d passed, %d failed' % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
