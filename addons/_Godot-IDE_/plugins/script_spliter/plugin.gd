@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const BUILDER : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/builder.gd")
const CONTEXT : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/context_window.gd")

const CMD_MENU_TOOL : String = "Script Spliter"

#CONTEXT
const ICON_ADD_COLUMN : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/icons/split_cplus.svg")
const ICON_REMOVE_COLUMN : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/icons/split_cminus.svg")
const ICON_ADD_ROW : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/icons/split_rplus.svg")
const ICON_REMOVE_ROW : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/icons/split_rminus.svg")
const ICON_FLOATING : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/context/icons/atop.png")
const ICON_TAB : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/assets/tab_icon.svg")
	
const SPLIT_TYPES : Array[Array] = [
	[0, 0], 
	[2, 1], 
	[1, 2], 
	[3, 1], 
	[1, 3], 
	[2, 2], 
	[3, 3], 
	[4, 4], 
	[5, 5], 
	[6, 6], 
	[7, 7]
	]
	
var _inputs : Array[InputEvent] = []

var _rmb_editor_add_split : EditorContextMenuPlugin = null
var _rmb_editor_remove_split: EditorContextMenuPlugin = null
var _rmb_editor_code_add_split : EditorContextMenuPlugin = null
var _rmb_editor_code_remove_split : EditorContextMenuPlugin = null
var _rmb_editor_pop_script : EditorContextMenuPlugin = null
var _rmb_editor_code_pop_script : EditorContextMenuPlugin = null

var _rmb_close_all_tab_in_split : EditorContextMenuPlugin = null
var _rmb_close_all_tab_in_split_right : EditorContextMenuPlugin = null
var _rmb_close_all_tab_in_split_left : EditorContextMenuPlugin = null

var _menu_split_selector : Window = null
var _builder : Object = null

var _daemon_chaser : Node = null

#region _REF_
var _tab_container : Node = null:
	get:
		if !is_instance_valid(_tab_container):
			_tab_container = IDE.get_script_editor_container()
		return _tab_container
		
var _item_list : Node = null:
	get:
		if !is_instance_valid(_item_list):
			_item_list = IDE.get_script_list()
		return _item_list
#endregion

#region _USER_BUFFER_
var _rows : int = 0:
	set(e):
		_rows = maxi(e, 0)
var _columns : int = 0:
	set(e):
		_columns = maxi(e, 0)
var _refresh_warnings_on_save : bool = true
#endregion

var _frm : int = 0
var _d_chase : bool = false

func get_builder() -> Object:
	return _builder

func get_split_rows() -> int:
	return _rows

func get_split_columns() -> int:
	return _columns
	
func _on_save(res : Resource) -> void:
	if res is Script:
		_save_external_data()
	
func _save_external_data() -> void:
	if _d_chase == true:
		return#
	_d_chase = true
	if _refresh_warnings_on_save and is_instance_valid(_builder):
		var root : SceneTree = get_tree()
		if root and root.root.has_focus():
			if _daemon_chaser == null:
				_daemon_chaser = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/script_spliter/core/DaemonChaser.gd").new()
				add_child(_daemon_chaser)
			_daemon_chaser.set_current_index(_builder.get_current_focus_index())
			_daemon_chaser.buffer = _builder.get_focus_config()
			_builder.enable_focus_highlight(false)
			_daemon_chaser.run(_builder.focus_by_index, _builder.set_focus_config)
	set_deferred(&"_d_chase", false)

func _process(__: float) -> void:
	if _frm < 2:
		_frm += 1
		return
	_frm = 0
	set_process(false)
	if is_instance_valid(_builder):
		_builder.update()

func _on_change_settings() -> void:
	if is_instance_valid(_builder):
		_builder.update_config()
		var settings : EditorSettings = EditorInterface.get_editor_settings()
		var changes : PackedStringArray = settings.get_changed_settings()
		
		if &"plugin/script_spliter/behaviour/refresh_warnings_on_save" in changes:
			_refresh_warnings_on_save = settings.get_setting(&"plugin/script_spliter/behaviour/refresh_warnings_on_save")
	
			
func _init() -> void:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if editor:
		var KEYS : PackedInt64Array = [
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0
		]
		var key : String = "plugin/script_spliter/input/spliy_type_"
		
		for x : int in range(0, mini(SPLIT_TYPES.size(), KEYS.size()), 1):
			var key_token : String = str(key, x + 1)
			var __input : InputEvent = null
			if editor.has_setting(key_token):
				var variant : Variant = editor.get_setting(key_token)
				if variant is InputEvent:
					__input = variant
					_inputs.append(__input)
					continue
			__input = InputEventKey.new()
			__input.pressed = true
			__input.ctrl_pressed = true
			__input.keycode = KEYS[x]
			editor.set_setting(key_token, __input)
			__input.append(__input)
			
	set_process_input(_inputs.size() > 0)
	
	var o : Object = _tab_container
	if o == null:
		#push_warning("[Script-Spliter] 0x000A")
		return
	o = _item_list
	if o == null:
		#push_warning("[Script-Spliter] 0x000B")
		return

func _run() -> void:
	if is_instance_valid(_builder):
		var settings : EditorSettings = EditorInterface.get_editor_settings()
		var scripts_tab_container : Node = _tab_container
		
		if !scripts_tab_container:
			push_warning("[Script-Spliter] 0x000A Error can not find editor reference!")
			return
		
		var il : Node = _item_list
		if null != il:
			_builder.set_item_list(il)
		else:
			push_warning("[Script-Spliter] 0x000B Error can not find editor reference!")
			return
	
		if  !scripts_tab_container.is_node_ready():
			await scripts_tab_container.ready
			if !is_instance_valid(scripts_tab_container):
				push_error("Unspected error reference be replace or free it, can not run plugin!")
				return

		settings.settings_changed.connect(_on_change_settings)

		_builder.init_1()
		_builder.build(scripts_tab_container, _columns, _rows)
		set_process_input(true)

func set_type_split(columns : int, rows : int) -> void:
	_columns = columns
	_rows = rows
	
	var str_columns : String = str(maxi(_columns, 1))
	var str_rows : String = str(maxi(rows, 1))
	
	print("[{0}] {1} {2}: > {3} {5} - {4} {6}".format(
		[
			_get_translated_text("INFO"),
			_get_translated_text("Setting"),
			_get_translated_text("To"),
			_get_translated_text("Columns"),
			_get_translated_text("Rows"),
			str_columns, 
			str_rows
			]) )

	if is_instance_valid(_builder):
		_builder.update_build(columns, rows)

func _exit_tree() -> void:
	remove_tool_menu_item(CMD_MENU_TOOL)
	_setup(0)

	if is_instance_valid(_builder):
		_builder.init_0()
		_builder.free.call_deferred()

	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings.settings_changed.is_connected(_on_change_settings):
		settings.settings_changed.disconnect(_on_change_settings)
		
	if is_instance_valid(_daemon_chaser) and !_daemon_chaser.is_queued_for_deletion():
		_daemon_chaser.queue_free()

func _get_translated_text(text : String) -> String:
	# TODO: Translation
	return text

func swap(caller : Object) -> void:
	if is_instance_valid(_builder):
		_builder.swap(caller)

func _setup(input : int) -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()

	if input != 0:
		add_to_group(&"ScriptSpliter")
		
		main_screen_changed.connect(_on_change)
		resource_saved.connect(_on_save)
		
		var ctx_add_column : String = _get_translated_text("ADD_SPLIT").capitalize()
		var ctx_remove_split : String = _get_translated_text("REMOVE_SPLIT").capitalize()
		var ctx_pop_script : String = _get_translated_text("MAKE_FLOATING_SCRIPT").capitalize()
		var ctx_close_tabs : String = _get_translated_text("CLOSE_OTHERS_TABS_IN_SPLIT").capitalize()
		var ctx_close_tabs_right : String = _get_translated_text("CLOSE_RIGHT_TABS_IN_SPLIT").capitalize()
		var ctx_close_tabs_left : String = _get_translated_text("CLOSE_LEFT_TABS_IN_SPLIT").capitalize()

		#SETUP
		_rmb_editor_add_split = CONTEXT.new(ctx_add_column, _add_window_split, _can_add_split, ICON_ADD_COLUMN)
		_rmb_editor_remove_split = CONTEXT.new(ctx_remove_split, _remove_window_split, _can_remove_split, ICON_REMOVE_COLUMN)

		_rmb_editor_code_add_split = CONTEXT.new(ctx_add_column, _add_window_split, _can_add_split, ICON_ADD_COLUMN)
		_rmb_editor_code_remove_split = CONTEXT.new(ctx_remove_split, _remove_window_split, _can_remove_split, ICON_REMOVE_COLUMN)

		_rmb_editor_pop_script = CONTEXT.new(ctx_pop_script, _make_pop_script, _can_make_pop_script, ICON_FLOATING)
		_rmb_editor_code_pop_script = CONTEXT.new(ctx_pop_script, _make_pop_script, _can_make_pop_script, ICON_FLOATING)

		_rmb_close_all_tab_in_split = CONTEXT.new(ctx_close_tabs, _close_all_tabs_in_split, _can_close_tab_in_split, ICON_TAB)
		_rmb_close_all_tab_in_split_left = CONTEXT.new(ctx_close_tabs_left, _close_all_tabs_in_split_left, _can_close_left_tab_in_split, ICON_TAB)
		_rmb_close_all_tab_in_split_right = CONTEXT.new(ctx_close_tabs_right, _close_all_tabs_in_split_right, _can_close_right_tab_in_split, ICON_TAB)
		
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _rmb_close_all_tab_in_split)
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _rmb_close_all_tab_in_split_left)
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _rmb_close_all_tab_in_split_right)
		

		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _rmb_editor_add_split)
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _rmb_editor_remove_split)

		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _rmb_editor_code_add_split)
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _rmb_editor_code_remove_split)
		
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _rmb_editor_pop_script)
		add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _rmb_editor_code_pop_script)

		if !settings.has_setting(&"plugin/script_spliter/rows"):
			settings.set_setting(&"plugin/script_spliter/rows", _rows)
		else:
			_rows = settings.get_setting(&"plugin/script_spliter/rows")
		if !settings.has_setting(&"plugin/script_spliter/columns"):
			settings.set_setting(&"plugin/script_spliter/columns", _columns)
		else:
			_columns = settings.get_setting(&"plugin/script_spliter/columns")
		if !settings.has_setting(&"plugin/script_spliter/save_rows_columns_count_on_exit"):
			settings.set_setting(&"plugin/script_spliter/save_rows_columns_count_on_exit", false)
		if !settings.has_setting(&"plugin/script_spliter/behaviour/refresh_warnings_on_save"):
			settings.set_setting(&"plugin/script_spliter/behaviour/refresh_warnings_on_save", _refresh_warnings_on_save)
		else:
			_refresh_warnings_on_save = settings.get_setting(&"plugin/script_spliter/behaviour/refresh_warnings_on_save")
	else:
		if is_in_group(&"ScriptSpliter"):
			remove_from_group(&"ScriptSpliter")
			
		main_screen_changed.disconnect(_on_change)
		resource_saved.disconnect(_on_save)

		if is_instance_valid(_rmb_close_all_tab_in_split):
			remove_context_menu_plugin(_rmb_close_all_tab_in_split)
		if is_instance_valid(_rmb_close_all_tab_in_split_right):
			remove_context_menu_plugin(_rmb_close_all_tab_in_split_right)
		if is_instance_valid(_rmb_close_all_tab_in_split_left):
			remove_context_menu_plugin(_rmb_close_all_tab_in_split_left)		
		
		if is_instance_valid(_rmb_editor_add_split):
			remove_context_menu_plugin(_rmb_editor_add_split)
		if is_instance_valid(_rmb_editor_remove_split):
			remove_context_menu_plugin(_rmb_editor_remove_split)
		if is_instance_valid(_rmb_editor_code_add_split):
			remove_context_menu_plugin(_rmb_editor_code_add_split)
		if is_instance_valid(_rmb_editor_code_remove_split):
			remove_context_menu_plugin(_rmb_editor_code_remove_split)
		if is_instance_valid(_rmb_editor_pop_script):
			remove_context_menu_plugin(_rmb_editor_pop_script)
		if is_instance_valid(_rmb_editor_code_pop_script):
			remove_context_menu_plugin(_rmb_editor_code_pop_script)


		if settings.has_setting(&"plugin/script_spliter/save_rows_columns_count_on_exit"):
			if settings.get_setting(&"plugin/script_spliter/save_rows_columns_count_on_exit") == true:
				settings.set_setting(&"plugin/script_spliter/rows", _rows)
				settings.set_setting(&"plugin/script_spliter/columns", _columns)

func _can_close_tab_in_split(_path : PackedStringArray) -> bool:
	return _builder.has_other_tabs()
	
func _can_close_right_tab_in_split(_path : PackedStringArray) -> bool:
	return _builder.has_right_tabs()
	
func _can_close_left_tab_in_split(_path : PackedStringArray) -> bool:
	return _builder.has_left_tabs()

func _close_all_tabs_in_split(__ : Variant) -> void:
	_builder.close_other_tabs()
	
func _close_all_tabs_in_split_right(__ : Variant) -> void:
	_builder.close_right_tabs()
	
func _close_all_tabs_in_split_left(__ : Variant) -> void:
	_builder.close_left_tabs()
	
func _can_add_split(path : PackedStringArray) -> bool:
	if !is_instance_valid(_builder):
		return false
	if path.size() == 0:
		return _builder.can_add_split(null)
	else:
		for x : String in path:
			if x.begins_with("res://"):
				var sc : ScriptEditor = EditorInterface.get_script_editor()
				return _builder.can_add_split(sc.get_current_editor().get_base_editor())
			else:
				var node : Node = get_node_or_null(x)
				if node:
					return _builder.can_add_split(node)
				else:
					var sc : ScriptEditor = EditorInterface.get_script_editor()
					return _builder.can_add_split(sc.get_current_editor().get_base_editor())
	return false

func _can_remove_split(path : PackedStringArray) -> bool:
	if !is_instance_valid(_builder):
		return false
	if path.size() == 0:
		return _builder.can_remove_split(null)
	else:
		for x : String in path:
			if x.begins_with("res://"):
				var sc : ScriptEditor = EditorInterface.get_script_editor()
				return _builder.can_remove_split(sc.get_current_editor().get_base_editor())
			else:
				var node : Node = get_node_or_null(x)
				if node:
					return _builder.can_remove_split(node)
				else:
					var sc : ScriptEditor = EditorInterface.get_script_editor()
					return _builder.can_remove_split(sc.get_current_editor().get_base_editor())
	return false

func _add_window_split(variant : Variant) -> void:
	var control : Control = null
	if variant is Script:
		var sc : ScriptEditor = EditorInterface.get_script_editor()
		if variant == sc.get_current_script():
			control = sc.get_current_editor().get_base_editor()
		else:
			var c : ScriptEditorBase = sc.get_current_editor()
			if c:
				control = c.get_base_editor()
	elif variant is CodeEdit:
		control = variant
	if is_instance_valid(control):
		_builder.add_split(control)

func _remove_window_split(variant : Variant) -> void:
	var control : Control = null
	if variant is Script:
		var sc : ScriptEditor = EditorInterface.get_script_editor()
		if variant == sc.get_current_script():
			control = sc.get_current_editor().get_base_editor()
		else:
			var c : ScriptEditorBase = sc.get_current_editor()
			if c:
				control = c.get_base_editor()
	elif variant is CodeEdit:
		control = variant
	if is_instance_valid(control):
		_builder.remove_split(control)

func _make_pop_script(variant : Variant) -> void:
	var control : Control = null
	if variant is Script:
		var sc : ScriptEditor = EditorInterface.get_script_editor()
		var arr : Array[ScriptEditorBase] = sc.get_open_script_editors()
		var scs : Array[Script] = sc.get_open_scripts()
		if arr.size() == scs.size():
			for y : int in range(0, scs.size(), 1):
				if scs[y] == variant:
					control = arr[y].get_base_editor()
					break
	if variant is CodeEdit:
		control = variant
	if is_instance_valid(control):
		_builder.make_pop_script(control)

func _can_make_pop_script(path : PackedStringArray) -> bool:
	if !is_instance_valid(_builder):
		return false
	for x : String in path:
		var node : Node = get_node_or_null(x)
		if node:
			return !_builder.is_pop_script(node)
	return false

func _on_change(screen_name : String) -> void:
	if screen_name == "Script":
		if is_instance_valid(_builder):
			_builder.update_rect.call_deferred()
	

func _enter_tree() -> void:
	_setup(1)
	if !is_instance_valid(_builder):
		_builder = BUILDER.new(self)
	add_tool_menu_item(CMD_MENU_TOOL, _on_tool_command)

func _on_tool_command() -> void:
	if is_instance_valid(_builder):
		var data : Array[int] = _builder.get_current_columns_and_rows()
		_columns = data[0]
		_rows = data[1]
	
	if !is_instance_valid(_menu_split_selector):
		_menu_split_selector = (ResourceLoader.load("res://addons/_Godot-IDE_/plugins/script_spliter/context/menu_tool.tscn") as PackedScene).instantiate()
		_menu_split_selector.set_plugin(self)
		_menu_split_selector.visible = false
		add_child(_menu_split_selector)
	_menu_split_selector.popup_centered.call_deferred()

func _ready() -> void:
	set_process(false)
	set_process_input(false)
	if !get_tree().root.is_node_ready():
		await get_tree().root.ready
	for __ : int in range(2):
		await get_tree().process_frame
	_run()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_builder) and !_builder.is_queued_for_deletion():
			_builder.init_0()
			_builder.free()

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		for x : InputEvent in _inputs:
			if event.is_match(x, true):
				var z : int = _inputs.find(x)
				if z > -1:
					var matched : Array = SPLIT_TYPES[z]
					set_type_split(matched[0], matched[1])
