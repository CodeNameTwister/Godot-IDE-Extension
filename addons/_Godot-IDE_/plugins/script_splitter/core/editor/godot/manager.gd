@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const CreateTool = preload("./../../../core/editor/application/create_tool.gd")
const UpdateMetadata = preload("./../../../core/editor/application/update_metadata.gd")
const FocusTool = preload("./../../../core/editor/application/focus_tool.gd")
const SelectByIndex = preload("./../../../core/editor/application/select_by_index.gd")
const FocusByTab = preload("./../../../core/editor/application/focus_by_tab.gd")
const ReparentTool = preload("./../../../core/editor/application/reparent_tool.gd")
const MergeTool = preload("./../../../core/editor/application/merge_tool.gd")
const SplitColumn = preload("./../../../core/editor/application/split_column.gd")
const SplitRow = preload("./../../../core/editor/application/split_row.gd")
const RemoveByTab = preload("./../../../core/editor/application/remove_by_tab.gd")
const RefreshWarnings = preload("./../../../core/editor/application/refresh_warnings.gd")
const UpdateListSelection = preload("./../../../core/editor/application/update_list_selection.gd")
const SwapTab = preload("./../../../core/editor/application/swap_tab.gd")
const RmbMenu = preload("./../../../core/editor/application/rmb_menu.gd")
const UserTabClose = preload("./../../../core/editor/application/user_tab_close.gd")
const Io = preload("./../../../core/editor/application/io.gd")
const CustomSplit = preload("./../../../core/editor/application/custom_split.gd")

const ToolDB = preload("./../../../core/editor/database/tool_db.gd")
const Task = preload("./../../../core/editor/coroutine/task.gd")

const BaseContainer = preload("./../../../core/base/container.gd")
const BaseList = preload("./../../../core/base/list.gd")


signal update_request()

# API
var split_column : SplitColumn = null
var split_row : SplitRow = null
var refresh_warnings : RefreshWarnings = null
var merge_tool : MergeTool = null

# APPLICATION
var _create_tool : CreateTool = null
var _focus_tool : FocusTool = null
var _update_metadata : UpdateMetadata = null
var _select_by_index : SelectByIndex = null
var _focus_by_tab : FocusByTab = null
var _remove_by_tab : RemoveByTab = null
var _reparent_tool : ReparentTool = null
var _update_list_selection : UpdateListSelection = null
var _rmb_menu : RmbMenu = null
var _user_tab_close : UserTabClose = null
var _custom_split : CustomSplit = null

var io : Io = null
var swap_tab : SwapTab = null

# DB
var _tool_db : ToolDB = null

# REF
var _base_container : BaseContainer = null
var _base_list : BaseList = null
var _task : Task = null

func _app_setup() -> void:
	_task = Task.new()
	_tool_db = ToolDB.new()
	
	_focus_tool = FocusTool.new(self, _tool_db)
	_update_metadata = UpdateMetadata.new(self, _tool_db)
	_create_tool = CreateTool.new(self, _tool_db)
	_select_by_index = SelectByIndex.new(self, _tool_db)
	_focus_by_tab = FocusByTab .new(self, _tool_db)
	_reparent_tool = ReparentTool.new(self, _tool_db)
	merge_tool = MergeTool.new(self, _tool_db)
	_remove_by_tab = RemoveByTab.new(self, _tool_db)
	_update_list_selection = UpdateListSelection.new(self, _tool_db)
	swap_tab = SwapTab.new(self, _tool_db)
	_rmb_menu = RmbMenu.new(self, _tool_db)
	_user_tab_close = UserTabClose.new(self, _tool_db)
	_custom_split = CustomSplit.new(self, _tool_db)
	
	io = Io.new(self, _tool_db)
	
	split_column = SplitColumn.new(self, _tool_db)
	split_row = SplitRow.new(self, _tool_db)
	refresh_warnings = RefreshWarnings.new(self, _tool_db)
	
	_base_list.update_selections_callback = _update_list_selection.execute
	
func update_list(__ : Variant) -> void:
	_base_list.update_list_selection()	
	
func get_current_tool(ref : Node = null) -> ToolDB.MickeyTool:
	if ref == null:
		ref = _base_container.get_current_container()
	return _tool_db.get_by_reference(ref)

func _init(base_container : BaseContainer, base_list : BaseList) -> void:
	_base_container = base_container
	_base_list = base_list
	
	#_base_list.set_handler(self)
#	
	_base_list.updated.connect(update_all_metadata)
	_base_list.item_selected.connect(_on_item_selected)
	_base_list.move_item.connect(_move_item_list)
	_base_container.update.connect(update_metadata)
	_base_container.focus_by_tab.connect(_on_focus_tab)
	_base_container.remove_by_tab.connect(_on_remove_tab)
	
	_base_container.swap_tab.connect(_onswap_tab)
	_base_container.same_swap_tab.connect(_on_same_swap_tab)
	_base_container.change_container.connect(update_list)

	_base_container.rmb_click.connect(_on_tab_rmb)
	
	_base_container.exiting.connect(_on_exiting)

	_app_setup()
	
func _on_exiting() -> void:
	_tool_db.clear()
	
func get_total_editors() -> int:
	var container : Control = _base_container.get_current_container()
	if is_instance_valid(container):
		return container.get_child_count()
	return 0
	
func get_current_totaL_editors(current : Node) -> int:
	var container : Control = null
	
	if current == null:
		container = _base_container.get_current_container()
	elif current is Node:
		container = _tool_db.get_by_reference(current).get_root()
		
	if is_instance_valid(container):
		return container.get_child_count()
	return 0
	
func get_total_split_container(by_row : bool) -> int:
	if by_row:
		var rows : Array = []
		for x : Node in _base_container.get_all_containers():
			var parent : Node = x.get_parent()
			if parent:
				if !rows.has(parent):
					rows.append(parent)
		return rows.size()
	else:
		return _base_container.get_all_containers().size()
	
func get_total_splitters() -> int:
	return _base_container.get_all_splitters().size()
	
func get_current_total_splitters(current : Node) -> int:
	if current is CodeEdit:
		var container : Control = null
		var value : ToolDB.MickeyTool = _tool_db.get_by_reference(current)
		if is_instance_valid(value) and value.is_valid():
			container = _base_container.get_container(value.get_root())
		if is_instance_valid(container):
			return container.get_child_count()
		return 0
	return _base_container.get_current_splitters().size()
	
func clear() -> void:
	_tool_db.clear()
	
func reset_by_control(control : Node) -> void:	
	var tls : Array[ToolDB.MickeyTool] = []
	for x : ToolDB.MickeyTool in _tool_db.get_tools():
		if x.is_valid():
			if control.find_child(x.get_control().name, true, false):
				tls.append(x)
			
	for t : ToolDB.MickeyTool in tls:
		t.reset()
	
func reset() -> void:	
	_tool_db.clear()
	
	_base_container.reset()
	_base_list.reset()
	
func _onswap_tab(from : Container, index : int, to : Container) -> void:
	swap_tab.execute([from, index, to])
	
func _on_same_swap_tab(from : Container, index : int, type : StringName) -> void:
	_custom_split.execute([from, index, type])
	
func _on_focus_tab(tab : TabContainer, index : int) -> void:
	_focus_by_tab.execute([tab, index])
	
func _on_remove_tab(tab : TabContainer, index : int) -> void:
	_remove_by_tab.execute([tab, index])
	
func _on_item_selected(i : int) -> void:
	_select_by_index.execute(i)
	
func is_valid_item_index(index : int) -> bool:
	return index > -1 and _base_list.item_count() > index and !_base_list.get_item_tooltip(index).is_empty() and !_base_list.get_item_text(index).is_empty()

func update() -> bool:
	if !_base_container.has_method(&"is_active") or !_base_container.is_active():
		return false
		
	_task.update()
	_tool_db.garbage(1)
	
	var update_required : bool = false
	for x : Node in _base_container.get_editors():
		update_required = !_create_tool.execute(x) || update_required
			
	_tool_db.garbage(0)
	_base_container.garbage()
	
	_select_by_index.execute(_base_list.get_selected_id())

	_update_root()
	
	_base_container.update_split_container()
	_base_list.update_list()
	return !update_required

# API
func set_symbol(__ : String) -> void:
	var tl : ToolDB.MickeyTool = _tool_db.get_tool_id(_base_list.get_selected_id())
	if is_instance_valid(tl):
		_focus_tool.execute(tl)
		var gui : Node = tl.get_gui() 
		if gui is CodeEdit:
			_center.call_deferred(gui)
		else:
			for x : Node in gui.get_children():
				if x is RichTextLabel:
					_center.call_deferred(x)
	
func _center(gui : Variant) -> void:
	if is_instance_valid(gui):
		if gui is CodeEdit:
			if gui.get_caret_count() > 0:
				gui.scroll_vertical = gui.get_scroll_pos_for_line(maxi(gui.get_caret_line(0) - 1, 0))
				gui.center_viewport_to_caret.call_deferred(0)

func unsplit_column(current : Variant) -> void:
	if merge_tool.execute([current, false]):
		update_request.emit()
	
func unsplit_row(current : Variant) -> void:
	if merge_tool.execute([current, true]):
		update_request.emit()

func move_tool(control : Control, index : int) -> bool:
	return _reparent_tool.execute([control, index])
	
func get_current_root() -> Control:
	return _base_container.get_current_editor()
	
func get_editor_list() -> BaseList:
	return _base_list
	
func get_base_container() -> BaseContainer:
	return _base_container
	
func get_editor_container() -> TabContainer:
	return _base_container.get_editor_container()

func select_editor_by_index(index : int) -> void:
	_base_list.select(index)
	
func focus_tool(mk : Variant) -> void:
	_focus_tool.execute(mk)

func tool_created() -> void:
	_base_container.tool_created()
	
func update_metadata(mk : Variant = null) -> void:
	_task.add(_update_metadata.execute.bind(mk))
	update_request.emit()
	
func update_all_metadata() -> void:
	if !_task.has(_update_metadata.execute):
		_task.add(_update_metadata.execute)
		update_request.emit()

func clear_editors() -> void:
	if !_task.has(_clear_editor):
		_task.add(_clear_editor)
		update_request.emit()

func _clear_editor() -> void:
	var spls : Array[Node] = _base_container.get_all_splitters()
	var total : int = spls.size()
	
	if total > 1:
		total = 0
		for x : Node in spls:
			if is_instance_valid(x):
				if x.is_queued_for_deletion():
					continue
				total += 1
				
		if total > 1:
			for x : Node in spls:
				if x.get_child_count() == 0:
					if total < 2:
						return
						
					var c : Node = _base_container.get_container_item(x)
					if c and !c.is_queued_for_deletion():
						var container : Node = _base_container.get_container(x)
						if container and container.get_child_count() < 2:
							container.get_parent().queue_free()
						c.queue_free()
						total -= 1
	
func _update_root() -> void:
	var root : Control = _base_container.get_root_container()
	
	if root:
		var v : bool = false
		var nodes : Array[Node] = root.get_tree().get_nodes_in_group(&"__SP_IC__")
		var total : int = nodes.size()
		for x : Node in nodes:
			if total < 2:
				break
			if x.get_child_count() == 0:
				x.queue_free()
				total -= 1
			else:
				if x.get_child(0).get_child_count() == 0:
					x.queue_free()
					total -= 1
	
		for x : Node in _base_container.get_all_splitters():
			if x.get_child_count() > 0:
				v = true
				break
		root.get_parent().visible = v
		
func get_control_tool_by_current(current : Variant) -> Node:
	var root : Node = null
	if null == current or current is PackedStringArray and current.size() == 0:
		current = get_base_container().get_current_container()
		if current is TabContainer:
			var i : int = current.current_tab
			if i > -1:
				current = current.get_child(i)
	if current:
		if current is String:
			for x : int in _base_list.item_count():
				if current == _base_list.get_item_tooltip(x):
					var mk : ToolDB.MickeyTool = _tool_db.get_tool_id(x)
					if mk:
						root = mk.get_control()
						break
		elif current is Node:
			for x : ToolDB.MickeyTool in _tool_db.get_tools():
				if x.has(current):
					root = x.get_control()
					break
	return root
	
func _on_tab_rmb(index : int, tab : TabContainer) -> void:
	_rmb_menu.execute([index, tab])
	
func left_tab_close(value : Variant) -> void:
	_user_tab_close.execute([value, -1])
	
func right_tab_close(value : Variant) -> void:
	_user_tab_close.execute([value, 1])
	
func others_tab_close(value : Variant) -> void:
	_user_tab_close.execute([value, 0])

func _move_item_list(from : int, to : int) -> void:
	move_item_container(null, from, to)

func move_item_container(container : TabContainer, from : int, to : int) -> void:
	var vfrom : int = -1
	var vto : int = -1
	
	if container == null:
		vfrom = from
		vto = to
	else:
		for x : ToolDB.MickeyTool in _tool_db.get_tools():
			if x.get_root() == container:
				var _idx : int = x.get_control().get_index()
				if _idx == from:
					vfrom = x.get_index()
				elif _idx == to:
					vto = x.get_index()
	
	if vfrom == -1 or vto == -1:
		return
		
	_base_container.move_container(vfrom, vto)
