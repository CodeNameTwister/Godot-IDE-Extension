@tool
extends ItemList
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


signal on_start_drag(t : ItemList)
signal on_stop_drag(t : ItemList)

var is_drag : bool = false:
	set(e):
		is_drag = e
		if is_drag:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var _fms : float = 0.0

func _init() -> void:
	if is_node_ready(): 
		_ready()

func _ready() -> void:
	set_process(false)
	setup()

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

func _on_input(e : InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == 1:
			if e.pressed:
				_fms = 0.0
				is_drag = false
				set_process(true)
			else:
				set_process(false)
				if _fms >= 0.24:
					on_stop_drag.emit(self)
