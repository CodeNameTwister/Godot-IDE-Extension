@tool
extends  Node
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	

const BUILT_IN : Dictionary = { "region " : Color.MEDIUM_PURPLE }

@export var tree : Tree = null

var _plugin : EditorPlugin = null

func _setup() -> void:
	var PREDEFINED :  Dictionary = {
		#I have absolutely no idea what f🎃ck color to make it.
		"TODO" : Color.GREEN_YELLOW,
		"FIX" : Color.ORANGE,
		"FIXME" : Color.ORANGE,
		"NOTE" : Color.SKY_BLUE,
		"HACK" : Color.YELLOW_GREEN,
		"XXX" : Color.YELLOW,
		"BUG" : Color.RED
	}
		
	var value : Variant = IDE.get_config("fancy_filters_script", "custom_tags")
	if value is Dictionary:
		var dirty : bool = false
		for x : Variant in value.keys():
			if x is String:
				if value[x] is Color:
					continue
			dirty = true
			value.erase(x)
		if dirty:
			IDE.set_config("fancy_filters_script", "custom_tags", value)
		return
	
	IDE.set_config("fancy_filters_script", "custom_tags", PREDEFINED)


func set_plugin(plugin : EditorPlugin) -> void:
	_plugin = plugin
	
func _get_tags() -> Dictionary:
	var out : Dictionary = {}
	
	var value : Variant = IDE.get_config("fancy_filters_script", "custom_tags")
	if value is Dictionary:
		for x : Variant in value.keys():
			if x is String:
				if value[x] is Color:
					out[x] = value[x]
	
	return out

func _get_editor() -> CodeEdit:
	var script_editor : ScriptEditor = EditorInterface.get_script_editor()
	var script : Script = script_editor.get_current_script() if script_editor != null else null
	var editor : ScriptEditorBase = script_editor.get_current_editor() if script != null else null
	var control : Control = editor.get_base_editor() if editor != null else null
	
	return control if control is CodeEdit else null

func clear() -> void:
	tree.clear()

func _sort(a : Variant, b : Variant) -> bool:
	return a.index < b.index
	
func _ready() -> void:
	tree.item_activated.connect(_on_activate)

func jline(line_number: int):
	var script_editor = EditorInterface.get_script_editor()
	
	if !script_editor:
		return
		
	var current_editor = script_editor.get_current_editor()
	
	if current_editor:
		var base_editor : Control = current_editor.get_base_editor()
		if base_editor is CodeEdit:
			base_editor.set_caret_line(line_number - 1)
			base_editor.center_viewport_to_caret()		
			
func _on_activate() -> void:
	var item : TreeItem = tree.get_selected()
	var variant : Variant = item.get_metadata(0)
	if variant is int:
		jline(variant)

func fill(items : Array[Dictionary]) -> void:
	clear()
	var root : TreeItem = tree.create_item()
	
	root.set_text(0, tr("Tags"))
	root.set_selectable(0, false)
	
	for item : Dictionary in items:
		var ti : TreeItem = root.create_child() 
		var line : String = item.line
		ti.set_selectable(0, true)
		
		ti.set_text(0, "{0}: {1}".format([line, item.sign]))
		
		ti.set_custom_color(0, item.color)
		
		ti.set_metadata(0, line.to_int())

	if items.size() < 1:
		root.set_text(0, "No Tags Aviable")
	
func _refresh() -> void:
	clear()
	
	
	var cd : CodeEdit = _get_editor()
	if cd:
		var items : Array[Dictionary] = []
		var search : String = cd.text
		
		var rplcj : RegEx = RegEx.create_from_string("\\n")
		
		var rgxm : Array[RegExMatch] = rplcj.search_all(search, 0, -1)
		
		var deep : int = 0
		
		var tags : Dictionary = {}
		
		tags.merge(BUILT_IN)
		tags.merge(_get_tags())
		
		for x : String in tags.keys():
			var dottext : RegEx = RegEx.create_from_string("(?m)\\#{0}\\b(.*)".format([x]))
			var rmatch : Array[RegExMatch] = dottext.search_all(search)
			
			for exmatch : RegExMatch in rmatch:
				if exmatch.strings.size() > 0:
					var item : Dictionary = {}
					var offset : int = exmatch.get_start(0)
					var line : int = 1
					var txt : String = exmatch.strings[0]
					
					for rline : RegExMatch in rgxm:
						if rline.get_start(0) <= offset:
							line += 1
							continue
						break
					
					item.index = line
					if line < 10:
						item.line = str("0",line)
					else:
						item.line = str(line)
					item.sign = txt
					
					item.color = tags[x]
					
					item.deep = deep
					items.append(item)
				
		items.sort_custom(_sort)
		fill(items)
		
func _process(__ : float) -> void:
	set_process(false)
	_refresh()

func _on_change_script(res : Variant = null) -> void:
	if res is Script:
		set_process(true)
	
func _enter_tree() -> void:
	_setup()
	
	if _plugin and !_plugin.resource_saved.is_connected(_on_change_script):
		_plugin.resource_saved.connect(_on_change_script)
	
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if !editor.editor_script_changed.is_connected(_on_change_script):
			editor.editor_script_changed.connect(_on_change_script)
	
		
func _exit_tree() -> void:
	if _plugin and _plugin.resource_saved.is_connected(_on_change_script):
		_plugin.resource_saved.disconnect(_on_change_script)
		
	var editor : ScriptEditor = EditorInterface.get_script_editor()
	if editor:
		if editor.editor_script_changed.is_connected(_on_change_script):
			editor.editor_script_changed.disconnect(_on_change_script)
