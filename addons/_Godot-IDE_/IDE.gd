@tool
class_name IDE extends EditorPlugin
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# ./plugins: Folder for extensions.
# ./shared_resources: Free use for any purposes.
# =============================================================================	

const EDITOR_CONFIG_PATH : String = "plugin/godot_ide/"
const PATH_CONFIG : String = "res://.ide/"
	
static var _ref : Dictionary[String, Object] = {}
static var _safe_ref : Dictionary[String, Node] = {}

static var debug : bool = true

static var PRIVATE_METHODS : String = "__"
static var VIRTUAL_METHODS : String = "_"

#region DEV_API
## Get current editor container for edit/view scripts.
static func get_script_editor_container() -> TabContainer:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("script_editor_container", script_editor, "*", "TabContainer", 0)
	if out is TabContainer:
		return out
	return null

## Get current script/documents opened list.
static func get_script_list() -> ItemList:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("script_list", script_editor, "*", "ItemList", 0)
	if out is ItemList:
		return out
	return null
	
static func get_script_list_search_bar() -> LineEdit:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("script_list_search_bar", script_editor, "*", "LineEdit", 0)
	if out is LineEdit:
		return out
	return null
	
static func get_script_list_current_label() -> Label:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("script_list_current_label", script_editor, "*", "Label", 2)
	if out is Label:
		return out
	return null
	
static func get_filter_methods() -> ItemList:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("filter_methods", script_editor, "*", "ItemList", 1)
	if out is ItemList:
		return out
	return null
	
static func get_filter_methods_search_bar() -> LineEdit:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("filter_methods_search_bar", script_editor, "*", "LineEdit", 1)
	if out is LineEdit:
		return out
	return null
	
static func get_file_menu_button() -> MenuButton:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("file_menu_button", script_editor, "*", "MenuButton", 0)
	if out is MenuButton:
		return out
	return null
	
static func get_edit_menu_button() -> MenuButton:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("edit_menu_button", script_editor, "*", "MenuButton", 1)
	if out is MenuButton:
		return out
	return null
	
static func get_search_menu_button() -> MenuButton:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("search_menu_button", script_editor, "*", "MenuButton", 2)
	if out is MenuButton:
		return out
	return null
	
static func get_go_to_menu_button() -> MenuButton:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("get_go_to_menu_button", script_editor, "*", "MenuButton", 3)
	if out is MenuButton:
		return out
	return null
	
static func get_debug_menu_button() -> MenuButton:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("debug_menu_button", script_editor, "*", "MenuButton", 17)
	if out is MenuButton:
		return out
	return null
	
static func get_script_list_container() -> VSplitContainer:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("script_list_container", script_editor, "*", "VSplitContainer", 0)
	if out is VSplitContainer:
		return out
	return null
	
static func get_editor_container() -> HSplitContainer:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var out : Variant = _get_reference("editor_container", script_editor, "*", "HSplitContainer", 0)
	if out is HSplitContainer:
		return out
	return null
	
## Raito must be 0.1 - 1.0
static func get_screen_size(ratio : float = 1.0) -> Vector2:
	var screen : Vector2 = DisplayServer.screen_get_size()
	return screen * ratio
	
static func clamp_screen_size(current_size : Vector2, min_ratio : float = 0.0, max_ratio : float = 1.0) -> Vector2:
	var screen : Vector2 = DisplayServer.screen_get_size()
	var max_screen : Vector2 = screen * max_ratio
	var min_screen : Vector2 = screen * min_ratio
	return Vector2(max(min(current_size.x, max_screen.x), min_screen.x), max(min(current_size.y, max_screen.y), min_screen.y))
	
static func get_script_properties_list(script : Script, full : bool = true, check_is_native : bool = true) -> Dictionary:
	if script == null:
		return {}
	var nname : String = get_name_script(script)
	if check_is_native and ClassDB.class_exists(nname):
		return _generate_native(nname)
	if full:
		var data : Dictionary = _generate(script)
		return _generate_native(script.get_instance_base_type(), data, data.size()-1)
	else:
		return _generate(script)
	
static func _generate(script : Script, data : Dictionary = {}, index : int = -1) -> Dictionary:
	if script == null:
		return data
	var funcs : Dictionary = {}
	var props : Dictionary = {}
	var signals : Dictionary = {}
	var constants : Dictionary = {}
	var base : Dictionary = {
		"name" : &"GDScript"
		,"functions" : funcs
		,"properties" : props
		,"signals" : signals
		,"constants" : constants
		,"type": 1
		,"custom": false
		,"path" : script.resource_path
		,"tool" : script.is_tool()
		,"abstract" : script.is_abstract()
		,"built_in" : script.is_built_in()
	}
	
	var base_name : String = get_name_script(script, base)
	base["name"] = base_name
	index += 1
	data[index] = base
	
	for dict: Dictionary in script.get_script_method_list():
		var func_name: StringName = dict.name
		if func_name.begins_with("@"):continue
		funcs[func_name] =_get_header_virtual(dict)
		if dict.has("flags"):
			if dict["flags"] & METHOD_FLAG_STATIC:
				funcs[func_name] += "||static"
			elif dict["flags"] & METHOD_FLAG_CONST:
				funcs[func_name] += "||const"
		
	for dict : Dictionary in script.get_script_property_list():
		var pro_name: StringName = dict.name
		var as_exporrt : bool = false
		if !pro_name.get_extension().is_empty():
			continue
		if dict.has("usage"):
			var usage : int = dict["usage"]
			if !(usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			for x : int in [PROPERTY_USAGE_STORAGE, PROPERTY_USAGE_EDITOR, PROPERTY_USAGE_CHECKABLE, PROPERTY_USAGE_CHECKED, PROPERTY_USAGE_GROUP]:
				if usage & x:
					as_exporrt = true
					break
		props[pro_name] =_get_header_virtual(dict)
		if as_exporrt:
			props[pro_name] += "||export"
		else:
			if dict.has("flags"):
				if dict["flags"] & METHOD_FLAG_STATIC:
					props[pro_name] += "||static"
				elif dict["flags"] & METHOD_FLAG_CONST:
					props[pro_name] += "||const"
		
	for dict : Dictionary in script.get_property_list():
		var pro_name: StringName = dict.name
		if !pro_name.get_extension().is_empty():
			continue
		if dict.has("usage"):
			var usage : int = dict["usage"]
			if !(usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
		props[pro_name] =_get_header_virtual(dict)
		props[pro_name] += "||static"
		
	for dict : Dictionary in script.get_script_signal_list():
		var pro_name: StringName = dict.name
		signals[pro_name] =_get_header_virtual(dict)
	
	for dict : Variant in script.get_script_constant_map():
		if dict is StringName:
			var variant : Variant = script.get(dict)
			constants[dict] = "{0}||{1}".format([dict, get_type(typeof(variant))])
		elif dict is Dictionary:
			var pro_name: StringName = dict.name
			constants[pro_name] =_get_header_virtual(dict)

	if data.size() > 0:
		var start : int = 0
		while !data.has(start) and start < index:
			start += 1
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["functions"]
			for k : Variant in funcs.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["properties"]
			for k : Variant in props.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["signals"]
			for k : Variant in signals.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["constants"]
			for k : Variant in constants.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
				else:
					clazz[k] = constants[k] + "||overrided"
	return _generate(script.get_base_script(), data, index)
	

static func _generate_native(native :  StringName, data : Dictionary = {}, index : int = 0) -> Dictionary:
	if native.is_empty() or !ClassDB.class_exists(native):
		return data
	var funcs : Dictionary = {}
	var props : Dictionary = {}
	var signals : Dictionary = {}
	var constants : Dictionary = {}
	
	var api_type : int = ClassDB.class_get_api_type(native)
	
	var base : Dictionary = {
		"name" : native
		,"functions" : funcs
		,"properties" : props
		,"signals" : signals
		,"constants" : constants
		,"type" : 0
		,"custom": false
		,"path" : "NativeScript"
		,"tool" : api_type == ClassDB.APIType.API_EDITOR or api_type == ClassDB.APIType.API_EDITOR_EXTENSION
		,"abstract" : false #!
		,"built_in" : false
	}
	index += 1
	data[index] = base
	
	
	for dict: Dictionary in ClassDB.class_get_method_list(native, true):
		funcs[dict.name] =_get_header_virtual(dict)
		
	for dict : Dictionary in ClassDB.class_get_property_list(native, true):
		var pro_name: StringName = dict.name
		if !pro_name.get_extension().is_empty():
			continue
		props[pro_name] =_get_header_virtual(dict)
		
	for dict : Dictionary in ClassDB.class_get_signal_list(native, true):
		var pro_name: StringName = dict.name
		signals[pro_name] =_get_header_virtual(dict)
		
	for dict : String in ClassDB.class_get_enum_list(native, true):
		var pro_name: StringName = dict
		constants[pro_name] = "{0}||enum||void".format([dict])
		
	for dict : String in ClassDB.class_get_integer_constant_list(native, true):
		var pro_name: StringName = dict
		constants[pro_name] = "{0}||int||void".format([dict])
		
	if data.size() > 0:
		var start : int = 0
		while !data.has(start) and start < index:
			start += 1
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["functions"]
			for k : Variant in funcs.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["properties"]
			for k : Variant in props.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["signals"]
			for k : Variant in signals.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"
		for x : int in range(start, index, 1):
			var clazz : Dictionary = data[x]["constants"]
			for k : Variant in constants.keys():
				if clazz.has(k):
					if !"||overrided" in clazz[k]:
						clazz[k] += "||overrided"

	return _generate_native(ClassDB.get_parent_class(native), data, index)

#endregion


# =============================================================================	
#region DEV_CONFIG
static func set_config(plugin_name : String, config_name : String, value : Variant) -> void:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if editor:
		if config_name.is_empty():
			printerr("Config name can not be empty!")
			return
		if plugin_name.is_empty():
			printerr("Plugin name can not be empty")
			return
		editor.set_setting(EDITOR_CONFIG_PATH.path_join(plugin_name).path_join(config_name), value)
	
static func add_property_config_info(plugin_name : String, config_name : String, type : Variant.Type, hint : int, hint_string : String):
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if editor:
		if config_name.is_empty():
			printerr("Config name can not be empty!")
			return
		if plugin_name.is_empty():
			printerr("Plugin name can not be empty")
			return
		editor.add_property_info({
			"name": EDITOR_CONFIG_PATH.path_join(plugin_name).path_join(config_name),
			"type": type,
			"hint": hint,
			"hint_string": hint_string
		})
	
static func get_config(addon_name : String, config_name : String) -> Variant:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if editor:
		var setting : String = EDITOR_CONFIG_PATH.path_join(addon_name).path_join(config_name)
		if editor.has_setting(setting):
			return editor.get_setting(setting)
	return null
	
static func get_type(_typeof : int) -> String:
	var txt : String = ""
	match _typeof:
		TYPE_BOOL : txt = "bool"
		TYPE_INT : txt = "int"
		TYPE_FLOAT: txt = "float"
		TYPE_STRING : txt = "String"
		TYPE_VECTOR2 : txt = "Vector2"
		TYPE_VECTOR2I : txt = "Vector2i"
		TYPE_RECT2 : txt = "Rect2"
		TYPE_RECT2I : txt = "Rect2i"
		TYPE_VECTOR3 : txt = "Vector3"
		TYPE_VECTOR3I : txt = "Vector3i"
		TYPE_TRANSFORM2D : txt = "Tranform2D"
		TYPE_VECTOR4 : txt = "Vector4"
		TYPE_VECTOR4I : txt = "Vector4i"
		TYPE_PLANE : txt = "Plane"
		TYPE_QUATERNION : txt = "Quaternion"
		TYPE_AABB : txt = "AABB"
		TYPE_BASIS : txt = "Basis"
		TYPE_TRANSFORM3D : txt = "Transform3D"
		TYPE_PROJECTION : txt = "Projection"
		TYPE_COLOR : txt = "Color"
		TYPE_STRING_NAME : txt = "StringName"
		TYPE_NODE_PATH : txt = "NodePath"
		TYPE_RID : txt = "RID"
		TYPE_OBJECT : txt = "Object"
		TYPE_CALLABLE : txt = "Callable"
		TYPE_SIGNAL : txt = "Signal"
		TYPE_DICTIONARY : txt = "Dictionary"
		TYPE_ARRAY : txt = "Array"
		TYPE_PACKED_BYTE_ARRAY : txt = "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY : txt = "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY : txt = "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY : txt = "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY : txt = "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY : txt = "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY : txt = "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY : txt = "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY : txt = "PackedColorArray"
		TYPE_PACKED_VECTOR4_ARRAY : txt = "PackedVector4Array"
		_:
			txt = "Variant"
	return txt
	
static func set_file_config_value(section : String, key : String, value : Variant) -> int:
	if !DirAccess.dir_exists_absolute(PATH_CONFIG):
		if OK != DirAccess.make_dir_recursive_absolute(PATH_CONFIG):
			push_warning("Can not creates config dir!")
			return 1
		if FileAccess.file_exists(PATH_CONFIG.path_join(".gdignore")):
			var file : FileAccess = FileAccess.open(PATH_CONFIG.path_join(".gdignore"), FileAccess.WRITE)
			file.store_string("FOLDER Godot-IDE CONFIG")
			file.close()
			
	var cfg_path : String = PATH_CONFIG.path_join("config.ini")
	var cfg : ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(cfg_path):
		cfg.load(cfg_path)
	cfg.set_value(section, key, value)
	return cfg.save(cfg_path)
	
static func get_file_config_value(section : String, key : String) -> Variant:
	var cfg_path : String = PATH_CONFIG.path_join("config.ini")
	if !FileAccess.file_exists(cfg_path):
		return null
	var cfg : ConfigFile = ConfigFile.new()
	var err : int = cfg.load(cfg_path)
	if OK != err:
		return null
	return cfg.get_value(section, key, "")
	
#endregion
# =============================================================================	
static func clamp_rect_to_screen(to_clamp_rect: Rect2, max_aviable_rect : Rect2) -> Rect2:
	
	if to_clamp_rect.position.x < max_aviable_rect.position.x:
		to_clamp_rect.position.x = max_aviable_rect.position.x
	elif to_clamp_rect.position.x + to_clamp_rect.size.x > max_aviable_rect.position.x + max_aviable_rect.size.x:
		to_clamp_rect.position.x = max_aviable_rect.position.x + max_aviable_rect.size.x - to_clamp_rect.size.x

	if to_clamp_rect.position.y < max_aviable_rect.position.y:
		to_clamp_rect.position.y = max_aviable_rect.position.y
	elif to_clamp_rect.position.y + to_clamp_rect.size.y > max_aviable_rect.position.y + max_aviable_rect.size.y:
		to_clamp_rect.position.y = max_aviable_rect.position.y + max_aviable_rect.size.y - to_clamp_rect.size.y
		
	if to_clamp_rect.size.x > max_aviable_rect.size.x:
		to_clamp_rect.position.x = max_aviable_rect.position.x + (max_aviable_rect.size.x - to_clamp_rect.size.x) / 2
	if to_clamp_rect.size.y > max_aviable_rect.size.y:
		to_clamp_rect.position.y = max_aviable_rect.position.y + (max_aviable_rect.size.y - to_clamp_rect.size.y) / 2

	return to_clamp_rect


static func get_header_function(dict : Dictionary) -> String:
	var params : String = ""
	var args : Array = dict["args"]
	var separator : String = ""
	var default_args : Array = dict["default_args"]
	var _default_index : int = default_args.size()

	for y : int in range(args.size() - 1, -1, -1):
		var arg : Dictionary = args[y]
		var txt : String = arg["name"]
		if !(arg["class_name"]).is_empty():
			txt += str(" : ", arg["class_name"] as String)
		else:
			var _typeof : int = arg["type"]
			txt += str(" : ", IDE.get_type(_typeof))
		if _default_index > 0:
			_default_index -= 1
			var def : Variant = default_args[_default_index]
			var _type : int = typeof(def)
			if def == null or _type < 1:
				txt += str(' = null')
			elif _type < 5:
				if def is String:
					txt += str(' = "', def, '"')
				elif def is StringName:
					txt += str(' = &"', def, '"')
				else:
					txt += str(" = ", def)
			else:
				txt += str(" = ", IDE.get_type(typeof(def)), def)
		params = str(txt, separator, params)
		separator = ", "

	var return_dic : Dictionary = dict["return"]
	var return_type : String = "void"
	var return_value : String = "pass"
	if !return_dic["class_name"].is_empty():
		return_type = (return_dic["class_name"] as String)
		return_value = "return null"
	else:
		var _type : int = return_dic["type"]
		if _type < 1:
			var func_name : String = str(dict["name"]).to_lower()
			if func_name == "get" or __is_variant(func_name):
				return_type = "Variant"
				return_value = "return null"
			else:
				return_type = "void"
		else:
			return_type = IDE.get_type(return_dic["type"])
			if _type == TYPE_INT:
				return_value = "return 0"
			elif _type == TYPE_BOOL:
				return_value = "return false"
			elif _type == TYPE_FLOAT:
				return_value = "return 0.0"
			elif _type == TYPE_STRING:
				return_value = 'return ""'
			elif _type == TYPE_ARRAY:
				return_value = "return []"
			else:
				return_value = str("return ", return_type,"()")
	return "func {0}({1}) -> {2}:\n\t#TODO: code here :)\n\t{3}".format([dict["name"], params, return_type, return_value])



static func _get_header_virtual(dict : Dictionary, include_paremeters : bool = true) -> String:
	var params : String = ""
	var separator : String = ""
	if dict.has("args"):
		var args : Array = dict["args"]
		var default_args : Array = dict["default_args"]
		var _default_index : int = default_args.size()

		for y : int in range(args.size() - 1, -1, -1):
			var arg : Dictionary = args[y]
			var txt : String = "" #arg["name"]
			if !(arg["class_name"]).is_empty():
				txt += str(arg["class_name"] as String)
			else:
				var _typeof : int = arg["type"]
				txt += str(IDE.get_type(_typeof))
			if include_paremeters and _default_index > 0:
				_default_index -= 1
				var def : Variant = default_args[_default_index]
				var _type : int = typeof(def)
				if def == null or _type < 1:
					txt += str(' = null')
				elif _type < 5:
					if def is String:
						txt += str(' = "', def, '"')
					elif def is StringName:
						txt += str(' = &"', def, '"')
					else:
						txt += str(" = ", def)
				else:
					txt += str(" = ",IDE.get_type(typeof(def)), def)
			params = str(txt, separator, params)
			separator = ", "

		if dict.has("return"):
			var return_dic : Dictionary = dict["return"]
			var return_type : String = "void"

			if !return_dic["class_name"].is_empty():
				return_type = (return_dic["class_name"] as String)
			else:
				var _type : int = return_dic["type"]
				if _type < 1:
					var func_name : String = str(dict["name"]).to_lower()
					if func_name == "get" or __is_variant(func_name):
						return_type = "Variant"
					else:
						return_type = "void"
				else:
					return_type = get_type(return_dic["type"])

	#if params.is_empty():
		#params = "-"
			return "{0}||{1}||{2}".format([dict["name"], params, return_type]) #Replace x more space.
	elif dict.has("class_name"):
		var classname : String = dict["class_name"]
		if classname.is_empty() and dict.has("type"):
			classname = get_type(dict["type"])
		params = classname
	return "{0}||{1}||void".format([dict["name"], params]) 

static func __is_variant(func_name : String) -> bool:
	const FUNC_GET : Array[String] = ["get_", "_get"]
	for x : String in FUNC_GET:
		if func_name.begins_with(x) or func_name.ends_with(x):
			return true
	return func_name.contains("_get_") 
	
static func get_name_script(script : Script, ref_data : Dictionary = {}) -> StringName:
	var base_name : StringName = script.get_global_name()
	if base_name.is_empty():
		var path : String = script.resource_name
		if path.is_empty():
			path = script.resource_path
			if !path.is_empty():
				var _name : String = path.get_file()
				_name = _name.trim_suffix("." + _name.get_extension())
				base_name = _name
			else:
				base_name = &"CustomScript"
			ref_data["custom"] = true
		else:
			base_name = path
	return base_name

static func _reset() -> void:
	for x : String in _ref.keys():
		var object : Variant = _ref[x]
		if is_instance_valid(object) and object is Node:
			if _safe_ref.has(x):
				var parent : Node = _safe_ref[x]
				if is_instance_valid(parent) and !parent.is_queued_for_deletion():
					var current : Node = object.get_parent()
					if current != parent:
						if is_instance_valid(current):
							object.reparent(parent)
						else:
							parent.add_child(object)

static func _get_reference(container_name : String, root_container : Node, pattern : String, type : String, index : int) -> Variant:
	if !is_instance_valid(root_container):
		if debug:
			# If you recieved this message, try reset the engine with this addon enabled.
			# | If the problem persist, make a issue on "https://github.com/CodeNameTwister/godot_ide"
			push_warning("Caution!, not root reference setted!!")
		return null
	elif _ref.has(container_name):
		var object : Variant = _ref[container_name]
		if is_instance_valid(object):
			if object is Node:
				if !_safe_ref.has(container_name):
					_safe_ref[container_name] = object.get_parent()
			return object
	var new_object : Variant = _find(root_container, pattern, type, index)
	if is_instance_valid(new_object):
		_ref[container_name] = new_object
		return new_object
	if debug:
		# If you recieved this message, try reset the engine with this addon enabled.
		# | If the problem persist, make a issue on "https://github.com/CodeNameTwister/godot_ide"
		push_warning("Caution!, can not found: {0}!!".format([container_name]))
	return null
	
static func _find(root : Node, pattern : String, type : String, index : int = 0) -> Node:
	var e : Array[Node] = root.find_children(pattern, type, true, false)
	if e.size() > index:
		return e[index]
	return null
