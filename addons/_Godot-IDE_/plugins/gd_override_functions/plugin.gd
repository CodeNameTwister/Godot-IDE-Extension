@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	GD Override Functions
#
#	Virtual Popups override functions. godot 4
#	author:	"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var RES : Script = preload("res://addons/_Godot-IDE_/plugins/gd_override_functions/popup/virtuals_popup_context.gd")

#region extension_features
var popup_virtual_functions : RefCounted = null
var popup_virtual_functions_code : RefCounted = null
#endregion

var _c_input : InputEvent = null

func _init() -> void:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if editor:
		var input : Variant = editor.get_setting("plugin/gd_override_functions/invoke_input")
		if input is InputEvent:
			_c_input = input
		else:
			_c_input = InputEventKey.new()
			_c_input.pressed = true
			_c_input.alt_pressed = true
			_c_input.keycode = KEY_INSERT
			editor.set_setting("plugin/gd_override_functions/invoke_input", _c_input)
			

func _enter_tree() -> void:
	popup_virtual_functions = RES.new()
	popup_virtual_functions_code = RES.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, popup_virtual_functions)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, popup_virtual_functions_code)

func _exit_tree() -> void:
	remove_context_menu_plugin(popup_virtual_functions)
	remove_context_menu_plugin(popup_virtual_functions_code)
	
	popup_virtual_functions = null
	popup_virtual_functions_code = null

#Input because the dev can be change buttons ( >.>)
func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_match(_c_input, true):
		var editor : ScriptEditor = EditorInterface.get_script_editor()
		if editor:
			var sc : Script = editor.get_current_script()
			if sc:
				if popup_virtual_functions and popup_virtual_functions.has_method(&"callback"):
					popup_virtual_functions_code.call(&"callback", sc)
