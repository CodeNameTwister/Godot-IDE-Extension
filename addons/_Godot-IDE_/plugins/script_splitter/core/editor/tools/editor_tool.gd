@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const MickeyTool = preload("./../../../core/editor/tools/magic/mickey_tool.gd")
const MickeyToolRoute = preload("./../../../core/editor/tools/magic/mickey_tool_route.gd")

func build(control : Node) -> MickeyTool:
	return _build_tool(control)

func _build_tool(_control : Node) -> MickeyTool:
	return null
