@tool
extends EditorPlugin
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	

var TAB : PackedScene = preload("res://addons/_Godot-IDE_/plugins/fancy_filters_script/filter_scene.tscn")

var _parent : Control = null
var _container : Control = null
var _script_info : Control = null

var _id_show_hide_tool : int = -1
var _id_toggle_position_tool : int = -1
var _id_switch_panels : int = -1

var _c_input_show_hide : InputEventKey = null
var _c_input_switch_panels : InputEventKey = null

var _menu : MenuButton = null

func _init() -> void:
	var input0 : Variant = IDE.get_config("fancy_filters_script", "show_hide")
	var input1 : Variant = IDE.get_config("fancy_filters_script", "switch_panels")
	if input0 is InputEventKey:
		_c_input_show_hide = input0
	else:
		_c_input_show_hide = InputEventKey.new()
		_c_input_show_hide.pressed = true
		_c_input_show_hide.ctrl_pressed = true
		_c_input_show_hide.keycode = KEY_T
		IDE.set_config("fancy_filters_script", "show_hide", _c_input_show_hide)
	if input1 is InputEventKey:
		_c_input_switch_panels = input1
	else:
		_c_input_switch_panels = InputEventKey.new()
		_c_input_switch_panels.pressed = true
		_c_input_switch_panels.ctrl_pressed = true
		_c_input_switch_panels.keycode = KEY_G
		IDE.set_config("fancy_filters_script", "switch_panels", _c_input_switch_panels)

func _get_traduce(msg : String) -> String:
	return msg

func _on_pop_pressed(index : int) -> void:
	if index > -1:
		if index == _id_show_hide_tool:
			_container.visible = !_container.visible 
		elif index == _id_toggle_position_tool:
			toggle_position()
		elif index == _id_switch_panels:
			if !_script_info.visible:
				var tab : Variant = _script_info.get_parent()
				if tab is TabContainer:
					tab.current_tab = _script_info.get_index()
			else:
				var script_list : Control = IDE.get_script_list_container()
				if is_instance_valid(script_list):#
					var tab : Variant = script_list.get_parent()
					if tab is TabContainer:
						tab.current_tab = script_list.get_index()

func _apply_changes() -> void:
	if _container:
		if _container.has_method(&"force_update"):
			_container.call_deferred(&"force_update")
	get_tree().call_group(&"UPDATE_ON_SAVE", &"update")

func _enter_tree() -> void:
	var container : VSplitContainer = IDE.get_script_list_container()
	if container:
		var variant : Variant = IDE.get_config("fancy_filter_script", "script_list_and_filter_to_right")
		var expected_index : int = 0
		if variant is bool:
			if variant == true:
				expected_index = 1
		
		container.name = "Script List"
		_container = TAB.instantiate()
		
		if _container.get_child_count() > 0:
			_script_info = _container.get_child(0)
		
		var parent : Control = container.get_parent()
		
		_parent = container.get_parent()
		parent.add_child(_container)
		container.reparent(_container)
		toggle_position()
		
		if _container.get_index() != expected_index:
			toggle_position()
			
		_menu = MenuButton.new()
		_menu.text = "Godot-IDE"
		_menu.visible = false
		
		var file : MenuButton = IDE.get_file_menu_button()
		var root : Node = file.get_parent()
		
		root.add_child(_menu)
		
		var pop : PopupMenu = _menu.get_popup()
		var total : int = pop.item_count
		var msg : String = _get_traduce("Show/Hide Scripts and Filters Panel")
		
		pop.index_pressed.connect(_on_pop_pressed)
		
		_add_input(pop, msg, _c_input_show_hide)
		_id_show_hide_tool = total
		
		total = pop.item_count
		msg = _get_traduce("Toggle Script Info/Script List Panel")
		_add_input(pop, msg, _c_input_switch_panels)
		_id_switch_panels = total
			
		total = pop.item_count
		msg = _get_traduce("Toggle Position Script and Filters Panel")
		pop.add_item(msg, -1) #, KEY_MASK_CTRL | KEY_NOT_DEFINED_YET
		_id_toggle_position_tool =total
		
func _add_input(pop : PopupMenu, msg : String, input : InputEventKey) -> void:
	if null != input:
		if input.ctrl_pressed and input.alt_pressed:
			pop.add_item(msg, -1, KEY_MASK_CTRL | KEY_MASK_ALT | input.keycode)				
		elif input.ctrl_pressed:
			pop.add_item(msg, -1, KEY_MASK_CTRL | input.keycode)
		elif input.alt_pressed:
			pop.add_item(msg, -1, KEY_MASK_ALT | input.keycode)
		else:
			pop.add_item(msg, -1, input.keycode) 
	else:
		pop.add_item(msg, -1, input.keycode) #, KEY_MASK_CTRL | KEY_NOT_DEFINED_YET) #, KEY_MASK_CTRL | KEY_NOT_DEFINED_YET
		
func _ready() -> void:
	if !Engine.get_main_loop().root.is_node_ready():
		await Engine.get_main_loop().root.ready
	for __ : int in range(30):
		var scene : SceneTree = get_tree()
		if !is_instance_valid(scene):
			return
		await scene.process_frame
	if is_instance_valid(_menu):
		var p : Node = _menu.get_parent()
		p.move_child(_menu, 0)
		_menu.visible = true
		
func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_match(_c_input_switch_panels):
		_on_pop_pressed(_id_switch_panels)
		
func toggle_position() -> void:
	var container : Control = _container
	if container:
		var parent : Control = container.get_parent()
			
		if parent is HSplitContainer and parent.get_child_count() > 1:
			if container.get_index() != 0:
				var size : float = (parent.get_child(0) as Control).size.x
				parent.move_child(container, 0)
				parent.split_offset = -size
				parent.clamp_split_offset.call_deferred()
			else:
				var size : float = (parent.get_child(1) as Control).size.x
				parent.move_child(_container, parent.get_child_count() - 1)
				parent.split_offset = size
				parent.clamp_split_offset.call_deferred()

func _exit_tree() -> void:
	var container : VSplitContainer = IDE.get_script_list_container()
	
	if is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null
	
	if is_instance_valid(_container) and _container.is_inside_tree():
		IDE.set_config("fancy_filter_script", "script_list_and_filter_to_right", _container.get_index() > 0)
		
	if container:
		var current_parent : Node = container.get_parent()
		if current_parent != _parent:
			if current_parent == null:
				_parent.add_child(container)
			else:
				container.reparent(_parent)
		if is_instance_valid(_container):
			_container.queue_free()
		container.visible = true
		
		var parent : Control = container.get_parent()
		if parent is HSplitContainer:
			if container.get_index() != 0:
				var size : float = (parent.get_child(1) as Control).size.x
				parent.move_child(container, 0)
				parent.split_offset = -size
				parent.clamp_split_offset.call_deferred()
				
