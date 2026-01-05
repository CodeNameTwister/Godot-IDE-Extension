@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#Override app function.
func execute(value : Variant = null) -> bool:
	if value is Array:
		if value.size() > 1:
			if value[0] is TabContainer and value[1] is int:
				var control : TabContainer = value[0]
				var index : int = value[1]
				for x : MickeyTool in _tool_db.get_tools():
					if is_instance_valid(x):
						if x.get_root() == control:
							if x.get_control().get_index() == index:
								x.trigger_focus()
								return true
	return false
