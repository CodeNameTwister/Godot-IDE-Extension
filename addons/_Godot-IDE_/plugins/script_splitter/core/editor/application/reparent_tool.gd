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
		if value[0] is Control and value[1] is int:
			if value[1] < 0:
				return false
			for x : MickeyTool in _tool_db.get_tools():
				if x.get_index() == value[1]:
					if x.is_valid():
						x.ochorus(value[0])
						return true
	return false
