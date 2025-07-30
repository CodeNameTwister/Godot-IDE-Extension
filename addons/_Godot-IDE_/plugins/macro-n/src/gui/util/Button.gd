@tool
extends Button
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


func _pressed() -> void:
	if owner and owner.has_method(name):
		owner.call(name)
