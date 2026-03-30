@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


const InputTool = preload("core/Input.gd")
const TWISTER_script_splitter = preload("core/builder.gd")
var builder : TWISTER_script_splitter = null
var handler : InputTool = null
		
var tab_container : Node = null:
	get:
		if !is_instance_valid(tab_container):
			tab_container = IDE.get_script_editor_container()
		return tab_container
var item_list : Node = null:
	get:
		if !is_instance_valid(item_list):
			item_list = IDE.get_script_list()
		return item_list
		
func find(root : Node, pattern : String, type : String) -> Node:
	var e : Array[Node] = root.find_children(pattern, type, true, false)
	if e.size() > 0:
		return e[0]
	return null

func _enter_tree() -> void:
	add_to_group(&"__SCRIPT_SPLITTER__")
	entered(false)
	
	var script_editor : ScriptEditor  = EditorInterface .get_script_editor()
	
	script_editor.tree_exiting.connect(exiting)
	script_editor.tree_entered.connect(entered)

func entered(wt : bool = true) -> void:
	exiting()
	
	if wt:
		for __ : int in range(30):
			await get_tree().process_frame
			
	builder = TWISTER_script_splitter.new()
	handler = InputTool.new(self, builder)
	
	if wt:
		_ready()
		
func exiting() -> void:
	set_process(false)
	set_process_input(false)
	
	for x : Variant in [handler, builder]:
		if is_instance_valid(x) and x is Object:
			x.call(&"init_0")
			
	handler = null
	builder = null
	
func script_split() -> void:
	handler.get_honey_splitter().split()
	
func script_merge(value : Node = null) -> void:
	handler.get_honey_splitter().merge(value)
	
func _ready() -> void:
	set_process(false)
	set_process_input(false)
	for __ : int in range(5):
		await Engine.get_main_loop().process_frame
	if is_instance_valid(builder):
		builder.init_1(self, tab_container, item_list)
	if is_instance_valid(handler):
		handler.init_1()
	
	builder.connect_callbacks(
		handler.add_column, 
		handler.add_row, 
		handler.remove_column, 
		handler.remove_row,
		handler.left_tab_close,
		handler.right_tab_close,
		handler.others_tab_close
		)
	
func _save_external_data() -> void:
	if builder:
		builder.refresh_warnings()
	
func remove_from_control(control : Node) -> void:
	builder.reset_by_control(control)

func _exit_tree() -> void:
	remove_from_group(&"__SCRIPT_SPLITTER__")
	
	var script_editor : ScriptEditor  = EditorInterface .get_script_editor()
	
	if is_instance_valid(script_editor):
		script_editor.tree_exiting.disconnect(exiting)
		script_editor.tree_entered.disconnect(entered)
	
	set_process(false)
	set_process_input(false)
	for x : Variant in [handler, builder]:
		if is_instance_valid(x) and x is Object:
			x.call(&"init_0")
			
			
func get_builder() -> Object:
	return builder
	
func _process(delta: float) -> void:
	if is_instance_valid(builder):
		builder.update(delta)
	
func _input(event: InputEvent) -> void:
	if handler.event(event):
		get_viewport().set_input_as_handled()

func _io_call(id : StringName) -> void:
	if builder:
		builder.handle(id)

func get_current_editor() -> String:
	var o : Object = get_builder()
	if o is TWISTER_script_splitter:
		return o.get_editor_manager().get_current_editor_path()
	return ""
	
func create_custom_container(split : PackedStringArray) -> void:
	if builder:
		var manager : Object = builder.get_editor_manager()
		if !manager:
			return
		manager.make_custom_container(split)

func move_item_container(container : TabContainer, from : int, to : int) -> void:
	builder.get_editor_manager().move_item_container(container, from, to)
