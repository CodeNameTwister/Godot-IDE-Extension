@tool
extends Button
# =============================================================================	
# Author: Twister
# Fancy Search Files
#
# Addon for Godot
# =============================================================================	


func _pressed() -> void:
	if owner.has_method(name):
		owner.call(name)
