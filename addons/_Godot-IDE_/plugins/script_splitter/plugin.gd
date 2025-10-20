@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


const InputTool = preload("res://addons/_Godot-IDE_/plugins/script_splitter/core/Input.gd")
const TWISTER_script_splitter = preload("res://addons/_Godot-IDE_/plugins/script_splitter/core/builder.gd")
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
	builder = TWISTER_script_splitter.new()
	handler = InputTool.new(self, builder)
	
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
	builder.refresh_warnings()

func _exit_tree() -> void:
	remove_from_group(&"__SCRIPT_SPLITTER__")
	for x : Variant in [handler, builder]:
		if is_instance_valid(x) and x is Object:
			x.call(&"init_0")
			
func get_builder() -> Object:
	return builder
	
func _process(delta: float) -> void:
	builder.update(delta)
	
func _input(event: InputEvent) -> void:
	if handler.event(event):
		get_viewport().set_input_as_handled()

func _io_call(id : StringName) -> void:
	builder.handle(id)
