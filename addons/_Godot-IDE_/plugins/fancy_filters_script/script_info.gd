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

const SCRIPT_TOOL_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/Tools.svg")
const SCRIPT_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/Script.svg")
const SCRIPT_EXTEND_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/ScriptExtend.svg")
const SCRIPT_ABSTRACT_ICON : Texture2D = SCRIPT_ICON
const SCRIPT_NATIVE_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/InterfaceScript.svg")

const MEMBER_ANNOTATION_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberAnnotation.svg")
const MEMBER_CONSTANT_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberConstant.svg")
const MEMBER_CONSTRUCTOR_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberConstructor.svg")
const MEMBER_METHOD_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberMethod.svg")
const MEMBER_OPERATOR_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberOperator.svg")
const MEMBER_PROPERTY_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberProperty.svg")
const MEMBER_SIGNAL_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MemberSignal.svg")
const MEMBER_OVERRIDE_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/MethodOverride.svg")

@export var button_container : Control = null
@export var tree_container : Tree = null

#region CONFIG
var show_properties : bool = true
var show_signals : bool = true
var show_constants : bool = true
var show_parent_class : bool = true
var show_native_class : bool = false
var show_functions : bool = true
var show_inheritance : bool = true

var show_properties_color : Color = Color.ORANGE
var show_signals_color : Color = Color.GREEN
var show_constants_color : Color = Color.CYAN
var show_parent_class_color : Color = Color.WHITE_SMOKE
var show_native_class_color : Color = Color.WHITE_SMOKE
var show_function_color : Color = Color.YELLOW
#endregion

var _buffer : Dictionary = {}
var _last : Variant = null

func _enter_tree() -> void:
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if !editor.editor_script_changed.is_connected(_on_change_script):
			editor.editor_script_changed.connect(_on_change_script)
		
func _exit_tree() -> void:
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if editor.editor_script_changed.is_connected(_on_change_script):
			editor.editor_script_changed.disconnect(_on_change_script)

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
	
func force_update() -> void:
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	var sc : Script = _last	
	_last = null
	if editor:
		var nsc : Script = editor.get_current_script()
		if nsc:
			sc = nsc
	_on_change_script(sc)
		
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

				var pattern : RegEx = RegEx.create_from_string("[\\n\\t\\s]*var[\\n\\t\\s]+\\b" + symbol_name + "\\b.*|\\s*const[\\n\\t\\s]+\\b" + symbol_name + "\\b.*|\\s*func[\\n\\t\\s]+\\b" + symbol_name + "|\\s*signal[\\n\\t\\s]+\\b" + symbol_name)
				for x : int in range(lines.size()):
					var line = lines[x]
					if pattern.search(line):
						line_number = x
						break
						
				if line_number > -1:
					var sce: ScriptEditor = EditorInterface.get_script_editor()
					if !sce:
						return
					if sce.get_current_script() != current:
						EditorInterface.edit_script(current, line_number, 0)
					else:
						sce.goto_line(line_number)
					return
				var base : Script = current.get_base_script()	
				if base != null:
					current = base
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
	var SECONDARY_COLOR : Color = PRIMARY_COLOR.darkened(0.2)
	
	var index : int = -1
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
		if show_functions:
			sc_data = sc["functions"]
			if sc_data.size() > 0:
				var mthds : TreeItem = tree_item.create_child()
				mthds.set_text(0, "Methods")
				mthds.set_selectable(0, false)
				mthds.set_icon(0, MEMBER_METHOD_ICON)
				mthds.set_custom_color(0, PRIMARY_COLOR)
				meta = str("F", index)
				mthds.set_metadata(0, meta)
				mthds.set_icon_modulate(0, Color.YELLOW)
				if _buffer.has(meta):
					mthds.collapsed = _buffer[meta]
				for fnc : String in sc_data.keys():
					var packed : PackedStringArray = sc_data[fnc].split("||")
					var override : bool = false
					if "overrided" in packed:
						if index > 0:
							if !show_inheritance:
								continue
						else:
							if !show_inheritance and !script.has_method(fnc):
								continue
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
						_item.set_icon(0, PRIVATE_ICON)
					elif fnc.begins_with(protected_methods):
						_item.set_icon(0, PROTECTED_ICON)
					else:
						_item.set_icon(0, PUBLIC_ICON)
					if override:
						_item.set_icon_overlay(0, OVERRIDED_ICON)
					_item.set_custom_color(0, SECONDARY_COLOR)
					_item.set_text(0, text)
						
		if show_properties:
			sc_data = sc["properties"]
			if sc_data.size() > 0:
				var mthds : TreeItem = tree_item.create_child()
				mthds.set_text(0, "Properties")
				mthds.set_selectable(0, false)
				mthds.set_icon(0, MEMBER_PROPERTY_ICON)
				mthds.set_custom_color(0, PRIMARY_COLOR)
				meta = str("P", index)
				mthds.set_metadata(0, meta)
				mthds.set_icon_modulate(0, Color.ORANGE)
				if _buffer.has(meta):
					mthds.collapsed = _buffer[meta]
				for fnc : String in sc_data.keys():
					var packed : PackedStringArray = sc_data[fnc].split("||")
					var override : bool = false
					if "overrided" in packed:
						if !show_inheritance:
							continue
						override = true
					var _item : TreeItem = mthds.create_child()
					var text : String = "{0} : {1}".format([packed[0], packed[1]])
					_item.set_text(0, text)
					_item.set_custom_color(0, SECONDARY_COLOR)
					if "export" in packed:
						_item.set_icon(0, EXPORT_ICON)
						_item.set_tooltip_text(0, str("@export var ", text))
					elif "static" in packed:
						_item.set_icon(0, STATIC_ICON)
						_item.set_tooltip_text(0, str("static var ", text))
					elif "const" in packed:
						_item.set_icon(0, CONST_ICON)
						_item.set_tooltip_text(0, str("const ", text))
					elif fnc.begins_with(private_methods):
						_item.set_icon(0, PRIVATE_ICON)
					elif fnc.begins_with(protected_methods):
						_item.set_icon(0, PROTECTED_ICON)
					else:
						_item.set_icon(0, PUBLIC_ICON)
					if override:
						_item.set_icon_overlay(0, OVERRIDED_ICON)
						
		if show_signals:
			sc_data = sc["signals"]
			if sc_data.size() > 0:
				var mthds : TreeItem = tree_item.create_child()
				mthds.set_text(0, "Signals")
				mthds.set_selectable(0, false)
				mthds.set_icon(0, MEMBER_SIGNAL_ICON)
				mthds.set_custom_color(0, PRIMARY_COLOR)
				meta = str("S", index)
				mthds.set_metadata(0, meta)
				mthds.set_icon_modulate(0, Color.GREEN)
				if _buffer.has(meta):
					mthds.collapsed = _buffer[meta]
				for fnc : String in sc_data.keys():
					var packed : PackedStringArray = sc_data[fnc].split("||")
					var override : bool = false
					if "overrided" in packed:
						if !show_inheritance:
							continue
						override = true
					var _item : TreeItem = mthds.create_child()
					_item.set_text(0, "{0} ( {1} ) -> {2}".format([packed[0], packed[1], packed[2]]))
					
					_item.set_icon(0, MEMBER_SIGNAL_ICON)
					_item.set_custom_color(0, SECONDARY_COLOR)
					if show_inheritance and "overrided" in packed:
						_item.set_icon_overlay(0, OVERRIDED_ICON)
					if override:
						_item.set_icon_overlay(0, OVERRIDED_ICON)
					
		if show_constants:
			sc_data = sc["constants"]
			if sc_data.size() > 0:
				var mthds : TreeItem = tree_item.create_child()
				mthds.set_text(0, "Constant")
				mthds.set_selectable(0, false)
				mthds.set_icon(0, MEMBER_CONSTANT_ICON)
				mthds.set_custom_color(0, PRIMARY_COLOR)
				meta = str("I", index)
				mthds.set_metadata(0, meta)
				mthds.set_icon_modulate(0, Color.CYAN)
				if _buffer.has(meta):
					mthds.collapsed = _buffer[meta]
				for fnc : String in sc_data.keys():
					var packed : PackedStringArray = sc_data[fnc].split("||")
					var override : bool = false
					if "overrided" in packed:
						if !show_inheritance:
							continue
						override = true
					var _item : TreeItem = mthds.create_child()
					_item.set_text(0, "{0} : {1}".format([packed[0], packed[1]]))
					_item.set_icon(0, MEMBER_CONSTANT_ICON)
					_item.set_custom_color(0, SECONDARY_COLOR)
					if override:
						_item.set_icon_overlay(0, OVERRIDED_ICON)
					
func _ready() -> void:
	var editor : ScriptEditor  = EditorInterface.get_script_editor()
	if editor:
		var sc : Script = editor.get_current_script()
		if sc:
			_on_change_script(sc)
	
