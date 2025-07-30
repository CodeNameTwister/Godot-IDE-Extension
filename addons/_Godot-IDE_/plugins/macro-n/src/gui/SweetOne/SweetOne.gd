@tool
extends Window
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


const IGetAllFragments := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IGetAllFragments.gd")
const IGetFragment := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IGetFragment.gd")
const ISerializerFragment := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/ISerializerFragments.gd")

const EDITOR_KEY : String = "content"
const ID_KEY : String = "shortcut"

@export var fragment_data_container : Control = null
@export var base_editor : CodeEdit = null

var _GetAllFragments : IGetAllFragments = null
var _GetFragment : IGetFragment = null
var _SerializerFragment : ISerializerFragment = null


var _content_container : CodeEdit = null
var _id_container : LineEdit = null

func _ready() -> void:
	close_requested.connect(close)
	
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return
	get_child(0). add_theme_stylebox_override(&"panel", control.get_theme_stylebox(&"panel", &""))
	
	
func close() -> void:
	queue_free()
	
func set_dependencies(dependencies : Array) -> void:
	for dp : Variant in dependencies:
		if dp is IGetAllFragments:
			_GetAllFragments = dp
		elif dp is IGetFragment:
			_GetFragment = dp
		elif dp is ISerializerFragment:
			_SerializerFragment = dp
	for x : Object in [_GetAllFragments, _GetFragment, _SerializerFragment]:
		if !is_instance_valid(x):
			push_error("[Macro-N] Error on get dependencies!")
			return
	_setup()
	
func accept() -> void:
	var pray2god : bool = false
	var errors : PackedStringArray = []
	
	if !is_instance_valid(_id_container) or !is_instance_valid(_content_container):
		pray2god = true
	else:
		_id_container.text = _id_container.text.strip_edges()
		for x : Node in fragment_data_container.get_children():
			if x is LineEdit or x is CodeEdit:
				if x.text.is_empty():
					pray2god = true
					errors.append(x.name)
	
	if pray2god:	
		var pop : AcceptDialog = AcceptDialog.new()
		pop.title = "🔥 This is fine..."
		pop.size.x = 500
	
		if errors.size() > 0:
			pop.dialog_text = "Check that the values are set correctly:\n{0}".format([", ".join(errors)])
		else:
			pop.dialog_text = "An error occurred during processing!" #Get me out, Latom.
		
		for x : Node in pop.get_children(true):
			if x is Label:
				x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		EditorInterface.popup_dialog_centered(pop)
		return
		
	var shortcut : String = _id_container.text
	
	var text : String = "Create new Marcro? \n'{0}'".format([shortcut])
	
	var window : ConfirmationDialog = ConfirmationDialog.new()
	window.title = "Hey, Listen!"
	
	window.get_ok_button().self_modulate = Color.GREEN
	window.get_cancel_button().self_modulate = Color.RED
	
	if !_GetFragment.execute(shortcut)["shortcut"].is_empty():
		text = "The Macro '{0}' already exists!\nyou want to overwrite?".format([shortcut])
		window.get_ok_button().self_modulate = Color.ORANGE
		window.ok_button_text = "Overwrite"
		
	window.dialog_text = text
		
	for x : Node in window.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	
	window.confirmed.connect(_save)
	EditorInterface.popup_dialog_centered(window)
		
func _save() -> void:
	if !is_instance_valid(_id_container) or !is_instance_valid(_content_container):
		return
		
	var data : Dictionary[String, String] = {}
	for x : Node in fragment_data_container.get_children():
		if x is LineEdit or x is CodeEdit:
			data[x.name] = x.text
			
	var keys : PackedStringArray = _GetAllFragments.get_keys()
	if data.has_all(_GetAllFragments.get_keys()):
		var text : String = "The Macro {0} is saved!".format([data[keys[0]]])
		var result : int = _SerializerFragment.execute(
			data[keys[0]],
			data[keys[1]],
			data[keys[2]]
		)
		if OK != result:
			text = "An error on try save Macro: {0}".format([data[keys[0]]])
		else:
			close.call_deferred()
		
		var window : AcceptDialog = AcceptDialog.new()
		window.title = "Message Result"
		window.dialog_text = text
		
		for x : Node in window.get_children(true):
			if x is Label:
				x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		EditorInterface.popup_dialog_centered(window)
	else:
		push_error("[Macro-N] Error, not valid keys!")
		close()
		
func set_content(txt : String) -> void:
	if is_instance_valid(_content_container):
		base_editor.text = parse_text(txt)
		_content_container.text = base_editor.text
	else:
		push_warning("Can not found editor container!")

func parse_text(txt : String) -> String:
	var split : PackedStringArray = txt.split("\n", true, 0)
	var maxt : Array[int] = [0, 0]
	
	while split.size() > 0 and split[0].strip_edges().length() == 0:
		split.remove_at(0)
		
	if split.size() == 0:
		return ""
	
	for xline : int in range(split.size()):
		var line : String = split[xline]
		var indx : int = 0
		var cline : int = mini(xline, 1)
		while line.length() > indx and (line[indx] == '\t' or line[indx] == ' '):
			indx += 1
		maxt[cline] = maxi(maxt[cline], indx)
		
	if maxt[0] < maxt[1]:
		var st : int = maxt[0]
		for xline : int in range(split.size()):
			split[xline] = split[xline].substr(st, -1)
	
	return "\n".join(split)
	
func _on_change_txt() -> void:
	base_editor.text = _content_container.text
		
func _get_edit() -> CodeEdit:
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		var _editor : Control = editor.get_current_editor().get_base_editor()
		if _editor is CodeEdit:
			return _editor.duplicate(0)
	
	return CodeEdit.new()
		
func _setup() -> void:
	var keys : PackedStringArray = _GetAllFragments.get_keys()
	for x : Node in fragment_data_container.get_children():
		x.name = "_" + x.name
		x.queue_free()
	
	for k : String in keys:
		if k == EDITOR_KEY:
			var control : CodeEdit = _get_edit()
			var res : CodeHighlighter = ResourceLoader.load("uid://cyenwroye7tue").new()
			
			res.set_base(base_editor.syntax_highlighter)
			res.set_rgx(RegEx.create_from_string("\\barg\\d+\\b"))
				
			fragment_data_container.add_child(control)
			control.syntax_highlighter = res
			control.text_changed.connect(_on_change_txt)
			
			control.name = k
			
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_content_container = control
			continue
		
		var tittle: Label = Label.new()
		var edit : LineEdit = LineEdit.new()
		tittle.text = k.capitalize()
		edit.placeholder_text = "Please set {0} value".format([tittle.text])
		
		edit.name = k
		
		fragment_data_container.add_child(tittle)
		fragment_data_container.add_child(edit)
		
		tittle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if k == ID_KEY:
			_id_container = edit
			
	size = IDE.get_screen_size(0.75)
