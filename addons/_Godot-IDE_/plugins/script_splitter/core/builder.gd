@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const EditorManager = preload("./../core/editor/godot/manager.gd")
const BaseContainer = preload("./../core/base/container.gd")
const BaseList = preload("./../core/base/list.gd")

var _plugin : EditorPlugin = null
var _editor_manager : EditorManager = null


#region _REF_
var _item_list : ItemList = null:
	get:#
		if !is_instance_valid(_item_list):
			var script_editor: ScriptEditor = EditorInterface.get_script_editor()
			var items : Array[Node] = script_editor.find_children("*", "ItemList", true, false)
			if items.size() > 0:
				_item_list =  items[0]
			else:
				push_warning("[Script-Splitter] Can not find item list!")
		return _item_list
#endregion

func get_editor_manager() -> EditorManager:
	return _editor_manager

func handle(id : StringName) -> void:
	_editor_manager.io.execute(id)
	
func refresh_warnings() -> void:
	_editor_manager.refresh_warnings.execute()
	
func can_split(values : Variant) -> bool:
	var current : Node = null
	if values is PackedStringArray and values.size() > 0:
		var root : Node = _plugin.get_tree().root
		if root.has_node(values[0]):
			current = root.get_node(values[0])
	elif values is Node:
		current = values
	return _editor_manager.get_current_totaL_editors(current) > 1
	
func can_merge_column(values : Variant) -> bool:
	var current : Node = null
	if values is PackedStringArray and values.size() > 0:
		var root : Node = _plugin.get_tree().root
		if root.has_node(values[0]):
			current = root.get_node(values[0])
	elif values is Node:
		current = values
	return _editor_manager.get_current_total_splitters(current) > 1
	
func can_merge_row(_values : Variant) -> bool:
	return _editor_manager.get_total_split_container(true) > 1
	
func can_left_tab_close(values : Variant) -> bool:
	if values is PackedStringArray and values.size() > 0:
		var root : Node = _plugin.get_tree().root
		if root.has_node(values[0]):
			values = root.get_node(values[0])
		else:
			values = values[0]
	var node : Node = _editor_manager.get_control_tool_by_current(values)
	return node and node.get_index() > 0
	
func can_right_tab_close(values : Variant) -> bool:
	if values is PackedStringArray and values.size() > 0:
		var root : Node = _plugin.get_tree().root
		if root.has_node(values[0]):
			values = root.get_node(values[0])
		else:
			values = values[0]
	var node : Node = _editor_manager.get_control_tool_by_current(values)
	return node and node.get_index() < node.get_parent().get_child_count() - 1
	
func can_others_tab_close(values : Variant) -> bool:
	return can_left_tab_close(values) and can_right_tab_close(values)
	
func update(_delta : float) -> void:
	if _editor_manager.update():
		_plugin.set_process(false)
		
func multi_split(number : int, as_row : bool) -> void:
	var total : int = _editor_manager.get_current_total_splitters(null)
	if total == number:
		return
	var container : Node = _editor_manager.get_current_root()
	if !as_row:
		if total < number:
			number = number - total
			while number > 0:
				if !can_split(container):
					return
				_editor_manager.split_column.execute(container)
				number -= 1
		else:
			number = total - number
			while number > 0:
				if !can_merge_column(container):
					return
				_editor_manager.merge_tool.execute([_editor_manager.get_current_tool(container), false])
				number -= 1
	if !as_row:
		if total < number:
			number = number - total
			while number > 0:
				if !can_split(container):
					return
				_editor_manager.split_row.execute(container)
				number -= 1
		else:
			number = total - number
			while number > 0:
				if !can_merge_column(container):
					return
				_editor_manager.merge_tool.execute([_editor_manager.get_current_tool(container), true])
				number -= 1
	
func init_0() -> void:
	if is_instance_valid(_editor_manager):
		_editor_manager.reset()
	_editor_manager = null
	
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if editor.editor_script_changed.is_connected(_on_change):
			editor.editor_script_changed.disconnect(_on_change)
	
func _on_change(__ : Variant = null) -> void:
	_queue_update()
	
func connect_callbacks(
	on_column : Signal, 
	on_row : Signal, 
	out_column : Signal, 
	out_row : Signal, 
	left_tab_close : Signal, 
	right_tab_close : Signal, 
	others_tab_close : Signal,
	
	do_connect : bool = true) -> void:
	for x : Array in [
		[on_column, _editor_manager.split_column.execute],
		[on_row, _editor_manager.split_row.execute],
		[out_column, _editor_manager.unsplit_column],
		[out_row, _editor_manager.unsplit_row],
		[left_tab_close, _editor_manager.left_tab_close],
		[right_tab_close, _editor_manager.right_tab_close],
		[others_tab_close, _editor_manager.others_tab_close]
		]:
		if !x[0].is_null():
			if do_connect:
				if !x[0].is_connected(x[1]):
					x[0].connect(x[1])
			else:
				if x[0].is_connected(x[1]):
					x[0].disconnect(x[1])
func _nws() -> void:
	print("[Script Splitter] New Splitter System!\nNow use controls in toolbar for split columns and rows as you like!\nPlease provide feedback on the Github issues tab [https://github.com/CodeNameTwister/Script-Splitter]")
	
func swap_by_src(from : String, to : String, as_left : bool) -> void:
	_editor_manager.swap_tab.execute([from, to, as_left])
	
func reset_by_control(control : Node) -> void:
	if _editor_manager:
		_editor_manager.reset_by_control(control)
	
func _clean_settings() -> void:
	var e : EditorSettings = EditorInterface.get_editor_settings()
	if e.has_setting("plugin/script_spliter/rows"):
		_nws()
		e.set_setting("plugin/script_spliter/rows", null)
		e.set_setting("plugin/script_spliter/columns", null)
		e.set_setting("plugin/script_spliter/save_rows_columns_count_on_exit", null)
		e.set_setting("plugin/script_spliter/window/use_highlight_selected", null)
		e.set_setting("plugin/script_spliter/window/highlight_selected_color", null)
		e.set_setting("plugin/script_spliter/editor/split/reopen_last_closed_editor_on_add_split", null)
		e.set_setting("plugin/script_spliter/editor/split/remember_last_used_editor_buffer_size", null)
		e.set_setting("plugin/script_spliter/behavior/auto_create_split_by_config", null)
		e.set_setting("plugin/script_spliter/editor/list/colorize_actives", null)
		
		for x : String in [
			"plugin/script_spliter/behaviour/refresh_warnings_on_save"
			,"plugin/script_spliter/editor/out_focus_color_value"
			,"plugin/script_spliter/editor/out_focus_color_enabled"
			,"plugin/script_spliter/editor/minimap_for_unfocus_window"
			,"plugin/script_spliter/editor/behaviour/expand_on_focus"
			,"plugin/script_spliter/editor/behaviour/can_expand_on_same_focus"
			,"plugin/script_spliter/editor/behaviour/smooth_expand"
			,"plugin/script_spliter/editor/behaviour/smooth_expand_time"
			,"plugin/script_spliter/editor/behaviour/swap_by_double_click_separator_button"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/handle_back_and_forward"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/history_size"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/using_as_next_and_back_tab"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/use_native_handler_when_there_are_no_more_tabs"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/backward_key_button_input"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/forward_key_button_input"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/backward_mouse_button_input"
			,"plugin/script_spliter/editor/behaviour/back_and_forward/forward_mouse_button_input"
			,"plugin/script_spliter/editor/list/selected_color"
			,"plugin/script_spliter/editor/list/others_color"
			,"plugin/script_spliter/editor/tabs/use_old_behaviour"
			,"plugin/script_spliter/line/size"
			,"plugin/script_spliter/line/color"
			,"plugin/script_spliter/line/draggable"
			,"plugin/script_spliter/line/expand_by_double_click"
			,"plugin/script_spliter/line/button/size"
			,"plugin/script_spliter/line/button/modulate"
			,"plugin/script_spliter/behavior/create_all_open_editors"
			]:
			
			if e.has_setting(x):
				e.set_setting(x.replace("/script_spliter/", "/script_splitter/"), e.get_setting(x))
				e.set_setting(x, null)
				
		for x : int in range(1, 11, 1):
			e.set_setting(str("plugin/script_spliter/input/split_type_" , x), null)
		
		#for x : int in range(1, 11, 1):
			#e.set_setting(str("plugin/script_splitter/input/split_type_" , x), null)
		
	
func init_1(plugin : EditorPlugin, tab_container : TabContainer, item_list : ItemList) -> void:
	if !is_instance_valid(plugin) or !is_instance_valid(tab_container):
		printerr("Error, can`t initalize plugin, not valid references!")
		return
		
	_clean_settings()
	_plugin = plugin
	_plugin.set_process(true)
	
	_editor_manager = EditorManager.new(BaseContainer.new(tab_container), BaseList.new(item_list))
	_editor_manager.update_request.connect(_queue_update)
	
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if !editor.editor_script_changed.is_connected(_on_change):
			editor.editor_script_changed.connect(_on_change)
	
func _queue_update() -> void:
	_plugin.set_process(true)
