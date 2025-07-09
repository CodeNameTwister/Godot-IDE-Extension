@tool
extends Object
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	
const EditorContainer : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/EditorContainer.gd")
const DD : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/DDContainer.gd")
const DDO : PackedScene = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/ui/dd.tscn")
const DDITEM : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/DDItem.gd")

#region POPSC	
const FLYING_SCRIPT : PackedScene = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/flying_script.tscn")
const _POP_SCRIPT_PLACEHOLDER : String = "_POPGDScript_"
var _pop_scripts : Array[Window] = []
var _pop_script_placeholder : bool = false
#endregion

const GLOBALS : PackedStringArray = ["_GlobalScope", "_GDScript"]

var _plugin : Node = null

var _root : Node = null
var _main : EditorContainer = null
var _container : Root = null
var _editor : TabContainer = null

var _code_editors : Array[Mickeytools] = []
		
var _last_local_tool : Mickeytools = null
var _last_tool : Mickeytools = null:
	set(e):
		_last_tool = e
		if is_instance_valid(_last_tool):
			if !_last_tool.is_floating():
				_last_local_tool = _last_tool

var _tweener : ReTweener = null
var _item_list : ItemList = null:
	set(e):
		
		if e == null and is_instance_valid(_item_list):
			if _item_list.has_signal(&"on_start_drag") and  _item_list.is_connected(&"on_start_drag", _on_drag):
				_item_list.disconnect(&"on_start_drag", _on_drag)
			if _item_list.has_signal(&"on_stop_drag") and  _item_list.is_connected(&"on_stop_drag", _out_drag):
				_item_list.disconnect(&"on_stop_drag", _out_drag)
					
			if _item_list.get_script() == DDITEM:
				_item_list.set_script(null)
			_item_list = null
		else:
			_item_list = e
			if is_instance_valid(_item_list) and _item_list.get_script() != DDITEM:
				_item_list.set_script(DDITEM)
				
				if _item_list.has_signal(&"on_start_drag") and  !_item_list.is_connected(&"on_start_drag", _on_drag):
					_item_list.connect(&"on_start_drag", _on_drag)
				if _item_list.has_signal(&"on_stop_drag") and  !_item_list.is_connected(&"on_stop_drag", _out_drag):
					_item_list.connect(&"on_stop_drag", _out_drag)
					
				
	get:
		if !is_instance_valid(_item_list):
			var script_editor: ScriptEditor = EditorInterface.get_script_editor()
			var items : Array[Node] = script_editor.find_children("*", "ItemList", true, false)
			if items.size() > 0:
				_item_list =  items[0]
			else:
				push_warning("[Script-Spliter] Can not find item list!")
		return _item_list

#region __CONFIG__
var _SPLIT_USE_HIGHLIGHT_SELECTED : bool = true
var _MINIMAP_4_UNFOCUS_WINDOW : bool = false

var _SPLIT_HIGHLIGHT_COLOR : Color = Color.MEDIUM_SLATE_BLUE

var _SEPARATOR_LINE_SIZE : int = 8
var _SEPARATOR_LINE_COLOR : Color = Color.MAGENTA
var _SEPARATOR_BUTTON_SIZE : int = 19
var _SEPARATOR_BUTTON_MODULATE : Color = Color.WHITE
var _SEPARATOR_BUTTON_ICON : String = "res://addons/_Godot-IDE_/plugins/script_spliter/context/icons/expand.svg"

var _SEPARATOR_LINE_MOVEMENT : bool = true
var _SEPARATOR_LINE_DOUBLE_CLICK : bool = true

var _BEHAVIOUR_CAN_EXPAND_ON_FOCUS : bool = true
var _BEHAVIOUR_CAN_EXPAND_SAME_ON_FOCUS : bool = false

var _SEPARATOR_SMOOTH_EXPAND : bool = true
var _SEPARATOR_SMOOTH_EXPAND_TIME : float = 0.24

var _OUT_FOCUS_COLORED : bool = true
var _UNFOCUS_COLOR : Color = Color.GRAY

var _SWAP_BY_BUTTON : bool = true

#region _9_
var HANDLE_BACK_FORWARD_BUTTONS : bool = true
var HANDLE_BACKWARD_FORWARD_AS_NEXT_BACK_TAB : bool = false
var HANDLE_BACK_FORWARD_BUFFER : int = 20
var USE_NATIVE_ON_NOT_TABS : bool = true
var _HANDLE_BACKWARD_KEY_PATH : String = "res://addons/_Godot-IDE_/plugins/script_spliter/io/backward_key_button.tres"
var _HANDLE_FORWARD_KEY_PATH : String  = "res://addons/_Godot-IDE_/plugins/script_spliter/io/forward_key_button.tres"
var _HANDLE_BACKWARD_MOUSE_BUTTON_PATH : String = "res://addons/_Godot-IDE_/plugins/script_spliter/io/backward_mouse_button.tres"
var _HANDLE_FORWARD_MOUSE_BUTTON_PATH : String  = "res://addons/_Godot-IDE_/plugins/script_spliter/io/forward_mouse_button.tres"
#endregion

# CURRENT CONFIG
var current_columns : int = 1
var current_rows : int = 1

# FLAG
var _chaser_enabled : bool = false
var _focus_queue : bool = false

# REF
var _wm : Window = null

var is_dd_handled : bool = false
var _last_dd_root : Control = null
var _ddo : Control = null

signal tool_added(tool : Mickeytools)

func _get_data_cfg() -> Array[Array]:
	const CFG : Array[Array] = [
		[&"plugin/script_spliter/window/use_highlight_selected", &"_SPLIT_USE_HIGHLIGHT_SELECTED"]
		,[&"plugin/script_spliter/window/highlight_selected_color",&"_SPLIT_HIGHLIGHT_COLOR"]

		,[&"plugin/script_spliter/editor/minimap_for_unfocus_window", &"_MINIMAP_4_UNFOCUS_WINDOW"]
		,[&"plugin/script_spliter/editor/out_focus_color_enabled", &"_OUT_FOCUS_COLORED"]
		,[&"plugin/script_spliter/editor/out_focus_color_value", &"_UNFOCUS_COLOR"]
		,[&"plugin/script_spliter/editor/split/reopen_last_closed_editor_on_add_split", &"_SHOULD_OPEN_CLOSED_EDITOR_SCRIPT"]
		,[&"plugin/script_spliter/editor/split/remember_last_used_editor_buffer_size", &"_LAST_USED_EDITOR_SIZE"]

		,[&"plugin/script_spliter/line/size", &"_SEPARATOR_LINE_SIZE"]
		,[&"plugin/script_spliter/line/color", &"_SEPARATOR_LINE_COLOR"]
		,[&"plugin/script_spliter/line/draggable", &"_SEPARATOR_LINE_MOVEMENT"]
		,[&"plugin/script_spliter/line/expand_by_double_click", &"_SEPARATOR_LINE_DOUBLE_CLICK"]

		,[&"plugin/script_spliter/line/button/size", &"_SEPARATOR_BUTTON_SIZE"]
		,[&"plugin/script_spliter/line/button/modulate", &"_SEPARATOR_BUTTON_MODULATE"]
		,[&"plugin/script_spliter/line/button/icon_path", &"_SEPARATOR_BUTTON_ICON"]
		
		,[&"plugin/script_spliter/editor/behaviour/expand_on_focus", &"_BEHAVIOUR_CAN_EXPAND_ON_FOCUS"]
		,[&"plugin/script_spliter/editor/behaviour/can_expand_on_same_focus", &"_BEHAVIOUR_CAN_EXPAND_SAME_ON_FOCUS"]
		,[&"plugin/script_spliter/editor/behaviour/smooth_expand", &"_SEPARATOR_SMOOTH_EXPAND"]
		,[&"plugin/script_spliter/editor/behaviour/smooth_expand_time", &"_SEPARATOR_SMOOTH_EXPAND_TIME"]
		,[&"plugin/script_spliter/editor/behaviour/swap_by_double_click_separator_button", &"_SWAP_BY_BUTTON"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/handle_back_and_forward", &"HANDLE_BACK_FORWARD_BUTTONS"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/history_size", &"HANDLE_BACK_FORWARD_BUFFER"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/using_as_next_and_back_tab", &"HANDLE_BACKWARD_FORWARD_AS_NEXT_BACK_TAB"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/backward_key_button_path", &"_HANDLE_BACKWARD_KEY_PATH"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/forward_key_button_path", &"_HANDLE_FORWARD_KEY_PATH"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/backward_mouse_button_path", &"_HANDLE_BACKWARD_MOUSE_BUTTON_PATH"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/forward_mouse_button_path", &"_HANDLE_FORWARD_MOUSE_BUTTON_PATH"]
		,[&"plugin/script_spliter/editor/behaviour/back_and_forward/use_native_handler_when_there_are_no_more_tabs", &"USE_NATIVE_ON_NOT_TABS"]
		]
	return CFG
	
func _on_wm_foucs() -> void:
	if !is_instance_valid(_last_tool) or _last_tool.is_floating():
		if is_instance_valid(_last_local_tool):
			_last_local_tool.focus.emit(_last_local_tool)
		else:
			for x : Mickeytools in _code_editors:
				if !x.is_floating():
					x.focus.emit(x)
					return

func _out_wm_focus() -> void:
	return
	
func show_dd(root : Control) -> void:
	var dd : Control = null
	for xx : Node in _main.get_children():
		if xx is Control and !xx.visible:
			continue
		for x : Node in xx.get_children():
			if x is Control and x.visible:
				var mp : Vector2i = x.get_global_mouse_position()
				if x.get_global_rect().has_point(mp):
					dd = xx
					break
	if dd == null or _last_dd_root == dd:
		return
	_last_dd_root = dd
		
	var node : Node = _last_tool.get_root() 
	
	if node == root:
		return
	if node:
		if dd.find_child(node.name, true, false) != null:
			if is_instance_valid(_ddo):
				var p : Node = _ddo.get_parent()
				if p:
					p.remove_child(_ddo)
			return
	if !is_instance_valid(_ddo):
		_ddo = DDO.instantiate()
	else:
		var p : Node = _ddo.get_parent()
		if p:
			p.remove_child(_ddo)
	dd.add_child(_ddo)
	_ddo.visible = true

func set_item_list(o : ItemList) -> void:
	_item_list = o

func init_1() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var vp : Viewport = _plugin.get_viewport()
	if vp:
		_wm = vp.get_window()
		
		if !_wm.focus_entered.is_connected(_on_wm_foucs):
			_wm.focus_entered.connect(_on_wm_foucs)
		if !_wm.focus_exited.is_connected(_out_wm_focus):
			_wm.focus_exited.connect(_out_wm_focus)

	var hbkp : String = _HANDLE_BACKWARD_KEY_PATH
	var hbmp : String = _HANDLE_BACKWARD_MOUSE_BUTTON_PATH
	var hfkp : String = _HANDLE_FORWARD_KEY_PATH
	var hfmp : String = _HANDLE_FORWARD_MOUSE_BUTTON_PATH

	for x : Array in _get_data_cfg():
		if !settings.has_setting(x[0]):
			settings.set_setting(x[0], get(x[1]))
		else:
			set(x[1], settings.get_setting(x[0]))
			
	if !FileAccess.file_exists(_HANDLE_BACKWARD_KEY_PATH):
		_HANDLE_BACKWARD_KEY_PATH = hbkp
	if !FileAccess.file_exists(_HANDLE_BACKWARD_MOUSE_BUTTON_PATH):
		_HANDLE_BACKWARD_MOUSE_BUTTON_PATH = hbmp
	if !FileAccess.file_exists(_HANDLE_FORWARD_KEY_PATH):
		_HANDLE_FORWARD_KEY_PATH = hfkp
	if !FileAccess.file_exists(_HANDLE_FORWARD_MOUSE_BUTTON_PATH):
		_HANDLE_FORWARD_MOUSE_BUTTON_PATH = hfmp

	settings.add_property_info({
		"name": &"plugin/script_spliter/window/highlight_selected_color",
		"type": TYPE_COLOR
	})
	settings.add_property_info({
		"name": &"plugin/script_spliter/line/button/modulate",
		"type": TYPE_COLOR
	})
#endregion
	
#region _FEATURE#5_
var _SHOULD_OPEN_CLOSED_EDITOR_SCRIPT : bool = false
var _LAST_USED_EDITOR_SIZE : int = 4

var _lifo_src : PackedStringArray = []

func add_last_script_used(src : String) -> void:
	if _LAST_USED_EDITOR_SIZE > 0:
		if src.is_empty():
			return
		
		var x : int = _lifo_src.find(src)
		if x > -1:
			_lifo_src.remove_at(x)
		
		_lifo_src.append(src)
		var total : int = maxi(_LAST_USED_EDITOR_SIZE, 0)
		while _lifo_src.size() > total:
			_lifo_src.remove_at(0)
		
func get_last_script_used() -> String:
	var size : int = _lifo_src.size()
	var result : String = ""
	if size > 0:
		size -= 1
		result = _lifo_src[size]
		_lifo_src.remove_at(size)
	return result
#region

func update_config() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var changes : PackedStringArray = settings.get_changed_settings()

	var _dirty_colored : bool = _OUT_FOCUS_COLORED

	for x : Array in _get_data_cfg():
		if x[0] in changes:
			set(x[1], settings.get_setting(x[0]))

	_update_container()
	
	if _dirty_colored and !_OUT_FOCUS_COLORED:
		for x : Mickeytools in _code_editors:
			var gui : Node = x.get_control()
			if is_instance_valid(gui) and gui is Control:
				gui.modulate = Color.WHITE
	
	for x : String in changes:
		if "button_path" in x:
			if !InputMap.has_action(&"ui_script_spliter_forward"):
				InputMap.add_action(&"ui_script_spliter_forward")
			else:
				InputMap.action_erase_events(&"ui_script_spliter_forward")
			
			var key_0 : InputEventKey = ResourceLoader.load(_HANDLE_FORWARD_KEY_PATH)
			var key_1 : InputEventMouseButton = ResourceLoader.load(_HANDLE_FORWARD_MOUSE_BUTTON_PATH)
			InputMap.action_add_event(&"ui_script_spliter_forward", key_0)
			InputMap.action_add_event(&"ui_script_spliter_forward", key_1)
			
			if !InputMap.has_action(&"ui_script_spliter_backward"):
				InputMap.add_action(&"ui_script_spliter_backward")
			else:
				InputMap.action_erase_events(&"ui_script_spliter_backward")
				
			key_0 = ResourceLoader.load(_HANDLE_BACKWARD_KEY_PATH)
			key_1 = ResourceLoader.load(_HANDLE_BACKWARD_MOUSE_BUTTON_PATH)
			InputMap.action_add_event(&"ui_script_spliter_backward", key_0)
			InputMap.action_add_event(&"ui_script_spliter_backward", key_1)
			break

func _update_container() -> void:
	if !is_instance_valid(_main):
		return
	_main.separator_line_size = _SEPARATOR_LINE_SIZE
	_main.separator_line_color = _SEPARATOR_LINE_COLOR
	_main.drag_button_size = _SEPARATOR_BUTTON_SIZE
	_main.drag_button_modulate = _SEPARATOR_BUTTON_MODULATE
	_main.behaviour_expand_smoothed = _SEPARATOR_SMOOTH_EXPAND
	_main.behaviour_expand_smoothed_time = _SEPARATOR_SMOOTH_EXPAND_TIME
	_main.behaviour_expand_on_focus = _BEHAVIOUR_CAN_EXPAND_ON_FOCUS
	_main.behaviour_can_expand_focus_same_container = _BEHAVIOUR_CAN_EXPAND_SAME_ON_FOCUS
	_main.behaviour_expand_on_double_click = _SEPARATOR_LINE_DOUBLE_CLICK
	_main.behaviour_can_move_by_line = _SEPARATOR_LINE_MOVEMENT
	
	if !_SEPARATOR_BUTTON_ICON.is_empty():
		if FileAccess.file_exists(_SEPARATOR_BUTTON_ICON):
			var text : Variant = ResourceLoader.load(_SEPARATOR_BUTTON_ICON)
			if text is Texture:
				_main.drag_button_icon = text
			else:
				push_warning("[Script-Spliter] The resource is not a texture imported ", _SEPARATOR_BUTTON_ICON)
		else:
			push_warning("[Script-Spliter] Can not find the resource ", _SEPARATOR_BUTTON_ICON)

func _init(plugin : Object) -> void:
	_plugin = plugin

func init_0() -> void:
	if is_instance_valid(_tweener):
		_tweener.clear()
	_tweener = null
	
	if is_instance_valid(_ddo):
		if !_ddo.is_queued_for_deletion():
			_ddo.queue_free()
		
	if is_instance_valid(_wm):
		if _wm.focus_entered.is_connected(_on_wm_foucs):
			_wm.focus_entered.disconnect(_on_wm_foucs)
		if _wm.focus_exited.is_connected(_out_wm_focus):
			_wm.focus_exited.disconnect(_out_wm_focus)

	if is_instance_valid(_editor):
		if _editor.tree_exiting.is_connected(_on_container_exit):
			_editor.tree_exiting.disconnect(_on_container_exit)
		if _editor.tree_entered.is_connected(_on_container_entered):
			_editor.tree_entered.disconnect(_on_container_entered)
			
	
	if is_instance_valid(_root) and _root is Control:
		if _root.item_rect_changed.is_connected(update_rect):
			_root.item_rect_changed.disconnect(update_rect)

	for x : Mickeytools in _code_editors:
		x.reset(false)
		x.free()
	_code_editors.clear()

	if is_instance_valid(_container):
		var parent : Node = _container.get_parent()
		_container.visible = false
		if is_instance_valid(parent):
			parent.remove_child(_container)
		_container.queue_free()

	if is_instance_valid(_editor):
		_setup(_editor, false)
		_editor.visible = true
			
	_item_list = null
			
	for x : Window in _pop_scripts:
		if is_instance_valid(x) and !x.is_queued_for_deletion():
			x.queue_free()
	_pop_scripts.clear()


func _clear() -> void:
	for z : int in range(_code_editors.size() - 1, -1 , -1):
		var x : Mickeytools = _code_editors[z]
		var dirty : bool = false
		for e : Node in _editor.get_children():
			if x.is_equal(e):
				dirty = true
				break
		if !dirty:
			_code_editors[z].reset()
			_code_editors.remove_at(z)
			
	for x : Window in _pop_scripts:
		var node : Node = x.get_base_control()
		for y : Node in node.get_children():
			var dirty : bool = false
			for t : Mickeytools in _code_editors:
				if t.get_control() == y:
					dirty = true
			if !dirty:
				for zx : Node in _editor.get_children():
					if y == zx:
						dirty = true
						break
				if dirty:
					y.queue_free.call_deferred()
		if node.get_child_count() < 1:
			_pop_scripts.erase(x)
			x.queue_free()

	for x : Node in _main.get_children():
		if x is TabContainer:continue
		for y : Node in x.get_children():
			for z : Node in y.get_children():
				var dirty : bool = false
				for t : Mickeytools in _code_editors:
					if t.get_control() == z:
						dirty = true
				if !dirty:
					for zx : Node in _editor.get_children():
						if z == zx:
							dirty = true
							break
					if dirty:
						z.queue_free.call_deferred()
					else:
						y.remove_child(z)

func get_editors() -> Array[Mickeytools]:
	return _code_editors
	
func _get_editor_root() -> Node:
	var aviable : Node = get_aviable()
	if is_instance_valid(aviable):
		return aviable
	if is_instance_valid(_last_tool):
		return _last_tool.get_root()
	return null

func get_last_tool() -> Mickeytools:
	return _last_tool
	
func update_info(root : TabContainer, index : int , src : String) -> void:
	if !is_instance_valid(root):
		return
	var item_list : Control = _item_list
	if !src.is_empty():
		if is_instance_valid(item_list):
			var indx : int = -1
			for x : int in item_list.item_count:
				if item_list.get_item_tooltip(x) == src:
					indx = x
					break
			if indx > -1:
				var text : String = _item_list.get_item_text(indx)
				if text.is_empty() or text.begins_with("@"):
					text = item_list.get_item_tooltip(index).get_file()
				text = text.trim_suffix("(*)")
				root.set_tab_title(index, text)
				root.set_tab_icon(index, item_list.get_item_icon(indx))
			


class Root extends MarginContainer:
	var _helper : Object = null
	
	func _init(helper : Object) -> void:
		_helper = helper
	
	func _get_index(x : Mickeytools) -> int:
		var gui : Control = x.get_gui()
		if is_instance_valid(gui):
			var root : Control = x.get_root()
			if root:
				root = root.get_parent()
			if is_instance_valid(root):
				return root.get_index()
		return -1
	
	func _fwrd() -> bool:
		if _helper._chaser_enabled:
			return true
			
		var tool : Mickeytools = _helper.get_last_tool()
		if !is_instance_valid(tool):
			return false
			
		var root : Variant = tool.get_root()
		if !is_instance_valid(root):
			return false 
			
		if !_helper.HANDLE_BACKWARD_FORWARD_AS_NEXT_BACK_TAB:
			for __ : int in range(0, 2):
				if root == null:
					return false
				elif root.has_method(&"forward_editor"):
					var o : Object = root.call(&"forward_editor")
					if o and o.has_signal(&"focus"):
						o.emit_signal(&"focus", o, false)
						return true
					return false
				root = root.get_parent()
		else:
			var control : TabContainer = root
			var count : int = control.get_tab_count()
			if count > 1:
				var current : int = wrapi(control.current_tab + 1, 0, count)
				if current > -1 and  current < control.get_child_count():
					var gui : Node = control.get_child(current)
					for x : Mickeytools in _helper.get_editors():
						var ctrl : Control = x.get_control()
						if gui == ctrl or gui.find_child(ctrl.name):
							x.focus.emit.call_deferred(x)
							return true
		return false
		
	func _bkt() -> bool:
		if _helper._chaser_enabled:
			return false
		var tool : Mickeytools = _helper.get_last_tool()
		if !is_instance_valid(tool):
			return false
			
		var root : Variant = tool.get_root()
		if !is_instance_valid(root):
			return false
			
		if !_helper.HANDLE_BACKWARD_FORWARD_AS_NEXT_BACK_TAB:
			for __ : int in range(0, 2):
				if root == null:
					return false
				elif root.has_method(&"backward_editor"):
					var o : Object = root.call(&"backward_editor")
					if o and o.has_signal(&"focus"):
						o.emit_signal(&"focus", o, false)
						return true
					return false
				root = root.get_parent()
		else:
			var control : TabContainer = root
			var count : int = control.get_tab_count()
			if count > 1:
				var current : int = wrapi(control.current_tab - 1, 0, count)
				if current > -1 and  current < control.get_child_count():
					var gui : Node = control.get_child(current)
					for x : Mickeytools in _helper.get_editors():
						var ctrl : Control = x.get_control()
						if gui == ctrl or gui.find_child(ctrl.name):
							x.focus.emit.call_deferred(x)
							return true
		return false
		
	func _input(event: InputEvent) -> void:
		if _helper.HANDLE_BACK_FORWARD_BUTTONS:
			if event.is_action_pressed(&"ui_script_spliter_backward"):
				if _bkt() or !_helper.USE_NATIVE_ON_NOT_TABS:
					event.alt_pressed = false
					get_viewport().set_input_as_handled()
				return
			elif event.is_action_pressed(&"ui_script_spliter_forward"):
				if _fwrd() or !_helper.USE_NATIVE_ON_NOT_TABS:
					event.alt_pressed = false
					get_viewport().set_input_as_handled()
		if _helper.is_dd_handled:
			_helper.show_dd(self)

class Mickeytools extends Object:
	signal focus(_self : Mickeytools)
	signal tool_updated()

	var _helper : Object = null

	var _root : Node = null
	var _parent : Node = null
	var _reference : Node = null
	var _control : Node = null
	var _gui : Node = null
	var _index : int = 0
	var _src : String = ""
	
	func set_src(src : String) -> void:
		_src = src
		
	func get_src() -> String:
		return _src
	
	func get_title_name() -> String:
		if is_instance_valid(_reference):
			if _reference.get_parent() != null:
				return _helper.get_item_text(_src)
		return ""
		
	func has_focus() -> bool:
		if is_instance_valid(_reference):
			if _reference.get_parent() != null:
				return _helper.get_selected_item() == _reference.get_index()
		return false

	func get_gui() -> Node:
		return _gui

	func is_floating() -> bool:
		return _root and _root.get_parent().owner is Window

	func grab_focus(should_grab_focus : bool) -> void:
		var root : TabContainer = _root
		if is_instance_valid(root) and is_instance_valid(_control):
			if _control.get_parent() == null:
				return
			var index : int = _control.get_index()
			if !_helper._chaser_enabled:
				for x : Node in root.get_children():
					if x == _control:
						if index > -1 and index < root.get_child_count():
							root.current_tab = index
						break
		
		if should_grab_focus:
			if is_instance_valid(_gui) and _gui.is_inside_tree():
				var control : Control = _gui
				if control.focus_mode != Control.FOCUS_NONE:
					control.grab_focus.call_deferred()
				elif _control.focus_mode != Control.FOCUS_NONE:
					_control.grab_focus.call_deferred()
					
				if is_instance_valid(_gui):
					var vp : Viewport = _gui.get_viewport()
					if is_instance_valid(vp):
						var wm : Window = vp.get_window()
						if wm and !wm.has_focus():
							wm.grab_focus()
			
	func get_origin() -> Node:
		return _parent

	func get_control() -> Node:
		return _control

	func get_root() -> Node:
		return _root

	func get_reference() -> Node:
		return _reference

	func is_equal(reference : Node) -> bool:
		return _reference == reference

	func __hey_listen(c : Control, out : Array[CodeEdit]) -> bool:
		if c is CodeEdit and out.size() > 0:
			out[0] = c
			return true
		for x : Node in c.get_children():
			if __hey_listen(x, out):
				return true
		return false

	func _i_like_coffe() -> void:
		focus.emit(self)
		var tab : TabContainer = _root

		var parent : Node = tab.get_parent()
		if parent and parent.has_method(&"show_splited_container"):
			parent.call(&"show_splited_container")

		update()
		_helper.update_queue()

	func _init(helper : Object, root : Node, control : Control) -> void:
		_helper = helper
		set_root(root)
		set_reference(control)

	func set_root(root : Node) -> void:
		if root != _root:
			if is_instance_valid(_root):
				if _root.has_method(&"remove_editor"):
					_root.call(&"remove_editor", self)
		_root = root
		
	func _context_update(window : Window, control : Control) -> void:
		if is_instance_valid(window) and is_instance_valid(control) and is_instance_valid(_root):
			var root : Viewport= _root.get_viewport()
			var gvp : Vector2 = control.get_global_mouse_position()
			gvp.x += (window.size.x/ 4.0)
			gvp.y = min(gvp.y, root.size.y-window.size.y + 16.0)
			gvp.x = min(gvp.x, root.size.x-window.size.x + 16.0)
			
			window.set_deferred(&"position", gvp)
			
			

	func _on_input(input : InputEvent) -> void:
		if input is InputEventMouseMotion:
			return
		
		if input is InputEventMouseButton:
			if input.pressed and input.button_index == 2:
				if _reference.get_child_count() > 1:
					var variant : Node = _reference.get_child(1)
					if variant is Window and _gui is Control:
						_context_update.call_deferred(variant, _gui)

		if _helper.can_expand_same_focus():
			var tab : TabContainer = _root

			var parent : Node = tab.get_parent()
			if parent and parent.has_method(&"show_splited_container"):
				parent.call(&"show_splited_container")
				
	func _on_symb(symbol: String, line : int, column: int, edit : CodeEdit = null) -> void:
		const BREAKERS : PackedStringArray = [" ", "\n", "\t"]
		if edit:
			var txt : String = edit.get_text_for_symbol_lookup()
			if !txt.is_empty():
				var pck : PackedStringArray = txt.split('\n')
				if column > -1 and line > -1 and pck.size() > line:
					var cline : String = pck[line]
					while column > -1:
						var _char : String = cline[column]
						if _char in BREAKERS:
							break
						if _char == "@":
							symbol = str("@", symbol)
							break
						column -= 1
		_helper.set_search_symbol(symbol)

	func set_reference(control : Node) -> void:
		if !is_instance_valid(control):
			return
		if _reference == control:
			return
		elif is_instance_valid(_reference):
			reset()
			
		if is_instance_valid(_gui) and _gui.gui_input.is_connected(_on_input):
			_gui.gui_input.disconnect(_on_input)

		_reference = control
		_control  = null
		_gui = null

		if control is ScriptEditorBase:
			_gui = control.get_base_editor()

			if _gui is CodeEdit:
				var carets : PackedInt32Array = _gui.get_sorted_carets()
				if carets.size() > 0:
					var sc : ScriptEditor = EditorInterface.get_script_editor()
					if is_instance_valid(sc):
						var line : int = _gui.get_caret_line(0)
						if line > _gui.get_line_count():
							line = _gui.get_line_count() - 1
						if line > -1:
							sc.goto_line(line)
				if !_gui.symbol_lookup.is_connected(_on_symb):
					_gui.symbol_lookup.connect(_on_symb.bind(_gui))
			_control = _gui.get_parent()
			var __parent : Node = _control.get_parent()
			if __parent is VSplitContainer:
				_index = _control.get_index()
				_control = VSplitContainer.new()
				_parent = __parent
				
				var childs : Array[Node] = __parent.get_children()
				if __parent.is_inside_tree() and _control.is_inside_tree():
					for x : Node in childs:
						x.reparent(_control)
				else:
					for x : Node in childs:
						_parent.remove_child(x)
						_control.add_child(x)
		else:
			for x : Node in control.get_children():
				if x is RichTextLabel:
					if _reference is CanvasItem:
						var canvas : VBoxContainer = VBoxContainer.new()
						canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
						canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
						_root.add_child(canvas)
						canvas.size = _root.size
						
							
						if canvas.get_child_count() < 1:
							var childs : Array[Node] = _reference.get_children()
							if _reference.is_inside_tree() and canvas.is_inside_tree():
								for n : Node in childs:
									n.reparent(canvas)
							else:
								for n : Node in childs:
									_reference.remove_child(n)
									canvas.add_child(n)
								
						x.size = canvas.size
						_gui = canvas
						_control = canvas
						_helper.search_by_symbol(control)
					else:
						_gui = x
						_control = x
					break

		if _control == null:
			_gui = control
			if control.get_child_count() > 0:
				_gui = control.get_child(0)
			_control = _gui

		var parent : Node = _control.get_parent()
		if null != parent:
			_parent = parent

			
		if parent != _root:
			if parent != null:
				if !parent.is_inside_tree() or !_root.is_inside_tree():
					parent.remove_child(_control)
					_root.add_child(_control)
				else:
					_control.reparent(_root)
			else:
				_root.add_child(_control)
		if _gui:
			var gui : Control = _gui
			
			if gui.focus_mode != Control.FOCUS_NONE:
				if !gui.gui_input.is_connected(_on_input):
					gui.gui_input.connect(_on_input)
					
			if gui is VBoxContainer:
				gui = gui.get_child(0)
			if !gui.focus_entered.is_connected(_i_like_coffe):
				gui.focus_entered.connect(_i_like_coffe)
				if !gui.is_node_ready():
					await gui.ready
				if is_instance_valid(gui):
					focus.emit(self)
		tool_updated.emit()

	func update() -> void:
		if is_instance_valid(_control) and is_instance_valid(_reference):
			var root : TabContainer = _root
			if is_instance_valid(root):
				if _control.get_parent() == root and _reference.get_parent() != null:
					_helper.update_info.call_deferred(root, _control.get_index(), _src)

	func kill() -> void:
		for x : Node in [_gui, _reference]:
			if is_instance_valid(x) and x.is_queued_for_deletion():
				x.queue_free()

	func reset(disconnect_signals : bool = true) -> void:
		if is_instance_valid(_gui):
			if disconnect_signals and _gui.is_inside_tree():
				var gui : Control = _gui
				if gui is VBoxContainer:
					gui = gui.get_child(0)
				if gui.focus_entered.is_connected(_i_like_coffe):
					gui.focus_entered.disconnect(_i_like_coffe)
				if gui.gui_input.is_connected(_on_input):
					gui.gui_input.disconnect(_on_input)
				if gui is CodeEdit:
					if gui.symbol_lookup.is_connected(_on_symb):
						gui.symbol_lookup.disconnect(_on_symb)
			_gui.modulate = Color.WHITE
			
			if _gui is VBoxContainer:
				if _gui.is_inside_tree() and _reference.is_inside_tree():
					for x : Node in _gui.get_children():
						x.reparent(_reference)
				else:
					var childs : Array[Node] = _gui.get_children()
					for x : Node in childs:
						_gui.remove_child(x)
						_reference.add_child(x)
				if _gui != _control:
					_gui.queue_free()
					_gui = null
				_control.queue_free()
				_control = null

		if is_instance_valid(_control):
			if is_instance_valid(_parent):
				var parent : Node = _control.get_parent()
				if parent != _parent:
					if _control is VSplitContainer:
						if !_control.is_inside_tree() or !_parent.is_inside_tree():
							var childs : Array[Node] = _control.get_children()		
							for c : Node in childs:
								_control.remove_child(c)
								_parent.add_child(c)
						else:	
							for c : Node in _control.get_children():
								c.reparent(_parent)
						_control.queue_free()
					else:
						_helper.control_reparent.call_deferred(_index, _control, parent, _parent)
		_gui = null
		_parent = null
		_control = null
		_reference = null
		_index = 0
		
		if is_instance_valid(_helper) and !_helper.is_queued_for_deletion():
			if _helper.add_last_script_used.is_valid():
				_helper.add_last_script_used(_src)

func control_reparent(_index : int, _control : Object, parent : Object, _parent : Object) -> void:
	if !is_instance_valid(_control):
		return
		
	if !is_instance_valid(_parent):
		return
	
	if _parent != _control.get_parent():
		if is_instance_valid(parent):
			if _control.is_inside_tree() and _parent.is_inside_tree():
				_control.reparent(_parent)
			else:
				parent.remove_child(_control)
				_parent.add_child(_control)
		else:
			_parent.add_child(_control)
		if _parent.is_inside_tree():
			if _index > -1 and _index < _parent.get_child_count():
				_parent.move_child(_control, _index)

class ReTweener extends RefCounted:
	var _tween : Tween = null
	var _ref : Control = null
	var color : Color = Color.MEDIUM_SLATE_BLUE

	func create_tween(control : Control) -> void:
		if !is_instance_valid(control) or control.is_queued_for_deletion() or !control.is_inside_tree():
			return

		if _ref == control:
			return
		clear()
		_tween = control.get_tree().create_tween()
		_ref = control
		_tween.tween_method(_callback, color, Color.WHITE, 0.35)

	func _callback(c : Color) -> void:
		if is_instance_valid(_ref) and _ref.is_inside_tree():
			_ref.modulate = c
			return
		clear()

	func secure_clear(ref : Object) -> void:
		if !is_instance_valid(_ref) or _ref == ref:
			clear()

	func clear() -> void:
		if _tween:
			if _tween.is_valid():
				_tween.kill()
			_tween = null
			if is_instance_valid(_ref):
				_ref.modulate = Color.WHITE

func _set_focus(tool : Mickeytools, txt : String = "", items : PackedStringArray = [], refresh_history : bool = true) -> void:
	if !is_instance_valid(tool):
		return
	
	_last_tool = tool
	if !_chaser_enabled:
		var ctrl : Variant = tool.get_control()
		if is_instance_valid(ctrl) and ctrl.is_inside_tree():
			var root : Control = tool.get_root()
			if root is TabContainer and ctrl.get_parent() == root:
				var indx : int = ctrl.get_index()
				if root.current_tab != indx:
					root.current_tab = indx
				if refresh_history:
					var current : Node = root
					for __ : int in range(0, 2):
						if current == null:
							break
						elif current.has_method(&"add_editor"):
							current.call(&"add_editor", tool, HANDLE_BACK_FORWARD_BUFFER)
							break
						current = current.get_parent()
	
	var ref : Node = _last_tool.get_reference()
	if ref.get_parent() == null:
		return

	var index : int = ref.get_index()
	if index < 0:
		return
		
	for x : Node in _editor.get_children():
		if x == ref:
			if index > -1 and is_instance_valid(_item_list):
				if _item_list.item_count > index:
					_item_list.item_selected.emit(index)
			break

	if _SPLIT_USE_HIGHLIGHT_SELECTED and _code_editors.size() > 1:
		var control : Node = _last_tool.get_gui()
		if is_instance_valid(control) and control.is_inside_tree():
			if _tweener == null:
				_tweener = ReTweener.new()
			_tweener.color = _SPLIT_HIGHLIGHT_COLOR
			_tweener.create_tween(control)
	
	var gui : Node = _last_tool.get_gui()
	if is_instance_valid(gui) and should_grab_focus():
		if !_MINIMAP_4_UNFOCUS_WINDOW and _OUT_FOCUS_COLORED:
			for x : Mickeytools in _code_editors:
				if is_instance_valid(x):
					var _gui : Variant = x.get_gui()
					if is_instance_valid(_gui) and _gui is CodeEdit:
						_gui.modulate = _UNFOCUS_COLOR
						_gui.minimap_draw = false
					
			if gui is CodeEdit:
				gui.modulate = Color.WHITE
				gui.minimap_draw = true
		
		elif !_MINIMAP_4_UNFOCUS_WINDOW:
			for x : Mickeytools in _code_editors:
				if is_instance_valid(x):
					var _gui : Variant = x.get_gui()
					if is_instance_valid(_gui) and _gui is CodeEdit:
						_gui.minimap_draw = false
			if gui is CodeEdit:
				gui.minimap_draw = true
		
		elif _OUT_FOCUS_COLORED:
			for x : Mickeytools in _code_editors:
				if is_instance_valid(x):
					var _gui : Variant = x.get_gui()
					if is_instance_valid(gui) and gui is CodeEdit:
						_gui.modulate = _UNFOCUS_COLOR
			if gui is CodeEdit:
				gui.modulate = Color.WHITE
		
		var vp : Viewport = gui.get_viewport()
		if is_instance_valid(vp):
			var wm : Window = vp.get_window()
			if wm and !wm.has_focus():
				wm.grab_focus()
		if is_instance_valid(gui) and !gui.has_focus():
			if gui is VBoxContainer:
				gui = gui.get_child(0)
			gui.grab_focus.call_deferred()
	
	var item_list : ItemList = _item_list
	if is_instance_valid(item_list):
		_update_path()
		
		if txt.length() > 0:
			for x : int in range(item_list.item_count - 1, -1, -1):
				var _txt : String = item_list.get_item_text(x)
				if _txt.is_empty() or _txt.begins_with("@"):
					_txt = item_list.get_item_tooltip(x).get_file()
				if !(_txt in items):
					item_list.remove_item(x)
			item_list.get_parent().get_child(0).set(&"text", txt)
			item_list.queue_redraw()
		
	set_deferred(&"_focus_queue", false)
	
func _update_path() -> void:
	if _item_list.item_count == _editor.get_child_count():
		for x : Mickeytools in _code_editors:
			var ref : Control = x.get_reference()
			if is_instance_valid(ref):
				var index : int = ref.get_index()
				if index > -1 and _item_list.item_count > index:
					x.set_src(_item_list.get_item_tooltip(index))
		
func _on_focus(tool : Mickeytools, refresh_history : bool = true) -> void:
	if _focus_queue:
		return
	_focus_queue = true
	
	var filesearch : Object = _item_list.get_parent().get_child(0)
	if filesearch is LineEdit:
		var txt : String = filesearch.text
		if !txt.is_empty():
			var items : PackedStringArray = []
			for x : int in _item_list.item_count:
				items.append(_item_list.get_item_text(x))
			filesearch.set(&"text", "")
			_set_focus.call_deferred(tool, txt, items, refresh_history)
			return
	_set_focus(tool, "", [], refresh_history)

func _out_it(node : Node, with_signals : bool = false) -> void:
	var has_tween : bool = is_instance_valid(_tweener)
	if has_tween and _code_editors.size() == 0:
		_tweener.clear()
		
	for x : int in range(_code_editors.size() - 1, -1 , -1):
		var tool : Mickeytools = _code_editors[x]
		if is_instance_valid(tool):
			if tool.is_equal(node):
				if has_tween:
					_tweener.secure_clear(tool.get_control())
				tool.reset(with_signals)
				tool.free()
			else:
				continue
		_code_editors.remove_at(x)

func _grab_focus_by_tab(tb : int) -> void:
	if tb > -1 and tb < _editor.get_child_count():
		var ctrl : Control = _editor.get_child(tb)
		for pop : Window in _pop_scripts:
			var control : Control = pop.get_base_control()
			for m : Mickeytools in _code_editors:
				var gui : Control = m.get_gui()
				if m.get_reference() == ctrl and (control == gui or gui.get_parent()):
					m.focus.emit(m)

func _on_tab_change(tb : int = 0) -> void:
	if !_chaser_enabled:
		_grab_focus_by_tab(tb)
		
	process_update_queue(tb)

func _setup(editor : TabContainer, setup : bool) -> void:	
	const INIT_2 : Array[StringName] = [&"connect", &"disconnect"]
	const INIT_3 : Array[Array] = [[&"tab_changed", &"_on_tab_change"],[&"child_entered_tree", &"_on_it"], [&"child_exiting_tree", &"_out_it"]]
	var _2 : StringName = INIT_2[int(!setup)]
	for _3 : Array in INIT_3:
		var _0 : StringName = _3[0]
		if editor.has_signal(_0):
			var _1 : Callable = Callable.create(self, _3[1])
			if editor.is_connected(_0, _1) != setup:
				editor.call(_2, _0, _1)
			
	if setup:
		if !FileAccess.file_exists("res://addons/_Godot-IDE_/plugins/script_spliter/io/backward_key_button.tres"):
			if DirAccess.dir_exists_absolute("res://addons/_Godot-IDE_/plugins/script_spliter/io"):
				var input : InputEventKey = InputEventKey.new()
				input.keycode = KEY_LEFT
				input.alt_pressed = true
				input.pressed = true
				ResourceSaver.save(input, "res://addons/_Godot-IDE_/plugins/script_spliter/io/backward_key_button.tres")
				input = null
		if !FileAccess.file_exists("res://addons/_Godot-IDE_/plugins/script_spliter/io/forward_key_button.tres"):
				if DirAccess.dir_exists_absolute("res://addons/_Godot-IDE_/plugins/script_spliter/io"):
					var input : InputEventKey = InputEventKey.new()
					input.keycode = KEY_RIGHT
					input.alt_pressed = true
					input.pressed = true
					ResourceSaver.save(input, "res://addons/_Godot-IDE_/plugins/script_spliter/io/forward_key_button.tres")
					input = null
		if !FileAccess.file_exists("res://addons/_Godot-IDE_/plugins/script_spliter/io/backward_mouse_button.tres"):
				if DirAccess.dir_exists_absolute("res://addons/_Godot-IDE_/plugins/script_spliter/io"):
					var input : InputEventMouseButton = InputEventMouseButton.new()
					input.button_index = MOUSE_BUTTON_XBUTTON1
					input.pressed = true
					ResourceSaver.save(input, "res://addons/_Godot-IDE_/plugins/script_spliter/io/backward_mouse_button.tres")
					input = null
		if !FileAccess.file_exists("res://addons/_Godot-IDE_/plugins/script_spliter/io/forward_mouse_button.tres"):
				if DirAccess.dir_exists_absolute("res://addons/_Godot-IDE_/plugins/script_spliter/io"):
					var input : InputEventMouseButton = InputEventMouseButton.new()
					input.button_index = MOUSE_BUTTON_XBUTTON2
					input.pressed = true
					ResourceSaver.save(input, "res://addons/_Godot-IDE_/plugins/script_spliter/io/forward_mouse_button.tres")
					input = null
		
		if !InputMap.has_action(&"ui_script_spliter_forward"):
			InputMap.add_action(&"ui_script_spliter_forward")
		else:
			InputMap.action_erase_events(&"ui_script_spliter_forward")
		
		if FileAccess.file_exists(_HANDLE_FORWARD_KEY_PATH):
			var key_0 : InputEventKey = ResourceLoader.load(_HANDLE_FORWARD_KEY_PATH)
			if key_0 is InputEvent:
				InputMap.action_add_event(&"ui_script_spliter_forward", key_0)
			else:
				printerr("Not type InputEvent: ", key_0)
		#else:
			#printerr("Not exist file ", _HANDLE_FORWARD_KEY_PATH)
		
		if FileAccess.file_exists(_HANDLE_FORWARD_MOUSE_BUTTON_PATH):
			var key_1 : Variant = ResourceLoader.load(_HANDLE_FORWARD_MOUSE_BUTTON_PATH)
			if key_1 is InputEvent:
				InputMap.action_add_event(&"ui_script_spliter_forward", key_1)
			else:
				printerr("Not type InputEvent: ", key_1)
		#else:
			#printerr("Not exist file ", _HANDLE_FORWARD_MOUSE_BUTTON_PATH)
		
		if !InputMap.has_action(&"ui_script_spliter_backward"):
			InputMap.add_action(&"ui_script_spliter_backward")
		else:
			InputMap.action_erase_events(&"ui_script_spliter_backward")
			
		if FileAccess.file_exists(_HANDLE_BACKWARD_KEY_PATH):
			var key_0 : Variant = ResourceLoader.load(_HANDLE_BACKWARD_KEY_PATH)
			if key_0 is InputEvent:
				InputMap.action_add_event(&"ui_script_spliter_backward", key_0)
			else:
				printerr("Not type InputEvent: ", key_0)
		#else:
			#printerr("Not exist file ", _HANDLE_BACKWARD_KEY_PATH)
		
		if FileAccess.file_exists(_HANDLE_BACKWARD_MOUSE_BUTTON_PATH):
			var key_1 : InputEventMouseButton = ResourceLoader.load(_HANDLE_BACKWARD_MOUSE_BUTTON_PATH)
			if key_1 is InputEvent:
				InputMap.action_add_event(&"ui_script_spliter_backward", key_1)
			else:
				printerr("Not type InputEvent: ", key_1)
		#else:
			#printerr("Not exist file ", _HANDLE_BACKWARD_MOUSE_BUTTON_PATH)

func _on_sub_change(__ : int, tab : TabContainer) -> void:
	if _chaser_enabled:
		return
	var _tab : int = tab.current_tab
	if _tab > -1 and _tab < tab.get_child_count():
		var control : Control = tab.get_child(_tab)
			
		for x : Mickeytools in _code_editors:
			if is_instance_valid(x):
				var ctrl : Variant = x.get_control()
				if is_instance_valid(ctrl):
					if ctrl == control:
						x.focus.emit(x)
						return
			
func _on_tab_rmb(itab : int, tab : TabContainer) -> void:
	if tab.get_child_count() > itab and itab > -1:
		if is_instance_valid(_item_list):
			var ref : Node = tab.get_child(itab)
			for x : Mickeytools in _code_editors:
				if x.get_control() == ref:
					for e : Node in _editor.get_children():
						if e == x.get_reference() and e.get_parent() != null:
							var i : int = e.get_index()
							if i > -1 and i < _item_list.item_count:
								_item_list.item_clicked.emit(i, _item_list.get_local_mouse_position(), MOUSE_BUTTON_RIGHT)
							return
					break

func _on_close(itab : int, tab : TabContainer) -> void:
	if tab.get_child_count() > itab and itab > -1:
		if is_instance_valid(_item_list):
			var ref : Node = tab.get_child(itab)
			for x : Mickeytools in _code_editors:
				if x.get_control() == ref:
					for e : Node in _editor.get_children():
						if e == x.get_reference():
							remove_tool(x)
							var i : int = e.get_index()
							if i > -1 and i < _item_list.item_count:
								_item_list.item_clicked.emit(i, _item_list.get_local_mouse_position(), MOUSE_BUTTON_MIDDLE)
							return
					break

func _on_enter(n : Node, tab : TabContainer) -> void:
	var root : Node = n.get_parent()
	for x : Mickeytools in _code_editors:
		if x.get_root() == root:
			x.update.call_deferred()
			break
	var _v : bool = tab.get_child_count() > 0
	if tab.visible != _v:
		tab.visible = _v

func _on_exit(n : Node, tab : TabContainer) -> void:
	var _v : bool = tab.get_child_count() > 1 or (tab.get_child_count() > 0 and tab.get_child(0) != n)
	if tab.visible != _v:
		tab.visible = _v
	if !is_queued_for_deletion():
		process_update_queue()

func _get_root() -> Control:
	var margin : Root = Root.new(self)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var texture : TextureRect = TextureRect.new()
	texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	texture.texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/assets/github_CodeNameTwister.png")
	texture.self_modulate.a = 0.25

	margin.add_child(texture)
	return margin

func _get_container() -> Control:
	var editor : EditorContainer = EditorContainer.new()
	editor.separator_line_size = 4.0
	editor.drag_button_size = 12.0
	editor.behaviour_can_expand_focus_same_container = true
	return editor

func _out_drag(e : Control) -> void:
	var current : Control = null
	
	is_dd_handled = false
	_last_dd_root = null
	if is_instance_valid(_ddo):
		_ddo.visible = false
		var np : Node = _ddo.get_parent()
		if is_instance_valid(np):
			current = np
			np.remove_child(_ddo)
	if is_instance_valid(current):
		if current.get_global_rect().has_point(current.get_global_mouse_position()):
			if e is TabBar:
				var ct : int = e.current_tab
				var p : Node = e.get_parent()
				if p and ct < p.get_child_count():
					var gui : Node = p.get_child(ct)
					
					var root : Node = null
					for x : Mickeytools in _code_editors:
						var __root : Node = x.get_root()
						if is_instance_valid(_root) and __root.get_parent() == current:
							root = __root
							break
					
					if is_instance_valid(root):
						for x : Mickeytools in _code_editors:
							if x.get_control() == gui or x.get_gui() == gui:
								if root != x.get_root():
									queue_swap(x, root)
									return
			elif e is ItemList:
				var it : PackedInt32Array = e.get_selected_items()
				if it.size() > 0:
					var src : String = e.get_item_tooltip(it[0])
					var root : Node = null
					for x : Mickeytools in _code_editors:
						var __root : Node = x.get_root()
						if is_instance_valid(_root) and __root.get_parent() == current:
							root = __root
							break
					
					if is_instance_valid(root):
						for x : Mickeytools in _code_editors:
							if x.get_src() == src:
								if root != x.get_root():
									queue_swap(x, root)
									return
					
								
func queue_swap(x : Mickeytools, root : Node) -> void:
	if is_instance_valid(x):
		var ref : Node = x.get_reference()
		if is_instance_valid(ref) and is_instance_valid(root):
			remove_tool(x)
			create_code_editor.call_deferred(root, ref)
			_new_tools.call_deferred(_code_editors.duplicate(false))
			
	
func _new_tools(tools : Array[Mickeytools]) -> void:
	var tool : Mickeytools = null
	for x in _code_editors:
		if x in tools:
			continue
		tool = x
		break
	if tool:
		tool.focus.emit.call_deferred(tool)
	await Engine.get_main_loop().process_frame
	if is_instance_valid(tool):
		tool.update()
	
func _on_drag(e : Control) -> void:
	is_dd_handled = is_instance_valid(e)
	if !is_dd_handled:
		_last_dd_root = null
		if is_instance_valid(_ddo):
			_ddo.visible = false
			var np : Node = _ddo.get_parent()
			if np:
				np.remove_child(_ddo)

func _get_container_edit() -> Control:
	var rtab : DD = DD.new()

	rtab.get_tab_bar().tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS

	rtab.drag_to_rearrange_enabled = true


	rtab.child_entered_tree.connect(_on_enter.bind(rtab))
	rtab.child_exiting_tree.connect(_on_exit.bind(rtab))

	rtab.visible = false

	var rcall : Callable = _on_sub_change.bind(rtab)

	rtab.tab_changed.connect(rcall)
	rtab.tab_clicked.connect(rcall)
	rtab.get_tab_bar().tab_close_pressed.connect(_on_close.bind(rtab))
	rtab.get_tab_bar().select_with_rmb = true
	rtab.get_tab_bar().tab_rmb_clicked.connect(_on_tab_rmb.bind(rtab))
	
	rtab.on_dragging.connect(_on_drag)
	rtab.out_dragging.connect(_out_drag)

	rtab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtab.size_flags_vertical = Control.SIZE_EXPAND_FILL

	return rtab
			
func _create_by_last_used() -> void:
	if _lifo_src.size() > 0:
		var item_list : ItemList = _item_list
		if is_instance_valid(item_list):
			var unused : Array[Node] = []
			if _item_list.item_count == _editor.get_child_count():
				for x : Node in _main.get_children():
					if is_instance_valid(x):
						if x is TabContainer and x.get_child_count() == 0:
							unused.append(x)
						else:
							for y : Node in x.get_children():
								if y is TabContainer and y.get_child_count() == 0:
									unused.append(y)
			for u : Node in unused:
				var sc : String = get_last_script_used()
				var dirty : bool = false
				if sc.is_empty():
					continue
				
				for x : int in _item_list.item_count:
					if _item_list.get_item_tooltip(x) == sc:
						create_code_editor(u, _editor.get_child(x))
						dirty = true
						break
				if !dirty and sc.begins_with("res://") and FileAccess.file_exists(sc):
					if _SHOULD_OPEN_CLOSED_EDITOR_SCRIPT:
						var res : Variant = ResourceLoader.load(sc)
						if res is Script:
							EditorInterface.edit_script.call_deferred(res)
			
func update() -> void:
	if is_queued_for_deletion() or !_plugin.is_inside_tree():
		return
	
	_clear()
	if _editor.get_child_count() > 0:
		var root : Node = _get_editor_root()
		if null != root and _editor.current_tab > -1:
			create_code_editor(root, _editor.get_current_tab_control())
			
		_create_by_last_used()
					 
		for x : Node in _main.get_children():
			if is_instance_valid(x):
				if x is TabContainer and x.get_child_count() == 0:
					for z : Node in _editor.get_children():
						if null != create_code_editor(x, z):
							break
				else:
					for y : Node in x.get_children():
						if y is TabContainer and y.get_child_count() == 0:
							for z : Node in _editor.get_children():
								if null != create_code_editor(y, z):
									break
									
	if !is_instance_valid(_last_tool) or _last_tool.is_queued_for_deletion():
		for i : int in range(_code_editors.size() - 1, -1, -1):
			if is_instance_valid(_code_editors[i]):
				_last_tool = _code_editors[i]
				_last_tool.focus.emit.call_deferred(_last_tool)
				break
			_code_editors.remove_at(i)
			
	if _pop_scripts.size() > 0:
		for p : Window in _pop_scripts:
			if !p.visible:
				p.show()
				
		if _pop_script_placeholder:
			for x : Mickeytools in _code_editors:
				if !x.is_floating():
					var ref : Node = x.get_reference()
					if ref.get_parent() != null:
						if get_item_text(x.get_src()).begins_with(_POP_SCRIPT_PLACEHOLDER):
							continue
						_clear_placeholder()
	else:
		_clear_placeholder()	
	
func _clear_placeholder() -> void:				
	if _pop_script_placeholder:
			for x : int in range(_item_list.item_count):
				var txt : String = _item_list.get_item_text(x)
				if txt.is_empty() or txt.begins_with("@"):
					txt = _item_list.get_item_tooltip(x).get_file()
				if txt.begins_with(_POP_SCRIPT_PLACEHOLDER):
					_item_list.item_clicked.emit(x, _item_list.get_local_mouse_position(), MOUSE_BUTTON_MIDDLE)
					break
			_pop_script_placeholder = false
		
					

func is_visible_minimap_required() -> bool:
	return _MINIMAP_4_UNFOCUS_WINDOW

func get_item_text(src : String) -> String:
	var item_list : Control = _item_list
	var text : String = ""
	if !src.is_empty():
		if is_instance_valid(item_list):
			var indx : int = -1
			for x : int in item_list.item_count:
				if item_list.get_item_tooltip(x) == src:
					indx = x
					break
			if indx > -1:
				text = item_list.get_item_text(indx)
				if text.is_empty() or text.begins_with("@"):
					text = item_list.get_item_tooltip(indx).get_file()
				text = text.trim_suffix("(*)")
	return text

func get_aviable() -> Node:
	for x : Node in _main.get_children():
		if x is TabContainer and x.get_child_count() == 0:
			return x
		for y : Node in x.get_children():
			if y is TabContainer and y.get_child_count() == 0:
				return y
	return null

func is_node_valid(root : Node) -> bool:
	return is_instance_valid(root) and root.is_inside_tree()

func is_valid_code_editor(root : Node, editor : Node, fallback : bool = true) -> bool:
	if !is_node_valid(root) or !is_node_valid(editor):
		return false

	if !editor.is_node_ready():
		return false
			
	if editor.get_child_count() == 0:
		if fallback and editor.is_inside_tree():
			var index : int = editor.get_index()
			if index > -1 and _item_list.item_count > index:
				_item_list.item_selected.emit(index)
				return is_valid_code_editor(root, editor, false)
		return false
			
	return true
	

func is_valid_doc(editor : Control) -> bool:
	if !editor is ScriptEditorBase:
		for x : Node in editor.get_children():
			if x is RichTextLabel:
				return true
	return false

func add_tool(tool : Mickeytools) -> void:
	_code_editors.append(tool)
	tool_added.emit(tool)
	
func remove_tool(x : Mickeytools, with_signals : bool = true) -> void:
	x.reset(with_signals)
	_code_editors.erase(x)
	x.free() 

func create_code_editor(root : Node, editor : Node) -> Mickeytools:
	if !is_valid_code_editor(root, editor):
		return null
	
	var tool : Mickeytools = null
	
	if root.get_child_count() > 0:
		var childs : Array[Node] = root.get_children()
		for m : Mickeytools in _code_editors:
			if m.get_reference() == editor:
				var o : Node = m.get_control()
				if o in childs or m.get_gui() in childs:
					return null
	else:
		for m : Mickeytools in _code_editors:
			if m.get_reference() == editor:
				var o : Node = m.get_control()
				var __root : Control = m.get_root()
				if is_instance_valid(__root) and __root.get_child_count() > 1:
					if __root and __root.current_tab != o.get_index():
						tool = m
						break
	
	if is_valid_doc(editor):
		if editor.name.begins_with("@"):
			return
				
	if null == tool:
		for x : Mickeytools in _code_editors:
			if x.is_equal(editor):
				return null
		tool = Mickeytools.new(self, root, editor)
		tool.focus.connect(_on_focus)
		add_tool(tool)
		
		tool.focus.emit(tool)
	else:
		tool.reset()
		tool.set_root(root)
		tool.set_reference(editor)

	if _last_tool == null:
		_last_tool = tool
		tool.focus.emit(tool)
	tool.update.call_deferred()
	return tool
	
func update_queue(__ : int = 0) -> void:
	if _plugin:
		_plugin.set_process(true)
	if _main and _container:
		update_rect()
		_main.update()

#region callback
func _on_it(editor : Node) -> void:
	if is_valid_doc(editor):
		if editor.name.begins_with("@"):
			editor.queue_free()
			return
	update_queue(0)
	update()
	
func _on_container_entered() -> void:
	update_queue()

func _on_container_exit() -> void:
	for x : Mickeytools in _code_editors:
		x.reset()
	if !is_queued_for_deletion():
		process_update_queue()
#endregion

func remove_split(node : Node) -> void:
	if _code_editors.size() > 1:
		if node is CodeEdit:
			for it : int in range(_code_editors.size() - 1, -1, -1):
				var x : Mickeytools = _code_editors[it]
				if x.get_gui() == node:
					_remove_split_by_control(x.get_control())
					
					remove_tool(x)
												
					process_update_queue()
					break

func _remove_split_by_control(c : Control) -> void:
	for x : Node in _main.get_children():
		if x is TabContainer:continue
		if x.get_child_count() > 0:
			for y : Node in x.get_children():
				for z : Node in y.get_children():
					if z == c:
						_main.remove_child(x)
						return

func _get_unused_editor_control() -> Array[Node]:
	var out : Array[Node] = []
	for x : Node in _editor.get_children():
		var exist : bool = false
		for m : Mickeytools in _code_editors:
			if !is_instance_valid(m):
				_code_editors.erase(m)
				continue
			if m.is_equal(x):
				exist = true
				break
		if !exist:
			out.append(x)
	return out

func _free_editor_container(control : Control) -> bool:
	if control.get_parent() == _main:
		for x : int in range(_code_editors.size() - 1, -1 , -1):
			var c : Mickeytools = _code_editors[x]
			var cc : Variant = c.get_control()
			if is_instance_valid(cc):
				var _a : Node = cc.get_parent()
				var _b : Node = control
				if _a == _b or _a.get_parent() == _b:
					remove_tool(c)
			else:
				remove_tool(c)
		_main.remove_child(control)
		control.queue_free()
		return true
	return false

func build(editor : TabContainer, columns : int = 0, rows : int = 0) -> void:
	_setup(editor, true)
	
	var root : Node = editor.get_parent()
	if is_instance_valid(root) and !(root is Root):
		_root = root

	if is_instance_valid(_editor) and _editor != editor:
		if _editor.tree_entered.is_connected(_on_container_entered):
			_editor.tree_entered.disconnect(_on_container_entered)

		if _editor.tree_exiting.is_connected(_on_container_exit):
			_editor.tree_exiting.disconnect(_on_container_exit)

	_editor = editor

	if !_editor.tree_entered.is_connected(_on_container_entered):
		_editor.tree_entered.connect(_on_container_entered)

	if !_editor.tree_exiting.is_connected(_on_container_exit):
		_editor.tree_exiting.connect(_on_container_exit)

	if !is_instance_valid(_container):
		_container = _get_root()

	if !is_instance_valid(_main):
		_main = _get_container()

	root = _container.get_parent()

	if root != _root:
		if is_instance_valid(root):
			root.remove_child(_container)
		var index : int = _editor.get_index()
		_root.add_child(_container)
		_root.move_child(_container, index)

	root = _main.get_parent()
	if root != _container:
		if is_instance_valid(root):
			root.remove_child(_main)
		_container.add_child(_main)

	_container.size = _container.get_parent().size
	_container.anchor_left = 0.0
	_container.anchor_top = 0.0
	_container.anchor_right = 1.0
	_container.anchor_bottom = 1.0

	_main.behaviour_expand_on_focus = true
	_main.behaviour_expand_on_double_click = true


	_editor.visible = false
	_main.visible = true
	
	update_config()

	update_build(columns, rows)
	
	if (_root is Control):
		if !_root.item_rect_changed.is_connected(update_rect):
			_root.item_rect_changed.connect(update_rect)
	update_rect.call_deferred()
	
func update_rect() -> void:
	var _size : Vector2 = _container.size
	_size.x = maxf(_container.size.x, 1.0)
	_size.y = maxf(_container.size.y, 1.0)
	_main.size = _size
	for x : Node in _main.get_children():
		if x is Control:
			if x is TabContainer:
				continue
			for y : Node in x.get_children():
				if y is Control:
					y.set_deferred(&"size", x.size)
	_main.update()

func find_editor(node : Node) -> Control:
	for x : Node in _main.get_children():
		for y : Node in x.get_children():
			if y == node:
				return x
	return null

func can_remove_split(node : Node) -> bool:
	if !is_instance_valid(_main):
		return false
		
	if node == null:
		return _code_editors.size() > 1
		
	if _code_editors.size() > 1:
		if node is CodeEdit:
			var main : bool = false
			for x : Mickeytools in _code_editors:
				if x.is_floating():
					continue
				var item_list : Node = _item_list
				if item_list:
					var reference : Node = x.get_reference()
					if reference.get_parent() != null:
						if get_control_item_name(reference.get_index()).begins_with(_POP_SCRIPT_PLACEHOLDER):
							continue
				if main:
					return true
				main = true
	return false

func get_control_item_name(index : int) -> String:
	var item_list : Node = _item_list
	if item_list:
		if index > -1 and index < item_list.item_count:
			var text : String = item_list.get_item_text(index)
			if text.is_empty() or text.begins_with("@"):
				text = item_list.get_item_tooltip(index).get_file()
			return text
	return ""


func get_editor_item_text(c : int) -> String:
	var item_list : Control = _item_list
	var text : String = ""
	if c > -1:
		if is_instance_valid(item_list):
			if null != item_list and c < _editor.get_child_count() and item_list.item_count > c:
				text = item_list.get_item_text(c)
				if text.is_empty() or text.begins_with("@"):
					text = item_list.get_item_tooltip(c).get_file()
				text = text.trim_suffix("(*)")
	return text

func can_add_split(_node : Node) -> bool:
	if !is_instance_valid(_main):
		return false
			
	if _node == null:
		return _code_editors.size() < _editor.get_child_count()
			
	for o : int in _editor.get_child_count():
		if get_editor_item_text(o).begins_with(_POP_SCRIPT_PLACEHOLDER):
			continue
		var x : Node = _editor.get_child(o)
		var created : bool = false
		if x.has_method(&"get_base_editor"):
			x = x.call(&"get_base_editor")
			for m : Mickeytools in _code_editors:
				if m.get_gui() == x:
					created = true
					break
		else:
			if x.get_child_count() > 0:
				var child : Node = x.get_child(0)
				for m : Mickeytools in _code_editors:
					var gui : Node = m.get_gui()
					if gui == x or child == gui:
						created = true
						break
			else:
				for m : Mickeytools in _code_editors:
					var gui : Node = m.get_gui()
					if gui == x :
						created = true
						break
		if !created:
			return true
	return false

func add_split(control : Node) -> void:
	var unused : Array[Node] = _get_unused_editor_control()
	if unused.size() == 0:
		print("[INFO] Not aviable split!")
		return

	var current_unused : Node = control

	for x : Mickeytools in _code_editors:
		if x.is_equal(control) or x.get_gui() == control:
			current_unused = null
			break

	var root : Control = get_aviable()
	if root == null:
		var broot : Node = _main.make_split_container_item()
		root = _get_container_edit()
		broot.add_child(root)
		_main.add_child(broot)

	if null == current_unused:
		current_unused = unused[0]

	_create_by_last_used()
	if root.get_child_count() == 0:
		create_code_editor(root, current_unused)
			
	process_update_queue()
	
func get_current_columns_and_rows() -> Array[int]:
	var out : Array[int] = [0, 0]
	if is_instance_valid(_main):
		var columns : int = _main.max_columns
		var container : int = _main.get_child_count()
		if container > 0 and columns > 0:
			@warning_ignore("integer_division")
			container = int(container / columns)
		out[0] = columns
		out[1] = container
	return out
	
func update_build(columns : int, rows : int) -> void:
	for x : Node in _main.get_children():
		if x is EditorContainer:
			for y in x.get_children():
				if y.has_method(&"reset"):
					y.call(&"reset")
	_out_drag(null)
	
	current_columns = maxi(columns, 0)
	current_rows = maxi(rows, 0)

	var totals : int = maxi(current_columns * current_rows, 1)
	_main.max_columns = current_columns

	while _main.get_child_count() > totals:
		if !_free_editor_container(_main.get_child(_main.get_child_count() - 1)):
			break

	while _main.get_child_count() < totals:
		var broot : Node = _main.make_split_container_item()
		var root : Node = _get_container_edit()
		broot.add_child(root)
		_main.add_child(broot)

	var aviable : Node = get_aviable()
	if aviable:
		if _lifo_src.size() > 0:
			_create_by_last_used()
			aviable = get_aviable()
	while aviable != null:
		var unused : Array[Node] = _get_unused_editor_control()
		if unused.size() == 0:
			break
		if null == create_code_editor(aviable, unused[0]):
			break
		aviable = get_aviable()
	
	process_update_queue()
	

#region _CHASER_	
func get_current_focus_index() -> int:
	var arr : PackedInt32Array = _item_list.get_selected_items()
	if arr.size() > 0:
		return arr[0]
	return 0
	
func focus_by_index(index : int, check_is_visible : bool = true) -> int:
	if _code_editors.size() > index:
		if check_is_visible:
			while _code_editors.size() > index:
				var cd : Mickeytools  = _code_editors[index]
				if cd != _last_tool:
					var variant : Variant = cd.get_control()
					if is_instance_valid(variant):
						if variant is Control:
							var parent : Node = variant.get_parent()
							if parent is TabContainer:
								if parent.get_current_tab_control() == variant:
									_on_focus(cd)
									return index
				index += 1
		else:
			var cd : Mickeytools  = _code_editors[index]
			var variant : Variant = cd.get_control()
			if is_instance_valid(variant):
				if variant is Control:
					var parent : Node = variant.get_parent()
					if parent is TabContainer:
						if parent.get_current_tab_control() == variant:
							_on_focus(cd)
							return index
	return -1

func get_focus_config() -> Dictionary:
	return {
		"highlight_selected" : _SPLIT_USE_HIGHLIGHT_SELECTED
		,"behaviour_expand_on_focus" : _main.behaviour_expand_on_focus
		,"last_tool" : _last_tool
	}

func set_focus_config(d : Dictionary) -> void:
	_chaser_enabled = false
	_SPLIT_USE_HIGHLIGHT_SELECTED = d["highlight_selected"]
	_main.behaviour_expand_on_focus = d["behaviour_expand_on_focus"]

	var _last : Variant = d["last_tool"]
	if is_instance_valid(_last):
		if _last != _last_local_tool:
			_last.focus.emit(_last)

func enable_focus_highlight(enable : bool) -> void:
	_chaser_enabled = !enable
	_SPLIT_USE_HIGHLIGHT_SELECTED = enable
	_main.behaviour_expand_on_focus = enable
	
func should_grab_focus() -> bool:
	return !_chaser_enabled
#endregion

#region _POP_SCRIPT_
func _on_pop_input(event : InputEvent) -> void:
	(_editor.get_parent() as Control).gui_input.emit(event)

func is_pop_script(ctrl : Node) -> bool:
	for pop : Node in _pop_scripts:
		var control : Control = pop.get_base_control()
		if ctrl is CodeEdit:
			for __ : int in range(2):
				ctrl = ctrl.get_parent()
				if ctrl == null:
					return false
		for x : Node in control.get_children():
			if x == ctrl:
				return true
	return false

func _on_pop_script_close(pop : Window) -> void:
	if !is_instance_valid(pop) or pop.is_queued_for_deletion():
		return
	var container : Node = pop.get_base_control()
	for x : Mickeytools in _code_editors:
		var gui : Node = x.get_gui()
		var control : Node = x.get_control()
		if control.get_parent() == container or gui.get_parent() == container:
			remove_tool(x, true)
			
			if container.get_child_count() < 1:
				_pop_scripts.erase(pop)
				if !pop.is_queued_for_deletion():
					pop.queue_free()
			update_queue()
			return
	push_warning("Can not free popscript!")

func make_pop_script(control : Node) -> Window:
	if control is CodeEdit:
		for __ : int in range(2):
			control = control.get_parent()
			if control == null:
				return null
	var m : Mickeytools = null
	for x : Mickeytools in _code_editors:
		if x.get_control() == control:
			m = x
			break
			
	if m == null:
		return null
	
	var node : Node = FLYING_SCRIPT.instantiate()
	node.set_base_control(_get_container_edit())
		
	var editor : Control = m.get_reference()
	remove_tool(m)
	
	_plugin.add_child(node)
		
	var tool : Mickeytools = create_code_editor(node.get_base_control(), editor)
	if null == tool:
		if !node.is_inside_tree():
			node.free()
		else:
			node.queue_free()
		return null
		
	node.proxy = editor
	node.controller = tool
	
	node.on_close.connect(_on_pop_script_close)
	
	_pop_scripts.append(node)
	
	_check_pop()
	return node
	
func _check_pop() -> void:
	if !_pop_script_placeholder:
		var placeholder : bool = true
		var total_floatings : int = 0
		for x : Mickeytools in _code_editors:
			if !x.is_floating():
				placeholder = false
				break
			total_floatings += 1
		if placeholder and _editor.get_child_count() <= total_floatings:
			_pop_script_placeholder = true
			var PLACEHOLDER : String = str("res://addons/_Godot-IDE_/plugins/script_spliter/context/",_POP_SCRIPT_PLACEHOLDER, ".gd")
			if FileAccess.file_exists(PLACEHOLDER):
				var script : Script = ResourceLoader.load(PLACEHOLDER)
				if null != script:
					_editor.child_entered_tree.connect(_on_placeholder, CONNECT_ONE_SHOT)
					EditorInterface.edit_script(script)

func _placeholder_queue() -> void:
	for x : int in _editor.get_child_count():
		var txt : String = get_editor_item_text(x)
		if txt.begins_with(_POP_SCRIPT_PLACEHOLDER):
			var n : Node = _editor.get_child(x)
			var c : Control = n.call(&"get_base_editor")
			if c != null:
				if c is CodeEdit:
					c.editable = false
					c.minimap_draw = false
	
func _on_placeholder(__ : Node) -> void:
	_placeholder_queue.call_deferred()
#endregion
	
func process_update_queue(__ : int = 0) -> void:
	update_queue(__)
	update_queue.call_deferred(__)

func get_selected_item() -> int:
	var item_list : ItemList = _item_list
	if is_instance_valid(item_list):
		for x : int in item_list.item_count:
			if item_list.is_selected(x):
				return x
	return -1

func can_expand_same_focus() -> bool:
	return _BEHAVIOUR_CAN_EXPAND_SAME_ON_FOCUS

#region _8_
func swap(caller : Object) -> void:
	if !_SWAP_BY_BUTTON:
		return
		
	if !is_instance_valid(_main) or _main.get_child_count() == 0:
		return
	
	var separators : Array = _main.get_separators()
	if separators.size() == 0:
		return
		
	var index : int = 0
	var linesep : Object = null
	for x : Object in separators:
		if x == caller:
			linesep =x
			break
		index += 1
		
	if linesep:
		if linesep.is_vertical:
			var atotal : int = 1
			var btotal : int = 1
			var nodes : Array[Node] = []
			
			for x : int in range(index + 1, separators.size(), 1):
				var clinesep : Object = separators[x]
				if clinesep.is_vertical:
					break
				atotal += 1
			for x : int in range(index - 1, -1, -1):
				var clinesep : Object = separators[x]
				if clinesep.is_vertical:
					break
				btotal += 1
			
			var cindex : int = index
			while atotal > 0:
				cindex += 1
				atotal -= 1
				if cindex < _main.get_child_count():
					nodes.append(_main.get_child(cindex))
					continue
				break
				
			for x : Node in nodes:
				cindex = btotal
				while cindex > 0:
					cindex -= 1
					_main.move_child(x, x.get_index() - 1)
		else:
			index += 1
			if _main.get_child_count() > index:
				var child : Node = _main.get_child(index - 1)
				_main.move_child(child, index)
#endregion
#region _7_
var _search_symbol : String = ""

func set_search_symbol(symbol: String) -> void:
	_search_symbol = symbol
	
func reset_symbol() -> void:
	_search_symbol = ""
	
func search_by_symbol(reference : Node) -> void:
	if _search_symbol.is_empty():
		return
	var symbol : String = _search_symbol
	var class_nm : StringName = reference.name.strip_edges()
	
	reset_symbol()
	
	if symbol == class_nm:
		return
	
	if class_nm.is_empty():
		return
		
	if class_nm.begins_with("_"):
		if class_nm in GLOBALS:
			return
			
	if ClassDB.class_exists(class_nm):
		var prefx : String = ""
		if class_nm == "GraphNode":
			prefx = "class_theme_item"
		if symbol.begins_with("@"):
			prefx = "class_annotation"
		elif ClassDB.class_has_signal(class_nm, symbol):
			prefx = "class_signal"
		elif ClassDB.class_has_enum(class_nm, symbol, true):
			prefx = "class_constant"
		elif ClassDB.class_has_integer_constant(class_nm, symbol):
			prefx = "class_constant"
		else:
			var list : Array[Dictionary] = ClassDB.class_get_property_list(class_nm, true)
			for x : Dictionary in list:
				if x.name == symbol:
					prefx = "class_property"
					break
			if prefx.is_empty():
				list = ClassDB.class_get_method_list(class_nm, true)
				for x : Dictionary in list:
					if x.name == symbol:
						prefx = "class_method"
						break
		if !prefx.is_empty():
			var path : String = "{0}:{1}:{2}".format([prefx, class_nm, symbol])
			EditorInterface.get_script_editor().goto_help(path)
#endregion

#region 0.3.6
var last_hover_tab : TabBar = null

func get_hover_tab(tabs : Array[TabBar] = []) -> TabBar:
	var nodes : Array[TabBar] = tabs
	if tabs.size() == 0:
		nodes = get_tabs()
	for n : TabBar in nodes:
		if n.get_global_rect().has_point(n.get_global_mouse_position()):
			return n
	return null
	
func has_other_tabs() -> bool:
	var tabs : Array[TabBar] = get_tabs()
	var hover : TabBar = get_hover_tab(tabs)
	last_hover_tab = hover
	if is_instance_valid(hover):
		var container : TabContainer = hover.get_parent()
		if container.get_tab_count() > 1:
			var index :int = container.current_tab
			if index > 0 and index < container.get_tab_count() - 1:
				return true
	return false
	
func has_right_tabs() -> bool:
	var tabs : Array[TabBar] = get_tabs()
	var hover : TabBar = get_hover_tab(tabs)
	last_hover_tab = hover
	if is_instance_valid(hover):
		var container : TabContainer = hover.get_parent()
		var index : int = container.current_tab
		return index > -1 and index < container.get_tab_count() - 1
	return false
	
func has_left_tabs() -> bool:
	var tabs : Array[TabBar] = get_tabs()
	var hover : TabBar = get_hover_tab(tabs)
	last_hover_tab = hover
	if is_instance_valid(hover):
		var container : TabContainer = hover.get_parent()
		var index : int = container.current_tab
		return index > 0
	return false
	
func get_tabs() -> Array[TabBar]:
	var tabs : Array[TabBar] = []
	var nodes : Array[Node] = _plugin.get_tree().get_nodes_in_group(&"__SPLITER_TAB__")
	for x : Node in nodes:
		if x is TabBar:
			tabs.append(x)
	return tabs
	
func close_right_tabs() -> void:
	var hover : TabBar = last_hover_tab
	if is_instance_valid(hover):
		var container : TabContainer = hover.get_parent()
		var index : int = container.current_tab
		if index > -1 and container.get_child_count() > index:
			var childs : Array[Node] = container.get_children()
			var out : Array[Node] = []
			var _tools : Array[Mickeytools] = []
			for c : int in range(index + 1, childs.size(), 1):
				out.append(childs[c])
			for x : Mickeytools in _code_editors:
				if x.get_control() in out:
					_tools.append(x)
			for t : Mickeytools in _tools:
				t.reset(true)
				
func close_left_tabs() -> void:
	var hover : TabBar = last_hover_tab
	if is_instance_valid(hover):
		var container : TabContainer = hover.get_parent()
		var index : int = container.current_tab
		if index > -1 and container.get_child_count() > index:
			var childs : Array[Node] = container.get_children()
			var out : Array[Node] = []
			var _tools : Array[Mickeytools] = []
			for c : int in range(index - 1, -1, -1):
				out.append(childs[c])
			for x : Mickeytools in _code_editors:
				if x.get_control() in out:
					_tools.append(x)
			for t : Mickeytools in _tools:
				t.reset(true)
				
func close_other_tabs() -> void:
	var hover : TabBar = last_hover_tab
	if is_instance_valid(hover):
		var container : TabContainer = hover.get_parent()
		var index : int = container.current_tab
		if index > -1 and container.get_child_count() > index:
			var out : Array[Node] = container.get_children()
			var _tools : Array[Mickeytools] = []
			out.erase(container.get_child(index))
			for x : Mickeytools in _code_editors:
				if x.get_control() in out:
					_tools.append(x)
			for t : Mickeytools in _tools:
				t.reset(true)
#endregion
