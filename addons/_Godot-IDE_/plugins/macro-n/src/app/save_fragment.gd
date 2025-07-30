@tool
extends "res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/ISerializerFragments.gd"
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	

const IFragmentDB := preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/out/IFragmentDB.gd")

var _fragment_db : IFragmentDB = null

func _init(fragment_db : IFragmentDB) -> void:
	_fragment_db = fragment_db



#Implement ISerializerFragments function.
func execute(shortcut : String, description : String, content : String) -> int:
	description = description.strip_edges()
	shortcut = shortcut.strip_edges()
	
	var result : int = _fragment_db.save_fragment(shortcut, description, content)
	if OK != result:
		push_error("On error on try save macro fragment!")
	return result
