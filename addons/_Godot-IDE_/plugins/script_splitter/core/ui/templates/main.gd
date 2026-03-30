@tool
extends Popup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const LABEL = preload("component/label.tscn")

@export var scroll : VBoxContainer
@export var _file : Label
@export var _name : LineEdit
@export var _color : ColorPickerButton

var _current : String = ""

func _x(n : Node, t : StyleBox) -> void:
	if n is Control:
		n.add_theme_stylebox_override("panel", t)
		
	for z : Node in n.get_children():
		_x(z, t)

func _ready() -> void:
	popup_hide.connect(_on_hide)
	var gui_base : Control = EditorInterface.get_base_control()
	if gui_base:
		_x(self, gui_base.get_theme_stylebox("panel", "Panel"))
		
	check()

func _on_hide() -> void:
	queue_free()
	
func set_file(_pth : String) -> void:
	_file.text = _pth.get_file()
	if !_pth.begins_with("uid:"):
		var id : int = ResourceLoader.get_resource_uid(_pth)
		if id > -1:
			_pth = ResourceUID.id_to_text(id)
	_current = _pth
	
func _error(msg : String) -> void:
	EditorInterface.get_editor_toaster().push_toast("[Script Splitter] {0}".format([msg]), EditorToaster.SEVERITY_ERROR, "Wait to the next version dude.")
						
func ok() -> void:
	if !ResourceLoader.exists(_current) or (_current.begins_with("uid:") and !ResourceLoader.exists(ResourceUID.uid_to_path(_current))):
		_error("Current file not exist o eliminated!")
		return
	
	var tname : String = _name.text.strip_edges()
	
	if tname.is_empty():
		_error("Template name can not be empty!")
		return
	
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		var items : Dictionary = x.get_items()
		if items.has(tname):
			_error("Already exist template name!")
			return
	
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_C_TEMPLATE__"):
		x.create_template(tname, [_current], _color.color)
		x.serialize()
		EditorInterface.get_editor_toaster().push_toast("[Script Splitter] New template created: {0}".format([tname]), EditorToaster.SEVERITY_INFO, "New template created!")
		
	cancel()
	
func cancel() -> void:
	hide()
	
func check() -> void:
	var tps : PackedStringArray = []
	
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		var items : Dictionary = x.get_items()
		if items.has(_current):
			tps.append(x.get_tittle())
	
	if tps.size() > 0:
		for x : Node in scroll.get_children():
			x.queue_free()
			
		for t : String in tps:
			var l : Label = LABEL.instantiate()
			l.text = t
			scroll.add_child(l)
