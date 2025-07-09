@tool
extends CheckBox
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## V0.2 Used now as max columns by row!, 0 as infinite horizontal.
@export var columns : int = 0
## V0.2: Used now only as extra container if row > 1
@export var rows : int = 0

@export var is_custom : bool = false

func _pressed() -> void:
	if is_custom:
		if owner.has_method(&"enable_options"):
			owner.call(&"enable_options")
	else:
		if owner.has_method(&"set_split_value"):
			owner.call(&"set_split_value", columns, rows)
