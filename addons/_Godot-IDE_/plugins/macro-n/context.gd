extends EditorContextMenuPlugin
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	
const INTERFACE_SCRIPT = preload("res://addons/_Godot-IDE_/shared_resources/InterfaceScript.svg")
var _helper : Object = null
var _fragments : Window = null

var controller : Object = null


func _init(helper : Object) -> void:
	_helper = helper

#Override EditorContextMenuPlugin virtual function.
func _popup_menu(_paths : PackedStringArray) -> void:
	if controller == null:
		controller = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/gui/controller/ShowTextController.gd").new()
	var txt : String = controller.execute()
	if txt.is_empty():
		return
	add_context_menu_item("Macro-N", _on_save.bind(txt), INTERFACE_SCRIPT)
	
func _on_save(_variant : Variant, text : String) -> void:
	_helper.call(&"half_life", text, -1)
	
func show_macros() -> void:
	if !is_instance_valid(_fragments):
		var fragment : PackedScene = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/gui/Fragments/Fragments.tscn")
		_fragments = fragment.instantiate()
		_helper.add_child(_fragments)
		var db : Object = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/repo/configurator.gd").new()
		_fragments.set_dependencies(
			[
				ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/remove_fragment.gd").new(db),
				ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/get_all_fragments.gd").new(db),
				ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/app/save_fragment.gd").new(db)
			]
		)
		
		_fragments.on_create.connect(_helper.create_new)
		
	_fragments.popup_centered()
	
	
func invoke_macron_bypass() -> void:
	if controller == null:
		controller = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/gui/controller/ShowTextController.gd").new()
	var txt : String = controller.execute()
	txt = txt.strip_edges()
	if txt.is_empty():
		return
	_helper.call(&"half_life", txt, 1)

func invoke_macron() -> void:
	if controller == null:
		controller = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/src/gui/controller/ShowTextController.gd").new()
	var txt : String = controller.execute()
	txt = txt.strip_edges()
	if txt.is_empty():
		return
	_helper.call(&"half_life", txt, 0)
