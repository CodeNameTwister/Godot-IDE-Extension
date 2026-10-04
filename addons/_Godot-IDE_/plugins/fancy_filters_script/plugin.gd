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
var _as_info_top : bool = true
var _as_right_container : bool = false

var _input_defined : bool = false

# Scripts/Filters panel width pinning, for every layout combination (separate
# or embedded container, left or right placement). One stored width per
# distraction-free mode; -1.0 means "not captured yet".
var _width_focus_off : float = -1.0
var _width_focus_on : float = -1.0
var _mode : int = -1
var _dragging : bool = false
var _pinning : bool = false
var _last_parent_size : Vector2 = Vector2.ZERO
var _settle : int = 0
var _script_container : VSplitContainer = null
var _pin_control : Control = null
var _pin_sign : int = 1

const _DEFAULT_WIDTH : float = 220.0
const _MIN_PIN_WIDTH : float = 100.0

func _mode_now() -> int:
	# EditorInterface.distraction_free_mode (Godot 4.7). Read via get() so a
	# missing property degrades to "off" instead of erroring.
	var dfm : Variant = EditorInterface.get(&"distraction_free_mode")
	return 1 if (dfm is bool and dfm) else 0

func _get_width(mode : int) -> float:
	return _width_focus_off if mode == 0 else _width_focus_on

func _set_width(mode : int, value : float, persist : bool = true) -> void:
	if mode == 0:
		_width_focus_off = value
	else:
		_width_focus_on = value
	if persist:
		IDE.set_config("fancy_filters_script", "width_focus_off" if mode == 0 else "width_focus_on", value)

func _control_width() -> float:
	if is_instance_valid(_pin_control):
		return _pin_control.size.x
	return -1.0

## Shift the split so the pinned control is `width` pixels wide. Width changes
## 1:1 with split_offset (positive for the first child, negative for the
## second), so a signed delta is exact and placement-independent.
func _apply_width(width : float) -> void:
	if !_pinning or !is_instance_valid(_parent) or !is_instance_valid(_pin_control):
		return
	var current : float = _control_width()
	if current <= 0.0:
		return
	_parent.split_offset = int(round(_parent.split_offset + _pin_sign * (width - current)))
	_parent.clamp_split_offset()

func _capture_width(mode : int) -> void:
	var w : float = _control_width()
	if w > 0.0:
		_set_width(mode, w)

## Pinned control: the Filters panel when it is a standalone (separate) child of
## the splitter, otherwise the script-list container it is embedded in. Works
## for both left and right placement (the sign handles which child it is).
func _setup_pinning() -> void:
	var control : Control = _container if _as_separate_container else _script_container
	if _parent is SplitContainer and is_instance_valid(control) and control.get_parent() == _parent:
		_pin_control = control
		_pinning = true
	else:
		_pin_control = null
		_pinning = false
	if !_pinning:
		set_process(false)
		return
	_pin_sign = 1 if _pin_control.get_index() == 0 else -1
	if _parent.has_signal(&"drag_started") and !_parent.drag_started.is_connected(_on_drag_started):
		_parent.drag_started.connect(_on_drag_started)
	if _parent.has_signal(&"drag_ended") and !_parent.drag_ended.is_connected(_on_drag_ended):
		_parent.drag_ended.connect(_on_drag_ended)
	_mode = _mode_now()
	_last_parent_size = _parent.size
	_settle = 4
	set_process(true)

## First run for a mode: keep a sane on-screen width, else fall back to a
## comfortable default (avoids adopting a stale/clamped layout).
func _first_run_width() -> float:
	var w : float = _control_width()
	if w >= _MIN_PIN_WIDTH and w <= _parent.size.x * 0.5:
		return w
	return _DEFAULT_WIDTH

func _on_drag_started() -> void:
	_dragging = true

func _on_drag_ended() -> void:
	_dragging = false
	if _mode >= 0:
		_capture_width(_mode)

func _process(_delta : float) -> void:
	if !_pinning or _dragging:
		return
	if !is_instance_valid(_parent) or !is_instance_valid(_pin_control):
		return
	var changed : bool = false
	var mode : int = _mode_now()
	if mode != _mode:
		# Distraction-free toggled: keep the two modes' widths independent.
		var outgoing : int = _mode
		_mode = mode
		if _get_width(_mode) <= 0.0:
			var seed : float = _get_width(outgoing)
			if seed > 0.0:
				_set_width(_mode, seed)
		changed = true
	if _parent.size != _last_parent_size:
		_last_parent_size = _parent.size
		changed = true
	# After a mode switch / resize the children can be one frame stale, so a
	# single delta apply may overshoot and clamp. Re-correct for a few frames.
	if changed:
		_settle = 4
	if _get_width(_mode) <= 0.0:
		# First run for this mode: let the layout settle, then pick a width.
		if _settle > 0:
			_settle -= 1
			return
		if _control_width() > 0.0:
			var first : float = _first_run_width()
			_set_width(_mode, first)
			_apply_width(first)
		return
	if _settle > 0:
		var current : float = _control_width()
		if current <= 0.0:
			return
		_settle -= 1
		if absf(current - _get_width(_mode)) > 0.5:
			_apply_width(_get_width(_mode))

func _on_changes() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		var changes : PackedStringArray = settings.get_changed_settings()
		var rst : bool = false
		
		for x : String in changes:
			if "separate_container_list" in x:
				var value : Variant = IDE.get_config("fancy_filters_script", "separate_container_list")
				if value is bool and value != _as_separate_container:
					_as_separate_container = value
					rst = true
				
			elif "script_info_on_top" in x:
				var value : Variant = IDE.get_config("fancy_filters_script", "script_info_on_top")
				if value is bool and value != _as_info_top:
					_as_info_top = value
					rst = true
					
			elif "script_list_and_filter_to_right" in x:
				var value : Variant = IDE.get_config("fancy_filters_script", "script_list_and_filter_to_right")
				if value is bool and value != _as_right_container:
					_as_right_container = value
					rst = true
			
		if rst:
			_exit_tree()
			_enter_tree()
			
func _init() -> void:
	var input0 : Variant = IDE.get_config("fancy_filters_script", "show_hide")
	var input1 : Variant = IDE.get_config("fancy_filters_script", "switch_panels")
	var as_separate_container : Variant = IDE.get_config("fancy_filters_script", "separate_container_list")
	var as_info_top : Variant = IDE.get_config("fancy_filters_script", "script_info_on_top")
	var as_right_container : Variant = IDE.get_config("fancy_filters_script", "script_list_and_filter_to_right")
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		# 0.5.1
		if settings.has_setting("plugin/godot_ide/fancy_filter_script/script_list_and_filter_to_right"):
			settings.set_setting("plugin/godot_ide/fancy_filters_script/script_list_and_filter_to_right", settings.get_setting("plugin/godot_ide/fancy_filter_script/script_list_and_filter_to_right"))
			settings.set_setting("plugin/godot_ide/fancy_filter_script/script_list_and_filter_to_right", null)
		
		if !settings.settings_changed.is_connected(_on_changes):
			settings.settings_changed.connect(_on_changes)
	
	if as_separate_container is bool:
		_as_separate_container = as_separate_container
	else:
		IDE.set_config("fancy_filters_script", "separate_container_list", _as_separate_container)
	
	if as_info_top is bool:
		_as_info_top = as_info_top
	else:
		IDE.set_config("fancy_filters_script", "script_info_on_top", _as_info_top)
		
	if as_right_container is bool:
		_as_right_container = as_right_container
	else:
		IDE.set_config("fancy_filters_script", "script_list_and_filter_to_right", _as_right_container)
	
	var width_off : Variant = IDE.get_config("fancy_filters_script", "width_focus_off")
	if width_off is float or width_off is int:
		_width_focus_off = float(width_off)
	
	var width_on : Variant = IDE.get_config("fancy_filters_script", "width_focus_on")
	if width_on is float or width_on is int:
		_width_focus_on = float(width_on)
	
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
			IDE.set_config("fancy_filters_script", "script_list_and_filter_to_right", !_as_right_container)
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

func _await() -> bool:
	for __ : int in range(30):
		var scene : SceneTree = get_tree()
		if !is_instance_valid(scene):
			return false
		await scene.process_frame
	return true

func _m_offset(node : SplitContainer, default : float) -> float:
	if node.get_child_count() > 1:
		var wd : float = node.size.x
		var ml : float = node.get_child(0).get_combined_minimum_size().x
		var mr : float = node.get_child(1).get_combined_minimum_size().x
		var sep = node.get_theme_constant("separation")

		return wd - ml - mr - sep
	return default

func _enter_tree() -> void:
	if !is_node_ready():
		await ready
		
		if !(await _await()):
			return
	
	var container : VSplitContainer = IDE.get_script_list_container()
	_script_container = container
	if container:				
		container.name = "Script List"
		_container = TAB.instantiate()
		_container.enable = true
		_container.plugin = self
		
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
				
				if _as_info_top:
					if _container.get_index() > 0:
						container.move_child(_container, 0)
				else:
					if _container.get_index() < container.get_child_count() - 1:
						container.move_child(_container, -1)
					
				_offset.call_deferred(container, 100)
			else:	
				container.add_child(_container)
			
			if _as_right_container:
				if container.get_index() != _parent.get_child_count() - 1:
					_parent.move_child(container, -1)
					if _parent is SplitContainer:
						var mo : float = _m_offset(_parent, 0)
						if mo > 0.0:
							if _parent.get_child_count() > 1:
								_parent.set_deferred(&"split_offset", mo - 10)
							_parent.clamp_split_offset.call_deferred()
			else:
				if container.get_index() != 0:
					if _parent is SplitContainer:
						if _parent.get_child_count() > 1:
							_parent.set_deferred(&"split_offset", 10)
						_parent.clamp_split_offset.call_deferred()
					_parent.move_child(container, 0)
		else:
			parent.add_child(_container)
			container.reparent(_container)
			
			if _as_right_container:
				if _container.get_index() != parent.get_child_count() - 1:
					if _parent is SplitContainer:
						var mo : float = _m_offset(_parent, 0)
						if mo > 0.0:
							if _parent.get_child_count() > 1:
								_parent.set_deferred(&"split_offset", mo - 10)
							_parent.clamp_split_offset.call_deferred()
					
					parent.move_child(_container, -1)
			else:
				# Filters on the left: do not force a fixed offset. The stored
				# per-mode width is applied by _setup_pinning() below, or the
				# current native width is adopted on first run.
				if _container.get_index() != 0:
					parent.move_child(_container, 0)
		
		_setup_pinning()
		
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
		
func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_match(_c_input_switch_panels):
		_on_pop_pressed(_id_switch_panels)

func _offset(node : SplitContainer, size : float) -> void:
	if !is_instance_valid(node):
		return
		
	if !node.is_node_ready():
		await node.ready
		
		if !is_instance_valid(node):
			return
			
	if node.get_child_count() > 1:
		if _parent.get_child_count() > 1:
			node.set_deferred(&"split_offset", size)
		node.clamp_split_offset.call_deferred()

func _exit_tree() -> void:
	set_process(false)
	_pinning = false
	_dragging = false
	var container : VSplitContainer = IDE.get_script_list_container()

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
				_offset.call_deferred(parent, -size)
