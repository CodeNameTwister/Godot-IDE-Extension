@tool
extends EditorPlugin
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	

const CONTEXT := preload("res://addons/_Godot-IDE_/plugins/macro-n/context.gd")

var ctx_macron_n : EditorContextMenuPlugin = null
var macron_n : RefCounted = null

var _c_input : InputEvent = null
var _g_input : InputEvent = null
var _cb_input : InputEvent = null

		
func _enter_tree() -> void:
	ctx_macron_n = CONTEXT.new(self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, ctx_macron_n)
	
func _exit_tree() -> void:
	macron_n = null
	remove_context_menu_plugin(ctx_macron_n)

func half_life(txt : String, type : int) -> void:
	if !is_instance_valid(macron_n):
		macron_n = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/main.gd").new(self)
	macron_n.execute(txt, type)

func create_new() -> void:
	if !is_instance_valid(macron_n):
		macron_n = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/main.gd").new(self)
	macron_n.execute("# CODE HERE", 2)

func _init() -> void:
	var input : Variant = IDE.get_config("macro_n", "invoke_input")
	if input is InputEvent:
		_c_input = input
	else:
		_c_input = InputEventKey.new()
		_c_input.pressed = true
		_c_input.ctrl_pressed = true
		_c_input.keycode = KEY_E
		IDE.set_config("macro_n", "invoke_macro", _c_input)
	
	input = IDE.get_config("macro_n", "invoke_macro_by_pass")
	if input is InputEvent:
		_cb_input = input
	else:
		_cb_input = InputEventKey.new()
		_cb_input.pressed = true
		_cb_input.ctrl_pressed = true
		_cb_input.shift_pressed = true
		_cb_input.keycode = KEY_E
		IDE.set_config("macro_n", "invoke_macro_by_pass", input)
	
	input = IDE.get_config("macro_n", "show_all_macro")
	if input is InputEvent:
		_g_input = input
	else:
		_g_input = InputEventKey.new()
		_g_input.pressed = true
		_g_input.alt_pressed = true
		_g_input.keycode = KEY_END
		IDE.set_config("macro_n", "show_all_macro", _g_input)

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		if event.is_match(_c_input):
			ctx_macron_n.invoke_macron()
		elif event.is_match(_cb_input):
			ctx_macron_n.invoke_macron_bypass()
		elif event.is_match(_g_input):
			ctx_macron_n.show_macros()
