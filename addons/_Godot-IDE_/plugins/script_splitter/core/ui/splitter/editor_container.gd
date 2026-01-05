@tool
extends TabContainer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const Dottab = preload("./../../../core/ui/splitter/taby/dottab.gd")
const CLOSE = preload("./../../../assets/Close.svg")

const GLOBALS : PackedStringArray = ["_GlobalScope", "_GDScript"]

#
signal focus(o : TabContainer, index : int)
signal remove(o : TabContainer, index : int)
	
var _new_tab_settings : bool = false
var _tab_queue : int = -1
var _last_selected : int = -1

func _enter_tree() -> void:	
	add_to_group(&"__SC_SPLITTER__")
	
func _exit_tree() -> void:
	if is_in_group(&"__SC_SPLITTER__"):
		remove_from_group(&"__SC_SPLITTER__")

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	
	var tb : TabBar = get_tab_bar()
	if tb:
		tb.auto_translate_mode = auto_translate_mode

	
	drag_to_rearrange_enabled = true

	#CONNECT
	var tab : TabBar = get_tab_bar()
	tab.set_script(Dottab)
	tab.tab_selected.connect(_on_selected)
	tab.active_tab_rearranged.connect(_on_rearranged)
	
	tab.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	tab.tab_close_pressed.connect(_on_remove)
	tab.select_with_rmb = true
	tab.on_start_drag.connect(on_drag)
	tab.on_stop_drag.connect(out_drag)
	
func _on_rearranged(t : int) -> void:
	if _last_selected == t or t < 0:
		return
		
	for x : int in [_last_selected, t]:
		if x < 0 or x >= get_tab_count():
			return
	
	var sc : SceneTree = Engine.get_main_loop()
	if sc:
		for x : Node in sc.get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
			x.call(&"move_item_container", self, _last_selected, t)
	
func _set_tab() -> void:
	if current_tab != _tab_queue and _tab_queue > -1 and _tab_queue < get_tab_count():
		current_tab = _tab_queue
	_new_tab_settings = false
	
func set_tab(index : int) -> void:
	if index > -1 and index < get_tab_count():
		_tab_queue = index
	
	if _new_tab_settings:
		return
		
	_new_tab_settings = true
	_set_tab.call_deferred()
	
func on_drag(tab : TabBar) -> void:
	for x : Node in tab.get_tree().get_nodes_in_group(&"ScriptSplitter"):
		if x.has_method(&"dragged"):
			x.call(&"dragged", tab, true)
	
func out_drag(tab : TabBar) -> void:
	for x : Node in tab.get_tree().get_nodes_in_group(&"ScriptSplitter"):
		if x.has_method(&"dragged"):
			x.call(&"dragged", tab, false)

func _on_remove(index : int) -> void:
	remove.emit(self, index)
	
func _on_selected(value : int) -> void:
	_last_selected = value
	focus.emit(self, value)

func get_root() -> Node:
	return self

func set_item_tooltip(idx : int, txt : String) -> void:
	if idx > -1 and get_tab_count() > idx:
		set_tab_tooltip(idx, txt)
	
func set_item_text(idx : int, txt : String) -> void:
	if idx > -1 and get_tab_count() > idx:
		set_tab_title(idx, txt)
