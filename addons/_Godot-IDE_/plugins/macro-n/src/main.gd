extends RefCounted
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	

const IFragmentDB := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/out/IFragmentDB.gd")
const IGetAllFragments := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IGetAllFragments.gd")
const IGetFragment := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IGetFragment.gd")
const ISerializerFragment := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/ISerializerFragments.gd")
const IMacro = preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IMacro.gd")

var _root : Node = null
var _node : Window = null

func _init(root : Node) -> void:
	_root = root
	
func _cut() -> void:
	var ip : InputEventKey = InputEventKey.new()
	ip.ctrl_pressed = true
	ip.pressed = true
	ip.keycode = KEY_X
	Engine.get_main_loop().root.push_input(ip)
	
func _paste(txt : String) -> void:
	DisplayServer.clipboard_set(txt)
	
	var cip : InputEventKey = InputEventKey.new()
	cip.ctrl_pressed = true
	cip.pressed = true
	cip.keycode = KEY_V
	Engine.get_main_loop().root.push_input(cip)
	
func execute(txt : String, type : int) -> void:
	if type == 0 or type == 1:
		var FragmentDB : IFragmentDB = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/repo/configurator.gd").new()
		var macro : IMacro = null
		if type == 0:
			macro = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/invoke_macro.gd").new(FragmentDB)
		else:
			macro = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/invoke_macro_bypass.gd").new(FragmentDB)
		var content : String = macro.execute(txt)
		if content.length() == 0:
			return
			
		var sc : ScriptEditor = EditorInterface.get_script_editor()
		var node : Node = sc.get_current_editor()
		if node:
			node = node.get_base_editor()
			if node is CodeEdit:
				if node.get_caret_count() > 0:
					_cut()
					_paste(content)
	else:
		if is_instance_valid(_node):
			_node.popup_centered()
			return
			
		var GUI : PackedScene = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/gui/SweetOne/SweetOne.tscn")
		
		var FragmentDB : IFragmentDB = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/repo/configurator.gd").new()
		var GetAllFragments : IGetAllFragments = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/get_all_fragments.gd").new(FragmentDB)
		var GetFragment : IGetFragment = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/get_fragment.gd").new(FragmentDB)
		var SerializerFragment : ISerializerFragment = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/save_fragment.gd").new(FragmentDB)
		
		_node = GUI.instantiate()
		_root.add_child(_node)
		
		_node.set_dependencies([
			GetAllFragments,
			GetFragment,
			SerializerFragment
		])
		
		_node.set_content(txt)
		
		_node.popup_centered()
