@echo off
rem Opens the dialogue editor for this Godot project in the browser. Keep this window open while
rem writing; close it to stop. If the editor is already running, this just opens the browser at it.
python -P -E "%~dp0dialogue_editor.py" %*
pause
