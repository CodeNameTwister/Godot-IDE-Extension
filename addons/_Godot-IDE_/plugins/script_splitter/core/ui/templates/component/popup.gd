@tool
extends Popup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

signal accepted()
signal canceled()
@export var tittle : Label 
@export var _ok : Button
@export var _cancel : Button

func _x(n : Node, t : StyleBox) -> void:
	if n is Control:
		n.add_theme_stylebox_override("panel", t)
		
	for z : Node in n.get_children():
		_x(z, t)
		
func _on_hide() -> void:
	queue_free()

func _ready() -> void:
	popup_hide.connect(_on_hide)
	_ok.pressed.connect(_on_ok)
	_cancel.pressed.connect(_on_cancel)
	var gui_base : Control = EditorInterface.get_base_control()
	if gui_base:
		_x(self, gui_base.get_theme_stylebox("panel", "Panel"))
	
func _on_ok() -> void:
	accepted.emit()
	hide()
	
func _on_cancel() -> void:
	canceled.emit()
	hide()
