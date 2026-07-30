@tool
extends "./../../../core/editor/tools/editor_tool.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var _buff : Dictionary = {}

func _on_tree(editor : CodeEdit) -> void:
	if editor.get_caret_count() > 0:
		if editor.get_caret_column(0) -1 or editor.get_caret_line(0) -1:
			if editor.text.length() > 0:
				editor.set_caret_column(0)
				editor.set_caret_line(0)
			
				if _buff.has(editor):
					editor.get_tree().create_timer(0.124).timeout.connect(_on_time_out.bind(editor))
				return
	
	_buff.erase(editor)
				
func _on_time_out(editor : Variant) -> void:
	if is_instance_valid(editor):
		if editor is CodeEdit and editor.text.length() > 0 and editor.get_caret_count() > 0:
			if _buff.has(editor):
				var buff : Array = _buff[editor]
				editor.set_caret_line(buff[0])
				editor.set_caret_column(buff[1])
				editor.adjust_viewport_to_caret.call_deferred()
				_buff.erase(editor)
	
	
func _out_tree(editor : CodeEdit) -> void:
	for x : Variant in _buff.keys():
		if !x or !is_instance_valid(x):
			_buff.erase(x)
			
	if editor.is_queued_for_deletion():
		_buff.erase(editor)
		return
		
	if editor.get_caret_count() > 0:
		_buff[editor] = [
			editor.get_caret_line(0), 
			editor.get_caret_column(0)
			]

func _build_tool(control : Node) -> MickeyTool:
	if control is ScriptEditorBase:
		var editor : Control = control.get_base_editor()
		var mickey_tool : MickeyTool = null
		if editor is CodeEdit:
			if !editor.tree_entered.is_connected(_on_tree):
				editor.tree_entered.connect(_on_tree.bind(editor))
			if !editor.tree_exiting.is_connected(_out_tree):
				editor.tree_exiting.connect(_out_tree.bind(editor))
				
			var rcontrol : Node = editor.get_parent()
			if is_instance_valid(rcontrol):
				for __ : int in range(5):
					if rcontrol == null:
						break
					elif rcontrol is VSplitContainer:
						mickey_tool = MickeyTool.new(rcontrol.get_parent(), rcontrol, editor)
						break
					rcontrol = rcontrol.get_parent()
		return mickey_tool
	return null
