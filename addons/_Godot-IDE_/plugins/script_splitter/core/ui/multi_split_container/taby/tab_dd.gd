@tool
extends Control

@export var new_color : Color = Color.CYAN
var _default : Color = Color.WHITE

func _ready() -> void:
	add_to_group(&"SP_TAB_BUTTON")
	
	var _self : Node = self
	if _self is Button:
		gui_input.connect(_on_gui)
	_default = modulate
	
	mouse_entered.connect(_on_mouse)
	mouse_exited.connect(_out_mouse)
	
func _on_gui(e : InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT and  e.is_pressed():
			var _self : Variant = self
			if _self is Button:
				if !_self.button_pressed:
					_self.pressed.emit()
					get_viewport().set_input_as_handled()
			
	
func _on_mouse() -> void:
	modulate = new_color
	
func _out_mouse() -> void:
	modulate = _default

func _get_drag_data(__ : Vector2) -> Variant:
	return owner.button_main._get_drag_data(__)
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	owner.button_main._drop_data(_at_position, data)
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return owner.button_main._can_drop_data(at_position, data)

func get_selected_color() -> Color:
	return owner.get_selected_color()
