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
		var idx : int = value[0]
		var node : Node = value[1]
		
		if idx < 0:
			return false
		
		for x : MickeyTool in _tool_db.get_tools():
			if x.get_root() == node:
				if x.get_control().get_index() == idx:
					var list : Manager.BaseList = _manager.get_editor_list()
					var indx : int = x.get_index()
					if list.item_count() > indx and indx > -1:
						var el : ItemList = list.get_editor_list()
						el.item_clicked.emit(indx,el.get_local_mouse_position(), MOUSE_BUTTON_RIGHT)               
		
					return true
		
	return false
