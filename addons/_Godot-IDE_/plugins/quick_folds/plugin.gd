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
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.alt_pressed:
			var index : int = KEYS.find(event.keycode)
			if index > -1:
				folding(index, event.shift_pressed)

func _show_error(msg : String = 'Error, on try fold editor!') -> void:
	push_warning(msg)

func folding(level: int, from_back : bool) -> void:
	var interface : EditorInterface = get_editor_interface()
	var script_editor : ScriptEditor = null
	var editor : ScriptEditorBase = null
	
	if !is_instance_valid(interface):
		_show_error()
		return
		
	script_editor = interface.get_script_editor()
	
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
