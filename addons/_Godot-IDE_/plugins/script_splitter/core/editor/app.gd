@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const MickeyTool = preload("./../../core/editor/tools/magic/mickey_tool.gd")
const ToolDB = preload("./../../core/editor/database/tool_db.gd")
const Manager = preload("./../../core/editor/godot/manager.gd")

var _tool_db : ToolDB = null
var _manager : Manager = null

func _init(manager : Manager, tool_db : ToolDB) -> void:
	_manager = manager
	_tool_db = tool_db

func execute(_value : Variant = null) -> bool:
	return false
