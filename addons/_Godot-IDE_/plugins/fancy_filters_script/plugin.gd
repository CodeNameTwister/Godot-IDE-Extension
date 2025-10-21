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
var _placeholder : Control = null

var _id_show_hide_tool : int = -1
var _id_toggle_position_tool : int = -1
var _id_switch_panels : int = -1

var _c_input_show_hide : InputEventKey = null
var _c_input_switch_panels : InputEventKey = null

var _as_separate_container : bool = false

var _input_defined : bool = false

func _on_changes() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		for x : String in settings.get_changed_settings():
			if "separate_container_list" in x:
				var value : Variant = IDE.get_config("fancy_filters_script", "separate_container_list")
				if value is bool and value != _as_separate_container:
					_as_separate_container = value
					_exit_tree()
					_enter_tree()
				break
			
func _init() -> void:
	var input0 : Variant = IDE.get_config("fancy_filters_script", "show_hide")
	var input1 : Variant = IDE.get_config("fancy_filters_script", "switch_panels")
	var as_separate_container : Variant = IDE.get_config("fancy_filters_script", "separate_container_list")
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		# 0.5.1
		if settings.has_setting("plugin/godot_ide/fancy_filter_script/script_list_and_filter_to_right"):
			settings.set_setting("plugin/godot_ide/fancy_filters_script/script_list_and_filter_to_right", settings.get_setting("plugin/godot_ide/fancy_filter_script/script_list_and_filter_to_right"))
			settings.set_setting("plugin/godot_ide/fancy_filter_script/script_list_and_filter_to_right", null)
		
		if !settings.settings_changed.is_connected(_on_changes):
			settings.settings_changed.connect(_on_changes)
	
	if as_separate_container is bool:
		_as_separate_container = _as_separate_container
	else:
		IDE.set_config("fancy_filters_script", "separate_container_list", _as_separate_container)
	
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
		var variant : Variant = IDE.get_config("fancy_filters_script", "script_list_and_filter_to_right")
		var expected_index : int = 0
		if variant is bool:
			if variant == true:
				expected_index = 1
				
		container.name = "Script List"
		_container = TAB.instantiate()
		
		if _container.get_child_count() > 0:
			_script_info = _container.get_child(0)
		
		var parent : Control = container.get_parent()
		_parent = parent
		if !_as_separate_container:
			var x : int = container.get_child_count()
			if x > 1:
				var cntl : Node = container.get_child(x - 1)
				if cntl is Control:
					if _placeholder == null:
						_placeholder = Control.new()
						_placeholder.visible = false
						cntl.reparent(_placeholder)
					
				container.add_child(_container)
				container.move_child(_container, 0)
				container.split_offset = 100
				container.clamp_split_offset()
			else:	
				container.add_child(_container)
		else:
			parent.add_child(_container)
			container.reparent(_container)
			
		toggle_position()
		
		var cnt : Control = _container
		if !_as_separate_container:
			cnt = _container.get_parent()
			
		if cnt.get_index() != expected_index:
			toggle_position()
			
		var menu : MenuButton = IDE.get_menu_button()		
		if is_instance_valid(menu):
			if _input_defined:
				return
				
			_input_defined = true
			
			var pop : PopupMenu = menu.get_popup()
			var total : int = pop.item_count
			var msg : String = _get_traduce("Show/Hide Scripts and Filters Panel")
		
			if !pop.index_pressed.is_connected(_on_pop_pressed):
				pop.index_pressed.connect(_on_pop_pressed)
			
			_add_input(pop, msg, _c_input_show_hide)
			_id_show_hide_tool = total
			
			total = pop.item_count
			msg = _get_traduce("Toggle Script Info/Script List Panel (Only if the separated option enabled)")
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
		
func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_match(_c_input_switch_panels):
		_on_pop_pressed(_id_switch_panels)
		
func toggle_position() -> void:
	var container : Control = _container
	if container:
		if !_as_separate_container:
			container = container.get_parent()
			
			if null == container:
				return
			
		var parent : Control = container.get_parent()
			
		if parent is HSplitContainer and parent.get_child_count() > 1:
			if container.get_index() != 0:
				var size : float = (parent.get_child(0) as Control).size.x
				parent.move_child(container, 0)
				parent.split_offset = -size
				parent.clamp_split_offset.call_deferred()
				
				var settings : EditorSettings = EditorInterface.get_editor_settings()
				if is_instance_valid(settings):
					settings.set_setting("plugin/godot_ide/fancy_filters_script/script_list_and_filter_to_right", false)
			else:
				var size : float = (parent.get_child(1) as Control).size.x
				parent.move_child(container, parent.get_child_count() - 1)
				parent.split_offset = size
				parent.clamp_split_offset.call_deferred()
				
				var settings : EditorSettings = EditorInterface.get_editor_settings()
				if is_instance_valid(settings):
					settings.set_setting("plugin/godot_ide/fancy_filters_script/script_list_and_filter_to_right", true)

func _exit_tree() -> void:
	var container : VSplitContainer = IDE.get_script_list_container()
	
	if is_instance_valid(_container) and _container.is_inside_tree():
		IDE.set_config("fancy_filters_script", "script_list_and_filter_to_right", _container.get_index() > 0)
		
	if container:
		var current_parent : Node = container.get_parent()
		
		if _placeholder:
			for x : Node in _placeholder.get_children():
				x.reparent(container)
			_placeholder.queue_free()
			_placeholder = null
				
		if current_parent != _parent:
			if current_parent == null:
				_parent.add_child(container)
			else:
				container.reparent(_parent)
		for x : Node in container.get_children():
			if x is Control:
				x.visible = true
		if is_instance_valid(_container):
			_container.queue_free()
			_container = null
		container.visible = true
		
		var parent : Control = container.get_parent()
		if parent is HSplitContainer:
			if container.get_index() != 0:
				var size : float = (parent.get_child(1) as Control).size.x
				parent.move_child(container, 0)
				parent.split_offset = -size
				parent.clamp_split_offset.call_deferred()
			
	#TODO: Remove new menu buttons	
