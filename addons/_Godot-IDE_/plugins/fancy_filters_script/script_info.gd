@tool
extends Control
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	

const PUBLIC_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/func_public.svg")
const PRIVATE_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/func_private.svg")
const PROTECTED_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/func_virtual.svg")
const STATIC_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/static.svg")
const CONST_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/static.svg")
const EXPORT_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberAnnotation.svg")
const OVERRIDED_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MethodOverride.svg")
const CHECKED_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/check.svg")

var DOTS_ICON : Texture2D = null

const SCRIPT_TOOL_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/Tools.svg")
const SCRIPT_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/Script.svg")
const SCRIPT_EXTEND_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/ScriptExtend.svg")
const SCRIPT_ABSTRACT_ICON : Texture2D = SCRIPT_ICON
const SCRIPT_NATIVE_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/InterfaceScript.svg")

const MEMBER_ANNOTATION_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberAnnotation.svg")
const MEMBER_CONSTANT_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberConstant.svg")
#const MEMBER_CONSTRUCTOR_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberConstructor.svg")
const MEMBER_METHOD_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberMethod.svg")
#const MEMBER_OPERATOR_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberOperator.svg")
const MEMBER_PROPERTY_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberProperty.svg")
const MEMBER_SIGNAL_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberSignal.svg")
const MEMBER_OVERRIDE_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MethodOverride.svg")

enum SORT_NAME_TYPE{
	NONE = 0,
	ORDER_NAME_NORMAL = 1,
	ORDER_NAME_INVERT = 2#,
	#ORDER_ACCESSIBILITY_NORMAL,
	#ORDER_ACCESSIBILITY_INVERT
}

@export var button_container : Control = null
@export var tree_container : Tree = null

#region CONFIG
var use_colors_in_tittles : bool = false
var use_dots_as_item_icons : bool = false
var use_background_color_in_script_info : bool = false

var show_properties : bool = true
var show_signals : bool = true
var show_constants : bool = true
var show_parent_class : bool = true
var show_native_class : bool = false
var show_functions : bool = true
var show_inheritance : bool = false

var show_properties_color : Color = Color.ORANGE
var show_signals_color : Color = Color.GREEN
var show_constants_color : Color = Color.CYAN
var show_parent_class_color : Color = Color.WHITE
var show_native_class_color : Color = Color.WHITE
var show_function_color : Color = Color.YELLOW

var properties_color_item : Color = Color.WHITE
var signals_color_item : Color = Color.WHITE
var constants_color_item : Color = Color.WHITE
#var parent_class_color_item : Color = Color.WHITE
#var native_class_color_item : Color = Color.WHITE
var function_color_item : Color = Color.WHITE
var inheritance_color_item : Color = Color.CYAN

	
#var accessibility_order_by : Array[int] = [0,1,2,3,4,5]
var members_order_by : Array[int] = [0,1,2,3]
var name_order_by : SORT_NAME_TYPE = SORT_NAME_TYPE.NONE
#endregion

var _pop : Popup = null

var _buffer : Dictionary = {}
var _last : Variant = null

#var accessibility : AccesibilityOrder = null

#func _init() -> void:
	#accessibility = AccesibilityOrder.new(accessibility_order_by.size())

func _is_in_change(plugin : String, item : String, array : PackedStringArray) -> bool:
	item = plugin.path_join(item)
	for x : String in array:
		if x.ends_with(item):
			return true
	return false
	
func _setup(changes : PackedStringArray = []) -> void:
	var PLUGIN : String = "fancy_filters_script"
	var dirty : bool = false

	for x : String in [
		"show_properties"
		,"show_signals"
		,"show_constants"
		,"show_parent_class"
		,"show_native_class"
		,"show_functions"
		,"show_inheritance"
		,"use_colors_in_tittles"
		,"use_dots_as_item_icons"
		, "use_background_color_in_script_info"
		,"show_properties_color"
		,"show_signals_color"
		,"show_constants_color"
			#,"show_parent_class_color"
			#,"show_native_class_color"
		,"show_function_color"
		,"properties_color_item"
		,"signals_color_item"
		,"constants_color_item"
			#,"parent_class_color_item"
			#,"native_class_color_item"
		,"function_color_item"
		,"inheritance_color_item"
		#,"accessibility_order_by"
		,"members_order_by"
		,"name_order_by"
		]:
		if changes.size() == 0 or _is_in_change(PLUGIN, x, changes):
			var value : Variant = get(x)
			if value != null:
				var current : Variant = IDE.get_config(PLUGIN, x)
				if typeof(current) == typeof(value):
					set(x, current)
					dirty = true
				else:
					IDE.set_config(PLUGIN, x, value)
			else:
				push_warning("Its broke! > ", x)

	if use_dots_as_item_icons:
		if DOTS_ICON == null:
			DOTS_ICON = ResourceLoader.load("res://addons/_Godot-IDE_/shared_resources/dot.svg")
	else:
		DOTS_ICON = null

	if changes.size() > 0 and dirty:
		propagate_call(&"update_settings")
		force_update()

func _on_settings_changed() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		var changes : PackedStringArray = settings.get_changed_settings()
		_setup(changes)
		
func _enter_tree() -> void:
	_setup()
	
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if !editor.editor_script_changed.is_connected(_on_change_script):
			editor.editor_script_changed.connect(_on_change_script)
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		if !settings.settings_changed.is_connected(_on_settings_changed):
			settings.settings_changed.connect(_on_settings_changed)
	
		
func _exit_tree() -> void:
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if editor.editor_script_changed.is_connected(_on_change_script):
			editor.editor_script_changed.disconnect(_on_change_script)
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings:
		if settings.settings_changed.is_connected(_on_settings_changed):
			settings.settings_changed.disconnect(_on_settings_changed)

func enable_filter(filter_name : StringName, value : bool) -> void:
	if filter_name == &"show_all":
		var buttons : Array[Node] = button_container.get_children()
		if buttons[0] is Button:
			var val : bool = buttons[0].button_pressed
			for node : Node in buttons:
				if node is Button:
					node.button_pressed = val
					if get(node.name) != null:
						set(node.name, value)
	else:
		if get(filter_name) != null:
			set(filter_name, value)
		var buttons : Array[Node] = button_container.get_children()
		var all : Button = buttons[0]
		all.button_pressed = true
		for node : Node in buttons:
			if node is Button:
				if node.button_pressed == false and node != all:
					all.button_pressed = false
					break
	force_update()
	
func _on_collapsed(item : TreeItem) -> void:
	var meta : Variant = item.get_metadata(0)
	if meta is String:
		_buffer[meta] = item.collapsed
	
func _process(_delta: float) -> void:
	set_process(false)
	
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	var sc : Script = _last
	_last = null
	if editor:
		var nsc : Script = editor.get_current_script()
		if nsc:
			sc = nsc
	_on_change_script(sc)
	
func force_update() -> void:
	set_process(true)
		
func _on_activate() -> void:
	if tree_container:
		if is_instance_valid(_last):
			var current : Script = _last
			var item : TreeItem = tree_container.get_selected()
			if !item:
				return
			var symbol_name : String = item.get_text(0).split(" ", false, 1)[0]
			while true:
				var st : String = current.resource_path
				if !FileAccess.file_exists(st):
					return
					
				var script_content : String = FileAccess.get_file_as_string(st)
				var lines : PackedStringArray = script_content.split("\n", true)
				var line_number : int = -1

				var pattern : RegEx = RegEx.create_from_string("[\\s]*var[\\n\\t\\s]+\\b" + symbol_name + "\\b.*|\\s*const[\\n\\t\\s]+\\b" + symbol_name + "\\b.*|\\s*func[\\n\\t\\s]+\\b" + symbol_name + "|\\s*signal[\\n\\t\\s]+\\b" + symbol_name)
				for x : int in range(lines.size()):
					var line : String = lines[x]
					if pattern.search(line):
						line_number = x
						break
						
				if line_number > -1:
					var sce: ScriptEditor = EditorInterface.get_script_editor()
					if !sce:
						return
					if sce.get_current_script() != current:
						EditorInterface.edit_script(current, line_number, 0, true)
					sce.goto_line(line_number)
					return
				var base : Script = current.get_base_script()
				if base != null:
					current = base
					continue
				break
			var type : StringName = current.get_instance_base_type()
			while !type.is_empty():
				if ClassDB.class_exists(type):
					var symbol : String = item.get_tooltip_text(0)
					var prefx : String = ""
					if type == "GraphNode":
						prefx = "class_theme_item"
					if symbol.begins_with("@"):
						prefx = "class_annotation"
					elif ClassDB.class_has_signal(type, symbol_name):
						prefx = "class_signal"
					elif ClassDB.class_has_enum(type, symbol_name, true):
						prefx = "class_constant"
					elif ClassDB.class_has_integer_constant(type, symbol_name):
						prefx = "class_constant"
					else:
						var list : Array[Dictionary] = ClassDB.class_get_property_list(type, true)
						for x : Dictionary in list:
							if x.name == symbol_name:
								prefx = "class_property"
								break
						if prefx.is_empty():
							list = ClassDB.class_get_method_list(type, true)
							for x : Dictionary in list:
								if x.name == symbol_name:
									prefx = "class_method"
									break
					if !prefx.is_empty():
						var path : String = "{0}:{1}:{2}".format([prefx, type, symbol_name])
						EditorInterface.get_script_editor().goto_help(path)
						return
					type = ClassDB.get_parent_class(type)
					continue
				break
	
func _copy(fnc : String,data : String, type : int) -> void:
	if type == 1:
		data = data.trim_prefix("func ").split(")", false, 1)[0] + ")"
	elif type == 2:
		var packed : PackedStringArray = data.trim_prefix("func ").split("(", false, 1)
		data = packed[0] + ".emit("
		data += packed[1].split(")", true, 1)[0] + ")"
	elif type == 3:
		data = fnc
	else:
		var packed : PackedStringArray = data.split("\n", false, 0)
		if packed.size() > 1:
			data = str(packed[0], " ", packed[packed.size() - 1].strip_edges())
	DisplayServer.clipboard_set(data)
	print("Copied in clipboard: [", fnc, "] use ctrl + v for paste!")
				
func _on_pop_selection(option : StringName, item : TreeItem) -> void:
	if is_instance_valid(item):
		var parent : TreeItem = item.get_parent()
		if parent:
			if option == &"goto":
				tree_container.item_activated.emit()
			elif option == &"copy" or option == &"override_copy":
				var icon : Texture2D = parent.get_icon(0)
				if icon == null:
					return
				var itype : int = 3
				if icon == MEMBER_METHOD_ICON:
					if option == &"override_copy":
						itype = 0
					else:
						itype = 1
				elif icon == MEMBER_SIGNAL_ICON:
					itype = 2
				var editor : ScriptEditor = EditorInterface.get_script_editor()
				if editor:
					var sc : Script = editor.get_current_script()
					if sc:
						var func_ : StringName = item.get_text(0).get_slice(" ", 0)
						if itype == 3:
							_copy(func_, func_, itype)
							return
						if itype != 2:
							var base : Script = sc
							while base != null:
								for d : Dictionary in base.get_script_method_list():
									if d.name == func_:
										_copy(func_, IDE.get_header_function(d),itype)
										return
								for d : Dictionary in base.get_method_list():
									if d.name == func_:
										_copy(func_, IDE.get_header_function(d),itype)
										return
								var nbase : Script = base.get_base_script()
								if nbase != null:
									base = nbase
								break
							if base != null:
								var type : StringName = base.get_instance_base_type()
								if ClassDB.class_exists(type):
									for d : Dictionary in ClassDB.class_get_method_list(type, false):
										if d.name == func_:
											_copy(func_, IDE.get_header_function(d),itype)
											return
						else:
							var base : Script = sc
							while base != null:
								for d : Dictionary in base.get_script_signal_list():
									if d.name == func_:
										_copy(func_, IDE.get_header_function(d),itype)
										return
								for d : Dictionary in base.get_signal_list():
									if d.name == func_:
										_copy(func_, IDE.get_header_function(d),itype)
										return
								var nbase : Script = base.get_base_script()
								if nbase != null:
									base = nbase
								break
							if base != null:
								var type : StringName = base.get_instance_base_type()
								if ClassDB.class_exists(type):
									for d : Dictionary in ClassDB.class_get_signal_list(type, false):
										if d.name == func_:
											_copy(func_, IDE.get_header_function(d),itype)
											return
				

func _on_mouse(_mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var editor : ScriptEditor = EditorInterface.get_script_editor()
		if editor:
			var sc : Script = editor.get_current_script()
			if !is_instance_valid(sc):
				print("[INFO] The current editor does not have script focus!")
				return
		
		var item : TreeItem = tree_container.get_selected()
		if item:
			var parent : TreeItem = item.get_parent()
			if parent:
				var icon : Texture2D = parent.get_icon(0)
				if icon == null:
					return
				for x : Texture2D in [
					MEMBER_CONSTANT_ICON,
					MEMBER_METHOD_ICON,
					MEMBER_SIGNAL_ICON,
					MEMBER_PROPERTY_ICON
					]:
						if icon == x:
							var is_first : bool = true
							parent = parent.get_parent()
							if parent and parent.get_index() > 0:
								is_first = false
							if !is_instance_valid(_pop):
								var res : PackedScene = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/fancy_filters_script/pop_tree.tscn")
								_pop = res.instantiate()
								add_child(_pop)
							_pop.callback = _on_pop_selection.bind(item)
							_pop.enable_copy_override(!is_first and MEMBER_METHOD_ICON == icon)
							
							_pop.position = get_global_mouse_position() # Delete? #5
							_pop.popup() # Delete? #5
							## MACOS: Uncomment #5
							#var os_name : String = OS.get_name()
							#match  os_name:
								#"macOS":
									#_pop.popup_centered()
								#"iOS":
									#_pop.popup_centered()
								#_:
									#_pop.position = get_global_mouse_position() # IDE.clamp
									#_pop.popup()
							return
			
	
func _custom_order(s1 : String, s2 : String) -> bool:
	for x : int in mini(s1.length(), s2.length()):
		var c1 : String = s1[x].to_lower()
		var c2 : String = s2[x].to_lower()
		if c1 == c2:
			continue
		return c1 < c2
	return false
	
func _order_name(keys : Array) -> Array:
	if name_order_by != SORT_NAME_TYPE.NONE:
		if name_order_by == SORT_NAME_TYPE.ORDER_NAME_NORMAL:
			keys.sort_custom(_custom_order)
		elif name_order_by == SORT_NAME_TYPE.ORDER_NAME_INVERT:
			keys.sort_custom(_custom_order)
			keys.reverse()
	return keys
	
func _on_change_script(script : Script) -> void:
	if _last == script:
		return
	_last = script
	tree_container.clear()
	if script == null:
		return
	var data : Dictionary = IDE.get_script_properties_list(script)
	var root : TreeItem = tree_container.create_item()
	tree_container.columns = 1#3
	var path : String = script.resource_path
	if !path.is_empty():
		root.set_text(0, "* {0}  [{1}]".format([path.get_file(),path]))
	else:
		root.set_text(0, "Info")
					
	if _buffer.size() > 40:
		_buffer.clear()
		
	if !tree_container.item_collapsed.is_connected(_on_collapsed):
		tree_container.item_collapsed.connect(_on_collapsed)
	
	if !tree_container.item_activated.is_connected(_on_activate):
		tree_container.item_activated.connect(_on_activate)
		
	if !tree_container.item_mouse_selected.is_connected(_on_mouse):
		tree_container.allow_rmb_select = true
		tree_container.item_mouse_selected.connect(_on_mouse)
		
	
	var private_methods : String = IDE.PRIVATE_METHODS
	var protected_methods : String = IDE.VIRTUAL_METHODS
	
	tree_container.set_column_expand(0, true)
	tree_container.set_column_custom_minimum_width(0, 200)
	root.set_expand_right(0, true)
	root.set_selectable(0, false)
	
	var BASE_COLOR : Color = root.get_custom_color(0)
	if BASE_COLOR == Color.BLACK:
		BASE_COLOR = Color.WHITE
	
	var PRIMARY_COLOR : Color = BASE_COLOR.darkened(0.2)
	var SECONDARY_COLOR : Color = BASE_COLOR.darkened(0.4)
	
	var public_icon : Texture2D = PUBLIC_ICON
	var private_icon : Texture2D = PRIVATE_ICON
	var virtual_icon : Texture2D = PROTECTED_ICON
	var public_icon_modulate: Color = Color.WHITE
	var private_icon_modulate: Color = Color.WHITE
	var virtual_icon_modulate: Color = Color.WHITE
	
	if use_dots_as_item_icons and null != DOTS_ICON:
		public_icon = DOTS_ICON
		private_icon = DOTS_ICON
		virtual_icon = DOTS_ICON
		public_icon_modulate = Color.GREEN
		private_icon_modulate = Color.YELLOW
		virtual_icon_modulate = Color.REBECCA_PURPLE
	
	var index : int = -1
	var src : String = script.source_code
	var track_override : Dictionary[StringName, bool] = {}
	
	for sc : Dictionary in data.values():
		index += 1
		if index > 0:
			var native : bool = sc["path"] == "NativeScript"
			if native and !show_native_class:
				continue
			elif !native and !show_parent_class:
				continue
		
		var tree_item : TreeItem = root.create_child()
		var meta : String = str("C", index)
		tree_item.set_text(0, sc["name"])
		tree_item.set_tooltip_text(0, sc["path"])
		tree_item.set_metadata(0, meta)
		tree_item.set_custom_color(0, BASE_COLOR)
		tree_item.set_icon_modulate(0, Color.WHITE)
		if _buffer.has(meta):
			tree_item.collapsed = _buffer[meta]
		if sc["tool"]:
			tree_item.set_icon(0, SCRIPT_TOOL_ICON)
			tree_item.set_icon_modulate(0, Color.DEEP_SKY_BLUE)
			if index > 0:
				tree_item.set_icon_overlay(0, OVERRIDED_ICON)
		elif sc["abstract"]:
			tree_item.set_icon(0, SCRIPT_ABSTRACT_ICON)
			if index > 0:
				tree_item.set_icon_overlay(0, OVERRIDED_ICON)
		elif sc["path"] == "NativeScript":
			tree_item.set_icon(0, SCRIPT_NATIVE_ICON)
		else:
			if index > 0:
				tree_item.set_icon(0, SCRIPT_EXTEND_ICON)
			else:
				tree_item.set_icon(0, SCRIPT_ICON)
		tree_item.set_selectable(0, false)
		
		var sc_data : Dictionary = {}
		for order : int in members_order_by:
			if order == 0 and show_properties:
				sc_data = sc["properties"]
				if sc_data.size() > 0:
					#accessibility.reset()
					var mthds : TreeItem = tree_item.create_child()
					var item_color : Color = SECONDARY_COLOR
					var override_item_color : Color = inheritance_color_item
					if properties_color_item != Color.WHITE:
						item_color = properties_color_item
					mthds.set_text(0, "Properties")
					mthds.set_selectable(0, false)
					mthds.set_icon(0, MEMBER_PROPERTY_ICON)
					if use_background_color_in_script_info:
						var c : Color = show_properties_color
						c.a = 0.15
						mthds.set_custom_bg_color(0, c)
					if use_colors_in_tittles:
						mthds.set_custom_color(0, show_properties_color)
					else:
						mthds.set_custom_color(0, PRIMARY_COLOR)
					meta = str("P", index)
					mthds.set_metadata(0, meta)
					mthds.set_icon_modulate(0, show_properties_color)
					if _buffer.has(meta):
						mthds.collapsed = _buffer[meta]
					else:
						mthds.collapsed = true	
					for fnc : StringName in _order_name(sc_data.keys()):
						var packed : PackedStringArray = sc_data[fnc].split("||")
						var override : bool = false
						if "overrided" in packed:
							if !show_inheritance:
								continue
							override = true
						var _item : TreeItem = mthds.create_child()
						var text : String = "{0} : {1}".format([packed[0], packed[1]])
						_item.set_text(0, text)
						if "export" in packed:
							_item.set_icon(0, EXPORT_ICON)
							_item.set_tooltip_text(0, str("@export var ", text))
							#accessibility.add(0, fnc)
						elif "static" in packed:
							_item.set_icon(0, STATIC_ICON)
							_item.set_tooltip_text(0, str("static var ", text))
							#accessibility.add(1, fnc)
						elif "const" in packed:
							_item.set_icon(0, CONST_ICON)
							_item.set_tooltip_text(0, str("const ", text))
							#accessibility.add(2, fnc)
						elif fnc.begins_with(private_methods):
							_item.set_icon(0, private_icon)
							_item.set_icon_modulate(0, private_icon_modulate)
							#accessibility.add(3, fnc)
						elif fnc.begins_with(protected_methods):
							_item.set_icon(0, virtual_icon)
							_item.set_icon_modulate(0, virtual_icon_modulate)
							#accessibility.add(4, fnc)
						else:
							_item.set_icon(0, public_icon)
							_item.set_icon_modulate(0, public_icon_modulate)
							#accessibility.add(5, fnc)
						if override:
							#accessibility.add_overrided(fnc)
							_item.set_icon_overlay(0, OVERRIDED_ICON)
							_item.set_custom_color(0, override_item_color)
						else:
							_item.set_custom_color(0, item_color)
						if use_background_color_in_script_info:
							var c : Color = show_properties_color
							c.a = 0.05
							_item.set_custom_bg_color(0, c)
			
			elif order == 1 and show_functions:
				sc_data = sc["functions"]
				if sc_data.size() > 0:
					var mthds : TreeItem = tree_item.create_child()
					var item_color : Color = SECONDARY_COLOR
					var override_item_color : Color = inheritance_color_item
					if function_color_item != Color.WHITE:
						item_color = function_color_item
					mthds.set_text(0, "Methods")
					mthds.set_selectable(0, false)
					mthds.set_icon(0, MEMBER_METHOD_ICON)
					if use_background_color_in_script_info:
						var c : Color = show_function_color
						c.a = 0.15
						mthds.set_custom_bg_color(0, c)
					if use_colors_in_tittles:
						mthds.set_custom_color(0, show_function_color)
					else:
						mthds.set_custom_color(0, PRIMARY_COLOR)
					meta = str("F", index)
					mthds.set_metadata(0, meta)
					mthds.set_icon_modulate(0, show_function_color)
					if _buffer.has(meta):
						mthds.collapsed = _buffer[meta]
					else:
						mthds.collapsed = true	
					
					for fnc : StringName in _order_name(sc_data.keys()):
						var packed : PackedStringArray = sc_data[fnc].split("||")
						var override : bool = false
						if "overrided" in packed:
							if index > 0:
								if !show_inheritance:
									continue
							else:
								if !show_inheritance:
									if null == RegEx.create_from_string("func[\\s\\t\\n]*\\b{0}[\\s\\t\\n]*\\(".format([fnc])).search(src):
										continue
								track_override[fnc] = true
							override = show_inheritance
							
						var _item : TreeItem = mthds.create_child()
						var text : String = "{0} ( {1} ) -> {2}".format([packed[0], packed[1], packed[2]])
						if "static" in packed:
							_item.set_icon(0, STATIC_ICON)
							_item.set_tooltip_text(0, str("static var ", text))
						elif "const" in packed:
							_item.set_icon(0, CONST_ICON)
							_item.set_tooltip_text(0, str("const ", text))
						elif fnc.begins_with(private_methods):
							_item.set_icon(0, private_icon)
							_item.set_icon_modulate(0, private_icon_modulate)
						elif fnc.begins_with(protected_methods):
							_item.set_icon(0, virtual_icon)
							_item.set_icon_modulate(0, virtual_icon_modulate)
						else:
							_item.set_icon(0, public_icon)
							_item.set_icon_modulate(0, public_icon_modulate)
						if override:
							_item.set_icon_overlay(0, OVERRIDED_ICON)
							_item.set_custom_color(0, override_item_color)
						else:
							_item.set_custom_color(0, item_color)
						if index > 0:
							if track_override.has(fnc):
								_item.set_icon_overlay(0, CHECKED_ICON)
						_item.set_text(0, text)
						if use_background_color_in_script_info:
							var c : Color = show_function_color
							c.a = 0.05
							_item.set_custom_bg_color(0, c)
											
			elif order == 2 and show_signals:
				sc_data = sc["signals"]
				if sc_data.size() > 0:
					var mthds : TreeItem = tree_item.create_child()
					var item_color : Color = SECONDARY_COLOR
					var override_item_color : Color = inheritance_color_item
					if signals_color_item != Color.WHITE:
						item_color = signals_color_item
					mthds.set_text(0, "Signals")
					mthds.set_selectable(0, false)
					mthds.set_icon(0, MEMBER_SIGNAL_ICON)
					if use_background_color_in_script_info:
						var c : Color = show_signals_color
						c.a = 0.15
						mthds.set_custom_bg_color(0, c)
					if use_colors_in_tittles:
						mthds.set_custom_color(0, show_signals_color)
					else:
						mthds.set_custom_color(0, PRIMARY_COLOR)
					meta = str("S", index)
					mthds.set_metadata(0, meta)
					mthds.set_icon_modulate(0, show_signals_color)
					if _buffer.has(meta):
						mthds.collapsed = _buffer[meta]
					else:
						mthds.collapsed = true	
					
					for fnc : StringName in _order_name(sc_data.keys()):
						var packed : PackedStringArray = sc_data[fnc].split("||")
						var override : bool = false
						if "overrided" in packed:
							if !show_inheritance:
								continue
							override = true
						var _item : TreeItem = mthds.create_child()
						_item.set_text(0, "{0} ( {1} ) -> {2}".format([packed[0], packed[1], packed[2]]))
						
						_item.set_icon(0, MEMBER_SIGNAL_ICON)
						if override:
							_item.set_icon_overlay(0, OVERRIDED_ICON)
							_item.set_custom_color(0, override_item_color)
						else:
							_item.set_custom_color(0, item_color)
						if use_background_color_in_script_info:
							var c : Color = show_signals_color
							c.a = 0.05
							_item.set_custom_bg_color(0, c)
							
			elif order == 3 and show_constants:
				sc_data = sc["constants"]
				if sc_data.size() > 0:
					var mthds : TreeItem = tree_item.create_child()
					var item_color : Color = SECONDARY_COLOR
					var override_item_color : Color = inheritance_color_item
					if constants_color_item != Color.WHITE:
						item_color = constants_color_item
					mthds.set_text(0, "Constant")
					mthds.set_selectable(0, false)
					mthds.set_icon(0, MEMBER_CONSTANT_ICON)
					if use_background_color_in_script_info:
						var c : Color = show_constants_color
						c.a = 0.15
						mthds.set_custom_bg_color(0, c)
					if use_colors_in_tittles:
						mthds.set_custom_color(0, show_constants_color)
					else:
						mthds.set_custom_color(0, PRIMARY_COLOR)
					meta = str("I", index)
					mthds.set_metadata(0, meta)
					mthds.set_icon_modulate(0, show_constants_color)
					if _buffer.has(meta):
						mthds.collapsed = _buffer[meta]
					else:
						mthds.collapsed = true	
					for fnc : StringName in _order_name(sc_data.keys()):
						var packed : PackedStringArray = sc_data[fnc].split("||")
						var override : bool = false
						if "overrided" in packed:
							if !show_inheritance:
								continue
							override = true
						var _item : TreeItem = mthds.create_child()
						_item.set_text(0, "{0} : {1}".format([packed[0], packed[1]]))
						_item.set_icon(0, MEMBER_CONSTANT_ICON)
						if override:
							_item.set_icon_overlay(0, OVERRIDED_ICON)
							_item.set_custom_color(0, override_item_color)
						else:
							_item.set_custom_color(0, item_color)
						if use_background_color_in_script_info:
							var c : Color = show_constants_color
							c.a = 0.05
							_item.set_custom_bg_color(0, c)
							
					
func _ready() -> void:
	var editor : ScriptEditor  = EditorInterface.get_script_editor()
	if editor:
		var sc : Script = editor.get_current_script()
		if sc:
			set_process(false)
			_on_change_script(sc)
			return
	set_process(true)
