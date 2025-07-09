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
