@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const TEMPLATE_CONTAINER = preload("template_container.tscn")
const USER_PATH : String = "res://.script_splitter"

var _has_changes : bool = false

func _setup() -> void:
	if !DirAccess.dir_exists_absolute(USER_PATH):
		DirAccess.make_dir_recursive_absolute(USER_PATH)
	
	var path : String = USER_PATH.path_join(".gdignore")
	if !FileAccess.file_exists(path):
		var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string("Script Splitter - User Setting Folder")
		file.close()

func _enter_tree() -> void:
	add_to_group(&"__SP_C_TEMPLATE__")
	_setup()
	
func valid_changes() -> void:
	_has_changes = true
	
	serialize.call_deferred()
	
func create_template(tname : String, files : PackedStringArray, tcolor : Color) -> void:
	var node : Node = TEMPLATE_CONTAINER.instantiate()
	var dc : Dictionary = {}
	
	for x : String in files:
		dc[x] = true
	
	node.set_tittle(tname)
	node.set_items(dc)
	node.set_color(tcolor)
	
	add_child(node)
	_has_changes = true
	
	sorte()
	
func _exit_tree() -> void:
	remove_from_group(&"__SP_C_TEMPLATE__")
	
func deserialize() -> Dictionary:
	var path : String = USER_PATH.path_join("tp_split_setting.cfg")
	var cfg : ConfigFile = ConfigFile.new()
	var out : Dictionary = {}
	cfg.load(path)
	
	if cfg.has_section("setting"):
		for s : String in cfg.get_section_keys("setting"):
			var value : Variant = cfg.get_value("setting", s, {})
			if value is Dictionary:
				out[s] = value
			
	return out
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if !_has_changes:
			return
		serialize()
	
func serialize() -> bool:
	var path : String = USER_PATH.path_join("tp_split_setting.cfg")
	var _in : Dictionary = {}#deserialize()
	var cfg : ConfigFile = ConfigFile.new()
	
	for x : Node in get_children():
		if x.is_queued_for_deletion():
			continue
		var k : String = x.get_tittle()
		var d : Dictionary = x.get_items()
		
		if d.size() > 0:
			_in[k] = {
				"color" : x.get_color(),
				"path" : d
			}
		
	for x : String in _in.keys():
		var din : Dictionary = _in[x]
		var dat : Dictionary = din["path"]
		
		for y : String in dat.keys():
			if !ResourceLoader.exists(y):
				dat.erase(y)
				
		if dat.size() < 1:
			_in.erase(x)
			continue
	
		cfg.set_value("setting", x, din)
	
	_has_changes = false
	return cfg.save(path) == OK
	
func clear() -> void:
	for x : Node in get_children():
		x.queue_free()
	
func _load() -> void:
	clear()
	
	var data : Dictionary = deserialize()
	
	for x : String in data.keys():
		var _data : Dictionary = data[x]
		var node : Node = TEMPLATE_CONTAINER.instantiate()
		node.set_tittle(x)
		node.set_items(_data["path"])
		node.set_color(_data["color"])
		add_child(node)
		
	sorte()
		
func sorte():
	var p : Node = null
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		p = x.get_parent()
		break
		
	if p:
		var nds : Array[Node] = p.get_children()
		
		nds.sort_custom(
			func(na, nb): 
				return na.get_tittle().to_lower() < nb.get_tittle().to_lower()
				)
				
		for i : int in range(nds.size()):
			p.move_child(nds[i], i)
	
func _ready() -> void:
	_load()
