@tool
extends HBoxContainer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _enter_tree() -> void:
	add_to_group(&"__SP_PIN_ROOT__")
	
func _exit_tree() -> void:
	remove_from_group(&"__SP_PIN_ROOT__")
