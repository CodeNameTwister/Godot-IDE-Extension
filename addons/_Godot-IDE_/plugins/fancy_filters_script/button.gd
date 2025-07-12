@tool
extends Button
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	


func _pressed() -> void:
	if owner:
		if owner.has_method(name):
			owner.call(name)
