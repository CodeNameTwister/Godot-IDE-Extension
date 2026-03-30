@tool
extends Control 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index < 2:
			var btn : Button =  owner.button_main
			
			if !btn.button_pressed:
				btn.pressed.emit()
				
			var c : Control = btn.duplicate(0)
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 2
			
			btn._drag_icon = c
			btn.set_process(true)
			force_drag(btn, c)

func _get_drag_data(__ : Vector2) -> Variant:
	set_process(false)
	return owner._get_drag_data(__)
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	owner._drop_data(_at_position, data)
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return owner._can_drop_data(at_position, data)
