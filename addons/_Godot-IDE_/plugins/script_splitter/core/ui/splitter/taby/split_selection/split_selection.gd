@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@export var file_texture : TextureRect = null
var _btns : Array[Button] = []

func get_buttons() -> Array[Button]:
	return _btns

func add_button(b : Button) -> void:
	_btns.append(b)
