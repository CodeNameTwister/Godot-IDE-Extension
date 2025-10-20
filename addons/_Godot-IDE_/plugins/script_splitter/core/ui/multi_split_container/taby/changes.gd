@tool
extends Label

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			var btn : Node = get_parent().get_child(0)
			if btn is Button:
				btn.pressed.emit()
