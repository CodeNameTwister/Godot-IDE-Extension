@tool
extends Button
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	

func update_settings() -> void:
	var variant : Variant = owner.get(name)
	if variant is bool:
		button_pressed = variant
		
	visual()
	

func _ready() -> void:
	update_settings()

func _pressed() -> void:
	if owner.has_method(&"enable_filter"):
		owner.call(&"enable_filter", name, button_pressed)
		visual()

func visual() -> void:
	if button_pressed:
		var value : Variant = owner.get(str(name, "_color"))
		if value is Color:
			modulate = value
		else:
			modulate = Color.WHITE
	else:	
		modulate = Color.DARK_GRAY
		modulate.a = 0.7
