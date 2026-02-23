@tool
extends Node
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	GD Settings Tooltip
#	https://github.com/CodeNameTwister/Godot-Editor-Settings-Description
#
#	GD Settings Tooltip addon for godot 4
#
#	authors:
#	PiCode	2025		https://github.com/PiCode9560
#	Twister	2026		https://github.com/CodeNameTwister
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## Set a description on project and editor settings.

# =========================== EXAMPLE ===========================
## Get Script:
# const SETTINGS_TOOLTIPS = preload("path/to/info.gd")

## For Add editor Setting Tooltip
# SETTINGS_TOOLTIPS.set_editor_setting_tooltip(	"key_setting", "description for the setting")

## For Add Project Setting Tooltip
# SETTINGS_TOOLTIPS.set_project_setting_tooltip("key_setting", "description for the setting")
# ================================================================

const NAME : StringName = &"__EDITOR_INFO__"

static var _ref : Node = null
	
var _frame : float = 0.0

var _editor_changes : bool = false
var _project_changes : bool = false

var _editor_settings : Dictionary = {}
var _project_settings : Dictionary = {}
		
var _editor_setting_inspector : Control = null
var _project_setting_inspector : Control = null

static func get_singleton() -> Node:
	if !is_instance_valid(_ref):
		for x : Node in Engine.get_main_loop().get_nodes_in_group(NAME):
			if !is_instance_valid(x) or x.is_queued_for_deletion():
				continue
			_ref = x
			return _ref
		_ref = new()
		Engine.get_main_loop().root.add_child(_ref)
	return _ref
	
func _ready() -> void:
	if _ref != self:
		if is_instance_valid(_ref):
			_ref.queue_free()
		_ref = self
	_setup()
	
func _enter_tree() -> void:
	add_to_group(NAME)
	
func _exit_tree() -> void:
	remove_from_group(NAME)
	
func _on_change(node : Node) -> void:
	if node is Control and node.visible:
		if node == _editor_setting_inspector:
			_on_editor_inspector_changed()
		elif node == _project_setting_inspector:
			_on_project_inspector_changed()

func _setup() -> void:
	for x : Node in EditorInterface.get_base_control().find_children("*", "EditorSettingsDialog", true, false):
		for y : Node in x.find_children("*", "SectionedInspector", true, false):
			var control : Node = y.find_child("EditorInspector", true, false)
			var root : Node = y.find_child("Tree", true, false)
			
			if is_instance_valid(control) and is_instance_valid(root) and root is Tree:
				_editor_setting_inspector = control
				root.cell_selected.connect(_on_editor_inspector_changed)
				_editor_setting_inspector.visibility_changed.connect(_on_change.bind(_editor_setting_inspector))
			
	for x : Node in EditorInterface.get_base_control().find_children("*", "ProjectSettingsEditor", true, false):
		for y : Node in x.find_children("*", "General", true, false):
			for z : Node in y.find_children("*","SectionedInspector",true,false):
				var control : Node = y.find_child("EditorInspector", true, false)
				var root : Node = y.find_child("Tree", true, false)
				
				if is_instance_valid(control) and is_instance_valid(root) and root is Tree:
					_project_setting_inspector = control
					root.cell_selected.connect(_on_project_inspector_changed)
					_project_setting_inspector.visibility_changed.connect(_on_change.bind(_editor_setting_inspector))
	
	_on_editor_inspector_changed()
	
func _on_editor_inspector_changed() -> void:
	_editor_changes = true
	_frame = 0.0
	set_physics_process(true)
	
func _on_project_inspector_changed() -> void:
	_editor_changes = true
	_frame = 0.0
	set_physics_process(true)
	
func _update_editor(child : Node, property_path : String, data : Dictionary) -> void: 
	if is_instance_valid(child) and child.get_class() == "EditorHelpBitTooltip": 
		_on_tooltip(child, data[property_path])
	
func _physics_process(delta: float) -> void:
	_frame += delta
	if _frame < 1.0:
		return
	
	set_physics_process(false)
	
	if _editor_changes:
		_editor_changes = false
		for editor_property : Control in _editor_setting_inspector.find_children("*", "EditorProperty", true, false):
			var property_path : String = editor_property.tooltip_text.split("|")[-1]
			if _editor_settings.has(property_path):
				if !editor_property.child_entered_tree.is_connected(_update_editor):
					editor_property.child_entered_tree.connect(_update_editor.bind(property_path, _editor_settings))
			
	if _project_changes:
		_project_changes = false
		for editor_property : Control in _project_setting_inspector.find_children("*", "EditorProperty", true, false):
			var property_path : String = editor_property.tooltip_text.split("|")[-1]
			if _project_settings.has(property_path):
				if !editor_property.child_entered_tree.is_connected(_update_editor):
					editor_property.child_entered_tree.connect(_update_editor.bind(property_path, _project_settings))

func _on_tooltip(tooltip : Node, new_tooltip_text : String) -> void:
	for x : int in range(tooltip.get_child_count() - 1, -1, -1):
		var x_node : Node = tooltip.get_child(x)
		for y : int in range(x_node.get_child_count() - 1, -1, -1):
			var y_node : Node = x_node.get_child(y)
			if y_node is RichTextLabel:
				if !y_node.is_ready():
					await y_node.ready
				y_node.text = new_tooltip_text
				y_node.bbcode_enabled = true
				return

# ====================== PUBLIC ==========================

## Set a description tooltip for an editor setting.
static func set_editor_setting_tooltip(key_name : String, description : String) -> void:
	get_singleton()._editor_settings[key_name] = description

## Set a description tooltip for a project setting.
static func set_project_setting_tooltip(key_name : String, description : String) -> void:
	get_singleton()._project_settings[key_name] = description

static func clear() -> void:
	_ref.queue_free()
	_ref = null
