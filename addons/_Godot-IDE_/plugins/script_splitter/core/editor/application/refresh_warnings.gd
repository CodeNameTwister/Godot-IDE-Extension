@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var _refreshing : bool = true

func _init(manager : Manager, tool_db : ToolDB) -> void:
	super(manager, tool_db)
	_setup()
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var settings : EditorSettings = EditorInterface.get_editor_settings()
		if settings.settings_changed.is_connected(_on_change):
			settings.settings_changed.disconnect(_on_change)

func _on_change() -> void:
	var dt : Array = ["plugin/script_splitter/behaviour/refresh_warnings_on_save"]
	
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
		["_refreshing", "plugin/script_splitter/behaviour/refresh_warnings_on_save"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))
			
func execute(_value : Variant = null) -> bool:
	if !_refreshing:
		return true
	
	var sp : Array[Node] = Engine.get_main_loop().get_nodes_in_group(&"__SC_SPLITTER__")
	var current : Control = _manager.get_base_container().get_current_container()
	
	var ctool : MickeyTool = null
	var ltool : MickeyTool = null
	
	if sp.size() < 2:
		return true
	
	for x : Variant in _tool_db.get_tools():
		if is_instance_valid(x):
			if x.is_valid():
				var i : int = sp.find(x.get_root())
				var container : Node = sp[i]
				if container is TabContainer:
					var indx : int = x.get_control().get_index()
					if container.current_tab == indx:
						if container == current:
							ctool = x
						ltool = x
						_manager.select_editor_by_index(x.get_index())
					
						
	if is_instance_valid(ctool) and ctool != ltool:
		_manager.select_editor_by_index(ctool.get_index())
		
	return true
