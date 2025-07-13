@tool
extends IDE
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# ./plugins: Folder for extensions.
# ./shared_resources: Free use for any purposes.
# =============================================================================	

var _plugins : Array[EditorPlugin] = []
var _enable_plugins : Dictionary = {}

func _ready() -> void:
	debug = false
	_initialize()
	
func _enter_tree() -> void:	
	set_process(true)
	
func _process(_delta: float) -> void:
	var editor : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if !editor:
		return
	if editor.is_scanning():
		return
	set_process(false)
	var base : String = get_script().resource_path.get_base_dir()
	var path : String = base.path_join("plugins")
	
	_init_config(1)
	_load_plugins(path)
	
	_sugar_godot(path)
	_sugar_godot(base.path_join("shared_resources"), "teal")
	
func _init_config(init : int) -> void:
	const PATH : String = "res://.godot_ide/"
	var cfg_path : String = PATH.path_join("config.ini")
	if !DirAccess.dir_exists_absolute(PATH):
		DirAccess.make_dir_absolute(PATH)
		var file : FileAccess = FileAccess.open(PATH.path_join(".gdignore"), FileAccess.WRITE)
		if file:
			file.store_string("IDE CONFIG")
			file.close()
	if init == 1:
		if FileAccess.file_exists(cfg_path):
			var cfg : ConfigFile = ConfigFile.new()
			if cfg.load(cfg_path) == OK:
				var value : Variant = cfg.get_value("config", "plugin", {})
				if value is Dictionary:
					_enable_plugins = value
	else:
		var cfg : ConfigFile = ConfigFile.new()
		cfg.set_value("config", "plugin", _enable_plugins)
		if cfg.save(cfg_path) != OK:
			push_warning("Can not save plugin changes!")
		
	
#region __PRX__
func _apply_changes() -> void:
	_callback(&"_apply_changes")
			
func _set_window_layout(configuration: ConfigFile) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_set_window_layout"):
			plugin.call(&"_set_window_layout", configuration)	
	
func _build() -> bool:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_build"):
			if !plugin.call(&"_build"):
				return false
	return true
	
func _clear() -> void:
	_callback(&"_build")
	
func _disable_plugin() -> void:
	_callback(&"_disable_plugin")
	
func _edit(object: Object) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_edit"):
			plugin.call(&"_edit", object)	
	
func _forward_3d_draw_over_viewport(viewport_control: Control) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_forward_3d_draw_over_viewport"):
			plugin.call(&"_forward_3d_draw_over_viewport", viewport_control)	
	
func _forward_3d_force_draw_over_viewport(viewport_control: Control) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_forward_3d_force_draw_over_viewport"):
			plugin.call(&"_forward_3d_force_draw_over_viewport", viewport_control)	
	
func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_forward_canvas_draw_over_viewport"):
			plugin.call(&"_forward_canvas_draw_over_viewport", viewport_control)	
	
func _forward_canvas_force_draw_over_viewport(viewport_control: Control) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_forward_canvas_force_draw_over_viewport"):
			plugin.call(&"_forward_canvas_force_draw_over_viewport", viewport_control)	
	
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	var out : bool = false
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(&"_forward_canvas_gui_input"):
			out = plugin.call(&"_forward_canvas_gui_input", event) or out	
	return out
#endregion
	
func _callback(method : StringName) -> void:
	for plugin : EditorPlugin in _plugins:
		if plugin.has_method(method):
			plugin.call(method)	
	
func _exit_tree() -> void:
	for x : Node in _plugins:
		if is_instance_valid(x):
			if !x.is_queued_for_deletion():
				x.queue_free()
	_plugins.clear()
	_init_config(0)
	
func _load_plugins(path : String) -> void:
	if !DirAccess.dir_exists_absolute(path):
		path = path.get_base_dir().get_file()
		if EditorInterface.is_plugin_enabled(path):
			EditorInterface.set_plugin_enabled(path, false)
		printerr("{0}: Error, can not find 'plugins' folder! [0x00000003]".format([path.capitalize().to_upper()]))
		return
	
	var dir :DirAccess = DirAccess.open(path)
	var plugins_dir : Array = []
	var plugins_file : Array = []
	var authors : PackedStringArray = []
	
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while !file_name.is_empty():
			if dir.current_is_dir():
				plugins_dir.append(path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		printerr("{0}:error, can not open 'plugins' folder! [0x00000005]".format([path.get_base_dir().get_file().capitalize().to_upper()]))
	
	while plugins_dir.size() > 0:
		var current_path : String = plugins_dir.pop_back()
		var	plugin_path : String = current_path.path_join("plugin.gd")
		var plugin_cfg : String = current_path.path_join("plugin.cfg")
		
		if FileAccess.file_exists(plugin_cfg):
			var cfg : ConfigFile = ConfigFile.new()
			if cfg.load(plugin_cfg) == OK:
				if cfg.has_section_key("plugin", "script"):
					plugin_path = current_path.path_join(str(cfg.get_value("plugin", "script")))
				if cfg.has_section_key("plugin", "author"):
					var value : String = str(cfg.get_value("plugin", "author"))
					if !value.is_empty() and !authors.has(value):
						authors.append(value)
		
		if !FileAccess.file_exists(plugin_path):
			plugin_path = current_path.path_join(current_path.get_file())
			if !FileAccess.file_exists(plugin_path):
				printerr("{0}:error, can not open 'plugin/{1}' folder! [0x00000005]".format([path.get_base_dir().get_file().capitalize().to_upper(), current_path.get_file()]))
				continue
		plugins_file.append(plugin_path)
		
	var current_plugins : Dictionary = {}
	for plugin : String in plugins_file:
		if _enable_plugins.has(plugin):
			if _enable_plugins[plugin] == false:
				continue
		var variant : Variant = ResourceLoader.load(plugin)
		if variant is Script:
			if variant.can_instantiate():
				if !variant.is_tool():
					push_warning("Plugin script is not tool: {0}".format([plugin]))
				variant = variant.new()
				if variant is EditorPlugin:
					_plugins.append(variant)
					current_plugins[plugin] = true
					
	_enable_plugins = current_plugins
				
	for plugin : EditorPlugin in _plugins:
		get_parent().add_child(plugin)
		if plugin.has_method(&"_enable_plugin"):
			plugin.call(&"_enable_plugin")
	
	print("[Godot-IDE Extension]")
	if authors.size() > 0:
		print("> Contributors: {0}".format([", ".join(authors)]))
	
		
func _sugar_godot(dir : String, col : String = "blue") -> void:
	const config_path : String = "res://project.godot"
	if !ProjectSettings.has_setting("file_customization/folder_colors"):
		ProjectSettings.set_setting("file_customization/folder_colors", {dir: col})
	else:
		if !dir.ends_with("/"):
			dir += "/"
		var data : Dictionary = ProjectSettings.get_setting("file_customization/folder_colors", {})
		if !data.has(dir):
			data[dir] = col
			ProjectSettings.set_setting("file_customization/folder_colors", data)
		else:
			return
	var editor : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if editor:
		editor.scan.call_deferred()
		
func _initialize() -> void:
	var dirt : Dictionary = {}
	var dat : Array[Dictionary] = (get_script() as Script).get_script_method_list()
	for dct : Dictionary in dat:
		var key : String = dct["name"]
		if dirt.has(key):
			continue
		dirt[key] = true
		if has_method(key):
			if key.begins_with("get_"):
				if !dct.has("args") or dct["args"].size() == 0:
					call(key)
	
