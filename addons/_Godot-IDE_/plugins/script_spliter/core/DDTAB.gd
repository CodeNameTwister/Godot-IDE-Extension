@tool
extends TabBar
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


signal on_start_drag(t : TabBar)
signal on_stop_drag(t : TabBar)

var is_drag : bool = false:
	set(e):
		is_drag = e
		if is_drag:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var _fms : float = 0.0

func reset() -> void:
	if is_drag:
		set_process(false)
		is_drag = false
		if is_inside_tree():
			on_stop_drag.emit(null)

func _init() -> void:
	if is_node_ready():
		_ready()

func _ready() -> void:
	set_process(false)
	setup()
	
func _enter_tree() -> void:
	if !is_in_group(&"__SPLITER_TAB__"):
		add_to_group(&"__SPLITER_TAB__")
	
func _exit_tree() -> void:
	if is_in_group(&"__SPLITER_TAB__"):
		remove_from_group(&"__SPLITER_TAB__")

func _process(delta: float) -> void:
	_fms += delta
	if _fms > 0.24:
		if is_drag:
			if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				set_process(false)
				is_drag = false
				on_stop_drag.emit(self)
		else:
			on_start_drag.emit(self)
			is_drag = true

func setup() -> void:
	if !gui_input.is_connected(_on_input):
		gui_input.connect(_on_input)
	if !is_in_group(&"__SPLITER_TAB__"):
		add_to_group(&"__SPLITER_TAB__")

func _on_input(e : InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == 1:
			is_drag = false
			if e.pressed:
				_fms = 0.0
				set_process(true)
			else:
				set_process(false)
				if _fms >= 0.24:
					on_stop_drag.emit(self)
