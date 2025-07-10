@tool
extends Button
# =============================================================================	
# Author: Twister
# Fancy Searc Files
#
# Addon for Godot
# =============================================================================	


func _pressed() -> void:
	if owner.has_method(name):
		owner.call(name)
