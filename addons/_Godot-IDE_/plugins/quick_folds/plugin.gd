@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Quick Folds
#	https://github.com/CodeNameTwister/Quick-Folds
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const KEYS : PackedInt32Array = [
	KEY_1,
	KEY_2, 
	KEY_3, 
	KEY_4, 
	KEY_5, 
	KEY_6, 
	KEY_7, 
	KEY_8, 
	KEY_9,
	KEY_0
	]
	
var _inputs : Array[InputEvent] = []
var _inverted_inputs : Array[InputEvent] = []
	
func _init() -> void:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if editor:
		var key1 : String = "plugin/quick_folds/input/fold_type_"
		var key2 : String = "plugin/quick_folds/input/inverted_fold_type_"
		for z : Array in [[key1, _inputs, false], [key2, _inverted_inputs, true]]:
			for x : int in range(0, KEYS.size(), 1):
				var key_token : String = str(z[0], x + 1)
				var _input : InputEvent = null
				if editor.has_setting(key_token):
					var variant : Variant = editor.get_setting(key_token)
					if variant is InputEvent:
						_input = variant
						z[1].append(_input)
						continue
				_input = InputEventKey.new()
				_input.pressed = true
				_input.alt_pressed = true
				_input.shift_pressed = z[2]
				_input.keycode = KEYS[x]
				editor.set_setting(key_token, _input)
				z[1].append(_input)
				
	set_process_unhandled_input(_inputs.size() > 0 or _inverted_inputs.size() > 0)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		for x : InputEvent in _inputs:
			if event.is_match(x):
				var index : int = _inputs.find(x)
				if index > -1:
					folding(index, false)
				return
		for x : InputEvent in _inverted_inputs:
			if event.is_match(x):
				var index : int = _inverted_inputs.find(x)
				if index > -1:
					folding(index, true)
				return

func _show_error(msg : String = 'Error, on try fold editor!') -> void:
	push_warning(msg)

func folding(level: int, from_back : bool) -> void:
	var script_editor : ScriptEditor = null
	var editor : ScriptEditorBase = null
	
	script_editor = EditorInterface.get_script_editor()
	
	if !is_instance_valid(script_editor):
		_show_error()
		return
		
	editor = script_editor.get_current_editor()
	
	if !is_instance_valid(editor):
		_show_error()
		return
	
	var control : Control = script_editor.get_current_editor().get_base_editor()
	
	if control is CodeEdit:
		control.unfold_all_lines()
		
		if from_back:
			var max_indent : int = 0
			for line_idx : int in range(control.get_line_count()):
				max_indent = maxi(max_indent, control.get_indent_level(line_idx))
				
			level = maxi(max_indent - maxi(level * control.indent_size, 0), -1)
				
			for line : int in range(control.get_line_count()):
				var indent: int = control.get_indent_level(line)
				if control.can_fold_line(line):
					if level < indent:
						control.fold_line(line)
					else:
						control.unfold_line(line)
			
		else:
			level = maxi((level - 1) * control.indent_size, -1)	
			
			for line : int in range(control.get_line_count()):
				var indent: int = control.get_indent_level(line)
				if control.can_fold_line(line):
					if level < indent:
						control.fold_line(line)
					else:
						control.unfold_line(line)
