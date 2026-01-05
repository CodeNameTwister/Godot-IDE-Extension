@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


const Builder = preload("./../core/builder.gd")
const Context = preload("./../core/contex/window.gd")
const SSPContext = preload("./../core/contex/ssp_window.gd")

var _plugin : EditorPlugin = null
var _builder : Builder = null

signal add_row(value : Resource)
signal add_column(value : Resource)
signal remove_row(value : Resource)
signal remove_column(value : Resource)

signal left_tab_close(value : Resource)
signal right_tab_close(value : Resource)
signal others_tab_close(value : Resource)
	
const ICON_ADD_COLUMN : Texture2D = preload("./../assets/split_cplus.svg")
const ICON_ADD_ROW : Texture2D = preload("./../assets/split_rplus.svg")
const ICON_REMOVE_COLUMN : Texture2D = preload("./../assets/split_cminus.svg")
const ICON_REMOVE_ROW : Texture2D = preload("./../assets/split_rminus.svg")
	
const L_TAB_BAR : Texture2D = preload("./../assets/LTabBar.svg")
const R_TAB_BAR : Texture2D = preload("./../assets/RTabBar.svg")
const TAB_BAR: Texture2D = preload("./../assets/TabBar.svg")
	
	
var _context_add_split_column : Context = null
var _context_add_split_row : Context = null
var _context_remove_split_column : Context = null
var _context_remove_split_row : Context = null
var _context_editor_split : SSPContext = null

var _editor_context_add_split_column : Context = null
var _editor_context_add_split_row : Context = null
var _editor_context_remove_split_column : Context = null
var _editor_context_remove_split_row : Context = null

var _editor_context_left_tab_close : Context = null
var _editor_context_right_tab_close : Context = null
var _editor_context_botH_tab_close : Context = null

func get_honey_splitter() -> SSPContext:
	return _context_editor_split

# Traduction?
func _tr(message : String) -> String:
	# ...
	return message.capitalize()
	
func init_1() -> void:	
	
	_context_add_split_column = Context.new(_tr("SPLIT_COLUMN"), _add_column_split, _can_split, ICON_ADD_COLUMN)
	_context_add_split_row = Context.new(_tr("SPLIT_ROW"), _add_row_split, _can_split, ICON_ADD_ROW)
	_context_remove_split_column = Context.new(_tr("MERGE_SPLITTED_COLUMN"), _remove_column_split, _can_merge_column, ICON_REMOVE_COLUMN)
	_context_remove_split_row = Context.new(_tr("MERGE_SPLITTED_ROW"), _remove_row_split, _can_merge_row, ICON_REMOVE_ROW)
	_context_editor_split = SSPContext.new()
	
	_editor_context_add_split_column = Context.new(_tr("SPLIT_COLUMN"), _add_column_split, _can_split, ICON_ADD_COLUMN)
	_editor_context_add_split_row = Context.new(_tr("SPLIT_ROW"), _add_row_split, _can_split, ICON_ADD_ROW)
	_editor_context_remove_split_column = Context.new(_tr("MERGE_SPLITTED_COLUMN"), _remove_column_split, _can_merge_column, ICON_REMOVE_COLUMN)
	_editor_context_remove_split_row = Context.new(_tr("MERGE_SPLITTED_ROW"), _remove_row_split, _can_merge_row, ICON_REMOVE_ROW)
	
	_editor_context_left_tab_close = Context.new(_tr("CLOSE_LEFT_TABS"), _left_tab_close, _can_left_tab_close, L_TAB_BAR)
	_editor_context_botH_tab_close = Context.new(_tr("CLOSE_OTHERS_TABS"), _others_tab_close, _can_others_tab_close, TAB_BAR)
	_editor_context_right_tab_close = Context.new(_tr("CLOSE_RIGHT_TABS"), _right_tab_close, _can_right_tab_close, R_TAB_BAR)
	
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _context_add_split_column)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _context_add_split_row)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _context_remove_split_column)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _context_remove_split_row)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _context_editor_split)
	
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_add_split_column)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_add_split_row)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_remove_split_column)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_remove_split_row)
	
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_left_tab_close)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_right_tab_close)
	_plugin.add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_botH_tab_close)
	
	
	
func _get_value(value : Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return value
		
	elif value is Array:
		var packed : PackedStringArray = []
		for x : Variant in value:
			if x is Resource:
				packed.append(x.resource_path)
				return packed
			elif x is String:
				packed.append(x)
				return packed
				
	elif value is Resource:
		var packed : PackedStringArray = [value.resource_path]
		return packed
	return []
	
func _get_resource(value : Variant) -> Variant:
	if value is Resource:
		return value
	elif value is Node:
		return value
		
	var packed : PackedStringArray = []
	if value is Array:
		for x : Variant in value:
			if x is String:
				packed.append(x)
				break
	elif value is PackedStringArray:
		packed = value
		
	if packed.size() == 0:
		return null
		
	return packed[0]
	
func _can_split(value : Variant = null) -> bool:
	return _plugin.builder.can_split(_get_value(value))
	
func _can_merge_column(value : Variant = null) -> bool:
	return _plugin.builder.can_merge_column(_get_value(value))
	
func _can_merge_row(value : Variant = null) -> bool:
	return _plugin.builder.can_merge_row(_get_value(value))
	
func _can_left_tab_close(value : Variant = null) -> bool:
	return _plugin.builder.can_left_tab_close(_get_value(value))
	
func _can_right_tab_close(value : Variant = null) -> bool:
	return _plugin.builder.can_right_tab_close(_get_value(value))
	
func _can_others_tab_close(value : Variant = null) -> bool:
	return _plugin.builder.can_others_tab_close(_get_value(value))
	
func _left_tab_close(value : Variant = null) -> void:
	left_tab_close.emit(_get_resource(value))
	
func _right_tab_close(value : Variant = null) -> void:
	right_tab_close.emit(_get_resource(value))
	
func _others_tab_close(value : Variant = null) -> void:
	others_tab_close.emit(_get_resource(value))
	
func _add_column_split(value : Variant = null) -> void:
	add_column.emit(_get_resource(value))
	
func _add_row_split(value : Variant = null) -> void:
	add_row.emit(_get_resource(value))
	
func _remove_column_split(value : Variant = null) -> void:
	remove_column.emit(_get_resource(value))
	
func _remove_row_split(value : Variant = null) -> void:
	remove_row.emit(_get_resource(value))
		
func init_0() -> void:
	for x : Variant in [
		_context_add_split_column,
		_context_add_split_row,
		_context_remove_split_column,
		_context_remove_split_row,
		_context_editor_split,
		_editor_context_add_split_column,
		_editor_context_add_split_row,
		_editor_context_remove_split_column,
		_editor_context_remove_split_row
	]:
		if is_instance_valid(x):
			_plugin.remove_context_menu_plugin(x)
	
func _init(plugin : EditorPlugin, builder : Builder) -> void:
	_plugin = plugin
	_builder = builder

func event(event : InputEvent) -> bool:
	if event.is_pressed():
		if event is InputEventKey:
			if event.keycode == KEY_1 and event.ctrl_pressed:
				_plugin.builder.multi_split(2, false)
				pass
			if event.keycode == KEY_2 and event.ctrl_pressed:
				_plugin.builder.multi_split(4, false)
				pass
	return false
