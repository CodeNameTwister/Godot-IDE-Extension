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
	elif value is MickeyTool:
		_tool = value
		
	if _tool == null:
		if value is MickeyTool:
			_tool = value
		elif value is Node:
			_tool = _tool_db.get_by_reference(value)
	
	if is_instance_valid(_tool) and _tool.is_valid():
		if _manager._focus_tool.unfocus_enabled:
			_tool.get_root().modulate = _manager._focus_tool.unfocus_color		
		var idx : int = _tool.get_index()
		if idx > -1 and _manager.get_editor_list().item_count() > idx:
			_manager.move_tool(_manager.get_base_container().new_column(), idx)
			_manager.io.update()
			return true
			
	return false
