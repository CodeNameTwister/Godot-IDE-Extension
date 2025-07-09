@tool
extends Popup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	script-ide: Virtual Popups
#
#	Virtual Popups for script-ide addon.godot 4
#	author:	"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const BUILT_IN_SCRIPT: String = "::GDScript"

const ICON_PUBLIC : Texture = preload("res://addons/_Godot-IDE_/shared_resources/func_public.svg")
const ICON_VIRTUALS : Texture = preload("res://addons/_Godot-IDE_/shared_resources/func_virtual.svg")
const ICON_PRIVATE : Texture = preload("res://addons/_Godot-IDE_/shared_resources/func_private.svg")
const ICON_CHECKED : Texture = preload("res://addons/_Godot-IDE_/shared_resources/check.svg")
#const ICON_WARNING : Texture = preload("res://addons/gd_override_functions/popup/icon/warning.png")

const ICON_NATIVE_CLASS : Texture = preload("res://addons/_Godot-IDE_/shared_resources/Script.svg")
const ICON_CUSTOM_CLASS : Texture = preload("res://addons/_Godot-IDE_/shared_resources/ScriptExtend.svg")
const ICON_CUSTOM_SCRIPT : Texture = preload("res://addons/_Godot-IDE_/shared_resources/PluginScript.svg")
const ICON_INTERFACE_SCRIPT : Texture = preload("res://addons/_Godot-IDE_/shared_resources/InterfaceScript.svg")

const ICON_ORDER_DEFAULT : Texture = preload("res://addons/_Godot-IDE_/shared_resources/up.svg")
const ICON_ORDER_INVERT : Texture = preload("res://addons/_Godot-IDE_/shared_resources/down.svg")

var COLOR_CLASS : Color = Color.DARK_SLATE_BLUE
var COLOR_NATIVE_CLASS : Color = Color.BLACK
var COLOR_PARAMETERS : Color = Color.BLACK
var COLOR_INTERFACE : Color = Color.BLACK

var include_paremeters : bool = false

# FILTERS
var _private_begin_equal_protected : bool = false
var _public_filter : bool = false
var _private_filter : bool = false
var _protected_filter : bool = true
var _interface_filter : bool = true

enum FILTER_TYPE{
	DEFAULT,
	REVERSE,
	DEFAUL_TREE,
	REVERSE_TREE
}

@export_tool_button("Test")
var test_button: Callable = _testing

@export var tree : Tree
@export var accept_button : Button
@export var cancel_button : Button

@export var check_generate_at_line : CheckBox

# GENERATORS
@export var interface_generate_button : Button
@export var virtual_generate_button : Button

#region order
@export var order_button : Button
#endregion

#region filter_handler
@export var public_button : Button
@export var protected_button : Button
@export var private_button : Button
@export var interface_button : Button

var _last_script : Script = null
var _last_filter : FILTER_TYPE = FILTER_TYPE.REVERSE
#endregion

var _buffer_data : Dictionary = {}
var _created_funcs : Dictionary = {}

var _generate_at_end_line : bool = true

#region _USER_CONFIG_
## Class name chars in the begin for identify a class as interface
var _interface_begins_with : String = "I"
## Class name chars in the end for identify a class as interface.
var _interface_end_with : String = "Interface"
## Ignore Upper/Lower case of class name.
var _interface_ignore_case : bool = true
## Function name in the begin for identify function as virtual.
var _char_virtual_function : String = "_"
## Function name in the end for identify function as virtual.
var _char_private_function : String = "__"
## Include native class like IMyClass, MyClassInterface.
var _include_native_class_for_check_interfaces : bool = false
#endregion

func _update_settings() -> void:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if null == editor:
		return
		
	if editor.has_setting("plugin/gd_override_functions/interface/class_as_interface_if_begins_with"):
		_interface_begins_with = editor.get_setting("plugin/gd_override_functions/interface/class_as_interface_if_begins_with")
	if editor.has_setting("plugin/gd_override_functions/interface/class_as_interface_if_end_with"):
		_interface_end_with = editor.get_setting("plugin/gd_override_functions/interface/class_as_interface_if_end_with")
	if editor.has_setting("plugin/gd_override_functions/interface/class_interface_name_ignore_case"):
		_interface_ignore_case = editor.get_setting("plugin/gd_override_functions/interface/class_interface_name_ignore_case")
	if editor.has_setting("plugin/gd_override_functions/inheritance/virtual_functions_begins_with"):
		_char_virtual_function = editor.get_setting("plugin/gd_override_functions/inheritance/virtual_functions_begins_with")
	if editor.has_setting("plugin/gd_override_functions/inheritance/private_functions_begins_with"):
		_char_private_function = editor.get_setting("plugin/gd_override_functions/inheritance/private_functions_begins_with")
	if editor.has_setting("plugin/gd_override_functions/inheritance/include_native_class_for_check_interfaces"):
		_include_native_class_for_check_interfaces = editor.get_setting("plugin/gd_override_functions/inheritance/include_native_class_for_check_interfaces")
	if _interface_ignore_case:
		_interface_end_with = _interface_end_with.to_lower()
		_interface_begins_with = _interface_begins_with.to_lower()

func make_tree(input_script : Script, filter_type : FILTER_TYPE = _last_filter) -> void:
	_buffer_data = {}
	_created_funcs = {}
	if tree == null:
		push_error("Not defined tree!")
		return

	tree.clear()
	
	_update_settings()

	_last_script = input_script
	_last_filter = filter_type

	var callback : Callable = _on_accept_button
	if accept_button:
		if accept_button.pressed.is_connected(_on_accept_button):
			accept_button.pressed.disconnect(_on_accept_button)
		accept_button.pressed.connect(callback)
	if tree.item_activated.is_connected(_on_accept_button):
		tree.item_activated.disconnect(_on_accept_button)
	tree.item_activated.connect(callback)

	# script-ide: Check if built-in script. In this case we need to duplicate it for whatever reason.
	if (input_script.get_path().contains(BUILT_IN_SCRIPT)):
		input_script = input_script.duplicate()

	var output : Array = generate_data(input_script)
	var base : Dictionary = output[0]
	var base_count : int = output[1]

	#MAKE TREE
	var start : int = 0
	var end : int = base_count + 1
	var step : int = 1
	if filter_type == FILTER_TYPE.DEFAULT or filter_type == FILTER_TYPE.DEFAUL_TREE:
		start = base_count
		end = -1
		step = -1

	tree.set_column_custom_minimum_width(0, 25)

	tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
	tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	tree.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)

	tree.set_column_title(0, "Class/Functions")
	tree.set_column_title(1, "Params")
	tree.set_column_title(2, "Return")
	tree.column_titles_visible = true

	var root : TreeItem = tree.create_item()
	root.set_text(0, "Classes")

	_created_funcs = _clear_funcs(input_script)

	_buffer_data = base

	if filter_type == FILTER_TYPE.DEFAUL_TREE or filter_type == FILTER_TYPE.REVERSE_TREE:
		var last : TreeItem = root
		for x : int in range(start, end, step):
			var dict : Dictionary = base[x]
			var funcs : Dictionary = dict["funcs"]

			if funcs.size() == 0:continue

			var item : TreeItem = tree.create_item(last, -1)

			item.set_text(0, dict["name"])
			last = item

			if dict["type"] == 0:
				item.set_custom_bg_color(0, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(1, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(2, COLOR_NATIVE_CLASS)
				item.collapsed = true
				item.set_icon(0, ICON_NATIVE_CLASS)
			elif dict["type"]  == 1:
				item.set_custom_bg_color(0, COLOR_CLASS)
				item.set_custom_bg_color(1, COLOR_CLASS)
				item.set_custom_bg_color(2, COLOR_CLASS)
				if dict["custom"] == true:
					item.set_icon(0, ICON_CUSTOM_SCRIPT)
				else:
					item.set_icon(0, ICON_CUSTOM_CLASS)
			elif dict["type"] == 3:
				item.set_custom_bg_color(0, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(1, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(2, COLOR_NATIVE_CLASS)
				item.collapsed = true
				item.set_icon(0, ICON_INTERFACE_SCRIPT)
			else:
				item.set_custom_bg_color(0, COLOR_INTERFACE)
				item.set_custom_bg_color(1, COLOR_INTERFACE)
				item.set_custom_bg_color(2, COLOR_INTERFACE)
				if dict["custom"] == true:
					item.set_icon(0, ICON_INTERFACE_SCRIPT)
				else:
					item.set_icon(0, ICON_INTERFACE_SCRIPT) #NOTNATIVE4NOW
			item.set_selectable(0, false)
			item.set_selectable(1, false)
			item.set_selectable(2, false)
			for key : Variant in funcs.keys():
				var sub_item : TreeItem = tree.create_item(item, -1)
				var func_name : PackedStringArray = (funcs[key] as String).split('||', false, 2)
				for fx : int in range(0, func_name.size(), 1):
					sub_item.set_text(fx, func_name[fx])
				sub_item.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
				sub_item.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
				sub_item.set_selectable(1, false)
				sub_item.set_selectable(2, false)
				sub_item.set_custom_color(1, COLOR_PARAMETERS)
				sub_item.set_custom_color(2, COLOR_PARAMETERS)
				if _created_funcs.has(key):
					sub_item.set_icon_overlay(0, ICON_CHECKED)
					sub_item.set_selectable(0, false)
				else:
					#if dict["type"] == 2 and !override.has(key):
						#sub_item.set_icon_overlay(0, ICON_WARNING)
					#else:
					sub_item.set_icon_overlay(0, null)
					sub_item.set_selectable(0, true)
				if (key as String).begins_with(_char_private_function):
					sub_item.set_icon(0, ICON_PRIVATE)
				elif (key as String).begins_with(_char_virtual_function):
					sub_item.set_icon(0, ICON_VIRTUALS)
				else:
					sub_item.set_icon(0, ICON_PUBLIC)
	else:
		for x : int in range(start, end, step):
			var dict : Dictionary = base[x]
			var funcs : Dictionary = dict["funcs"]

			if funcs.size() == 0:continue

			var item : TreeItem = tree.create_item(null, -1)

			item.set_text(0, dict["name"])
			if dict["type"] == 0:
				item.set_custom_bg_color(0, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(1, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(2, COLOR_NATIVE_CLASS)
				item.collapsed = true
				item.set_icon(0, ICON_NATIVE_CLASS)
			elif dict["type"]  == 1:
				item.set_custom_bg_color(0, COLOR_CLASS)
				item.set_custom_bg_color(1, COLOR_CLASS)
				item.set_custom_bg_color(2, COLOR_CLASS)
				if dict["custom"] == true:
					item.set_icon(0, ICON_CUSTOM_SCRIPT)
				else:
					item.set_icon(0, ICON_CUSTOM_CLASS)
			elif dict["type"] == 3:
				item.set_custom_bg_color(0, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(1, COLOR_NATIVE_CLASS)
				item.set_custom_bg_color(2, COLOR_NATIVE_CLASS)
				item.collapsed = true
				item.set_icon(0, ICON_INTERFACE_SCRIPT)
			else:
				item.set_custom_bg_color(0, COLOR_INTERFACE)
				item.set_custom_bg_color(1, COLOR_INTERFACE)
				item.set_custom_bg_color(2, COLOR_INTERFACE)
				if dict["custom"] == true:
					item.set_icon(0, ICON_INTERFACE_SCRIPT)
				else:
					item.set_icon(0, ICON_INTERFACE_SCRIPT) #NOTNATIVE4NOW
			item.set_selectable(0, false)
			item.set_selectable(1, false)
			item.set_selectable(2, false)
			for key : Variant in funcs.keys():
				var sub_item : TreeItem = tree.create_item(item, -1)
				var func_name : PackedStringArray = (funcs[key] as String).split('||', false, 2)
				for fx : int in range(0, func_name.size(), 1):
					sub_item.set_text(fx, func_name[fx])
				sub_item.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
				sub_item.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
				sub_item.set_selectable(1, false)
				sub_item.set_selectable(2, false)
				sub_item.set_custom_color(1, COLOR_PARAMETERS)
				sub_item.set_custom_color(2, COLOR_PARAMETERS)
				if _created_funcs.has(key):
					sub_item.set_icon_overlay(0, ICON_CHECKED)
					sub_item.set_selectable(0, false)
				else:
					#if dict["type"] == 2 and !override.has(key):
						#sub_item.set_icon_overlay(0, ICON_WARNING)
					#else:
					sub_item.set_icon_overlay(0, null)
					sub_item.set_selectable(0, true)
				if (key as String).begins_with(_char_private_function):
					sub_item.set_icon(0, ICON_PRIVATE)
				elif (key as String).begins_with(_char_virtual_function):
					sub_item.set_icon(0, ICON_VIRTUALS)
				else:
					sub_item.set_icon(0, ICON_PUBLIC)

	if root.get_child_count() == 0:
		root.set_text(0, "No functions aviables!")
		tree.hide_root = false

	_update_gui()

## Generate tree data, @output Array(base class data, total bases inherited class])
func generate_data(script : Script) -> Array:
	var data_base : Dictionary = {}
	var base_count : int = _generate_native(script.get_instance_base_type(), data_base, _generate(script.get_base_script(), data_base))
	return [data_base, base_count]

func _on_settings_change() -> void:
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	var changes : PackedStringArray = editor.get_changed_settings()
	if "plugin/gd_override_functions/generate_at_end_line" in changes:
		_generate_at_end_line = editor.get_setting("plugin/gd_override_functions/generate_at_end_line")
	if "plugin/gd_override_functions/order_inverted" in changes:
		var inverted : bool = editor.get_setting("plugin/gd_override_functions/order_inverted")
		if inverted:
			_last_filter = FILTER_TYPE.REVERSE
		else:
			_last_filter = FILTER_TYPE.DEFAULT
			
	if "plugin/gd_override_functions/initial_size" in changes:
		var _size : Variant = editor.get_setting("plugin/gd_override_functions/initial_size")
		if _size is Vector2 or _size is Vector2i:
			size = _size
			size.x = maxf(size.x, 512.0)
			size.y = maxf(size.y, 512.0)
		
#region init
func _ready() -> void:
	var w_size : Vector2 =  DisplayServer.window_get_size()
	if w_size != Vector2.ZERO:
		size = w_size * 0.6
		
	config_update(false)
	
	if !Engine.is_editor_hint():
		#Component created for be used in editor mode, so testing is invoke in non editor mode.
		_testing()


func _testing() -> void:
	await get_tree().process_frame

	#Also work with class_name
	var input_script : Script = ResourceLoader.load("res://addons/gd_override_functions/popup/testing/child.gd")

	#Show popup
	call_deferred(&"show")
	make_tree(input_script, _last_filter)

func _on_change_order_pressed() -> void:
	match _last_filter:
		#FILTER_TYPE.REVERSE:
			#_last_filter = FILTER_TYPE.DEFAULT
		#FILTER_TYPE.DEFAULT:
			#_last_filter = FILTER_TYPE.REVERSE_TREE
		#FILTER_TYPE.REVERSE_TREE:
			##_last_filter = FILTER_TYPE.DEFAUL_TREE
		#FILTER_TYPE.DEFAUL_TREE:
			#_last_filter = FILTER_TYPE.REVERSE
		FILTER_TYPE.REVERSE:
			_last_filter = FILTER_TYPE.DEFAULT
		FILTER_TYPE.DEFAULT:
			_last_filter = FILTER_TYPE.REVERSE
		_:
			_last_filter = FILTER_TYPE.REVERSE
	var root : TreeItem = tree.get_root()
	var collapsed : Dictionary = {}

	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			collapsed[tree_item.get_text(0)] = tree_item.collapsed
			tree_item = tree_item.get_next()

	make_tree(_last_script, _last_filter)
	root = tree.get_root()

	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			var txt : String = str(tree_item.get_text(0))
			if collapsed.has(txt):
				tree_item.collapsed = collapsed[txt]
			tree_item = tree_item.get_next()


func _on_public_filter_pressed() -> void:
	var root : TreeItem = tree.get_root()
	var collapsed : Dictionary = {}

	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			collapsed[tree_item.get_text(0)] = tree_item.collapsed
			tree_item = tree_item.get_next()

	_public_filter = !_public_filter
	make_tree(_last_script, _last_filter)

	root = tree.get_root()
	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			var txt : String = str(tree_item.get_text(0))
			if collapsed.has(txt):
				tree_item.collapsed = collapsed[txt]
			tree_item = tree_item.get_next()

func _on_protected_filter_pressed() -> void:
	var root : TreeItem = tree.get_root()
	var collapsed : Dictionary = {}

	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			collapsed[tree_item.get_text(0)] = tree_item.collapsed
			tree_item = tree_item.get_next()

	_protected_filter = !_protected_filter
	make_tree(_last_script, _last_filter)

	root = tree.get_root()
	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			var txt : String = str(tree_item.get_text(0))
			if collapsed.has(txt):
				tree_item.collapsed = collapsed[txt]
			tree_item = tree_item.get_next()

func _on_private_filter_pressed() -> void:
	var root : TreeItem = tree.get_root()
	var collapsed : Dictionary = {}

	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			collapsed[tree_item.get_text(0)] = tree_item.collapsed
			tree_item = tree_item.get_next()

	_private_filter = !_private_filter
	make_tree(_last_script, _last_filter)

	root = tree.get_root()
	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			var txt : String = str(tree_item.get_text(0))
			if collapsed.has(txt):
				tree_item.collapsed = collapsed[txt]
			tree_item = tree_item.get_next()

func _on_interface_filter_pressed() -> void:
	var root : TreeItem = tree.get_root()
	var collapsed : Dictionary = {}

	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			collapsed[tree_item.get_text(0)] = tree_item.collapsed
			tree_item = tree_item.get_next()

	_interface_filter = !_interface_filter
	make_tree(_last_script, _last_filter)

	root = tree.get_root()
	if root:
		var tree_item : TreeItem = root.get_first_child()
		while null != tree_item:
			var txt : String = str(tree_item.get_text(0))
			if collapsed.has(txt):
				tree_item.collapsed = collapsed[txt]
			tree_item = tree_item.get_next()


func _on_generate_virtual_pressed() -> void:
	if _buffer_data.size() == 0:
		print("Not class aviables!")
		return
	var funcs : Dictionary = {}
	for x : Variant in _buffer_data.keys():
		if _buffer_data[x]["type"] > 0:
			var _class_data : Dictionary = _buffer_data[x]
			var _funcs : Dictionary = _class_data["funcs"]
			for _func : Variant in _funcs.keys():
				var func_name : String = str(_func)
				if !func_name.begins_with(_char_private_function) and func_name.begins_with(_char_virtual_function):
					if _created_funcs.has(_func):
						continue
					funcs[_func] = {
						"type" : _class_data["type"]
						,"class" :_class_data["name"]
						,"name" : str(_func)
						}
	if funcs.size() == 0:
		print("Not has virtual methods for override/implement!")
		return
	_make(funcs)

func _on_generate_interface_pressed() -> void:
	if _buffer_data.size() == 0:
		print("Not class aviables!")
		return
	var funcs : Dictionary = {}
	for x : Variant in _buffer_data.keys():
		if _buffer_data[x]["type"] == 2:
			var _class_data : Dictionary = _buffer_data[x]
			var _funcs : Dictionary = _class_data["funcs"]
			for _func : Variant in _funcs.keys():
				if _created_funcs.has(_func):
					continue
				funcs[_func] = {
					"type" : _class_data["type"]
					,"class" :_class_data["name"]
					,"name" : str(_func)
					}
			continue
	if funcs.size() == 0:
		print("Not has interfaces methods for override/implement!")
		return
	_make(funcs)

func _on_check_generate_at_line(toggled : bool) -> void:
	_generate_at_end_line = toggled

func config_update(save : bool = false) -> void:
	const SETTING : String = "plugin/gd_override_functions/initial_size"
	const SETTING_CHECK : String = "plugin/gd_override_functions/save_size_on_exit"
	var editor : EditorSettings = EditorInterface.get_editor_settings()
	
	size.x = maxf(size.x, 512)
	size.y = maxf(size.y, 512)
	
	if editor:
		if !editor.has_setting(SETTING_CHECK):
			editor.set_setting(SETTING_CHECK, true)
			
		if !editor.has_setting(SETTING):
			editor.set_setting(SETTING, (size as Vector2i))
			return
			
		if save:
			if editor.get_setting(SETTING_CHECK) == true:
				editor.set_setting(SETTING, (size as Vector2i))
		else:
			size = editor.get_setting(SETTING)

func _init() -> void:	
	_private_begin_equal_protected = _char_private_function.begins_with(_char_virtual_function)
	if !is_node_ready():
		await ready
	assert(tree and accept_button and cancel_button)

	tree.select_mode = Tree.SELECT_MULTI
	tree.multi_selected.connect(_on_tree_multi_selected)
	cancel_button.pressed.connect(_on_cancel_button)

	if public_button:
		public_button.pressed.connect(_on_public_filter_pressed)
	if protected_button:
		protected_button.pressed.connect(_on_protected_filter_pressed)
	if private_button:
		private_button.pressed.connect(_on_private_filter_pressed)
	if interface_button:
		interface_button.pressed.connect(_on_interface_filter_pressed)
	if interface_generate_button:
		interface_generate_button.pressed.connect(_on_generate_interface_pressed)
	if virtual_generate_button:
		virtual_generate_button.pressed.connect(_on_generate_virtual_pressed)

	if order_button:
		order_button.pressed.connect(_on_change_order_pressed)

	if check_generate_at_line:
		check_generate_at_line.toggled.connect(_on_check_generate_at_line)

	COLOR_CLASS = COLOR_CLASS.darkened(0.4)
	COLOR_NATIVE_CLASS = COLOR_CLASS.darkened(0.4)
	COLOR_PARAMETERS = COLOR_CLASS.lightened(0.3)
	COLOR_INTERFACE = COLOR_CLASS.lightened(0.2)

	visibility_changed.connect(_on_change_visibility)


	var editor : EditorSettings = EditorInterface.get_editor_settings()
	if !editor.has_setting("plugin/gd_override_functions/generate_at_end_line"):
		editor.set_setting("plugin/gd_override_functions/generate_at_end_line", _generate_at_end_line)
		editor.add_property_info({
			 "name": "plugin/gd_override_functions/generate_at_end_line",
			"type" : TYPE_BOOL
		})
	else:
		_generate_at_end_line = editor.get_setting("plugin/gd_override_functions/generate_at_end_line")

	if !editor.has_setting("plugin/gd_override_functions/order_inverted"):
		editor.set_setting("plugin/gd_override_functions/order_inverted", _last_filter == FILTER_TYPE.REVERSE)
		editor.add_property_info({
			 "name": "plugin/gd_override_functions/order_inverted",
			"type" : TYPE_BOOL
		})
	else:
		var inverted : bool = editor.get_setting("plugin/gd_override_functions/order_inverted")
		if inverted:
			_last_filter = FILTER_TYPE.REVERSE
		else:
			_last_filter = FILTER_TYPE.DEFAULT
			
	if !editor.has_setting("plugin/gd_override_functions/inheritance/virtual_functions_begins_with"):
		editor.set_setting("plugin/gd_override_functions/inheritance/virtual_functions_begins_with", _char_virtual_function)
	if !editor.has_setting("plugin/gd_override_functions/inheritance/private_functions_begins_with"):
		editor.set_setting("plugin/gd_override_functions/inheritance/private_functions_begins_with", _char_private_function)
		
	if !editor.has_setting("plugin/gd_override_functions/interface/class_as_interface_if_begins_with"):
		editor.set_setting("plugin/gd_override_functions/interface/class_as_interface_if_begins_with", _interface_begins_with)
	if !editor.has_setting("plugin/gd_override_functions/interface/class_as_interface_if_end_with"):
		editor.set_setting("plugin/gd_override_functions/interface/class_as_interface_if_end_with", _interface_end_with)
	if !editor.has_setting("plugin/gd_override_functions/interface/class_interface_name_ignore_case"):
		editor.set_setting("plugin/gd_override_functions/interface/class_interface_name_ignore_case", false)
	if !editor.has_setting("plugin/gd_override_functions/inheritance/include_native_class_for_check_interfaces"):
		editor.set_setting("plugin/gd_override_functions/inheritance/include_native_class_for_check_interfaces", _include_native_class_for_check_interfaces)
	
	editor.settings_changed.connect(_on_settings_change)

	_update_gui()
#endregion

func _on_change_visibility() -> void:
	if !visible:
		_created_funcs.clear()
		_buffer_data.clear()

		var editor : EditorSettings = EditorInterface.get_editor_settings()
		editor.set_setting("plugin/gd_override_functions/generate_at_end_line", _generate_at_end_line)
		editor.set_setting("plugin/gd_override_functions/order_inverted", _last_filter == FILTER_TYPE.REVERSE)

		return

func _update_gui() -> void:
	if accept_button:
		accept_button.disabled = tree.get_selected() == null

	if public_button:
		public_button.button_pressed = _public_filter

	if protected_button:
		protected_button.button_pressed = _protected_filter

	if private_button:
		private_button.button_pressed = _private_filter

	if interface_button:
		interface_button.button_pressed = _interface_filter

	if order_button:
		if _last_filter == FILTER_TYPE.DEFAULT or _last_filter == FILTER_TYPE.DEFAUL_TREE:
			order_button.icon = ICON_ORDER_INVERT
		else:
			order_button.icon = ICON_ORDER_DEFAULT

	if check_generate_at_line:
		check_generate_at_line.button_pressed = _generate_at_end_line

	#UPDATE INTERFACE
	if virtual_generate_button:
		virtual_generate_button.disabled = true
		if _buffer_data.size() > 0:
			for x : Variant in _buffer_data.keys():
				if _buffer_data[x]["type"] > 0:
					var _class_data : Dictionary = _buffer_data[x]
					var _funcs : Dictionary = _class_data["funcs"]
					for _func : Variant in _funcs.keys():
						var func_name : String = str(_func)
						if !func_name.begins_with(_char_private_function) and func_name.begins_with(_char_virtual_function):
							if !_created_funcs.has(_func):
								virtual_generate_button.disabled = false
								break
					if !virtual_generate_button.disabled:
						break

	#UPDATE INTERFACE
	if interface_generate_button:
		interface_generate_button.disabled = true
		if _buffer_data.size() == 0:
			return
		for x : Variant in _buffer_data.keys():
			if _buffer_data[x]["type"] > 1:
				var _class_data : Dictionary = _buffer_data[x]
				var _funcs : Dictionary = _class_data["funcs"]
				for _func : Variant in _funcs.keys():
					if !_created_funcs.has(_func):
						interface_generate_button.disabled = false
						return

func _write_lines(_class_name : String, func_name : String, input_script : Script, data : String, is_interface : bool = false) -> bool:
	#ONLY EDITOR MODE
	if !Engine.is_editor_hint():
		print(data)
		return false

	var comment : String = "Override {0} {1}."
	var type : String = "function"

	if is_interface:
		comment = "Implement {0} {1}."

	if func_name.begins_with(_char_private_function):
		type = "private function"
	elif func_name.begins_with(_char_virtual_function):
		type = "virtual function"

	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var scripts : Array[Script] = script_editor.get_open_scripts()
	var scripts_editor : Array[ScriptEditorBase] = script_editor.get_open_script_editors()
	var edit : CodeEdit = null
	var iscript : int = -1

	for x : int in range(scripts.size()):
		if scripts[x] == input_script:
			iscript = x
			break

	if iscript == -1 or iscript >= scripts_editor.size():
		push_error("Error, can`t get editor!")
		return false

	edit = scripts_editor[iscript].get_base_editor()

	var new_line : String = str("#", comment.format([_class_name,type]),"\n", data)
	if !_generate_at_end_line and edit.get_caret_count() > 0:
		var line : int = -1
		for x : int in edit.get_caret_count():
			line = edit.get_caret_line(x)
			break
		if line > -1:
			var line_to : int = -1
			while line < edit.get_line_count():
				var ctxline : String = edit.get_line(line)
				if ctxline.length() > 0:
					if ctxline.begins_with(" ") or ctxline.begins_with("\t"):
						if !ctxline.strip_edges().is_empty():
							line_to = -1
						else:
							line_to = line
					else:
						if line_to == -1:
							line_to = line
						break
				else:
					if line_to == -1:
						line_to = line
				line += 1
			if line_to > -1 and line_to != edit.get_line_count() - 1:
				if line_to > 1:
					if !(edit.get_line(line_to - 1).strip_edges().is_empty()):
						new_line = str('\n', new_line)
				if line_to < edit.get_line_count() - 1:
					if !(edit.get_line(line_to + 1).strip_edges().is_empty()):
						new_line = str(new_line, '\n')
				var ctx : String = edit.get_line(line_to)
				if !ctx.strip_edges().is_empty():
					edit.set_line(line_to, new_line+'\n'+edit.get_line(line_to))
				else:
					edit.set_line(line_to, new_line)
				_goto_line(script_editor, line_to)
				return true

	if edit.text.ends_with("\n"):
		edit.text += str("\n", new_line)
	else:
		edit.text += str("\n\n", new_line)
	_goto_line(script_editor, edit.get_line_count() - 1)
	return true

# goto_line script-ide
func _goto_line(script_editor : ScriptEditor, index : int):
	script_editor.goto_line(index)

	var code_edit: CodeEdit = script_editor.get_current_editor().get_base_editor()
	code_edit.set_caret_line(index)
	code_edit.set_v_scroll(index)
	code_edit.set_caret_column(code_edit.get_line(index).length())
	code_edit.set_h_scroll(0)

	code_edit.grab_focus()

func __iterate_metada(buffer : PackedStringArray, input_script : Script, funcs : Dictionary, metadata : Array[Dictionary], totals : int = 0) -> int:
	if totals < funcs.size():
		for key : Variant in funcs.keys():
			var data : Dictionary = funcs[key]
			var class_type : int = data["type"]
			var _class_name : String = data["class"]
			var _func : String = data["name"]

			var is_interface : bool = class_type == 2

			for meta : Dictionary in metadata:
				if meta.name == _func:
					if _func in buffer:
						continue
					buffer.append(_func)
					if _write_lines(_class_name, _func, input_script, _get_full_header_virtual(meta), is_interface):
						if is_interface:
							print('[INFO] Created "{0}.{1}" interface function'.format([_class_name, _func]))
						else:
							print('[INFO] Created "{0}.{1}" function'.format([_class_name, _func]))
					else:
						if Engine.is_editor_hint():
							if is_interface:
								print('[INFO] Error on create "{0}.{1}" interface function!'.format([_class_name, _func]))
							else:
								print('[INFO] Error on create "{0}.{1}" function!'.format([_class_name, _func]))
					totals += 1
					if totals == funcs.size():
						break
	return totals

#region UI_CALLBACK
func _on_accept_button() -> void:
	var item : TreeItem = tree.get_next_selected(null)
	var funcs : Dictionary = {}

	while item != null:
		var parent : String = item.get_parent().get_text(0)
		var fname : String = item.get_text(0)

		for x : Variant in _buffer_data.keys():
			if _buffer_data[x]["name"] == parent:
				var _class_data : Dictionary = _buffer_data[x]
				var _funcs : Dictionary = _class_data["funcs"]
				if _funcs.has(fname):
					funcs[fname] = {
						"type" : _class_data["type"]
						,"class" :_class_data["name"]
						,"name" : fname
						}
		item = tree.get_next_selected(item)

	_make(funcs)

func _make(funcs : Dictionary) -> void:
	var type_base : StringName = _last_script.get_instance_base_type()
	var buffer : PackedStringArray = []
	if ClassDB.class_exists(type_base):
		__iterate_metada(buffer, _last_script, funcs, ClassDB.class_get_method_list(type_base), __iterate_metada(buffer, _last_script, funcs, _last_script.get_script_method_list(), 0),)
	else:
		__iterate_metada(buffer, _last_script, funcs, _last_script.get_script_method_list(), 0)
	_on_cancel_button()



func _on_cancel_button() -> void:
	hide()
	config_update(true)

func _on_tree_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	_update_gui()
#endregion

func _get_name(script : Script, ref_data : Dictionary) -> StringName:
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

func _clear_funcs(script : Script) -> Dictionary:
	var out : Dictionary = {}
	if Engine.is_editor_hint():
		var rgx : RegEx = RegEx.create_from_string("(?m)^func\\s+(\\w*)\\s*\\(")
		var source : String = script.source_code
		var script_editor: ScriptEditor = EditorInterface.get_script_editor()
		var scripts_editors : Array[ScriptEditorBase] = script_editor.get_open_script_editors()
		var scripts : Array[Script] = script_editor.get_open_scripts()
		var iscript : int = -1

		for x : int in range(scripts.size()):
			if scripts[x] == script:
				iscript = x
				break
		if iscript > -1 and scripts_editors.size() > iscript:
			source = scripts_editors[iscript].get_base_editor().text
		for rs : RegExMatch in rgx.search_all(source):
			if rs.strings.size() > 1:
				var fname : String = rs.strings[1]
				out[fname] = fname
	else:
		for methods : Dictionary in script.get_script_method_list():
			out[methods.name] = methods.name
	return out

func _generate_native(native :  StringName, data : Dictionary, index : int = 0) -> int:
	if native.is_empty() or !ClassDB.class_exists(native):
		return index
	var funcs : Dictionary = {}
	var base : Dictionary = {
		"name" : native
		,"funcs" : funcs
		,"type" : 0
		,"custom": false
	}
	index += 1
	data[index] = base
	
	if _include_native_class_for_check_interfaces:
		var base_name : String = native
		if _interface_ignore_case:
			base_name = base_name.to_lower()
		if (!_interface_begins_with.is_empty() and base_name.begins_with(_interface_begins_with)) or \
		(!_interface_end_with.is_empty() and base_name.ends_with(_interface_end_with)):
			base["type"] = 3
	
	if _interface_filter and base["type"] == 3:
		#SHOW ALL
		for dict: Dictionary in ClassDB.class_get_method_list(native):
			funcs[dict.name] = _get_header_virtual(dict)
	else:
		for dict: Dictionary in ClassDB.class_get_method_list(native):
			#region conditional
			if _protected_filter:
				if dict.flags & METHOD_FLAG_VIRTUAL > 0:
					funcs[dict.name] =_get_header_virtual(dict)
					continue
			if _public_filter:
				var method : StringName = dict.name
				if _private_begin_equal_protected:
					if !method.begins_with(_char_virtual_function):
						funcs[method] = _get_header_virtual(dict)
						continue
				else:
					if !method.begins_with(_char_private_function) and !method.begins_with(_char_virtual_function):
						funcs[method] =_get_header_virtual(dict)
						continue
			if _private_filter:
				var method : StringName = dict.name
				if _private_begin_equal_protected:
					if method.begins_with(_char_private_function):
						funcs[method] =_get_header_virtual(dict)
				else:
					if method.begins_with(_char_private_function) and !method.begins_with(_char_virtual_function):
						funcs[method] =_get_header_virtual(dict)
			#endregion

	for x : int in range(0, index, 1):
		var clazz : Dictionary = data[x]["funcs"]
		for k : Variant in funcs.keys():
			if clazz.has(k):
				clazz.erase(k)

	return _generate_native(ClassDB.get_parent_class(native), data, index)

func _generate(script : Script, data : Dictionary, index : int = -1) -> int:
	if script == null:
		return index
	var funcs : Dictionary = {}
	var base : Dictionary = {
		"name" : &"GDScript"
		,"funcs" : funcs
		,"type": 1
		,"custom": false
	}
	var base_name : String = _get_name(script, base)
	base["name"] = base_name
	index += 1
	data[index] = base

	if _interface_ignore_case:
		base_name = base_name.to_lower()
		
	if (!_interface_begins_with.is_empty() and base_name.begins_with(_interface_begins_with)) or \
	(!_interface_end_with.is_empty() and base_name.ends_with(_interface_end_with)):
		base["type"] = 2

	if _interface_filter and base["type"] == 2:
		#SHOW ALL
		for dict: Dictionary in script.get_script_method_list():
			if dict.name.begins_with("@"):continue
			funcs[dict.name] = _get_header_virtual(dict)
	else:
		for dict: Dictionary in script.get_script_method_list():
			var func_name: StringName = dict.name
			if func_name.begins_with("@"):continue
			#region conditional
			if _protected_filter:
				if (func_name.begins_with(_char_virtual_function) and !func_name.begins_with(_char_private_function)) or dict.flags & METHOD_FLAG_VIRTUAL > 0:
					funcs[func_name] = _get_header_virtual(dict)
			if _public_filter:
				if _private_begin_equal_protected:
					if !func_name.begins_with(_char_virtual_function):
						funcs[func_name] =_get_header_virtual(dict)
						continue
				else:
					if !func_name.begins_with(_char_private_function) and !func_name.begins_with(_char_virtual_function):
						funcs[func_name] =_get_header_virtual(dict)
						continue
			if _private_filter:
				if _private_begin_equal_protected:
					if func_name.begins_with(_char_private_function):
						funcs[func_name] =_get_header_virtual(dict)
				else:
					if func_name.begins_with(_char_private_function) and !func_name.begins_with(_char_virtual_function):
						funcs[func_name] =_get_header_virtual(dict)
			#endregion

	for x : int in range(0, index, 1):
		var clazz : Dictionary = data[x]["funcs"]
		for k : Variant in funcs.keys():
			if clazz.has(k):
				clazz.erase(k)
	return _generate(script.get_base_script(), data, index)

func __is_variant(func_name : String) -> bool:
	const FUNC_GET : Array[String] = ["get_", "_get"]
	for x : String in FUNC_GET:
		if func_name.begins_with(x) or func_name.ends_with(x):
			return true
	return func_name.contains("_get_")

func _get_header_virtual(dict : Dictionary) -> String:
	var params : String = ""
	var args : Array = dict["args"]
	var separator : String = ""
	var default_args : Array = dict["default_args"]
	var _default_index : int = default_args.size()

	for y : int in range(args.size() - 1, -1, -1):
		var arg : Dictionary = args[y]
		var txt : String = "" #arg["name"]
		if !(arg["class_name"]).is_empty():
			txt += str(arg["class_name"] as String)
		else:
			var _typeof : int = arg["type"]
			txt += str(_get_type(_typeof))
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
				txt += str(" = ",_get_type(typeof(def)), def)
		params = str(txt, separator, params)
		separator = ", "

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
			return_type = _get_type(return_dic["type"])

	if params.is_empty():
		params = "-"
	return "{0}||{1}||{2}".format([dict["name"], params, return_type]).replace(" ", "") #Replace x more space.

func _get_full_header_virtual(dict : Dictionary) -> String:
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
			txt += str(" : ", _get_type(_typeof))
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
				txt += str(" = ",_get_type(typeof(def)), def)
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
			return_type = _get_type(return_dic["type"])
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

func _get_type(_typeof : int) -> String:
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
