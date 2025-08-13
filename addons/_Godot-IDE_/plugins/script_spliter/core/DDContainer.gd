@tool
extends VBoxContainer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@warning_ignore("unused_signal")
signal on_dragging(e : Control)
signal out_dragging(e : Control)

const DDTAB : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/DDTAB.gd")
const CONTAINER = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/ui/taby/container.tscn")


var _buffer_editors : Array[Object] = []

var _tab_container : TabContainer = null

#static var _tab_focus : StyleBox = null
#static var _tab_disabled : StyleBox = null
#static var _tab_selected : StyleBox = null
#static var _tab_hovered : StyleBox = null
#static var _tab_unselected : StyleBox = null

func set_update_tab_extension(e : bool) -> void:
	if is_instance_valid(tab):
		tab.set_enable(e)

func _config_tab(_tab : StyleBox) -> void:
	if _tab is StyleBoxFlat:
		_tab.skew.x = 0.5
		_tab.border_color = Color.AQUA
		#_tab.border_width_left = 0.0
		#_tab.border_width_right = 0.0
		#_tab.border_width_top = 0.0
		#_tab.border_width_bottom = 0.1
var tab : Control = null

func _ready() -> void:
	if !is_instance_valid(_tab_container):
		_init()
	set(&"theme_override_constants/separation", -15)
		
func _init() -> void:
	_tab_container = TabContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var tb : TabBar = _tab_container.get_tab_bar()
	if tb:
		tb.auto_translate_mode = _tab_container.auto_translate_mode
	
	tab = CONTAINER.instantiate()
	tab.set_ref(_tab_container.get_tab_bar())
	
	add_child(tab)
	add_child(_tab_container)
	tab.z_index = 2
	
	_tab_container.child_entered_tree.connect(_on_child)
	_tab_container.child_exiting_tree.connect(_out_child)

func get_tab_container() -> TabContainer:
	return _tab_container

func is_empty() -> bool:
	return _tab_container.get_child_count() == 0
	
func get_container_children() -> Array[Node]:
	return _tab_container.get_children()
	
func get_container() -> TabContainer:
	return _tab_container
	
	#var root : Control = EditorInterface.get_base_control()
	#if root:
		#if _tab_focus == null:
			#_tab_focus = root.get_theme_stylebox(&"panel", &"tab_focus")
			#if _tab_focus is StyleBoxFlat:
				#_tab_focus = _tab_focus.duplicate()
				#_config_tab(_tab_focus)
		#if _tab_disabled == null:
			#_tab_disabled = root.get_theme_stylebox(&"panel", &"tab_disabled")
			#if _tab_disabled is StyleBoxFlat:
				#_tab_disabled = _tab_disabled.duplicate()
				#_config_tab(_tab_disabled)
		#if _tab_selected == null:
			#_tab_selected = root.get_theme_stylebox(&"panel", &"tab_selected")
			#if _tab_selected is StyleBoxFlat:
				#_tab_selected = _tab_selected.duplicate()
				#_config_tab(_tab_selected)
		#if _tab_hovered == null:
			#_tab_hovered = root.get_theme_stylebox(&"panel", &"tab_hovered")
			#if _tab_hovered is StyleBoxFlat:
				#_tab_hovered = _tab_hovered.duplicate()
				#_config_tab(_tab_hovered)
		#if _tab_unselected == null:
			#_tab_unselected = root.get_theme_stylebox(&"panel", &"tab_unselected")
			#if _tab_unselected is StyleBoxFlat:
				#_tab_unselected = _tab_unselected.duplicate()
				#_config_tab(_tab_unselected)
		#set(&"theme_override_styles/tab_focus", _tab_focus)
		#set(&"theme_override_styles/tab_disabled", _tab_disabled)
		#set(&"theme_override_styles/tab_selected", _tab_selected)
		#set(&"theme_override_styles/tab_hovered", _tab_hovered)
		#set(&"theme_override_styles/tab_unselected", _tab_unselected)

func reset() -> void:
	for x : Node in get_children(true):
		if x is TabBar:
			if x.get_script() == DDTAB:
				x.reset()

func clear_editors() -> void:
	_buffer_editors.clear()

func add_editor(o : Object, limit : int) -> Object:
	if is_instance_valid(o):
		if limit > 0:
			var i : int = _buffer_editors.find(o)
			if i > -1:
				_buffer_editors.remove_at(i)
			_buffer_editors.append(o)
		if limit > -1:
			while _buffer_editors.size() > limit:
				_buffer_editors.remove_at(0)
	return o
	
func remove_editor(o : Object) -> void:
	_buffer_editors.erase(o)
	
func backward_editor() -> Object:
	if _buffer_editors.size() > 1:
		var o : Variant = _buffer_editors.pop_back()
		while !is_instance_valid(o) and _buffer_editors.size() > 0:
			o = _buffer_editors.pop_back()
		if is_instance_valid(o):
			_buffer_editors.push_front(o)
			return o
	return null
	
func forward_editor() -> Object:
	if _buffer_editors.size() > 1:
		var o : Variant = _buffer_editors.pop_front()
		while !is_instance_valid(o) and _buffer_editors.size() > 0:
			o = _buffer_editors.pop_front()
		if is_instance_valid(o):
			_buffer_editors.push_back(o)
			return o
	return null

func _on_child(n : Node) -> void:
	if n is TabBar:
		if n.get_script() != DDTAB:
			n.set_script(DDTAB)
#
		if !n.on_start_drag.is_connected(_on_start_drag):
			n.on_start_drag.connect(_on_start_drag)
		if !n.on_stop_drag.is_connected(_on_stop_drag):
			n.on_stop_drag.connect(_on_stop_drag)
	elif is_instance_valid(tab):
			tab.update()
			
func _out_child(n : Node) -> void:
	if n is TabBar:
		if n.on_start_drag.is_connected(_on_start_drag):
			n.on_start_drag.disconnect(_on_start_drag)
		if n.on_stop_drag.is_connected(_on_stop_drag):
			n.on_stop_drag.disconnect(_on_stop_drag)
		if n.get_script() == DDTAB:
			n.set_script(null)
	elif is_instance_valid(tab):
		tab.update()
			
func update(color : Color) -> void:
	tab.set_select_color(color)
	tab.update()
			
func _on_stop_drag(_tab : TabBar) -> void:
	out_dragging.emit(_tab)

func _on_start_drag(_tab : TabBar) -> void:
	on_dragging.emit(_tab)
