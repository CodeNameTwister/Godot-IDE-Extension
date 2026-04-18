@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const EditorTool = preload("./../../../core/editor/tools/editor_tool.gd")

const HelperEditorTool = preload("./../../../core/editor/tools/helper_editor_tool.gd")
const ScriptEditorTool = preload("./../../../core/editor/tools/script_editor_tool.gd")
const TextEditorTool = preload("./../../../core/editor/tools/text_editor_tool.gd")
		
var _tools : Array[EditorTool] = [
	ScriptEditorTool.new(),
	HelperEditorTool.new(),
	TextEditorTool.new()
]
			
func execute(value : Variant = null) -> bool:
	if !is_instance_valid(value) or !(value is Control):
		return true
		
	var control : Control = value
	
	if !control.is_node_ready() or !control.is_inside_tree() or control.is_queued_for_deletion():
		return false
	
	for x : MickeyTool in _tool_db.get_tools():
		if x.has(control):
			x.set_queue_free(false)
			return true
			
	var index : int = control.get_index()
	if !_manager.is_valid_item_index(index):
		return false
	
	var root : Node = _get_root()
		
	if is_instance_valid(root):
		var mt : MickeyTool = _tools[0].build(control)
		var is_editor : bool = _is_editor(mt, control)
		var doc : bool = false
		
		if !is_editor:
			for z : int in range(1, _tools.size(), 1):
				var x : EditorTool = _tools[z]
				mt = x.build(control)
				
				if mt != null:
					doc = x is HelperEditorTool
					break
		
		if is_instance_valid(mt):
			mt.focus.connect(_manager.focus_tool)
			mt.new_symbol.connect(_manager.set_symbol)
			mt.clear.connect(_manager.clear_editors)
			mt.ochorus(root)
			
			_tool_db.append(mt)
			
			_manager.tool_created()
			_manager.update_metadata(mt)
		
			_manager.queue_focus(mt)
			
			if doc:
				var settings : EditorSettings = EditorInterface.get_editor_settings()
				if settings:
					if settings.has_setting("plugin/script_splitter/editor/document_helper/opening/use_new_split") and settings.get_setting("plugin/script_splitter/editor/document_helper/opening/use_new_split") == true:
						if settings.has_setting("plugin/script_splitter/editor/document_helper/opening/user_another_existing_split") and settings.get_setting("plugin/script_splitter/editor/document_helper/opening/user_another_existing_split") == true:
							var base : Manager.BaseContainer = _manager.get_base_container()
							#var s_container : Control = base.get_container_item(root)
							var new_container : Control = root
							var next : bool = false
							var win : Window = new_container.get_window()
							for x : Node in base.get_all_splitters():
								if root == x:
									next = true
									continue
								elif x.get_window() != win:
									continue
									
								new_container = x
								#if s_container == base.get_container_item(x):
									#if new_container != root:
										#new_container = x
								if next:
									break
					
							if new_container != root:
								_manager.add_task(_manager.swap_tab.execute.bind([root, mt.get_control().get_index(), new_container]))
								for x : MickeyTool in _tool_db.get_tools():
									var c : Control = x.get_control()
									if root == c:
										if c is TabContainer:
											if c.current_tab == x.get_gui().get_index():
												_manager.add_task(c.tab_selected.emit.bind(c.current_tab))
												break
								return false
					
						if settings.has_setting("plugin/script_splitter/editor/document_helper/opening/use_row_on_new_split") and settings.get_setting("plugin/script_splitter/editor/document_helper/opening/use_row_on_new_split"):
							_manager.add_task(_manager.split_row.execute.bind(mt))
						else:									
							_manager.add_task(_manager.split_column.execute.bind(mt))
			return false
	
		if is_editor:
			return true
				
	printerr("Error!, Can not build control for ", control.name)
	return false

func _is_editor(mt : MickeyTool, control : Control) -> bool:
	if is_instance_valid(mt):
		return true
	
	if control is ScriptEditorBase:
		var sce : ScriptEditor = EditorInterface.get_script_editor()
		if sce and control in sce.get_open_script_editors():
			if control.name.begins_with("@"):
				if !("Script" in control.name):
					return false
			return true
		return _manager.get_editor_list().get_item_tooltip(control.get_index()).is_empty()
		
	return false

func _get_root() -> Node:
	var root : Node = _manager.get_current_root()
	if !is_instance_valid(root):
		var splitters : Array[Node] = _manager.get_base_container().get_all_splitters()
		if splitters.size() == 0:
			for x : MickeyTool in _tool_db.get_tools():
				x.reset()
			_manager.get_base_container().initialize_editor_container()
			root = _manager.get_current_root()
		else:
			for x : Node in splitters:
				if is_instance_valid(x) and !x.is_queued_for_deletion():
					root = x
					break
	return root
