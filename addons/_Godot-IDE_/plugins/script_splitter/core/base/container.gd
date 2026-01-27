@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const SplitterContainer = preload("./../../../script_splitter/core/ui/splitter/splitter_container.gd")
const NControl = preload("./../../core/util/control.gd")

const IoBar = preload("./../../core/ui/splitter/io/io_bar.gd")

signal update()
signal focus_by_tab(root : TabContainer, index : int)
signal remove_by_tab(root : TabContainer, index : int)
signal change_container(container : TabContainer)
signal exiting()

@warning_ignore("unused_signal")
signal rmb_click(index : int, TabContainer)

@warning_ignore("unused_signal")
signal swap_tab(from : Container, index : int, to : Container)
@warning_ignore("unused_signal")
signal same_swap_tab(from : Container, index : int, type : StringName)

var _editor_container : TabContainer = null
var _editor_splitter_container : SplitterContainer = null

var _current_container : TabContainer = null:
	set(e):
		if _current_container != e:
			change_container.emit(e)
		_current_container = e
		
var _frm : int = 0

var _io_bar : Node = null

func on_focus(root : TabContainer, index : int) -> void:
	focus_by_tab.emit(root, index)
	
func on_remove(root : TabContainer, index : int) -> void:
	remove_by_tab.emit(root, index)
	
func get_io_bar() -> IoBar:
	if !is_instance_valid(_io_bar):
		_io_bar = IoBar.new()
	return _io_bar	

func get_container(control : Control) -> Container:
	if control is SplitterContainer.SplitterEditorContainer.Editor:
		return _editor_splitter_container.get_base_container(control)
	return null
	
func get_container_item(control : Control) -> Control:
	if control is SplitterContainer.SplitterEditorContainer.Editor:
		return _editor_splitter_container.get_base_container_item(control)
	return null

func _init(container : TabContainer) -> void:
	_editor_container = container
	_editor_splitter_container = SplitterContainer.new()
	_editor_splitter_container.initialize(_editor_container, self)
	_editor_splitter_container.visible = false
	
	_editor_container.child_entered_tree.connect(_on_update)
	_editor_container.child_exiting_tree.connect(_on_update)

	_editor_container.tree_exiting.connect(_on_exiting)

	
func is_active() -> bool:
	if _frm > 0:
		_frm -= 1
		return false
	return is_instance_valid(_editor_container) and _editor_container.is_inside_tree()
	
func _on_exiting() -> void:
	_frm = 3
	exiting.emit()

func initialize_editor_container() -> void:
	_editor_splitter_container.initialize_editor_contianer()

func _on_update(__ : Node) -> void:
	update.emit()
	
func set_current_container(container : TabContainer) -> void:
	if _editor_splitter_container.set_current_editor(container):
		_current_container = container
	
func get_editor_container() -> TabContainer:
	return _editor_container
	
func get_root_container() -> SplitterContainer.SplitterRoot:
	return _editor_splitter_container.get_root()
	
func get_editor_root_container(node : Node) -> SplitterContainer.BaseContainerItem:
	if node is SplitterContainer.SplitterRoot:
		node = node.get_parent()
		return node
	return null
	
func get_editors() -> Array[Node]:
	return _editor_container.get_children()

func get_current_editor() -> Control:
	return _editor_splitter_container.get_current_editor()

func tool_created() -> void:
	_editor_container.visible = false
	_editor_splitter_container.visible = true
	
func new_column() -> Control:
	_current_container = _editor_splitter_container.create_new_column()
	return _current_container
	
func new_row() -> Control:
	_current_container = _editor_splitter_container.create_new_row()
	return _current_container
	
func update_split_container() -> void:
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__ST_CS__"):
		if x.has_method(&"update"):
			x.call(&"update")
	
func get_all_containers() -> Array[Node]:
	if !_editor_splitter_container:
		return []
	return _editor_splitter_container.get_tree().get_nodes_in_group(&"__SP_BR__")
	
func get_current_containers() -> Array[Node]:
	if !is_instance_valid(_current_container):
		return []
	var c : Control = _editor_splitter_container.get_base_container(_current_container)
	if is_instance_valid(c):
		return c.get_children()
	return []
	
func get_all_splitters() -> Array[Node]:
	if !_editor_splitter_container:
		return []
	return _editor_splitter_container.get_tree().get_nodes_in_group(&"__SC_SPLITTER__")
	
func get_current_splitters() -> Array[Node]:
	if !is_instance_valid(_current_container):
		return []
	var c : Control = _editor_splitter_container.get_base_container_item(_current_container)
	if is_instance_valid(c):
		c = c.get_parent()
		if c:
			return c.get_children()
	return []
	
func garbage() -> void:
	var control : Node = get_current_editor()
	
	var nodes : Array[Node] = get_all_splitters()
	var total : int = nodes.size()
	if total > 2:
		total = 0
		for x : Node in nodes:
			if !x.is_queued_for_deletion():
				total += 1
		
		if total > 1:
			for x : Node in nodes:
				if total < 2:
					break
				if x.get_child_count() == 0:
					if control == x:
						control = null
					if !x.is_queued_for_deletion():
						x.queue_free()
						total -= 1
			
	if control == null:
		for x : Node in _editor_splitter_container.get_tree().get_nodes_in_group(&"__SC_SPLITTER__"):
			if x is Control and !x.is_queued_for_deletion():
				control = x
				break
	
func reset() -> void:
	_editor_container.visible = true
	
	if _editor_container.child_entered_tree.is_connected(_on_update):
		_editor_container.child_entered_tree.disconnect(_on_update)
	if _editor_container.child_exiting_tree.is_connected(_on_update):
		_editor_container.child_exiting_tree.disconnect(_on_update)
	
	_editor_splitter_container.reset()
	_editor_splitter_container.queue_free()

func get_current_container() -> TabContainer:
	return _current_container

func move_container(from : int, to : int) -> bool:
	if _editor_container.get_child_count() > from and from > -1:
		_editor_container.move_child(_editor_container.get_child(from), to)
		return true
	return false
