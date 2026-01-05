@tool
extends Control

func _ready() -> void:
	add_to_group(&"SP_TAB_BUTTON")

func _get_drag_data(__ : Vector2) -> Variant:
	return owner.button_main._get_drag_data(__)
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	owner.button_main._drop_data(_at_position, data)
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return owner.button_main._can_drop_data(at_position, data)

func get_selected_color() -> Color:
	return owner.get_selected_color()
