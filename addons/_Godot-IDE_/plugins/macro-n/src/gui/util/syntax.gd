extends CodeHighlighter
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	

var _enabled : bool = false
var rgx : RegEx = null

var _base : SyntaxHighlighter = null

func set_base(b : SyntaxHighlighter) -> void:
	_base = b
	_enabled = is_instance_valid(_base) and is_instance_valid(rgx)

func set_rgx(r : RegEx) -> void:
	rgx = r
	_enabled = is_instance_valid(_base) and is_instance_valid(rgx)
		
func _get_line_syntax_highlighting(line : int) -> Dictionary:
	var out : Dictionary = {}
	if _enabled:
		out = _base.get_line_syntax_highlighting(line)
		
	var line_text: String = get_text_edit().get_line(line)
	for x : RegExMatch in rgx.search_all(line_text):
		var start : int = x.get_start()
		var end : int = x.get_end()
		_add_color_region(out, start, end, Color.GOLD)
		
	return out

func _add_color_region(data: Dictionary, start_col: int, end_col: int, color: Color):
	for x : int in range(start_col, end_col, 1):
		data[x] = {"color": color}
