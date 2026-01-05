@tool
extends "./../../../../core/editor/tools/magic/mickey_tool.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func has(current_control : Node) -> bool:
	if super(current_control):
		return true
	for x : Node in current_control.get_children():
		if super(x):
			return true
	return false
	
func ochorus(root : Node) -> void:
	if is_instance_valid(_root_control) and is_instance_valid(root):
		var parent : Node = _root_control.get_parent()
		if parent != root:
			
			_connect_callback(false)
			
			if _owner == root:
				var childs : Array[Node] = _root_control.get_children()
				for n : Node in childs:
					_root_control.remove_child(n)
					_owner.add_child(n)
				_root_control.queue_free()
			else:
				if parent:
					_root_control.reparent(root)
				else:
					root.add_child(_root_control)
					
				if root is Control:
					_root_control.size = root.size
					
				if root is TabContainer:
					var tittle_id : int = _root_control.get_index()
					if tittle_id > -1 and tittle_id < root.get_tab_count():
						var tl : String = root.get_tab_title(tittle_id)
						if tl.is_empty() or (tl.begins_with("@") and "Text" in tl):
							root.set_tab_title(tittle_id, "Editor")
					
				_connect_callback(true)
				
			_root_control.visible = true
