@tool
extends "./../../../core/editor/app.gd"
const BaseList = preload("./../../../core/base/list.gd")

func execute(value : Variant = null) -> bool:
	if value is PackedStringArray:
		var resources : PackedStringArray = []
		for x : String in value:
			if ResourceLoader.exists(x):
				resources.append(x)
				var res : Resource = ResourceLoader.load(x)
				EditorInterface.edit_resource(res)
		if resources.size() > 0:
			_deferred(resources)
			return true
	return false
	
	
func _deferred(res : PackedStringArray, fbck : int = 15) -> void:
	_manager._task.add(_add.bind(res, fbck))
	_manager.update_request.emit()
	

func _add(res : PackedStringArray, fbck : int) -> void:
	var list : BaseList = _manager.get_editor_list()
	
	var tools : Array = []
	for _tool : MickeyTool in _tool_db.get_tools():
		if is_instance_valid(_tool) and _tool.is_valid():
			if res.has(list.get_item_tooltip(_tool.get_index())):
				tools.append(_tool)
	
	if tools.size() != res.size():
		if fbck > 0:
			fbck -= 1	
			_deferred.call_deferred(res, fbck)
		return
	
	var ctrl : Control = _manager.get_base_container().new_column()
	for _tool : Object in tools:
		var idx : int = _tool.get_index()
		if _manager._focus_tool.unfocus_enabled:
			_tool.get_root().modulate = _manager._focus_tool.unfocus_color
		if idx > -1 and list.item_count() > idx:
			_manager.move_tool(ctrl, idx)
			
	_manager.clear_editors()
