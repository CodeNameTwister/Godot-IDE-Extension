@tool
extends RefCounted
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


func execute() -> String:
	var text : String = ""
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		var sc : Script = editor.get_current_script()
		if sc:
			var base : ScriptEditorBase = editor.get_current_editor()
			var control : Control = base.get_base_editor()
			if control is CodeEdit:
				var last_line : int = -1
				for x : int in control.get_caret_count():
					var current : String = control.get_selected_text(x)
					if current.is_empty():
						continue
					var from : int = control.get_selection_from_column(x)
					var line : int = control.get_caret_line(x)
					if from > 0:
						var txt : String = control.get_line(line)
						if txt.length() > from:
							while from > -1:
								var chars :  String = txt[from]
								if chars == '\t':
									current = '\t' + current
								elif chars == ' ':
									current = ' ' + current
								from -= 1
					if last_line == -1:
						text += current
					elif last_line < line:
						text = str(text ,'\n', current)
					else:
						text = str(current ,'\n', text)
					last_line = line
	return text
