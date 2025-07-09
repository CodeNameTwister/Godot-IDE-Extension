@tool
extends Window
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4f
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
signal on_close(window : Window)

@export var _container : Control = null
@export var _base_control : TabContainer = null
@export var _always_top : Button = null
@export var _close : Button = null
@export var _root : Control = null

var proxy : Control = null
var replacer : Node = null
var controller : Object = null

func set_base_control(node : Node) -> void:
	if _base_control:
		_base_control.queue_sort()
	_base_control = node
	if _container:
		_container.add_child(node)
		return
	add_child(node)
	
	if node is Control:
		node.size = node.get_parent().size

func get_base_control() -> TabContainer:
	return _base_control

func _init() -> void:
	visible = false
	close_requested.connect(_on_close)
	visibility_changed.connect(_on_visibility)
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_focus_exited)
	
func _get_edit(n : Node) -> CodeEdit:
	if n is CodeEdit:
		return n
	for x : Node in n.get_children():
		return _get_edit(x)
	return null
	
func _on_focus() -> void:
	if replacer == null:
		var script_editor: ScriptEditor = EditorInterface.get_script_editor()
		var root : Node = script_editor.get_child(0).get_child(1).get_child(1)
		if root.get_child_count() > 2:
			replacer = root.get_child(2)
			if "FindReplaceBar" in replacer.name:
				replacer.get_parent().remove_child(replacer)
				
				if is_instance_valid(_root):
					_root.add_child(replacer)
				else:
					add_child(replacer)
					
	if is_instance_valid(controller):
		controller.emit_signal.call_deferred(&"focus", controller)
	
func _update_name() -> void:
	if is_queued_for_deletion():
		return
	if is_instance_valid(_base_control):
		if _base_control.current_tab > -1:
			title = "Script-Spliter: {0}".format([_base_control.get_tab_title(_base_control.current_tab)])
			return
	title = "Script-Spliter: Pop Script"
	
func _on_tabity(__ : int) -> void:
	_update_name.call_deferred()
	
func _on_always_top() -> void:
	if transient:
		return
	always_on_top = !always_on_top
	
func _shortcut_input(event: InputEvent) -> void:
	if is_instance_valid(proxy):
		var vp : Viewport = proxy.get_viewport()
		if vp and vp != get_viewport():
			vp.push_input(event)
			
func _ready() -> void:
	set_process_shortcut_input(true)
	if _always_top:
		if !_always_top.pressed.is_connected(_on_always_top):
			_always_top.pressed.connect(_on_always_top)
	if _close:
		if !_close.pressed.is_connected(_on_close):
			_close.pressed.connect(_on_close)
	if _base_control:
		if !_base_control.tab_changed.is_connected(_on_tabity):
			_base_control.tab_changed.connect(_on_tabity)
		if !_base_control.child_entered_tree.is_connected(_on_child):
			_base_control.child_entered_tree.connect(_on_child)
		if !_base_control.child_exiting_tree.is_connected(_out_child):
			_base_control.child_exiting_tree.connect(_out_child)
			
	var root : Control = EditorInterface.get_base_control()
	if root:
		add_theme_stylebox_override(&"Panel",root.get_theme_stylebox("panel", "PanelContainer"))
	
func _connect(n : Node, e : bool) -> void:
	if n is CodeEdit:
		if e:
			if !n.focus_entered.is_connected(_on_focus):
				n.focus_entered.connect(_on_focus)
		else:
			if n.focus_entered.is_connected(_on_focus):
				n.focus_entered.disconnect(_on_focus)
		return
	for x : Node in n.get_children():
		_connect(x, e)
		
func _on_child(n : Node) -> void:
	if n is Control:
		_connect(n, true)
	
func _out_child(n : Node) -> void:
	if n is Control:
		_connect(n, false)
	
func _on_visibility() -> void:
	if !visible:
		_on_focus_exited()
		_on_close()
		return
	set_deferred(&"always_top", false)
	set_process(true)
	_update_name.call_deferred()
	
func _on_close() -> void:
	on_close.emit(self)
	
	if _base_control and _base_control.get_child_count() < 1:
		queue_free()

func _on_focus_exited() -> void:
	if replacer != null:
		var script_editor: ScriptEditor = EditorInterface.get_script_editor()
		var root : Node = script_editor.get_child(0).get_child(1).get_child(1)
		
		var parent : Node = replacer.get_parent()
		if parent != root:
			if is_instance_valid(parent):
				parent.remove_child(replacer)
			root.add_child(replacer)
		replacer = null
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(replacer):
			var script_editor: ScriptEditor = EditorInterface.get_script_editor()
			var root : Node = script_editor.get_child(0).get_child(1).get_child(1)
			
			var parent : Node = replacer.get_parent()
			if parent != root:
				if is_instance_valid(parent):
					parent.remove_child(replacer)
				root.add_child(replacer)
			replacer = null
		if is_instance_valid(controller):
			controller.call(&"reset")

func _move_to_center() -> void:
	move_to_center()

func _alpha_value(v : float) -> void:
	get_child(0).modulate.a = v
