extends RefCounted
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


var user_path : String = ""
var templates_path : String = ""

var _pop_warn : ConfirmationDialog

var _helper : Node = null

func _init(helper : Node) -> void:
	assert(helper != null)
	_helper = helper

func _get_pop() -> Object:
	var packed : PackedScene = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/macro-n/context/Macro-N.tscn")
	return packed.instantiate()
	
func feed() -> void:
	var edit : ScriptEditor = EditorInterface.get_script_editor()
	
	if edit:
		var base : ScriptEditorBase = edit.get_current_editor()
		if base:
			var be : Control = base.get_base_editor()
			if be is CodeEdit:
				pipe_pop_in(be.text)
				
	#NO SYTNAX
	return

func pipe_pop_in(txt : String) -> void:
	txt = parse_text(txt)
	if txt.is_empty():
		print("[Macro-N] Error!, empty syntax!")
		return
	
	var pop : Node = _get_pop()
	if !pop.is_inside_tree():
		_helper.add_child(pop)
	pop.callback = pipe_save
	pop.call(&"show_feed", txt)
	
func pipe_save(path : String, txt : String) -> void:
	if !DirAccess.dir_exists_absolute(path):
		print("[Macro-N]: Can not find dir save path!")
		return
		
	path = path.strip_edges()
	if path.is_empty():
		path = "My Macro File"
		
	txt = parse_text(txt)
	
	var end : String = user_path.path_join(path + ".mn")
	if !FileAccess.file_exists(end):
		if !_save(end, txt):
			print("[Macro-N] Can not save syntax! ", end)
		else:
			print("[Macron-N] Saved syntax: ", end)
		return
	_save_warn(end, txt)
	
func _save(end : String, txt : String) -> bool:
	var file : FileAccess = FileAccess.open(end, FileAccess.WRITE)
	if !file:
		return false
	return file.store_string(txt)
	
func _save_warn(end : String, txt : String) -> void:
	if !is_instance_valid(_pop_warn):
		_pop_warn = ConfirmationDialog.new()
	_pop_warn.title = "Already Exist File, Ovewrite?"
	_pop_warn.canceled.connect(func():_pop_warn.queue_free())
	_pop_warn.confirmed.connect(
		func():
			_save(end, txt)
			_pop_warn.queue_free()
			)
	_helper.add_child(_pop_warn)
	_pop_warn.popup_centered()

func parse_text(txt : String) -> String:
	var split : PackedStringArray = txt.split("\n", true, 0)
	var maxt : Array[int] = [0, 0]
	
	while split.size() > 0 and split[0].strip_edges().length() == 0:
		split.remove_at(0)
		
	if split.size() == 0:
		return ""
	
	for xline : int in range(split.size()):
		var line : String = split[xline]
		var indx : int = 0
		var cline : int = mini(xline, 1)
		while line.length() > indx and (line[indx] == '\t' or line[indx] == ' '):
			indx += 1
		maxt[cline] = maxi(maxt[cline], indx)
		
	if maxt[0] < maxt[1]:
		var st : int = maxt[0]
		for xline : int in range(split.size()):
			split[xline] = split[xline].substr(st, -1)
	
	return "\n".join(split)
