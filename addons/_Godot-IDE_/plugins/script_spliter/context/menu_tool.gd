@tool
extends Window
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@export var _container : Node
@export var _custom_options : Control

var _plugin : Object = null

func _init_1() -> void:
	if _container and _plugin:
		var columns : int = _plugin.call(&"get_split_columns")
		var rows : int  = _plugin.call(&"get_split_rows")
		set_split_value(columns, rows)

func _ready() -> void:
	if _custom_options:
		_custom_options.visible = false
		
	if !visibility_changed.is_connected(_on_visibility_change):
		visibility_changed.connect(_on_visibility_change)

	_init_1()

func set_plugin(current_plugin : Object) -> void:
	_plugin = current_plugin

func _on_visibility_change() -> void:
	if !visible: return
	if !_plugin:
		return

	_init_1()
	
func enable_options() -> void:
	var custom : CheckBox = _container.get_child(_container.get_child_count() - 1)
	for c : Node in _container.get_children():
		if c is CheckBox:
			c.button_pressed = false
			
	_custom_options.visible = true
	custom.button_pressed = true

func set_split_value(columns : int, rows : int) -> void:
	var current : Node = null
	var custom : CheckBox = _container.get_child(_container.get_child_count() - 1)
	for c : Node in _container.get_children():
		if c is CheckBox:
			if c.columns == columns and c.rows == rows:
				current = c
				c.button_pressed = true
				continue
			c.button_pressed = false
			
	if columns < 2 and rows < 2:
		current = _container.get_child(0)
		if current is CheckBox:
			current.button_pressed = true
		else:
			current = null
			
	_custom_options.visible = current == null
	custom.button_pressed = _custom_options.visible
	_custom_options.set_values(columns, rows)

func _on_ok_pressed() -> void:
	var columns : int = _custom_options.get_columns_value()
	var rows : int = _custom_options.get_rows_value()
	if !_plugin:
		push_error("[ERROR] Can not set split type!")
	else:
		_plugin.call(&"set_type_split", columns, rows)
	hide()

func _on_cancel_pressed() -> void:
	hide()
