@tool
extends TabContainer
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if owner.has_method(&"set_settings"):
			owner.call(&"set_settings")
