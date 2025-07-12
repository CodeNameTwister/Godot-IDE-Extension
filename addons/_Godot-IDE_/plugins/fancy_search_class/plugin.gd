@tool
extends EditorPlugin
# =============================================================================	
# Author: Twister
# Fancy Search Class
#
# Addon for Godot
# =============================================================================	


const FANCY_SEARCH : PackedScene = preload("res://addons/_Godot-IDE_/plugins/fancy_search_class/gui/main.tscn")

var pop : Window = null
var _c_input : InputEvent = null

func _init() -> void:
	var input : Variant = IDE.get_config("fancy_search_class", "invoke_input")
	if input is InputEvent:
		_c_input = input
	else:
		_c_input = InputEventKey.new()
		_c_input.pressed = true
		_c_input.alt_pressed = true
		_c_input.keycode = KEY_DELETE
		IDE.set_config("fancy_search_class", "invoke_input", _c_input)
		

func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_match(_c_input):
		if !is_instance_valid(pop):
			pop = FANCY_SEARCH.instantiate()
			add_child(pop)
		pop.popup_centered()
