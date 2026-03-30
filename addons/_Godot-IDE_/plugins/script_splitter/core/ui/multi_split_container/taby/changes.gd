@tool
extends Label

func _on_mouse() -> void:
	owner.mouse_entered.emit()
	
func _out_mouse() -> void:
	owner.mouse_exited.emit()

func _ready() -> void:
	mouse_entered.connect(_on_mouse)
	mouse_exited.connect(_out_mouse)
	add_to_group(&"SP_TAB_BUTTON")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			var btn : Node = get_parent().get_child(0)
			if btn is Button:
				if !btn.button_pressed:
					btn.pressed.emit()
				
func _get_drag_data(__ : Vector2) -> Variant:
	return owner.button_main._get_drag_data(__)
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	owner.button_main._drop_data(_at_position, data)
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return owner.button_main._can_drop_data(at_position, data)

func get_selected_color() -> Color:
	return owner.get_selected_color()
