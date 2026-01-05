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

var _tools : Array[MickeyTool] = []

func get_tools() -> Array[MickeyTool]:
	return _tools

func append(mk : MickeyTool) -> void:
	_tools.append(mk)

func garbage(val : int) -> void:
	if val == 1:
		for x : Variant in  _tools:
			if is_instance_valid(x):
				(x as MickeyTool).set_queue_free(true)
	elif val == 0:
		for x : int in range(_tools.size() - 1, -1, -1):
			var variant : Variant = _tools[x]
			if !is_instance_valid(variant):
				_tools.remove_at(x)
				
			if !variant.is_valid():
				if !is_instance_valid(variant.get_owner()):
					var root : Node = variant.get_root()
					if is_instance_valid(root):
						variant.get_root().queue_free()
						variant.set_queue_free(true)
				
			if (variant as MickeyTool).is_queue_free():
				_tools.remove_at(x)
	
func get_tool_id(id : int) -> MickeyTool:
	for x : MickeyTool in _tools:
		if x.get_index() == id:
			return x
	return null
	
func has_tool_id(id : int) -> bool:
	for x : MickeyTool in _tools:
		if x.get_index() == id:
			return true
	return false


func clear() -> void:
	for x : MickeyTool in _tools:
		if is_instance_valid(x):
			x.reset()
	_tools.clear()

func get_by_reference(control : Node) -> MickeyTool:
	for x : MickeyTool in _tools:
		if x.has(control):
			return x
	return null
