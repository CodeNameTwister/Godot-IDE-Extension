@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _draw() -> void:
	pivot_offset.x = size.y * 0.335
	pivot_offset.y = size.y * 0.345
	size.x = get_child(0).size.x
