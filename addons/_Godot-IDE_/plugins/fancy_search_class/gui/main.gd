@tool
extends Window
# =============================================================================	
# Author: Twister
# Fancy Search Class
#
# Addon for Godot
# =============================================================================	


@export var _container : TabContainer = null
@export var _tree : Tree = null
@export var _tree_recents : Tree = null

#var files : Dictionary[StringName, Dictionary] = {}

const CUTE_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/Script.svg")

var _first_time : bool = false

var _recents : PackedStringArray = []

var _default_tx : Texture2D = null

var _collapsed : bool = false

func _enter_tree() -> void:
	_first_time = true
	
	var screen : Vector2 = DisplayServer.screen_get_size()
	var value : Variant = IDE.get_config("fancy_search_class", "size")
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
	
	var result : Variant = IDE.get_file_config_value("fancy_search_class", "recents")
	if result is PackedStringArray:
		_recents = result
		
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return
	get_child(0). add_theme_stylebox_override(&"panel", control.get_theme_stylebox(&"panel", &""))
	
func _save() -> void:
	IDE.set_file_config_value("fancy_search_class", "recents", _recents)
	
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
	IDE.set_config("fancy_search_class", "size", size)
		
func close() -> void:
	hide()
		
func get_icon(type : String) -> Texture2D:
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return null
	return control.get_theme_icon(type, "EditorIcons")
		
func _make_tree(root : TreeItem, key : StringName, dat : Dictionary, buff : Dictionary) -> void:
	if buff.has(key):
		return
	var tree : TreeItem = root.create_child()
	buff[key] = tree
	tree.set_text(0, key)
	for k : StringName in dat.keys():
		var packed : PackedStringArray = dat["class"]
		for p : String in packed:
			var t : TreeItem = tree.create_child()
			t.set_text(0, p)
			buff[p] = t
			
var pumpking : Pumpking = null
			
class Pumpking extends RefCounted:
	var cute_name : StringName = ""
	var next : Array[Pumpking] = []
	var back : Pumpking = null
	
	var witchies : PackedStringArray = []
	
	func born_pumpking() -> Pumpking:
		var borned_pumpking : Pumpking = Pumpking.new()
		next.append(borned_pumpking)
		return borned_pumpking
		
	func merge_pumpking(pumpking : Pumpking) -> void:
		if !(next in next) and back != pumpking:
			if pumpking in next:
				return
			next.append(pumpking)
	
	func get_pumpking(check_cute_name : StringName) -> Pumpking:
		if check_cute_name == cute_name:
			return self
		
		for x : Pumpking in next:
			var y : Pumpking = x.get_pumpking(check_cute_name)
			if y:
				return y
				
		return null
			
func _update_tree(filter : StringName) -> void:
	_tree.clear()
	if pumpking:
		if filter == &"All":
			_collapsed = true
			var root : TreeItem = _tree.create_item()
			root.set_text(0, pumpking.cute_name)
			for x : Pumpking in pumpking.next:
				_fill_tree(root, x)
		else:
			_collapsed = false
			var current : Pumpking = pumpking.get_pumpking(filter)
			if current != pumpking:
				var root : TreeItem = _tree.create_item()
				root.set_text(0, current.cute_name)
				_fill_tree(root, current)
			else:
				_update_tree(&"All")

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
				
			pumpking = Pumpking.new()
			search(fd)
			
			if _default_tx == null:
				_default_tx = get_icon("DEFAULT_NOT_FOUND")
			
			for p : Pumpking in pumpking.next:
				_fill_tab(p)
			
			if _first_time:
				_first_time = false
				_update_tree.call_deferred(&"All")
	_update_recents()
	
func _fill_tab(pump : Pumpking) -> void:
	var control : Control = Control.new()
	var index : int = -1
	var nname : StringName = pump.cute_name
	control.set_deferred(&"name", nname)
	_container.add_child(control)
	index = control.get_index()
	if _container.get_tab_count() > index:
		var icon : Texture2D = get_icon(nname)
		if icon == _default_tx:
			icon = CUTE_ICON
		_container.set_tab_icon(index, icon)
	for p : Pumpking in pump.next:
		_fill_tab(p)
	
func _fill_tree(root : TreeItem, pump : Pumpking) -> void:
	var tree : TreeItem = root.create_child()
	var nname : StringName = pump.cute_name
	tree.set_text(0, nname)
	var icon : Texture2D = get_icon(nname)
	if icon == _default_tx:
		icon = CUTE_ICON
	tree.set_icon(0, icon)
	tree.set_selectable(0, false)
	tree.collapsed = _collapsed
	
	for w : String in pump.witchies:
		var witch : TreeItem = tree.create_child()
		
		var text : String = w
		var slice : int = w.get_slice_count("/")
		if slice > 6:
			text = w.get_file()
			for x : int in range(slice - 1, slice - 4, -1):
				text = w.get_slice("/", x).path_join(text)
			text = "...".path_join(text)
		
		witch.set_text(0, text)
		witch.set_icon(0, icon)
		witch.set_custom_color(0, Color.DARK_GRAY)
		witch.set_icon_modulate(0, Color.DARK_GRAY)
		witch.set_metadata(0, w)
		witch.set_tooltip_text(0, w)
	
	for x : Pumpking in pump.next:
		_fill_tree(tree, x)
	
func _update_recents() -> void:
	_tree_recents.clear()
	var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if fs:
		var data : Dictionary[String, PackedStringArray] = {}
		var exist : PackedStringArray = []
		for x : String in _recents:
			if FileAccess.file_exists(x):
				var type : StringName = "File"
				var fe : EditorFileSystemDirectory = fs.get_filesystem_path(x.get_base_dir())
				if fe:
					for f : int in fe.get_file_count():
						if fe.get_file_path(f) == x:
							type = fe.get_file_script_class_name(f)
							if type.is_empty():
								type = fe.get_file_script_class_extends(f)
							break
					if type.is_empty():
						type = fs.get_file_type(x)	
				if !data.has(type):
					var packed : PackedStringArray = []
					data[type] = packed
				data[type].append(x)
				exist.append(x)
		_recents = exist
			
		
		var root : TreeItem = _tree_recents.create_item()
		root.set_text(0, "Recents Files")
		root.set_selectable(0, false)
		root.set_custom_color(0, Color.WHITE)
		
		for k : String in data.keys():
			var item : TreeItem = root.create_child()
			var icon : Texture2D = get_icon(k)
					
			item.set_text(0, k)
			item.set_selectable(0, false)
			item.set_custom_color(0, Color.GRAY)
			item.set_icon_modulate(0, Color.GRAY)
			
			if icon == _default_tx:
				icon = CUTE_ICON
			item.set_icon(0, icon)
			for y : String in data[k]:
				var fitem : TreeItem = item.create_child()
				fitem.set_text(0, y.get_file())
				fitem.set_icon(0, icon)
				fitem.set_tooltip_text(0, y)
				fitem.set_custom_color(0, Color.DARK_GRAY)
				fitem.set_icon_modulate(0, Color.DARK_GRAY)
				fitem.set_metadata(0, y)

func search(fd : EditorFileSystemDirectory) -> void:
	if pumpking == null:
		pumpking = Pumpking.new()
	pumpking.cute_name = "Found Files"
	for f : int in fd.get_file_count():
		var extension : StringName = fd.get_file_script_class_extends(f)
		var type : StringName = fd.get_file_script_class_name(f)
		var ee : bool = extension.is_empty()
		var te : bool = type.is_empty()
		if ee and te:
			continue
		var path : String = fd.get_file_path(f)
		
		if !ee:
			var grand_pumpking : Pumpking = pumpking.get_pumpking(extension)
			if grand_pumpking == null:
				grand_pumpking = pumpking.born_pumpking()
				grand_pumpking.cute_name = extension
			if !te:
				var newer_pumpking : Pumpking = grand_pumpking.get_pumpking(type)
				if newer_pumpking == null:
					newer_pumpking = grand_pumpking.born_pumpking()
					newer_pumpking.cute_name = type
				newer_pumpking.witchies.append(path)
			else:
				grand_pumpking.witchies.append(path)
		elif !te:
			var new_pumpking : Pumpking = pumpking.get_pumpking(type)
			if new_pumpking == null:
				new_pumpking = pumpking.born_pumpking()
				new_pumpking.cute_name = type
			new_pumpking.witchies.append(path)
		
		#if !ee:
			#if !files.has(extension):
				#var current_files : PackedStringArray = []
				#var classes : PackedStringArray = []
				#files[extension] = {
					#"files" : current_files,
					#"class" : classes,
					#"parent" : ""
				#}
			#var data : Dictionary = files[extension]
			#var packed : PackedStringArray = data["files"]
			#
			#if te:
				#if !(path in packed):
					#packed.append(path)
		#
		#if !te:
			#if !files.has(type):
				#var current_files : PackedStringArray = []
				#var classes : PackedStringArray = []
				#files[type] = {
					#"files" : current_files,
					#"class" : classes,
					#"parent" : extension
				#}
			#var data : Dictionary = files[type]
			#var packed : PackedStringArray = data["files"]
			#if !(path in packed):
				#packed.append(path)
		
	for x : int in fd.get_subdir_count():
		search(fd.get_subdir(x))
