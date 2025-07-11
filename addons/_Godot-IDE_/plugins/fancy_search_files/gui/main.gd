@tool
extends Window
# =============================================================================	
# Author: Twister
# Fancy Search Files
#
# Addon for Godot
# =============================================================================	


@export var _container : TabContainer = null
@export var _tree : Tree = null
@export var _tree_recents : Tree = null

var files : Dictionary[StringName, PackedStringArray] = {}

var _first_time : bool = false

var _recents : PackedStringArray = []

var _default_tx : Texture2D = null

func _enter_tree() -> void:
	_first_time = true
	
	var screen : Vector2 = DisplayServer.screen_get_size()
	var value : Variant = IDE.get_config("fancy_search_files", "size")
	if value is Vector2 or value is Vector2i:
		screen = value
	else:
		screen = screen * 0.6
	IDE.clamp_screen_size(screen, 0.3, 1.0)	
	size = screen

func _ready() -> void:
	update()
	for x : int in range(1, _container.get_child_count(), 1):
		_container.get_child(x).queue_free()
	visibility_changed.connect(_on_visible)
	_container.tab_changed.connect(_on_change)
	_tree.item_activated.connect(_on_activate.bind(_tree))
	_tree_recents.item_activated.connect(_on_activate.bind(_tree_recents))
	
	var result : Variant = IDE.get_file_config_value("fancy_search_files", "recents")
	if result is PackedStringArray:
		_recents = result
		
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return
	get_child(0). add_theme_stylebox_override(&"panel", control.get_theme_stylebox(&"panel", &""))
	
func _save() -> void:
	IDE.set_file_config_value("fancy_search_files", "recents", _recents)
	
func _on_visible() -> void:
	if visible:
		update()
	else:
		_save()
		queue_free()
		
func clear() -> void:
	_recents.clear()
	_tree_recents.clear()
	
func _on_activate(tree : Tree) -> void:
	if !tree:
		return
		
	var item : TreeItem = tree.get_selected()
	
	if !item:
		return
	
	var value : Variant = item.get_metadata(0)
	if value is String:
		if FileAccess.file_exists(value):
			EditorInterface.select_file(value)
			if ResourceLoader.exists(value):
				var res : Resource = ResourceLoader.load(value)
				if !(value in _recents):
					while _recents.size() > 30:
						_recents.remove_at(0)
					_recents.append(value)
				if res is Resource:
					if res is PackedScene:
						EditorInterface.open_scene_from_path(value)
					elif res is Script:
						EditorInterface.edit_script(res)
					else:
						EditorInterface.edit_resource(res)
	hide()
	
func _on_change(_tab_changed : int) -> void:
	var control : Control = _container.get_current_tab_control()
	if control:
		_update_tree(control.name)
		
func _exit_tree() -> void:
	if is_instance_valid(_tree):
		_tree.clear()
	IDE.set_config("fancy_search_files", "size", size)
		
func close() -> void:
	hide()
		
func get_icon(type : String) -> Texture2D:
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return null
	var icon : Texture2D = control.get_theme_icon(type, "EditorIcons")
	
	if icon == _default_tx:
		icon = control.get_theme_icon("File", "EditorIcons")
	return icon
			
func _update_tree(filter : StringName) -> void:
	_tree.clear()
	if files.size() == 0:
		return
	
	if filter == &"All":
		var root : TreeItem = _tree.create_item()
		root.set_selectable(0, false)
		for k : StringName in files.keys():
			var item : TreeItem = root.create_child()
			var icon : Texture2D = get_icon(k)
			item.set_text(0, k)
			item.set_icon_modulate(0, Color.WHITE)
			item.set_selectable(0, false)
			item.collapsed = true
			item.set_icon(0, icon)
			for f : String in files[k]:
				var fitem : TreeItem = item.create_child()
				var slice : int = f.get_slice_count("/")
				if slice > 5:
					var txt : String = ""
					for x : int in range(slice - 1, 3, -1):
						txt = f.get_slice("/", x).path_join(txt)
					txt = "...".path_join(txt)
					fitem.set_text(0, txt)
				else:
					fitem.set_text(0, f)
				fitem.set_icon(0, icon)
				fitem.set_metadata(0, f)
				fitem.set_icon_modulate(0, Color.GRAY)
				fitem.set_custom_color(0, Color.GRAY)
				fitem.set_tooltip_text(0, f)
	elif files.has(filter):
		var root : TreeItem = _tree.create_item()
		var item : TreeItem = root.create_child()
		var icon : Texture2D = get_icon(filter)
		item.set_text(0, filter)
		item.set_icon_modulate(0, Color.WHITE)
		item.set_selectable(0, false)
		item.collapsed = false
		item.set_icon(0, icon)
		for f : String in files[filter]:
			var fitem : TreeItem = item.create_child()
			fitem.set_text(0, f.get_file())
			fitem.set_icon(0, icon)
			fitem.set_metadata(0, f)
			fitem.set_icon_modulate(0, Color.GRAY)
			fitem.set_custom_color(0, Color.GRAY)
			fitem.set_tooltip_text(0, f)
	else:
		push_warning("Not valid type!")

func _process(_delta: float) -> void:
	var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if !fs:
		return
	if fs.is_scanning():
		return
	set_process(false)
	_update()
	
func update() -> void:
	set_process(true)

func _update() -> void:
	var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if fs:
		var fd : EditorFileSystemDirectory = fs.get_filesystem()
		if fd:
			for x : int in range(1, _container.get_child_count(), 1):
				var node : Node = _container.get_child(x)
				node.name = node.name + "_queue"
				node.queue_free()
			files.clear()
			search(fd)
		
			if _default_tx == null:
				_default_tx = get_icon("DEFAULT_NOT_FOUND")
				
			for x : StringName in files.keys():
				var control : Control = Control.new()
				var index : int = -1
				control.set_deferred(&"name", x)
				_container.add_child(control)
				index = control.get_index()
				if _container.get_tab_count() > index:
					_container.set_tab_icon(index, get_icon(x))
			if _first_time:
				_first_time = false
				_update_tree.call_deferred(&"All")
	_update_recents()
	
func _update_recents() -> void:
	_tree_recents.clear()
	var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if fs:
		var data : Dictionary[String, PackedStringArray] = {}
		for x : String in _recents:
			if FileAccess.file_exists(x):
				var type : String = fs.get_file_type(x)
				if !data.has(type):
					var packed : PackedStringArray = []
					data[type] = packed
				data[type].append(x)
		
		var root : TreeItem = _tree_recents.create_item()
		root.set_text(0, "Recents Files")
		root.set_selectable(0, false)
		root.set_custom_color(0, Color.WHITE)
		for k : String in data.keys():
			var item : TreeItem = root.create_child()
			var icon : Texture2D = get_icon(k)
			item.set_text(0, k)
			item.set_icon(0, icon)
			item.set_selectable(0, false)
			item.set_custom_color(0, Color.GRAY)
			item.set_icon_modulate(0, Color.GRAY)
			for y : String in data[k]:
				var fitem : TreeItem = item.create_child()
				fitem.set_text(0, y.get_file())
				fitem.set_icon(0, icon)
				fitem.set_tooltip_text(0, y)
				fitem.set_custom_color(0, Color.DARK_GRAY)
				fitem.set_icon_modulate(0, Color.DARK_GRAY)
				fitem.set_metadata(0, y)

func search(fd : EditorFileSystemDirectory) -> void:
	for f : int in fd.get_file_count():
		var type : StringName = fd.get_file_type(f)
		if !files.has(type):
			var _packed : PackedStringArray = []
			files[type] = _packed
		files[type].append(fd.get_file_path(f))
		
	for x : int in fd.get_subdir_count():
		search(fd.get_subdir(x))
