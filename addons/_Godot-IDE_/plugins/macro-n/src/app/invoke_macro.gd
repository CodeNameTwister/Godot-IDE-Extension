@tool
extends "res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IMacro.gd"
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


const IFragmentDB = preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/out/IFragmentDB.gd")
var _db : IFragmentDB

func _init(db : IFragmentDB) -> void:
	_db = db

#Implement IMacro function.
func execute(txt : String) -> String:
	var values : Array[Dictionary] = _db.get_all_fragments()
	if values.size() == 0:
		return ""
		
	var rgx : RegEx = RegEx.create_from_string("\\barg(\\d+)\\b")	
	
	for v : Dictionary in values:
		var val : String = v["shortcut"]
		var _rgx : RegEx = null
		_rgx = RegEx.create_from_string(str("(?m)^",rgx.sub(val, "(.*?)", true, 0, -1),"$"))
		
		if null != _rgx.search(txt):
			var input : Array = []
			var out : Dictionary = {}
			for x : RegExMatch in rgx.search_all(val, 0, -1):
				if x.strings.size() > 1:
					out[x.strings[0]] = x.strings[0]
					input.append(x.strings[0])
					
			var indx : int = 0
			for x : RegExMatch in _rgx.search_all(txt, 0, -1):
				for y : int in range(1, x.strings.size(), 1):
					var ctnt : String = x.strings[y]
					while indx >= input.size():
						input.append(ctnt)
					out[input[indx]] = ctnt
					indx += 1
					
			var nrgx : RegEx = RegEx.create_from_string("\\barg(\\d+)\\b")	
			var defnrgx : RegEx = RegEx.create_from_string("\\{(\\barg\\d+\\b)\\}")	
			var content : String = nrgx.sub(v["content"], "{$0}", true)
			return defnrgx.sub(content.format(out), "$1", true)
	return ""
