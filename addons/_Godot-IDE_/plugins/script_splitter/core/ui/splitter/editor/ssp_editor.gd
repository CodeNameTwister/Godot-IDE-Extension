@tool
extends CodeEdit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4f
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const UPDATE_TIME : float = 0.25

var _dlt : float = 0.0
var _text : String = ""
var _dlt_update : float = UPDATE_TIME

func set_text_reference(txt : String) -> void:
	if _text == txt:
		return
	_text = txt
	_dlt = 0.0
	_dlt_update = UPDATE_TIME + (txt.length() * 0.00001)
	
	set_process(true)

func _init() -> void:
	if is_node_ready():
		_ready()

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_dlt += delta
	if _dlt > _dlt_update:
		set_process(false)
		var sv : float = scroll_vertical
		var sh : int = scroll_horizontal
		text = _text
		scroll_vertical = sv	
		scroll_horizontal = sh
