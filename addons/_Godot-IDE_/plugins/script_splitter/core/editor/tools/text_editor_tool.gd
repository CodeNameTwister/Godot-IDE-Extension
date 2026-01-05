@tool
extends "./../../../core/editor/tools/editor_tool.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _build_tool(control : Node) -> MickeyTool:
	if control is ScriptEditorBase:
		var editor : Control = control.get_base_editor()
		var mickey_tool : MickeyTool = null
		if editor is CodeEdit:
			var parent : Node = control.get_parent()
			if parent != null and parent.is_node_ready() and !control.get_parent() is VSplitContainer:
				mickey_tool = MickeyTool.new(control, editor, editor)
		else:
			mickey_tool = MickeyTool.new(control, editor, editor)
		return mickey_tool
	return null
