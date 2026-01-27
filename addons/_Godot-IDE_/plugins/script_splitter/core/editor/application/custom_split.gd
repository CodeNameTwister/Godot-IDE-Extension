@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const BaseContainer = preload("./../../../core/base/container.gd")
const SpliterItem = preload("./../../../core/ui/multi_split_container/split_container_item.gd")

func execute(value : Variant = null) -> bool:
	if value is Array:
		if value.size() == 3:
			if value[0] is Container and value[1] is int and value[2] is StringName:
				var from : Container = value[0]
				var index : int = value[1]
				var type : StringName = value[2]
				
				if from is BaseContainer.SplitterContainer.SplitterEditorContainer.Editor:
					for x : MickeyTool in _tool_db.get_tools():
						if x.is_valid():
							
							if x.get_root() == from and x.get_control().get_index() == index:
								if type == &"LEFT":
									
									var c : Node = _manager.get_base_container().get_container_item(x.get_root())
									var cindex : int = 0
									
									if !c:
										return false
									cindex = c.get_index()
									
									_manager.split_column.execute(x)
									
									if !c.is_node_ready():
										await c.ready
											
									c = _manager.get_base_container().get_container_item(x.get_root())
									
									if is_instance_valid(c):
										if cindex > -1 and cindex < c.get_parent().get_child_count() and c.get_index() != cindex:
											c.get_parent().move_child.call_deferred(c, cindex)
											
								elif type == &"RIGHT":
									var c : Node = _manager.get_base_container().get_container_item(x.get_root())
									var cindex : int = 0
									
									if !c:
										return false
										
									cindex = c.get_index() + 1
									
									_manager.split_column.execute(x)
									
									if !c.is_node_ready():
										await c.ready
									
									c = _manager.get_base_container().get_container_item(x.get_root())
											
									if is_instance_valid(c):
										if cindex > -1 and cindex < c.get_parent().get_child_count() and c.get_index() != cindex:
											c.get_parent().move_child.call_deferred(c, cindex)
											
								elif type == &"TOP":
									var c : Node = _manager.get_base_container().get_container(x.get_root())
									var cindex : int = 0
									if !c:
										return false
										
									var root : Node = c.get_parent()
									
									if !root:
										return false
									
									cindex = root.get_index()
										
									_manager.split_row.execute(x)
										
									if !c.is_node_ready():
										await c.ready
										
									c = _manager.get_base_container().get_container_item(x.get_root())
									
									if is_instance_valid(c):
										var row : Node = c
										for __ : int in range(0, 2, 1):
											row = c.get_parent()
											
											if !is_instance_valid(row):
												break
												
										if is_instance_valid(row):
											var has : bool = false
											for ___ : int in range(0, 3, 1):
												if has:
													break
												for __ : int in range(0, 3, 1):
													await Engine.get_main_loop().process_frame
												if is_instance_valid(row) and is_instance_valid(c):
													var _root : Node = c.get_parent()
													if row.has_node(_root.get_path()) :
														has = true
														break
											
											if has and c and cindex > -1:
												for __ : int in range(0, 2, 1):
													c = c.get_parent()
													if !c:
														return false
												root = c.get_parent()
												if root and cindex < root.get_child_count() and c.get_index() != cindex:
													root.move_child(c, cindex)
									return true
								
								elif type == &"BOTTOM":
									_manager.split_row.execute(x)
									
									var c : Node = _manager.get_base_container().get_container(x.get_root())
									var cindex : int = 0
										
									if !c:
										return false
									
									if !c.is_node_ready():
										await c.ready
										
									cindex = c.get_index() + 1
										
									if c.get_index() < c.get_parent().get_child_count() - 1:
										if is_instance_valid(c):
											var row : Node = c
											for __ : int in range(0, 2, 1):
												row = c.get_parent()
												if !is_instance_valid(row):
													break
													
											if is_instance_valid(row):
												var z : int = c.get_index()
												if z > 0:
													var has : bool = false
													for ___ : int in range(0, 3, 1):
														if has:
															break
														for __ : int in range(0, 3, 1):
															await Engine.get_main_loop().process_frame
															if is_instance_valid(row) and is_instance_valid(c):
																var _root : Node = c.get_parent()
																if row.has_node(_root.get_path()) and _root is SpliterItem:
																	has = true
																	break
													if has and c and cindex > -1:
														for __ : int in range(0, 2, 1):
															c = c.get_parent()
															if !c:
																return false
														var root : Node = c.get_parent()
														if root and cindex < root.get_child_count() and c.get_index() != cindex:
															root.move_child(c, cindex)
								return true
	return false
