@tool
extends "./../../../core/ui/multi_split_container/multi_split_container.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const EXPAND = preload("./../../../assets/expand.svg")

var __setup : bool = false
var _delta : float = 0.0

func _init() -> void:
	super()
	
	drag_button_icon = EXPAND
	drag_button_size = 24.0
	behaviour_expand_on_focus = true
	behaviour_can_expand_focus_same_container = false
	behaviour_expand_smoothed = true
	drag_button_always_visible = false
	drag_button_modulate = Color.WHITE
	behaviour_expand_on_double_click = true
	behaviour_can_move_by_line = true
	
	_setup()
	
func _ready() -> void:
	super()
	modulate.a = 0.0
	set_physics_process(true)
	
func _physics_process(delta : float) -> void:
	_delta += delta * 2.0
	if _delta >= 1.0:
		_delta = 1.0
		set_physics_process(false)
	modulate.a = _delta
	
	
func _on_change() -> void:
	var dt : Array = ["plugin/script_splitter/editor/behaviour/expand_on_focus"
			,"plugin/script_splitter/editor/behaviour/can_expand_on_same_focus"
			,"plugin/script_splitter/editor/behaviour/smooth_expand"
			,"plugin/script_splitter/editor/behaviour/smooth_expand_time"
			,"plugin/script_splitter/line/size"
			,"plugin/script_splitter/line/color"
			,"plugin/script_splitter/line/draggable"
			,"plugin/script_splitter/line/expand_by_double_click"
			,"plugin/script_splitter/line/button/size"
			,"plugin/script_splitter/line/button/modulate"
			,"plugin/script_splitter/line/button/always_visible"
			]
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var changes : PackedStringArray = settings.get_changed_settings()
	
	for c in changes:
		if c in dt:
			_setup()
			update()
			break
	
func _setup() -> void:
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if !settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.connect(_on_change)
	
	for x : Array in [
		["behaviour_expand_on_focus", "plugin/script_splitter/editor/behaviour/expand_on_focus"]
		,["behaviour_can_expand_focus_same_container", "plugin/script_splitter/editor/behaviour/can_expand_on_same_focus"]
		,["behaviour_expand_smoothed", "plugin/script_splitter/editor/behaviour/smooth_expand"]
		,["drag_button_size", "plugin/script_splitter/editor/behaviour/smooth_expand_time"]
		,["separator_line_size", "plugin/script_splitter/line/size"]
		,["separator_line_color", "plugin/script_splitter/line/color"]
		,["behaviour_can_move_by_line", "plugin/script_splitter/line/draggable"]
		,["behaviour_expand_on_double_click", "plugin/script_splitter/line/expand_by_double_click"]
		,["drag_button_size", "plugin/script_splitter/line/button/size"]
		,["drag_button_modulate", "plugin/script_splitter/line/button/modulate"]
		,["drag_button_always_visible", "plugin/script_splitter/line/button/always_visible"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))
			

func _enter_tree() -> void:
	add_to_group(&"__ST_CS__")
	super()
	
	if __setup:
		return
		
	__setup = true
	
	_setup()
	
func _exit_tree() -> void:
	remove_from_group(&"__ST_CS__")
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.disconnect(_on_change)
	
