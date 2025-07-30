@tool
extends "res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IRemoveFragment.gd"
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

#Implement IRemoveFragment function.
func execute(txt : String) -> int:
	return _fragment_db.remove(txt)
