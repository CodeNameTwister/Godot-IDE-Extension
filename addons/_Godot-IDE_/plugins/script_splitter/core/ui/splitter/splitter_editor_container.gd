@tool
extends VBoxContainer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const Editor = preload("./../../../core/ui/splitter/editor_container.gd")
const CONTAINER = preload("./../../../core/ui/multi_split_container/taby/container.tscn")

var _editor : Editor = null
var _tab_old_behaviour : bool = false:
	set = _on_behaviour_changed
var tab : Node = null
		
func _on_behaviour_changed(e) -> void:
	_tab_old_behaviour = e
	if is_instance_valid(tab):
		tab.set_enable(!_tab_old_behaviour)
		_editor.tabs_visible = _tab_old_behaviour

func _on_change() -> void:
	var dt : Array = ["plugin/script_splitter/editor/tabs/use_old_behaviour"]
	
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
		["_tab_old_behaviour", "plugin/script_splitter/editor/tabs/use_old_behaviour"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))

func _ready() -> void:
	_editor = Editor.new()
	
	var iscale : int = -8
	set(&"theme_override_constants/separation", iscale)
	
	tab = CONTAINER.instantiate()
	tab.set_ref(_editor.get_tab_bar())
	tab.set_enable(!_tab_old_behaviour)
	_editor.tabs_visible = _tab_old_behaviour
	
	add_child(tab)
	add_child(_editor)
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
func _enter_tree() -> void:
	add_to_group(&"__SP_EC__")
	_setup()
	
func _exit_tree() -> void:
	remove_from_group(&"__SP_EC__")
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.disconnect(_on_change)
	
func get_editor() -> Editor:
	return _editor

func update() -> void:
	if !is_instance_valid(tab):
		return
	tab.update()
