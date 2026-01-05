@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
var LIST_VISIBLE_SELECTED_COLOR : Color = Color.from_string("7b68ee", Color.CORNFLOWER_BLUE)
var LIST_VISIBLE_OTHERS_COLOR : Color = Color.from_string("4835bb", Color.DARK_BLUE)


var _script_list_selection : bool = false

func _init(manager : Manager, tool_db : ToolDB) -> void:
	super(manager, tool_db)
	_setup()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var settings : EditorSettings = EditorInterface.get_editor_settings()
		if settings.settings_changed.is_connected(_on_change):
			settings.settings_changed.disconnect(_on_change)

func _on_change() -> void:
	var dt : Array = [
		"plugin/script_splitter/behaviour/refresh_warnings_on_saveplugin/script_splitter/editor/list/selected_color"
		,"plugin/script_splitter/behaviour/refresh_warnings_on_saveplugin/script_splitter/editor/list/others_color"
	]
	
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
		["LIST_VISIBLE_SELECTED_COLOR", "plugin/script_splitter/behaviour/refresh_warnings_on_saveplugin/script_splitter/editor/list/selected_color"]
		,["LIST_VISIBLE_OTHERS_COLOR", "plugin/script_splitter/behaviour/refresh_warnings_on_saveplugin/script_splitter/editor/list/others_color"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))
		

func execute(value : Variant = null) -> bool:
	if !value is Array or value.size() < 1:
		return false
		
	if _script_list_selection:
		return true
	
	_script_list_selection = true
	
	
	var _editor_list : ItemList = value[0]
	var _script_list : ItemList = value[1]
		
	var selected : String = ""
	var others_selected : PackedStringArray = []


	var current : TabContainer = _manager.get_base_container().get_current_container()
	
	
	for x : MickeyTool in _tool_db.get_tools():
		if x.is_valid():
			var _root : Node = x.get_root()
			if _root.current_tab == x.get_control().get_index():
				var idx : int = x.get_index()
				if _editor_list.item_count > idx and idx > -1:
					if _root == current:
						selected = _editor_list.get_item_tooltip(idx)
					else:
						others_selected.append(_editor_list.get_item_tooltip(idx))
	
	var color : Color = LIST_VISIBLE_SELECTED_COLOR
	var color_ctn : Color = LIST_VISIBLE_SELECTED_COLOR
	var others : Color = LIST_VISIBLE_OTHERS_COLOR
	color.a = 0.5
	others.a = 0.5
	color_ctn.a = 0.25
	
	for x : int in _script_list.item_count:
		var mt : String = _script_list.get_item_tooltip(x)
		if selected == mt:
			_script_list.set_item_custom_bg_color(x, color)
			_script_list.set_item_custom_fg_color(x, Color.WHITE)
			_script_list.select(x, true)
		elif others_selected.has(mt):
			_script_list.set_item_custom_bg_color(x, others)
		else:
			_script_list.set_item_custom_bg_color(x, Color.TRANSPARENT)
	_script_list.ensure_current_is_visible()
	set_deferred(&"_script_list_selection", false)
	return false
