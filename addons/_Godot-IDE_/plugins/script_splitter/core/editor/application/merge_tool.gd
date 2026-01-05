@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _get_tool(value : Variant) -> MickeyTool:
	var container : MickeyTool = null
		
	if value == null:
		container = _tool_db.get_by_reference(_manager.get_base_container().get_current_container())
	elif value is Node:
		container = _tool_db.get_by_reference(value)
	elif value is Resource:
		var list : ItemList = _manager.get_editor_list().get_editor_list()
		var pth : String = value.resource_path
		for x : int in list.item_count:
			if pth == list.get_item_tooltip(x):
				container = _tool_db.get_tool_id(x)
				break
	elif value is String:
		var list : ItemList = _manager.get_editor_list().get_editor_list()
		var pth : String = value
		for x : int in list.item_count:
			if pth == list.get_item_tooltip(x):
				container = _tool_db.get_tool_id(x)
				break
					
	return container

func execute(value : Variant = null) -> bool:
	if value is Array:
		var mk : MickeyTool = _get_tool(value[0])
		
		if is_instance_valid(mk) and value[1] is bool:
			if mk and mk.is_valid():
				var root : Node = mk.get_root()
				var control : Node = root
				if control.is_in_group(&"__SC_SPLITTER__"):
					var cbase : Manager.BaseContainer = _manager.get_base_container()
					if value[1]:
						control = cbase.get_container(control)
						for x : MickeyTool in _tool_db.get_tools():
							if x.is_valid():
								var node : Control = x.get_root()
								if control == cbase.get_container(node):
									x.reset()
						control.queue_free()
					else:
						for x : MickeyTool in _tool_db.get_tools():
							if x.is_valid():
								var node : Control = x.get_root()
								if node:
									if node == control:
										x.reset()
								else:
									x.reset()
								
					var base : Manager.BaseContainer = _manager.get_base_container()
					
					if root == base.get_current_container():
						var nodes : Array[Node] = control.get_tree().get_nodes_in_group(&"__SC_SPLITTER__")
						var container : Node = base.get_container_item(root)
						
						for n : Node in nodes:
							if n == root:
								continue
							var _container : Node = base.get_container_item(n)
							if _container.get_parent() == container.get_parent():
								var i0 : int = _container.get_index()
								var i1 : int = container.get_index()
								if i0 == i1 - 1 or i0 == i1 + 1:
									base.set_current_container(n)
									return true
					
						var z : int = nodes.find(root)
						if z != -1:
							if z == 0:
								if nodes.size() > 1:
									base.set_current_container(nodes[1])
							else:
								if nodes.size() > 1:
									base.set_current_container(nodes[z - 1])
						return true
					#if control.get_child_count() == 0 or root.get_child_count() == 0:
						#control.queue_free()
	return false
