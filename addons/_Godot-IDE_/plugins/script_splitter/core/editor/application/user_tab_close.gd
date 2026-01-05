@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func execute(arr : Variant = null) -> bool:	
	var value : Variant = arr[0]
	var type : int = arr[1]
	
	var _tool : MickeyTool = null
	
	if value == null:
		value = _manager.get_base_container().get_current_container()
		
	elif value is Resource:
		var list : ItemList = _manager.get_editor_list().get_editor_list()
		var pth : String = value.resource_path
		for x : int in list.item_count:
			if pth == list.get_item_tooltip(x):
				_tool = _tool_db.get_tool_id(x)
				break
	elif value is String:
		var list : ItemList = _manager.get_editor_list().get_editor_list()
		var pth : String = value
		for x : int in list.item_count:
			if pth == list.get_item_tooltip(x):
				_tool = _tool_db.get_tool_id(x)
				break
				
	if _tool == null:
		if value is MickeyTool:
			_tool = value
		elif value is Node:
			_tool = _tool_db.get_by_reference(value)
			
	if is_instance_valid(_tool):
		var root : Node = _tool.get_root()
		var indx : int = _tool.get_control().get_index()
		
		var index : PackedInt32Array = []
		
		for x : MickeyTool in _tool_db.get_tools():
			if x.get_root() == root:
				if type < 0:
					if x.get_control().get_index() < indx:
						index.append(x.get_index())
				elif type > 0:
					if x.get_control().get_index() > indx:
						index.append(x.get_index())
				else:
					if x.get_control().get_index() != indx:
						index.append(x.get_index())
		
		index.sort()
		
		for z : int in range(index.size() - 1, -1, -1):
			_manager.get_editor_list().remove(index[z])
	return false
