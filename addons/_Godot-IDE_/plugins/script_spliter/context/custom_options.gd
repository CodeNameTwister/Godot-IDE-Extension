@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@export var columns : SpinBox
@export var rows : SpinBox

func set_values(_columns : int, _rows : int) -> void:
	columns.value = _columns
	rows.value = _rows

func get_columns_value() -> int:
	return max(columns.value, 1)

func get_rows_value() -> int:
	return max(rows.value, 1)
