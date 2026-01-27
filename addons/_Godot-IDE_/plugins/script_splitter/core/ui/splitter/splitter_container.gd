@tool
extends MarginContainer 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const SplitterRoot = preload("./../../../core/ui/splitter/splitter_root.gd")
const HandlerContainer = preload("./../../../core/base/container.gd")
const BaseContainerItem = preload("splitter_item.gd")

const SplitterEditorContainer = preload("./../../../core/ui/splitter/splitter_editor_container.gd")

const Overlay = preload("./../../../core/ui/splitter/taby/overlay.gd")
const CODE_NAME_TWISTER = preload("./../../../assets/github_CodeNameTwister.svg")

var _handler_container : HandlerContainer = null
var _base_container : TabContainer = null

var _root : Container = null
var _root_container : SplitterRoot = null

var _last_editor_container : SplitterEditorContainer.Editor = null

var _overlay : Overlay = null

var swap_by_button : bool = true

func get_root() -> SplitterRoot:
	return _root_container

func get_base_editors() -> Array[Node]:
	if is_instance_valid(_base_container):
		return _base_container.get_children()
	return []
	
func initialize(container : TabContainer, handler_container : HandlerContainer) -> void:
	_setup()
	
	_handler_container = handler_container
	_base_container = container

	_root = self
	
	var credits : TextureRect = TextureRect.new()
	add_child(credits)
	
	credits.texture = CODE_NAME_TWISTER
	credits.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credits.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	credits.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	credits.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	credits.modulate.a = 0.25
	
	if is_instance_valid(_base_container):
		var root : Node = _base_container.get_parent()
		root.add_child(_root)
		root.move_child(_root, mini(_base_container.get_index(), 0))
	
	#_root.add_child(_root_container)
	
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vspl : HBoxContainer = HBoxContainer.new()	
	
	_root.add_child(vspl)
	vspl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vspl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var base : SplitterRoot = create_base_container(vspl, false)
	base.max_columns = 1
	_root_container = base
	
	var io : Node = _handler_container.get_io_bar()
	if io.get_parent() == null:
		vspl.add_child(io)
	else:
		io = HandlerContainer.IoBar.new()
		io.enable_vertical_split = false
		vspl.add_child(io)
		
	initialize_editor_contianer()
	
	_overlay = Overlay.new()
	add_child(_overlay)
	
func _on_change() -> void:
	var dt : Array = ["plugin/script_splitter/editor/behaviour/swap_by_double_click_separator_button"]
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var changes : PackedStringArray = settings.get_changed_settings()
	
	for c in changes:
		if c in dt:
			_setup()
			break
	
func _setup() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if !settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.connect(_on_change)
	
	for x : Array in [
		["swap_by_button", "plugin/script_splitter/editor/behaviour/swap_by_double_click_separator_button"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))
	
func initialize_editor_contianer() -> void:	
	if _root_container.get_child_count() > 0:
		for x : Node in _root_container.get_children():
			x.queue_free()
	_last_editor_container = create_new_editor_container(_root_container, true)
	
func swap(value : Variant) -> void:
	if !swap_by_button:
		return
		
	if !is_instance_valid(value):
		return
		
	elif !is_instance_valid(_root_container) or _root_container.get_child_count() == 0:
		return
	
	elif !value is SplitterRoot.LineSep:
		return
		
	var caller : SplitterRoot.LineSep = value
		
	var _main : SplitterRoot = caller.get_parent()
	
	if !is_instance_valid(_main):
		return
		
	var separators : Array = _main.get_separators()
	if separators.size() == 0:
		return
		
	var index : int = 0
	var linesep : Object = null
	for x : Object in separators:
		if x == caller:
			linesep =x
			break
		index += 1
		
	if linesep:
		if linesep.is_vertical:
			var atotal : int = 1
			var btotal : int = 1
			var nodes : Array[Node] = []
			
			for x : int in range(index + 1, separators.size(), 1):
				var clinesep : Object = separators[x]
				if clinesep.is_vertical:
					break
				atotal += 1
			for x : int in range(index - 1, -1, -1):
				var clinesep : Object = separators[x]
				if clinesep.is_vertical:
					break
				btotal += 1
			
			var cindex : int = index
			while atotal > 0:
				cindex += 1
				atotal -= 1
				if cindex < _main.get_child_count():
					nodes.append(_main.get_child(cindex))
					continue
				break
				
			for x : Node in nodes:
				cindex = btotal
				while cindex > 0:
					cindex -= 1
					var idx : int = x.get_index() - 1
					if _main.get_child_count() > idx:
						_main.move_child(x, idx)
		else:
			index += 1
			if _main.get_child_count() > index:
				var child : Node = _main.get_child(index - 1)
				_main.move_child(child, index)

func _enter_tree() -> void:
	add_to_group(&"ScriptSplitter")
	
func _exit_tree() -> void:
	remove_from_group(&"ScriptSplitter")
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.disconnect(_on_change)

	
func dragged(tab : TabBar, is_drag : bool) -> void:
	if is_instance_valid(_overlay):
		if is_drag:
			_overlay.start(tab)
		else:
			if _overlay.stop(tab):
				var container : Node = _overlay.get_container()
				var from : Container = tab.get_parent()
				if is_instance_valid(container) and is_instance_valid(from):
					if from != container:
						_handler_container.swap_tab.emit(from, tab.current_tab, container)
					else:
						var type : StringName = _overlay.get_type_split()
						if !type.is_empty():
							_handler_container.same_swap_tab.emit(from, tab.current_tab, type)
			
func create_new_column() -> SplitterEditorContainer.Editor:
	var item : BaseContainerItem = get_base_container_item(_last_editor_container)
	var root : Container = get_base_container(_last_editor_container)
	var index : int = item.get_index()
	var custom_position : bool = index >= 0 and index < item.get_parent().get_child_count() - 1
	_last_editor_container = create_editor_container(create_base_container_item(root))
	if custom_position:
		root.move_child(get_base_container_item(_last_editor_container), index + 1)
	return _last_editor_container
	
func create_new_row() -> SplitterEditorContainer.Editor:
	var root : Container = get_base_container(_last_editor_container)
	var index : int = root.get_index()
	var custom_position : bool = index >= 0 and index < root.get_parent().get_child_count() - 1
	_last_editor_container = create_new_editor_container(_root_container)# create_editor_container(create_base_container_item(create_base_container(_root_container)))
	if custom_position:
		_root_container.move_child(get_base_container(_last_editor_container).get_parent(), index + 1)
	return _last_editor_container
	

func set_current_editor(container : Node) -> bool:
	if container is SplitterEditorContainer.Editor:
		_last_editor_container = container
		return true
	return false
	
func get_base_container(editor : SplitterEditorContainer.Editor) -> Container:
	return editor.get_node("./../../../")
	
func get_base_container_item(editor : SplitterEditorContainer.Editor) -> BaseContainerItem:
	return editor.get_node("./../../")
	
func create_base_container(c_root : Node, _add_to_group : bool = true) -> Container:
	var b_root : Container = SplitterRoot.new()
	b_root.max_columns = 0
	c_root.add_child(b_root)
	b_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if _add_to_group:
		b_root.add_to_group(&"__SP_BR__")
		
	return b_root
		

func create_base_container_item(c_root : Container) -> BaseContainerItem:
	var b_item : BaseContainerItem = BaseContainerItem.new()
	c_root.add_child(b_item)
	
	b_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	return b_item
	
func create_editor_container(c_root : BaseContainerItem) -> SplitterEditorContainer.Editor:
	var b_editor : SplitterEditorContainer = SplitterEditorContainer.new()
	
	c_root.add_child(b_editor)
	b_editor.get_editor()
	
	var editor : SplitterEditorContainer.Editor = b_editor.get_editor()
	
	editor.focus.connect(_handler_container.on_focus)
	editor.remove.connect(_handler_container.on_remove)
	
	editor.get_tab_bar().tab_rmb_clicked.connect(_on_rmb_clicked.bind(editor))
	return editor
	
func _on_rmb_clicked(index : int, tab : Variant) -> void:
	if tab is SplitterEditorContainer.Editor:
		_handler_container.rmb_click.emit(index, tab)
	
func create_new_editor_container(c_root : Node, _add_to_group : bool = true) -> SplitterEditorContainer.Editor:
	return create_editor_container(create_base_container_item(create_base_container(c_root, _add_to_group)))

func get_current_editor() -> SplitterEditorContainer.Editor:
	return _last_editor_container

func reset() -> void:
	_root.queue_free()
	if is_instance_valid(_base_container):
		_base_container.visible = true
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.disconnect(_on_change)

func notify_creation() -> void:
	if is_instance_valid(_base_container) and  _base_container.visible:
		_base_container.visible = false
