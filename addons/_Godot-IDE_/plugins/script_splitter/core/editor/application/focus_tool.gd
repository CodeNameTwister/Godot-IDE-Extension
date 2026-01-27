@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const BaseList = preload("./../../../core/base/list.gd")

var unfocus_enabled : bool = true
var unfocus_color : Color = Color.DARK_GRAY

func _init(manager : Manager, tool_db : ToolDB) -> void:
	super(manager, tool_db)
	_setup()
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var settings : EditorSettings = EditorInterface.get_editor_settings()
		if settings.settings_changed.is_connected(_on_change):
			settings.settings_changed.disconnect(_on_change)

func _on_change() -> void:
	var dt : Array = ["plugin/script_splitter/editor/out_focus_color_enabled","plugin/script_splitter/editor/out_focus_color_value"]
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var changes : PackedStringArray = settings.get_changed_settings()
	
	for c in changes:
		if c in dt:
			_setup()
			var current : Node = _manager.get_base_container().get_current_container()
			for x : MickeyTool in _tool_db.get_tools():
				if x.is_valid():
					var root : Control = x.get_root()
					if root.modulate != Color.WHITE:
						if unfocus_enabled:
							root.modulate = unfocus_color
						else:
							root.modulate = Color.WHITE
					elif unfocus_enabled:
						if is_instance_valid(current):
							if x.get_root() != current:
								root.modulate = unfocus_color
			break
	
func _setup() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if !settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.connect(_on_change)
	
	for x : Array in [
		["unfocus_enabled", "plugin/script_splitter/editor/out_focus_color_enabled"]
		,["unfocus_color", "plugin/script_splitter/editor/out_focus_color_value"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))

func execute(value : Variant = null) -> bool:
	if value is ScriptEditorBase:
		var control : Control = value.get_base_editor()
		for x : MickeyTool in _tool_db.get_tools():
			if x.has(control):
				value = x
				break
	if value is MickeyTool:
		var index : int = value.get_index()
		var editor_list : BaseList = _manager.get_editor_list()
		if editor_list.item_count() > index and index > -1:
			var control : Node = value.get_control()
			var root : Node = value.get_root()
			if root is TabContainer:
				var base : Manager.BaseContainer = _manager.get_base_container()
				var _index : int = control.get_index()
				if root.current_tab != _index and  _index > -1 and _index < root.get_tab_count():
					if root.has_method(&"set_tab"):
						root.call(&"set_tab", _index)
					else:
						root.set(&"current_tab", _index)
					
				var container : Control = base.get_current_container()
				if is_instance_valid(container) and unfocus_enabled:
					container.modulate = unfocus_color
				
				base.set_current_container(root)
	
				if is_instance_valid(root):
					root.modulate = Color.WHITE
					
				var new_container : Node = base.get_container(root)
				if is_instance_valid(new_container) and new_container.has_method(&"expand_splited_container"):
					new_container.call(&"expand_splited_container", base.get_container_item(root))
				
				if is_instance_valid(container):
					container = base.get_container(container)
					if is_instance_valid(container) and container != new_container and container.has_method(&"expand_splited_container"):
						container.call(&"expand_splited_container", null)
				
				var grant_conainer : Node = base.get_editor_root_container(new_container)
				if is_instance_valid(grant_conainer):
					var parent : Node = grant_conainer.get_parent()
					if is_instance_valid(parent) and parent.has_method(&"expand_splited_container"):
						parent.call(&"expand_splited_container", base.get_editor_root_container(new_container))
					
			if !editor_list.is_selected(index):
				editor_list.select(index)
				
			_manager.io.update()
			_manager.get_editor_list().updated.emit()
	return false
