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
	
	if !control.is_node_ready() or !control.is_inside_tree():
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
		
		if !is_editor:
			for z : int in range(1, _tools.size(), 1):
				var x : EditorTool = _tools[z]
				mt = x.build(control)
				
				if mt != null:
					break
		
		if mt != null:
			mt.focus.connect(_manager.focus_tool)
			mt.new_symbol.connect(_manager.set_symbol)
			mt.clear.connect(_manager.clear_editors)
			mt.ochorus(root)
			
			_tool_db.append(mt)
			
			_manager.tool_created()
			_manager.update_metadata(mt)
			
			mt.trigger_focus()
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
