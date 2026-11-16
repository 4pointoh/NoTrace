#!/bin/sh
# Tests for this project's patched dialogue_nodes addon (files.gd, editor.gd), in a headless Godot
# editor. Run from Git Bash:
#   sh tooling/dialogue_editor/tests/godot/run.sh            the regression suite (dn_fix), ~2 min
#   sh tooling/dialogue_editor/tests/godot/run.sh --run-dn-test               the first patch's suite
#   sh tooling/dialogue_editor/tests/godot/run.sh "--run-fix=safe6,roundtrip" some dn_fix sections
#   sh tooling/dialogue_editor/tests/godot/run.sh "--run-review=big --big=res://data/game_stages/vn/anna_night/d_anna_night.tres"
#                                                             timings for one big file (dn_review)
# It builds a throwaway project in %TEMP%/dnt from project/ here plus a copy of the real
# addons/dialogue_nodes, with APPDATA/LOCALAPPDATA sandboxed, so nothing in the real project is
# written. The last line says "RESULT: N passed, M failed". The log is %TEMP%/dnt.log.
HERE="$(cd "$(dirname "$0")" && pwd)"
REAL="$(cd "$HERE/../../../.." && pwd)"
GODOT="${GODOT:-$REAL/../../Godot_v4.4.1-stable_win64.exe}"
TMPROOT="$(cd "${TEMP:-/tmp}" && pwd)"
P="$TMPROOT/dnt"
SB="$TMPROOT/dnt_sandbox"
LOG="$TMPROOT/dnt.log"
case "$P" in "$REAL"*) echo "refusing: $P is inside the real project"; exit 2;; esac
[ -f "$REAL/addons/dialogue_nodes/editor/files.gd" ] || { echo "can't find the addon under $REAL"; exit 2; }
[ -f "$GODOT" ] || { echo "can't find Godot at $GODOT (set GODOT=...)"; exit 2; }

# A fresh project each run, but keep .godot (the import) when the addon hasn't changed.
STAMP="$(cat "$REAL"/addons/dialogue_nodes/editor/*.gd "$HERE"/project/addons/*/plugin.gd | md5sum | cut -c1-32)"
if [ "$(cat "$P/.stamp" 2>/dev/null)" != "$STAMP" ]; then rm -rf "$P"; fi
mkdir -p "$P" "$SB/appdata" "$SB/local"
find "$P" -mindepth 1 -maxdepth 1 ! -name .godot ! -name .stamp -exec rm -rf {} +
cp -r "$HERE/project/." "$P/"
cp -r "$REAL/addons/dialogue_nodes" "$P/addons/"
mkdir -p "$P/test"
cp "$P/fixtures/"*.tres "$P/test/"
cp -r "$P/fixtures_big/data" "$P/data"
export APPDATA="$SB/appdata" LOCALAPPDATA="$SB/local"
if [ ! -d "$P/.godot" ]; then
  timeout 300 "$GODOT" --headless --editor --import --path "$P" > "$LOG.import" 2>&1
  echo "import exit: $?"
fi
echo "$STAMP" > "$P/.stamp"
timeout "${TMO:-500}" "$GODOT" --headless --editor --path "$P" -- ${1:---run-fix} > "$LOG" 2>&1
code=$?
grep -E "^(FAIL|RESULT)|SCRIPT ERROR" "$LOG" | tail -40
echo "test exit: $code (log: $LOG)"
