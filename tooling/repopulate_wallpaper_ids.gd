@tool
extends EditorScript
## Repopulates Background.wallpaperId across every background list from the
## authoritative wallpaperImagePath -> wallpaperId mapping in all_wallpapers.tres.
##
## WHY: the lazy-background migration rewrote the background-list .tres files and
## blanked every `wallpaperId`. That broke "unlock when you see it" — Main.gd's
## _on_dialogue_manager_dialogue_proceeded() unlocks currentBackground.wallpaperId,
## which is "" when the field is blank. This rebuilds the link deterministically.
##
## HOW: pure text transform (FileAccess + RegEx). It does NOT load the lists or
## call ResourceSaver.save, so sub-resource ORDER and UIDs are preserved. That
## matters: dialogue nodes reference backgrounds by array index, so re-saving (which
## can reorder sub-resources) would silently show the wrong CGs.
##
## SAFE + IDEMPOTENT: only edits the wallpaperId value of entries whose imagePath
## matches a wallpaper. Re-running with no source changes makes zero edits.
##
## USAGE: open this file in the Godot editor and run it (File > Run, Ctrl+Shift+X).
##   1. Leave DRY_RUN = true and run once -> prints the full audit, writes nothing.
##   2. Review the report.
##   3. Set DRY_RUN = false and run again -> applies the changes.

const ALL_WALLPAPERS_PATH := "res://resources/wallpapers/all_wallpapers.tres"
const LISTS_DIR := "res://data/background_lists"

## Report only; write nothing. Flip to false to actually apply the fix.
const DRY_RUN := false
## Also INSERT a wallpaperId line for entries that map to a wallpaper but have no
## wallpaperId field at all (e.g. boa_poker_new). That turns those CGs into on-see
## unlocks — a DESIGN CHANGE, not a regression fix — so it's OFF by default. Such
## entries are reported as "missing field" candidates for you to decide on.
const INSERT_MISSING := false
## When an entry already has a NON-empty wallpaperId that disagrees with
## all_wallpapers.tres, overwrite it to match the source of truth. If false, such
## conflicts are reported but left untouched.
## Verified safe: the only conflicts were a LISA_POK_REW_1/_3 transposition in
## lisa_poker_reward.tres; all_wallpapers.tres is authoritative (it defines each
## id's gallery image), so overwriting realigns "see image X -> unlock wallpaper X".
const OVERWRITE_CONFLICTS := true

var _img_re: RegEx
var _wid_re: RegEx
var _wimg_re: RegEx


func _run() -> void:
	_img_re = _compile("^(\\s*)imagePath\\s*=\\s*\"(.*)\"\\s*$")
	_wid_re = _compile("^(\\s*)wallpaperId\\s*=\\s*\"(.*)\"\\s*$")
	_wimg_re = _compile("^(\\s*)wallpaperImagePath\\s*=\\s*\"(.*)\"\\s*$")

	var map := _build_map(ALL_WALLPAPERS_PATH)
	if map.is_empty():
		push_error("No image->id mappings found in %s — aborting." % ALL_WALLPAPERS_PATH)
		return
	print("Loaded %d wallpaperImagePath -> wallpaperId mappings.\n" % map.size())

	var files := _collect_tres(LISTS_DIR)
	print("Scanning %d .tres files under %s\n" % [files.size(), LISTS_DIR])

	var matched := {}
	var total_filled := 0
	var total_conflicts := 0
	var total_conflicts_skipped := 0
	var total_missing := 0
	var files_changed := 0
	var rollup := []

	for path in files:
		var r := _process_file(path, map)
		for ip in r.matched:
			matched[ip] = true
		total_filled += r.filled
		total_conflicts += r.conflicts_applied
		total_conflicts_skipped += r.conflicts_skipped.size()
		total_missing += r.missing.size()
		if r.filled > 0 or r.missing.size() > 0 or r.conflicts_applied > 0 or r.conflicts_skipped.size() > 0:
			rollup.append({
				"path": path, "filled": r.filled, "missing": r.missing.size(),
				"conf": r.conflicts_applied + r.conflicts_skipped.size(),
			})

		if r.updates.size() > 0 or r.missing.size() > 0 or r.conflicts_skipped.size() > 0:
			print("* %s" % path)
			for u in r.updates:
				var tag := "  [CONFLICT->fixed] " if u.was_nonempty else "  [fill] "
				print("%s%s : \"%s\" -> \"%s\"" % [tag, u.image, u.old, u.new])
			for c in r.conflicts_skipped:
				print("  [CONFLICT-skipped] %s : has \"%s\", source says \"%s\"" % [c.image, c.old, c.new])
			for m in r.missing:
				print("  [missing field]   %s -> would be \"%s\"" % [m.image, m.id])

		if r.changed and not DRY_RUN:
			if _write(path, r.text):
				files_changed += 1

	var uncovered := []
	for ip in map.keys():
		if not matched.has(ip):
			uncovered.append(ip)
	uncovered.sort()

	print("\n==== SUMMARY ====")
	print("Blanks filled:              %d" % total_filled)
	print("Conflicts overwritten:      %d" % total_conflicts)
	print("Conflicts left as-is:       %d  (set OVERWRITE_CONFLICTS=true to fix)" % total_conflicts_skipped)
	print("Missing-field candidates:   %d  (set INSERT_MISSING=true to fill)" % total_missing)
	print("Wallpapers not in any list: %d  (expected for standalone res://data/wallpapers/* art)" % uncovered.size())
	for ip in uncovered:
		print("   - %s  (%s)" % [map[ip], ip])

	if not rollup.is_empty():
		print("\n---- per-file rollup (touched / candidate files) ----")
		for e in rollup:
			print("  fill=%-3d conflict=%-2d missing=%-3d  %s" % [e.filled, e.conf, e.missing, e.path])

	if DRY_RUN:
		print("\nDRY_RUN is ON — nothing written. Set DRY_RUN=false and re-run to apply.")
	else:
		print("\nApplied. Wrote %d file(s)." % files_changed)


func _process_file(path: String, map: Dictionary) -> Dictionary:
	var raw := _read_text(path)
	var nl := "\r\n" if raw.find("\r\n") != -1 else "\n"
	var norm := raw.replace("\r\n", "\n").replace("\r", "\n")
	var blocks := _split_blocks(norm.split("\n"))

	var res := {
		"updates": [], "missing": [], "conflicts_skipped": [], "matched": [],
		"filled": 0, "conflicts_applied": 0, "changed": false, "text": raw,
	}
	var out_lines := []

	for block in blocks:
		var img := ""
		var img_idx := -1
		var img_indent := ""
		var wid_idx := -1
		for j in block.size():
			var mi = _img_re.search(block[j])
			if mi:
				img = mi.get_string(2)
				img_idx = j
				img_indent = mi.get_string(1)
				continue
			if _wid_re.search(block[j]):
				wid_idx = j

		if img != "" and map.has(img):
			res.matched.append(img)
			var desired: String = map[img]
			if wid_idx != -1:
				var mw = _wid_re.search(block[wid_idx])
				var indent := mw.get_string(1)
				var old := mw.get_string(2)
				if old != desired:
					if old != "" and not OVERWRITE_CONFLICTS:
						res.conflicts_skipped.append({"image": img, "old": old, "new": desired})
					else:
						block[wid_idx] = "%swallpaperId = \"%s\"" % [indent, desired]
						res.updates.append({"image": img, "old": old, "new": desired, "was_nonempty": old != ""})
						res.changed = true
						if old == "":
							res.filled += 1
						else:
							res.conflicts_applied += 1
			elif INSERT_MISSING and img_idx != -1:
				block.insert(img_idx + 1, "%swallpaperId = \"%s\"" % [img_indent, desired])
				res.updates.append({"image": img, "old": "", "new": desired, "was_nonempty": false})
				res.changed = true
				res.filled += 1
			else:
				res.missing.append({"image": img, "id": desired})

		for line in block:
			out_lines.append(line)

	if res.changed:
		res.text = nl.join(out_lines)
	return res


## Builds wallpaperImagePath -> wallpaperId from all_wallpapers.tres. Drops any
## image path that ambiguously maps to two different ids.
func _build_map(path: String) -> Dictionary:
	var lines := _read_text(path).replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var map := {}
	var ambiguous := {}
	var cur_img := ""
	var cur_id := ""
	for raw_line in lines:
		var line := String(raw_line)
		if line.strip_edges().begins_with("["):
			_commit_map(map, ambiguous, cur_img, cur_id)
			cur_img = ""
			cur_id = ""
			continue
		var mi = _wimg_re.search(line)
		if mi:
			cur_img = mi.get_string(2)
			continue
		var md = _wid_re.search(line)
		if md:
			cur_id = md.get_string(2)
	_commit_map(map, ambiguous, cur_img, cur_id)
	return map


func _commit_map(map: Dictionary, ambiguous: Dictionary, img: String, id: String) -> void:
	if img == "" or id == "":
		return
	if ambiguous.has(img):
		return
	if map.has(img) and map[img] != id:
		push_warning("Ambiguous wallpaperImagePath '%s' -> '%s' and '%s'; skipping it." % [img, map[img], id])
		map.erase(img)
		ambiguous[img] = true
		return
	map[img] = id


## Splits .tres lines into blocks, each starting at a "[...]" section header.
func _split_blocks(lines) -> Array:
	var blocks := []
	var cur := []
	for raw_line in lines:
		var line := String(raw_line)
		if line.strip_edges().begins_with("[") and not cur.is_empty():
			blocks.append(cur)
			cur = []
		cur.append(line)
	if not cur.is_empty():
		blocks.append(cur)
	return blocks


func _collect_tres(dir_path: String) -> Array:
	var out := []
	var d := DirAccess.open(dir_path)
	if d == null:
		push_error("Cannot open directory: %s" % dir_path)
		return out
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full := dir_path.path_join(entry)
			if d.current_is_dir():
				out.append_array(_collect_tres(full))
			elif entry.ends_with(".tres"):
				out.append(full)
		entry = d.get_next()
	d.list_dir_end()
	out.sort()
	return out


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Could not read: %s" % path)
		return ""
	var t := f.get_as_text()
	f.close()
	return t


func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Could not open for write: %s" % path)
		return false
	f.store_string(text)
	f.close()
	return true


func _compile(pattern: String) -> RegEx:
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		push_error("Regex failed to compile: %s" % pattern)
	return re
