@tool
extends ItemList
class_name Files

# Dialogue files may be edited outside Godot (the web dialogue editor in
# tooling/dialogue_editor greps for this marker) while they are open here.
# Godot's saves write only the files with graph edits. An open file whose
# disk copy changed is reloaded when it has no graph edits (or only moved
# nodes). One with graph edits isn't written until the user chooses; choosing
# to overwrite backs the disk copy up to tooling/dialogue_editor/backups/.
const EXTERNAL_EDIT_SAFE = true
const BACKUPS = 'res://tooling/dialogue_editor/backups/'


signal opened(data : DialogueData)
signal switched(data : DialogueData)
signal closed

@export var editor_path: NodePath
@export var newDialogue_path: NodePath
@export var saveDialogue_path: NodePath
@export var openDialogue_path: NodePath
@export var confirmDialogue_path: NodePath

@onready var popupMenu = $PopupMenu

var file_icon = preload('res://addons/dialogue_nodes/icons/Script.svg')
var editor
var newDialogue
var saveDialogue
var openDialogue
var confirmDialogue

var current : int
var queued : Array # for closing
var reloadDialogue : ConfirmationDialog
var asking : Array = [] # ids of edited files that also changed on disk
var stale = false # the graph still shows an older copy of the current file


func _ready():
	editor = get_node(editor_path)
	newDialogue = get_node(newDialogue_path)
	saveDialogue = get_node(saveDialogue_path)
	openDialogue = get_node(openDialogue_path)
	confirmDialogue = get_node(confirmDialogue_path)
	
	confirmDialogue.get_ok_button().hide()
	confirmDialogue.add_button('Save', true, 'save_file')
	confirmDialogue.add_button('Discard', true, 'discard_file')
	confirmDialogue.add_cancel_button('Cancel')
	_setup()
	
	current = -1
	queued = []
	asking = []


func _exit_tree():
	close_all(true)
	file_icon = null


func _show_dir(idx):
	var metadata = get_item_metadata(idx)
	var parts = metadata['path'].split('/')
	set_item_text(idx, parts[-2] + '/' + parts[-1])
	


func _is_file_open(node_name):
	
	for idx in range(get_item_count()):
		if get_item_metadata(idx)['id'] == node_name:
			return true
	
	return false


func _get_file_idx(node_name):
	
	for idx in range(get_item_count()):
		if get_item_metadata(idx)['id'] == node_name:
			return idx
	
	return -1


# md5: the disk copy that data was loaded from (read before loading, so a
# write during the load still counts as a change)
func create_file(file_name, file_dir, data : DialogueData, md5 = null):
	var new_idx : int
	var node_name = file_dir.split('/')[-1] + '>' + file_name.split('.')[0]
	
	print(node_name)
	if _is_file_open(node_name):
		# file already open
		new_idx = _get_file_idx(node_name)
		select_file(new_idx)
	else:
		# init new file data
		new_idx = get_item_count()
		var path = file_dir+'/'+file_name
		var new_file = {
			'id': node_name,
			'path': path,
			'data': data,
			'modified': false,
			'moved_only': false,
			'md5': FileAccess.get_md5(path) if md5 == null else md5,
			'asked': ''}
		
		# add new file item
		add_item(file_name, file_icon)
		set_item_tooltip(new_idx, file_name)

		# set metadata
		set_item_metadata(new_idx, new_file)

		# show directory if files have the same name
		for idx in range(get_item_count()):
			if idx != new_idx and get_item_metadata(idx)['path'].split('/')[-1] == file_name:
				_show_dir(idx)
				_show_dir(new_idx)
		
		# select the new file
		select_file(new_idx)
	
	return new_idx


func select_file(idx):
	if idx < 0:
		return
	
	if current > -1:
		# update the data of previous current
		var metadata = get_item_metadata(current)
		metadata['data'] = _graph_data()
		set_item_metadata(current, metadata)
	
	current = idx
	var data : DialogueData= get_item_metadata(current)['data']
	select(current)
	switched.emit(data)


# moved: the edit only moved nodes in the graph
func modify_file(idx = current, moved = false):
	if idx < 0:
		return
	var metadata = get_item_metadata(idx)
	metadata['moved_only'] = moved and (not metadata['modified'] or metadata.get('moved_only', false))
	metadata['modified'] = true
	set_item_metadata(idx, metadata)
	set_item_text(idx, metadata['path'].split('/')[-1]+'(*)')


func new_file(path):
	var file_name : String = newDialogue.current_file
	var file_dir : String = newDialogue.current_dir
	var data = DialogueData.new()
	
	create_file(file_name, file_dir, data)
	save_file(current)
	
	switched.emit(data)


func open_file(path, internal = false):
	# open/read file
	print(path)
	var md5 = FileAccess.get_md5(path)
	var data = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)

	var file_name: String = path.get_file()       # e.g. "d_ana_shop_meeting.tres"
	var file_dir: String  = path.get_base_dir()   # e.g. "res://data/game_stages/vn/ana_shop_meeting"

	if data is DialogueData:
		print("file_dir: " + file_dir)
		print("file_name: " + file_name)

		if file_name == "" or file_name == null:
			file_name = openDialogue.current_file
		
		if file_dir == "" or file_dir == null:
			file_dir = openDialogue.current_dir
	else:
		printerr("File not supported!")
		return

	# create, setup file button
	var file_idx = create_file(file_name, file_dir, data, md5)

	if not internal:
		opened.emit(get_item_metadata(file_idx)["data"])


# Returns whether the file now holds the open copy, or, for a file without
# graph edits that changed on disk, whether the disk copy was taken instead.
# overwrite: the user chose to write over a disk copy changed outside Godot.
func save_file(idx = current, overwrite = false) -> bool:
	if idx < 0:
		return false
	
	var metadata = get_item_metadata(idx)
	
	# the disk copy was changed outside Godot since it was opened or saved here
	if _disk_changed(idx):
		if not _has_edits(idx):
			# nothing of ours to write: take the newer disk copy instead
			return _reload_file(idx)
		if not overwrite:
			# don't write over it until the user chooses
			push_warning('Dialogue Nodes: did not save %s: it was changed outside Godot and also has graph edits. Choose what to keep in the "Changed outside Godot" dialog.' % metadata['path'])
			_ask(idx)
			return false
		# write the graph edits, but keep the outside version too
		var backup = _backup_disk_copy(metadata['path'])
		if backup == '':
			return false
		print('Dialogue Nodes: wrote the graph over %s; the version changed outside Godot is in %s' % [metadata['path'], backup])
	
	# update the data if needed
	if idx == current:
		metadata['data'] = _graph_data()
		set_item_metadata(current, metadata)
	
	# save dialogue data to file
	var err = ResourceSaver.save(metadata['data'], metadata['path'])
	if err != OK:
		push_error('Dialogue Nodes: could not save %s (error %d)' % [metadata['path'], err])
		return false
	metadata['md5'] = FileAccess.get_md5(metadata['path'])
	
	if editor._debug:
		print('File saved: ', metadata['path'])
	
	metadata['modified'] = false
	metadata['moved_only'] = false
	set_item_metadata(idx, metadata)
	set_item_text(idx, metadata['path'].split('/')[-1])
	return true


func save_as_file(path, data):
	var file_name : String = saveDialogue.current_file
	var file_dir : String = saveDialogue.current_dir
	
	var idx = create_file(file_name, file_dir, data)
	# when that file was open already, create_file only switched to it:
	# put the Save As copy in it
	var metadata = get_item_metadata(idx)
	if metadata['data'] != data:
		metadata['data'] = data
		set_item_metadata(idx, metadata)
		switched.emit(data)
	modify_file(idx)
	# the file dialog has already asked whether to replace that file
	save_file(idx, true)


func save_all():
	for idx in range(get_item_count()):
		# only files with graph edits: writing the others again from the
		# graph would still change them (order, sizes, starts with no lines)
		if get_item_metadata(idx)['modified']:
			save_file(idx)
		elif _disk_changed(idx):
			_reload_file(idx)


# The graph's data, minus the nodes it is still freeing after a file was
# (re)loaded this frame: get_data() would list those as strays and save them.
# While the graph still shows an older copy (see _reload_file): the open copy.
func _graph_data() -> DialogueData:
	if stale and current > -1:
		return get_item_metadata(current)['data']
	var data : DialogueData = editor.get_data()
	for id in data.strays.duplicate():
		var node = editor.graph.get_node_or_null(NodePath(id))
		if node and node.is_queued_for_deletion():
			data.strays.erase(id)
			data.nodes.erase(StringName(id))
	return data


# Whether the open copy has graph edits worth asking about: moved nodes alone
# aren't, when the file was changed outside Godot.
func _has_edits(idx) -> bool:
	var metadata = get_item_metadata(idx)
	return metadata['modified'] and not metadata.get('moved_only', false)


# Whether someone else wrote the file since it was opened or saved here. Uses
# the MD5, not the modified time: that only has whole seconds, so a save made
# in the same second as ours would go unseen.
func _disk_changed(idx) -> bool:
	var metadata = get_item_metadata(idx)
	if not FileAccess.file_exists(metadata['path']):
		return false
	# no md5: opened before this script was loaded (installed with the
	# editor open), so a change can't be ruled out
	return metadata.get('md5') == null or FileAccess.get_md5(metadata['path']) != metadata['md5']


# Replace the open copy with the disk copy, and show it if it's in the graph.
func _reload_file(idx) -> bool:
	_setup()
	var metadata = get_item_metadata(idx)
	var md5 = FileAccess.get_md5(metadata['path'])
	var data = ResourceLoader.load(metadata['path'], '', ResourceLoader.CACHE_MODE_IGNORE)
	if not data is DialogueData:
		push_warning('Dialogue Nodes: %s changed outside Godot but could not be read; kept the open copy and did not save it.' % metadata['path'])
		return false
	
	var dropped = 'moved nodes' if metadata['modified'] and metadata.get('moved_only', false) else ''
	metadata['data'] = data
	metadata['md5'] = md5
	metadata['modified'] = false
	metadata['moved_only'] = false
	set_item_metadata(idx, metadata)
	set_item_text(idx, metadata['path'].split('/')[-1])
	if idx == current:
		if editor.is_visible_in_tree():
			switched.emit(data)
		else:
			# a big graph takes seconds to build: wait until it's looked at
			stale = true
	
	print('Dialogue Nodes: reloaded ', metadata['path'], ' (changed outside Godot)', '; dropped the graph\'s ' + dropped if dropped else '')
	return true


# Copy the disk copy to the backups folder before graph edits are written
# over it. Returns the backup's path, or '' when it couldn't be made.
func _backup_disk_copy(path : String) -> String:
	var root = ProjectSettings.globalize_path(BACKUPS)
	var folder = root + path.trim_prefix('res://')
	DirAccess.make_dir_recursive_absolute(root)
	# keep the backups out of Godot's file system and out of git
	for marker in [['.gdignore', ''], ['.gitignore', '*\n']]:
		if not FileAccess.file_exists(root + marker[0]):
			var file = FileAccess.open(root + marker[0], FileAccess.WRITE)
			if file:
				file.store_string(marker[1])
	DirAccess.make_dir_recursive_absolute(folder)
	
	var t = Time.get_datetime_dict_from_system()
	var ms = int(fmod(Time.get_unix_time_from_system(), 1.0) * 1000)
	var stamp = '%04d%02d%02d-%02d%02d%02d-%03d' % [t.year, t.month, t.day, t.hour, t.minute, t.second, ms]
	var backup = folder + '/' + stamp + '-outside-godot.tres.bak'
	var err = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), backup)
	if err != OK:
		push_error('Dialogue Nodes: %s changed outside Godot and could not be backed up (error %d); did not save the graph edits over it.' % [path, err])
		return ''
	return backup


func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		# deferred: nodes can't be added while this goes round the tree
		reload_changed_files.call_deferred()


# Coming back to Godot: show files changed meanwhile (eg in the web dialogue
# editor). Files without graph edits reload; for edited ones, ask.
func reload_changed_files():
	for idx in range(get_item_count()):
		if not _disk_changed(idx):
			continue
		if not _has_edits(idx):
			_reload_file(idx)
			continue
		# ask once per outside version (saving asks again)
		var metadata = get_item_metadata(idx)
		var md5 = FileAccess.get_md5(metadata['path'])
		if metadata.get('asked') != md5:
			metadata['asked'] = md5
			set_item_metadata(idx, metadata)
			_ask(idx)
	

# Ask what to do about an edited file that also changed on disk. Files
# found while the question is open join it.
func _ask(idx):
	_setup()
	var id = get_item_metadata(idx)['id']
	if not id in asking:
		asking.append(id)
	var names = []
	for asked in asking:
		var i = _get_file_idx(asked)
		if i > -1:
			names.append(get_item_metadata(i)['path'])
	reloadDialogue.dialog_text = 'Saved outside Godot (for example in the web dialogue editor), and also edited in this graph:\n\n%s\n\nUse the file on disk: load the saved version. Your graph edits to these files are dropped.\nOverwrite it with Godot\'s graph: save the graph over it now. The version on disk is copied to\n%s first.\nDecide later: Godot won\'t save these files until you choose. Run (F5) plays the file on disk.' % ['\n'.join(names), BACKUPS]
	if not reloadDialogue.visible:
		reloadDialogue.popup_centered.call_deferred()


# Made on first use too: when this script is reloaded with the editor open,
# _ready doesn't run again (and variables it didn't have before start null).
func _setup():
	if typeof(asking) != TYPE_ARRAY:
		asking = []
	if not is_instance_valid(reloadDialogue):
		reloadDialogue = ConfirmationDialog.new()
		reloadDialogue.title = 'Changed outside Godot'
		reloadDialogue.ok_button_text = 'Use the file on disk'
		reloadDialogue.add_button('Overwrite it with Godot\'s graph', true, 'overwrite')
		reloadDialogue.cancel_button_text = 'Decide later'
		# not exclusive: the editor may be showing its own dialog right now
		reloadDialogue.exclusive = false
		reloadDialogue.confirmed.connect(_on_reloadDialog_action.bind('reload'))
		reloadDialogue.custom_action.connect(_on_reloadDialog_action)
		# Decide later, Esc and the window's close button: nothing is written
		reloadDialogue.canceled.connect(_on_reloadDialog_action.bind('later'))
		add_child(reloadDialogue)
	if not editor.visibility_changed.is_connected(_on_editor_visibility_changed):
		editor.visibility_changed.connect(_on_editor_visibility_changed)
		switched.connect(_on_switched)
		# Cancel, Esc and the window's close button: close nothing
		confirmDialogue.canceled.connect(_on_confirmDialog_hide)


func _on_reloadDialog_action(action):
	var ids = asking
	asking = []
	reloadDialogue.hide()
	for id in ids:
		var idx = _get_file_idx(id)
		if idx < 0 or not get_item_metadata(idx)['modified']:
			continue
		match action:
			'reload':
				_reload_file(idx)
			'overwrite':
				save_file(idx, true)


func _on_editor_visibility_changed():
	if stale and current > -1 and editor.is_visible_in_tree():
		switched.emit(get_item_metadata(current)['data'])


func _on_switched(_data):
	stale = false


func close_file(idx = current):
	if idx < 0:
		return
	
	var metadata = get_item_metadata(idx)
	var count = get_item_count()
	# whether the graph shows this file (none does while closing all)
	var shown = idx == current or current < 0

	if metadata['modified'] and not idx in queued:
		queued.append(idx)
		confirmDialogue.popup_centered()
		return
	elif idx == current:
		if count == 1:
			current = -1
		elif count == current+1:
			current -= 1
	elif idx < current:
		current -= 1
	
	remove_item(idx)
	# another file closing leaves the graph (and its unsaved edits) alone
	if shown:
		closed.emit()
	
	if editor._debug:
		print('File closed: ', metadata['path'])
	
	if current > -1:
		select(current)
		if shown:
			switched.emit(get_item_metadata(current)['data'])


func close_all(force_close = false):
	# Check if any file is modified
	var modified = false
	for idx in range(get_item_count()):
		if get_item_metadata(idx)['modified']:
			modified = true
			break
	
	# Store all files in queue, ask for confirmation
	if modified and not force_close:
		queued.clear()
		for idx in range(get_item_count()):
			queued.push_front(idx)
		confirmDialogue.popup_centered()
		return
	
	# If none are modified, close all files
	current = -1
	for idx in range(get_item_count()):
		close_file(0)


func _on_confirmDialog_action(action):
	if len(queued) > 0:
		match (action):
			'save_file':
				for idx in queued:
					# one that can't be saved stays open
					if not get_item_metadata(idx)['modified'] or save_file(idx):
						close_file(idx)
			'discard_file':
				for idx in queued:
					close_file(idx)
	queued.clear()
	confirmDialogue.hide()


func _on_confirmDialog_hide():
	queued.clear()


func _on_empty_clicked(at_pos, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var pop_pos = at_pos + global_position + Vector2(get_window().position)
		popupMenu.popup(Rect2(pop_pos, popupMenu.size))


func _on_item_clicked(index, at_pos, mouse_button_index):
	_on_empty_clicked(at_pos, mouse_button_index)
