@tool
extends EditorContextMenuPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
var CONTEXT : String = "CUSTOM"
var ICON : Texture = null
var SHORTCUT : Shortcut = null
var CALLABLE : Callable
var VALIDATOR : Callable

func _init(context : String, handle : Callable, validator : Callable, icon : Texture, input_key : Array[InputEvent] = []):
	CONTEXT = context
	CALLABLE = handle
	ICON = icon
	VALIDATOR = validator
	if input_key.size() > 0:
		SHORTCUT = Shortcut.new()
		SHORTCUT.events = input_key
		add_menu_shortcut(SHORTCUT, handle)

func _popup_menu(paths : PackedStringArray):
	if VALIDATOR.is_valid():
		if !VALIDATOR.call(paths):
			return
	if SHORTCUT:
		add_context_menu_item_from_shortcut(CONTEXT, SHORTCUT, ICON)
	else:
		if CALLABLE.is_valid():
			add_context_menu_item(CONTEXT, CALLABLE, ICON)
		else:
			push_error("Not valid callaback!")
