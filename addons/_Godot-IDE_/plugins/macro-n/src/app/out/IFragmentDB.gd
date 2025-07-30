@tool
extends RefCounted
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	

func save_fragment(shortcut : String, description : String, full_text : String) -> int:
	push_error("Not supported!")
	return -1
	
func get_fragment(shortcut : String) -> Dictionary:
	push_error("Not supported!")
	return {}

func get_all_fragments() -> Array[Dictionary]:
	push_error("Not supported!")
	return []
	
func get_data_keys() -> PackedStringArray:
	push_error("Not supported!")
	return []

func remove(shortcut : String) -> int:
	push_error("Not supported!")
	return -1
