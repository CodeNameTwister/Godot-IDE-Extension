@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func execute(value : Variant = null) -> bool:
	if value is Array:
		var control : Control = value[0]
		var index : int = value[1]
		
		if index < 0:
			return false
		
		for x : MickeyTool in _tool_db.get_tools():
			if x.get_root() == control and x.get_control().get_index() == index:
				var _index : int = x.get_index()
				x.reset()
				_manager.get_editor_list().remove(_index)
				return true
	return false
				
