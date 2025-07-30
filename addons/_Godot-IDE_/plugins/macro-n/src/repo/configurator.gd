@tool
extends "res://addons/_Godot-IDE_/plugins/macro-n/src/app/out/IFragmentDB.gd"
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	

const URI : String = "res://addons/_Godot-IDE_/plugins/macro-n/save/user_data.dat"

func _setup() -> void:
	var dir : String = URI.get_base_dir()
	if !DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)

func _get_dto() -> Dictionary:
	return {
		"shortcut" : "",
		"description" : "",
		"content" : ""
	}

func _get_database() -> ConfigFile:
	_setup()
	
	var cfg : ConfigFile = ConfigFile.new()
	
	if FileAccess.file_exists(URI) and cfg.load(URI) != OK:
		push_error("[Macro-N] Can not restore user data saved!")
		var dir : String = URI.get_base_dir()
		var file : String = URI.get_file()
		var index : int = 0
		var uri : String = dir.path_join(str(file, "_back", index))
		while FileAccess.file_exists(uri):
			uri = dir.path_join(str(file, "_back", index))
			index += 1
		var io : FileAccess = FileAccess.open(uri, FileAccess.WRITE)
		if io:
			io.store_string(FileAccess.get_file_as_string(URI))
			io.close()
	
	return cfg

#Implement IFragmentDB function.
func save_fragment(shortcut : String, description : String, full_text : String) -> int:
	var cfg : ConfigFile = _get_database()
	cfg.set_value(shortcut, "description", description)
	cfg.set_value(shortcut, "content", full_text)
	return cfg.save(URI)

#Implement IFragmentDB function.
func get_fragment(shortcut : String) -> Dictionary:
	var cfg : ConfigFile = _get_database()
	
	var data : Dictionary = _get_dto()
	
	if cfg.has_section(shortcut):
		data["shortcut"] = shortcut
		for k : String in data.keys():
			if cfg.has_section_key(shortcut, k):
				data[k] = cfg.get_value(shortcut, k, "")
			
	return data

#Implement IFragmentDB function.
func get_all_fragments() -> Array[Dictionary]:
	var cfg : ConfigFile = _get_database()
	var out : Array[Dictionary] = []
	
	for shortcut : String in cfg.get_sections():
		var data : Dictionary = _get_dto()
		for k : String in data.keys():
			if cfg.has_section_key(shortcut, k):
				data[k] = cfg.get_value(shortcut, k, "")
		
		data["shortcut"] = shortcut
		
		out.append(data)
	
	return out
	
#Implement IFragmentDB function.
func remove(shortcut : String) -> int:
	var db : ConfigFile = _get_database()
	if db.has_section(shortcut):
		db.erase_section(shortcut)
		return db.save(URI)
	return -1

#Implement IFragmentDB function.
func get_data_keys() -> PackedStringArray:
	return PackedStringArray(_get_dto().keys())
