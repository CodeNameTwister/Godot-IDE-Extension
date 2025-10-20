@tool
extends "res://addons/_Godot-IDE_/plugins/script_splitter/core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const BaseContainer = preload("res://addons/_Godot-IDE_/plugins/script_splitter/core/base/container.gd")


func execute(value : Variant = null) -> bool:
	if value is Array:
		if value.size() == 3:
			if value[0] is Container and value[1] is int and value[2] is Container:
				var from : Container = value[0]
				var index : int = value[1]
				var to : Container = value[2]
				
				if from == to:
					return false
				
				if from is BaseContainer.SplitterContainer.SplitterEditorContainer.Editor and to is BaseContainer.SplitterContainer.SplitterEditorContainer.Editor:
					for x : MickeyTool in _tool_db.get_tools():
						if x.is_valid():
							if x.get_root() == from and x.get_control().get_index() == index:
								x.ochorus(to)
								_manager.clear_editors()
								return true
			else:
				if value[0] is String and value[1] is String and value[2] is bool:
					var base : Manager.BaseList = _manager.get_editor_list()
					var from : String = value[0]
					var left : bool = value[2]
					var to : String = value[1]
					var fm : MickeyTool = null
					var tm : MickeyTool = null
					if from == to:
						return false
					for x : MickeyTool in _tool_db.get_tools():
						if !x.is_valid():
							continue
						var t : String = base.get_item_tooltip(x.get_index())
						if from == t:
							fm = x
						elif to == t:
							tm = x
					if is_instance_valid(fm) and is_instance_valid(tm) and fm != tm:
						var froot : Node = fm.get_root()
						var troot : Node = tm.get_root()
						if froot == troot:
							var tidx : int = tm.get_control().get_index()
							if left:
								froot.move_child(fm.get_control(), maxi(tidx - 1,0))
							else:
								froot.move_child(fm.get_control(), tidx)
						else:
							if froot.get_child_count() == 1:
								
								if _manager.merge_tool.execute([tm.get_control(), froot.get_parent().get_child_count() == 1]):
									fm.ochorus(troot)
								#if froot.get_parent().get_child_count() == 1:
									#froot.get_parent().queue_free()
								#else:
									#froot.queue_free()
						#_manager.get_base_container().update_split_container()
							else:
								fm.ochorus(troot)
						return true
	return false
