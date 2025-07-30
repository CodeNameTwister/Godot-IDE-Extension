@tool
extends "res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IGetFragment.gd"
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
	

#Implement IGetFragment function.
func execute(shortcut : String) -> Dictionary:
	return _fragment_db.get_fragment(shortcut)
