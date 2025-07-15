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

var _id_show_hide_tool : int = -1
var _id_toggle_position_tool : int = -1

var _c_input : InputEventKey = null

func _init() -> void:
	var input : Variant = IDE.get_config("fancy_filters_script", "show_hide")
	if input is InputEventKey:
		_c_input = input
	else:
		_c_input = InputEventKey.new()
		_c_input.pressed = true
		_c_input.ctrl_pressed = true
		_c_input.keycode = KEY_T
		IDE.set_config("fancy_filters_script", "show_hide", _c_input)

func _get_traduce(msg : String) -> String:
	return msg

func _on_pop_pressed(index : int) -> void:
	if index > -1:
		if index == _id_show_hide_tool:
			_container.visible = !_container.visible 
		if index == _id_toggle_position_tool:
			toggle_position()

func _apply_changes() -> void:
	if _container:
		if _container.has_method(&"force_update"):
			_container.call_deferred(&"force_update")
	get_tree().call_group(&"UPDATE_ON_SAVE", &"update")

func get_id(pop : PopupMenu, index : int, msg : String) -> int:
	if msg != pop.get_item_text(index):
		for x : int in pop.item_count:
			if msg == pop.get_item_text(x):
				return x
	return index

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
		
		var parent : Control = container.get_parent()
		
		_parent = container.get_parent()
		parent.add_child(_container)
		container.reparent(_container)
		toggle_position()
		
		if _container.get_index() != expected_index:
			toggle_position()
		
		var menu : MenuButton = IDE.get_file_menu_button()
		var pop : PopupMenu = menu.get_popup()
		var total : int = pop.item_count
		var msg : String = _get_traduce("Show/Hide Scripts and Filters Panel")
		
		pop.index_pressed.connect(_on_pop_pressed)
		
		if null != _c_input:
			if _c_input.ctrl_pressed and _c_input.alt_pressed:
				pop.add_item(msg, -1, KEY_MASK_CTRL | KEY_MASK_ALT | _c_input.keycode)				
			elif _c_input.ctrl_pressed:
				pop.add_item(msg, -1, KEY_MASK_CTRL | _c_input.keycode)
			elif _c_input.alt_pressed:
				pop.add_item(msg, -1, KEY_MASK_ALT | _c_input.keycode)
			else:
				pop.add_item(msg, -1, _c_input.keycode) 
		else:
			pop.add_item(msg, -1, _c_input.keycode) #, KEY_MASK_CTRL | KEY_NOT_DEFINED_YET) #, KEY_MASK_CTRL | KEY_NOT_DEFINED_YET
		_id_show_hide_tool = get_id(pop, total, msg)
			
		msg = _get_traduce("Toggle Position Script and Filters Panel")
		total = pop.item_count
		pop.add_item(msg, -1) #, KEY_MASK_CTRL | KEY_NOT_DEFINED_YET
		_id_toggle_position_tool = get_id(pop, total, msg)
		
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
	
	var menu : MenuButton = IDE.get_file_menu_button()
	var pop : PopupMenu = menu.get_popup()
	if pop:
		if _id_show_hide_tool > -1 and pop.item_count >= _id_toggle_position_tool:
			pop.remove_item(_id_toggle_position_tool) 
		if _id_show_hide_tool > -1 and pop.item_count >= _id_show_hide_tool:
			pop.remove_item(_id_show_hide_tool) 
	
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
				
