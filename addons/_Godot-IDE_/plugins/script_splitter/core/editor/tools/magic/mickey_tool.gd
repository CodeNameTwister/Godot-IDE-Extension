@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const Notfy = preload("./../../../../core/util/control.gd")

signal focus(_tool : Object)
signal new_symbol(symbol : String)
signal clear()

var _owner : Control = null
var _root_control : Control = null
var _control : Control = null
var _index : int = -1

var _queue_free : bool = false

func set_queue_free(q : bool) -> void:
	_queue_free = q

func is_queue_free() -> bool:
	return _queue_free

func is_valid() -> bool:
	for x : Variant in [_owner, _root_control, _control]:
		if !is_instance_valid(x) or (x as Node).is_queued_for_deletion() or !(x as Node).is_inside_tree():
			return false
	return _owner != get_root()

func update_metadata(tittle : String, tooltips : String, icon : Texture2D) -> void:
	if is_instance_valid(_control):
		var parent : Node = _root_control
		for __ : int in range(0, 4, 1):
			if parent is TabContainer or parent == null:
				break
			parent = parent.get_parent()
		
		if parent is TabContainer:
			var index : int = _root_control.get_index()
			if index > -1 and parent.get_tab_count() > index:
				if !tittle.is_empty() and parent.get_tab_title(index) != tittle:
					parent.set_tab_title(index, tittle)
					_root_control.name = tittle
				if !tooltips.is_empty() and parent.get_tab_tooltip(index) != tooltips:
					parent.set_tab_tooltip(index, tooltips)
				parent.set_tab_icon(index, icon)

func ochorus(root : Node) -> void:
	if is_instance_valid(_root_control) and is_instance_valid(root):
		var parent : Node = _root_control.get_parent()
		if parent != root:
			
			_connect_callback(false)
			
			if parent:
				_root_control.reparent(root)
			else:
				root.add_child(_root_control)
				
			if _owner == root:
				if _root_control.get_index() != _index:
					if _owner.get_child_count() > _index:
						_owner.move_child(_root_control, _index)
			else:
				if root is TabContainer:
					var tittle_id : int = _root_control.get_index()
					if tittle_id > -1 and tittle_id < root.get_tab_count():
						var tl : String = root.get_tab_title(tittle_id)
						if tl.is_empty() or (tl.begins_with("@") and "Text" in tl):
								root.set_tab_title(tittle_id, "Editor")
						
				_connect_callback(true)			
					
			_root_control.visible = true
			
func trigger_focus() -> void:
	focus.emit(self)
			
func get_owner() -> Node:
	return _owner
					
func get_root() -> Node:
	if _root_control:
		return _root_control.get_parent()
	return null
	
func get_root_control() -> Node:
	if _root_control:
		var node : Node = _root_control.get_parent()
		if node:
			return node.get_parent()
	return null
	
	
func get_control() -> Node:
	return _root_control
	
func get_gui() -> Node:
	return _control

func has(current_control : Node) -> bool:
	return _owner == current_control or _root_control == current_control or _control == current_control or get_root() == current_control

func _init(owner_control : Control, current_root_control : Control, current_control : Control) -> void:
	_owner = owner_control
	_root_control = current_root_control
	_control = current_control
	_index = current_root_control.get_index()
	
	_owner.tree_exiting.connect(reset)
	
	for x : Control in [
		_owner, _root_control, _control
	]:
		x.set_script(Notfy)
		if _owner == x:
			x.panic()
		if x.has_signal(&"notification"):
			if !x.is_connected(&"notification", _on_not):
				x.connect(&"notification", _on_not)
	
	_con_focus(_control, true)
	
func _con_focus(n : Node, con : bool) -> void:
	if n is Control:
		if n.focus_mode != Control.FOCUS_NONE:
			if con:
				if !_control.gui_input.is_connected(_on_input):
					_control.gui_input.connect(_on_input)
			else:
				if _control.gui_input.is_connected(_on_input):
					_control.gui_input.disconnect(_on_input)
	for x : Node in n.get_children():
		_con_focus(x, con)

func _get_callables(gui : Control) -> Array:
	return [
		[gui.focus_entered, _i_like_coffe],
		#[gui.focus_exited, _i_like_candy],
		#[gui.visibility_changed, _i_like_coffe],
	]
	
func _connect_callback(con : bool) -> void:
	var gui : Control = _control
	if gui is VBoxContainer:
		gui = gui.get_child(0)
		
	var arr : Array = _get_callables(gui)
	
	if gui is CodeEdit:
		arr.append([gui.symbol_lookup, _on_symb])
		
	if _control.focus_mode != Control.FOCUS_NONE:
		_con_focus(_control, con)
			
	for x : Array in arr:
		if con:
			if !x[0].is_connected(x[1]):
				x[0].connect(x[1])
		else:
			if x[0].is_connected(x[1]):
				x[0].disconnect(x[1])
		
	if con:
		if is_instance_valid(gui):
			focus.emit.call_deferred(self)
	elif is_instance_valid(_control):
		_control.modulate = Color.WHITE
		
func _on_not(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		reset()
	
func get_index() -> int:
	if is_instance_valid(_owner) and _owner.is_inside_tree():
		return _owner.get_index()
	return -1
	
func _i_like_coffe() -> void:	
	focus.emit(self)
	
func reset() -> void:
	for x : Variant in [
		_owner, _root_control, _control
	]:
		if is_instance_valid(x):
			x.set_script(null)
			
	if _control is CodeEdit and !_control.is_queued_for_deletion() and _control.get_parent() is VSplitContainer:
		for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
			x.script_merge(_control)
			break
	
	ochorus(_owner)
	set_queue_free(true)
	_owner = null
	_root_control = null
	_control = null
	
	clear.emit()
	
func _context_update(window : Window, control : Control) -> void:
	if is_instance_valid(window) and is_instance_valid(control):
		var screen_rect: Rect2 = DisplayServer.screen_get_usable_rect(window.current_screen)
		var gvp: Vector2 = control.get_screen_position() + control.get_local_mouse_position()
		gvp.y = min(gvp.y, screen_rect.position.y + screen_rect.size.y - window.size.y + 16.0)
		gvp.x = min(gvp.x, screen_rect.position.x + screen_rect.size.x - window.size.x + 16.0)
		window.set_deferred(&"position", gvp)

func _on_input(input : InputEvent) -> void:
	if input is InputEventMouseMotion:
		return
	
	if input is InputEventMouseButton:
		if input.pressed and input.button_index == MOUSE_BUTTON_RIGHT:
			for x : Node in _owner.get_children():
				var variant : Node = x
				if variant is Window and _control is Control:
					_context_update.call_deferred(variant, _control)
			trigger_focus()

func _on_symb(symbol: String, _line : int, _column: int, _edit : CodeEdit = null) -> void:
	new_symbol.emit(symbol)
