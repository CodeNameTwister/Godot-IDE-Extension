@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@export var lbl : Control

var _0x0001 : float = 0.0
var _0x0002 : float= 0.5

func _ready() -> void:
	if !is_inside_tree():
		set_process(false)
		
func _process(delta: float) -> void:
	if !visible:
		return
	var p : Control = get_parent()
	if !p:
		return
	_0x0001 += delta * 2.0
	if _0x0001 >= 1.0:
		_0x0001 = 0.0
		if _0x0002 == 1.0:
			_0x0002 = 0.5
		else:
			_0x0002 = 1.0
	modulate.a = lerp(modulate.a, _0x0002, _0x0001)
	lbl.pivot_offset = (lbl.size + Vector2.ONE) / 2.0
	lbl.scale = lerp(lbl.scale, Vector2.ONE * _0x0002 , _0x0001 * 0.24)
	
func _enter_tree() -> void:
	set_process(true)
	
func _exit_tree() -> void:
	set_process(false)
