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
