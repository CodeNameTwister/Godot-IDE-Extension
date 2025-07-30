@tool
extends Window
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


@export var update_btn : Button
@export var base_edit : CodeEdit
@export var code_edit : CodeEdit
@export var container : Control

var _origin : Object = null

var _code : String = ""
		
func _get_edit() -> CodeEdit:
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		var _editor : Control = editor.get_current_editor().get_base_editor()
		if _editor is CodeEdit:
			return _editor.duplicate(0)
	
	return CodeEdit.new()

func _on_change_txt() -> void:
	base_edit.text = code_edit.text

func _ready() -> void:
	close_requested.connect(close)
	
	var res : CodeHighlighter = ResourceLoader.load("uid://cyenwroye7tue").new()
	
	res.set_base(base_edit.syntax_highlighter)
	res.set_rgx(RegEx.create_from_string("\\barg\\d+\\b"))
	
	if code_edit == null:
		code_edit = _get_edit()
		container.add_child(code_edit)
		code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
	
	code_edit.syntax_highlighter = res
	code_edit.text_changed.connect(_on_change_txt)
	
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return
	get_child(0). add_theme_stylebox_override(&"panel", control.get_theme_stylebox(&"panel", &""))
	
func set_origin(o : Object) -> void:
	_origin = o
	
func close() -> void:
	queue_free()
	
func update() -> void:
	var pop : ConfirmationDialog = ConfirmationDialog.new()
	pop.title = "Macro-N"
	pop.size.x = 350
		
	pop.dialog_text = "Are you sure update?"
		
	for x : Node in pop.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	pop.confirmed.connect(_on_confirm)
	EditorInterface.popup_dialog_centered(pop)

func _on_confirm() -> void:
	_origin.set_meta(&"content", code_edit.text)
	
	var pop : AcceptDialog = AcceptDialog.new()
	pop.title = "Macro-N"
	pop.size.x = 350
	pop.dialog_text = "Macro content update!\nRemember press 'UPDATE' button for save!"
		
	for x : Node in pop.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	pop.close_requested.connect(close)
	pop.confirmed.connect(close)
	EditorInterface.popup_dialog_centered(pop)
	
func _on_change() -> void:
	update_btn.disabled = _code == code_edit.text

func set_code(code : String) -> void:
	_code = code
	base_edit.text = _code
	code_edit.text = _code
	
	code_edit.text_changed.connect(_on_change)
	update_btn.disabled = true
