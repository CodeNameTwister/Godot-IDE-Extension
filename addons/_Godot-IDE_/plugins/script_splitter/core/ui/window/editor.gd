@tool
extends Window
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const GRANT_KEY_CODES : PackedInt64Array = [
	KEY_S, KEY_SPACE, KEY_K, KEY_G, KEY_SLASH
]

@export var _root : Node = null
@export var _search : Control = null

func get_root() -> Node:
	return _root
	
func _ready() -> void:
	_search.visible = false
	set_physics_process(false)
	
	var _size : Vector2 = Engine.get_main_loop().root.size
	_size = _size * 0.75
	_size.x = maxf(_size.x, 512.0)
	_size.y = maxf(_size.y, 512.0)
	size = _size
	
	show()
	move_to_center()
	$PanelContainer/VBoxContainer/HBoxContainer/always_top.button_pressed = always_on_top

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_on_close()

func _enter_tree() -> void:
	if !close_requested.is_connected(_on_close):
		close_requested.connect(_on_close)
		
	if !focus_entered.is_connected(_on_focus):
		focus_entered.connect(_on_focus)
		
	if !focus_exited.is_connected(_out_focus):
		focus_exited.connect(_out_focus)
		
	if !tree_exiting.is_connected(_on_close):
		tree_exiting.connect(_on_close)
		
func _out_focus() -> void:
	always_on_top = $PanelContainer/VBoxContainer/HBoxContainer/always_top.button_pressed
		
func setup() -> void:
	if _root:
		var x : Node = _root.get_child(1).get_child(0)
		x.child_exiting_tree.connect(update)
		
func _on_focus(__ : Variant = null) -> void:
	always_on_top = false
	_search.code_edit = null
	_focus(_root)
	_search.visible = _search.visible and null != _search.code_edit
	
func _focus(n : Node, focus : bool = false) -> void:
	if n:
		if focus and n is Control:
			var c : Control = n
			if c.focus_mode != Control.FOCUS_NONE:
				c.grab_focus.call_deferred()
				
			if c is CodeEdit:
				_search.code_edit = c
				if _search.visible:
					_search.update_search()
			
		for x : Node in n.get_children():
			if x is TabContainer:
				if !x.tab_changed.is_connected(_on_focus):
					x.tab_changed.connect(_on_focus)
				_focus(x.get_current_tab_control(), true)
				break	
			_focus(x, focus)
		
		
func _on_close() -> void:
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
		x.call(&"remove_from_control", self)
		
	if !is_queued_for_deletion():
		queue_free()

func _resizez(n : Node) -> void:
	if n is Control:
		if n.size > _root.size:
			n.set_deferred(&"size", _root.size)
	for x : Node in n.get_children():
		_resizez(x)
	
func update(__ : Variant  = null) -> void:
	if _root.get_child_count() == 0:
		queue_free()
		return
	call_deferred(&"set_physics_process", true)

func _physics_process(__: float) -> void:
	set_physics_process(false)
	if !_root or _root.get_child_count() == 0 or _root.get_child(1).get_child(0).get_child_count() == 0:
		queue_free()
		return
	
	_resizez(_root)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.ctrl_pressed and event.shift_pressed == false:
			if event.keycode == KEY_F:
				_search.open()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode in GRANT_KEY_CODES:
				var vp : Viewport = (Engine.get_main_loop().root)
				vp.push_input(event)
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if _search.visible and (_search.has_focus() or _search.is_search_focused()):
				_search.close()
				get_viewport().set_input_as_handled()

func center() -> void:
	move_to_center()
	
func always_top() -> void:
	pass
