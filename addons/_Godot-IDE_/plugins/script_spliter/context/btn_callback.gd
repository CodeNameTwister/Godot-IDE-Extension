@tool
extends Button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _pressed() -> void:
	var parent : Node = owner
	if parent == null:
		parent = get_parent()
	if parent:
		if parent.has_method(name):
			parent.call(name)
