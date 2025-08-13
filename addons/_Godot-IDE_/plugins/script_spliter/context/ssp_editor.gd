@tool
extends CodeEdit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4f
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


const UPDATE_TIME : float = 1.25

var _dlt : float = 0.0
var _text : String = ""

func set_text_reference(txt : String) -> void:
	_text = txt
	_dlt = 0.0
	set_process(true)

func _init() -> void:
	if is_node_ready():
		_ready()

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_dlt += delta
	if _dlt > UPDATE_TIME:
		set_process(false)
		var sv : float = scroll_vertical
		var sh : int = scroll_horizontal
		text = _text
		scroll_vertical = sv	
		scroll_horizontal = sh
