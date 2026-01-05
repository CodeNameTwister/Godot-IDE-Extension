@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const SplitterList = preload("./../../core/ui/splitter/splitter_list.gd")

signal item_selected(item : int)
signal move_item(from : int, to : int)
signal updated()

var _editor_list : ItemList = null
var _script_list : ItemList = null
var _script_filesearch : LineEdit = null
var _editor_filesearch : LineEdit = null
var _update_list_queue : bool = false
var _array_list : Array = []
var _selet_queue : int = -1
var _selecting : bool = false

var update_selections_callback : Callable

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_editor_list):
			_editor_list.visible = true
			if _editor_list.item_selected.is_connected(_item_selected):
				_editor_list.item_selected.disconnect(_item_selected)
			if _editor_list.property_list_changed.is_connected(_on_property):
				_editor_list.property_list_changed.disconnect(_on_property)
		if is_instance_valid(_editor_filesearch):
			_editor_filesearch.visible = true
			
		if is_instance_valid(_script_filesearch):
			_script_filesearch.queue_free()
		
		if is_instance_valid(_script_list):
			_script_list.queue_free()

func _on_sc_item_selected(index : int) -> void:
	if _script_list.item_count > index and index > -1:
		index = _get_script_selected(index)
		if index == -1:
			return
		select(index)
	
func _on_sc_item_activate(index : int) -> void:
	if _script_list.item_count > index:
		index = _get_script_selected(index)
		if index > -1 and index < _editor_list.item_count:
			_editor_list.item_activated.emit(index)

func _on_property() -> void:
	_script_list.update()
	
func _on_sc_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if _script_list.item_count > index:
		index = _get_script_selected(index)
		if index == -1:
			return
		_editor_list.item_clicked.emit(index, at_position, mouse_button_index)
		_script_list.update()
			
func _get_script_selected(index : int) -> int:
	if _editor_list.item_count == _script_list.item_count:
		return index
		
	var tp : String = _script_list.get_item_tooltip(index)
	var cindx : int = -1
	if !tp.is_empty():
		for x : int in _editor_list.item_count:
			if tp == _editor_list.get_item_tooltip(x):
				cindx = x
				break
	else:
		tp = _script_list.get_item_text(index)
		for x : int in _editor_list.item_count:
			if tp == _editor_list.get_item_text(x):
				cindx = x
				break
		
	return cindx
		
#func set_handler(manager : Object) -> void:
	#_script_list.set_handler(manager)
		#
func _init(list : ItemList) -> void:
	_editor_list = list
	_editor_list.item_selected.connect(_item_selected)
	_editor_list.property_list_changed.connect(_on_property)
	
	var parent: Node = _editor_list.get_parent()
	_script_list = list.duplicate()
	_script_list.set_script(SplitterList)
	_script_list.set_reference(_update_list)
	_script_list.set_list(_editor_list)
	_script_list.item_selected.connect(_on_sc_item_selected)
	_script_list.item_activated.connect(_on_sc_item_activate)
	_script_list.item_clicked.connect(_on_sc_item_clicked)
	
	if _script_list.has_signal(&"move_item_by_index"):
		_script_list.connect(&"move_item_by_index", _on_move_item_by_index)
	#_editor_list.draw.connect(_on_update_list)
	
	_script_list.add_to_group(&"__SP_LT__")
	_array_list = [_editor_list, _script_list]
	
	list.visible = false
	
	var filesearch : Object = parent.get_child(0)
	if filesearch is LineEdit:
		_editor_filesearch = filesearch
		var txt : String = filesearch.text
		if !txt.is_empty():
			filesearch.set(&"text", "")
		
		_script_filesearch = filesearch.duplicate()
		_script_filesearch.text_changed.connect(_on_update_list_search)
		
		filesearch.visible = false
	
	parent.add_child(_script_list)
	parent.move_child(_script_list, 0)
	parent.add_child(_script_filesearch)
	parent.move_child(_script_filesearch, 0)
	
	_script_list.update()
	
func _on_update_list() -> void:
	if _update_list_queue:
		return
		
	if !is_instance_valid(_script_list) or !is_instance_valid(_editor_list):
		return
		
	_update_list_queue = true
	
	var filtered : bool = false
		
	if is_instance_valid(_script_filesearch):
		filtered = !_script_filesearch.text.is_empty()
			
	
	var item_list : ItemList = _editor_list
	
	_script_list.clear()
	
	if filtered:
		_on_update_list_search(_script_filesearch.text)
	else:
		for x : int in item_list.item_count:
			var indx : int = _script_list.item_count
			_script_list.add_item(item_list.get_item_text(x), item_list.get_item_icon(x), true)
			_script_list.set_item_metadata(indx, item_list.get_item_metadata(x))
			_script_list.set_item_tooltip(indx, item_list.get_item_tooltip(x))
			_script_list.set_item_icon_modulate(indx, item_list.get_item_icon_modulate(x))
			_script_list.set_item_custom_fg_color(indx, item_list.get_item_custom_fg_color(x))
	
		update_list_selection()
	
	set_deferred(&"_update_list_queue", false)
	
func _on_update_list_search(txt : String) -> void:
	if txt.is_empty():
		_on_update_list()
		return
		
	if !is_instance_valid(_script_list):
		return
		
	_script_list.clear()
	
	var rgx : RegEx = RegEx.create_from_string("(?i).*{0}.*".format([txt]))
	
	if !is_instance_valid(rgx) or !rgx.is_valid():
		return
	
	var item_list : ItemList = _editor_list
	for x : int in item_list.item_count:
		var _txt : String = item_list.get_item_text(x)
		if rgx.search(_txt) != null:
			var indx : int = _script_list.add_item(item_list.get_item_text(x), item_list.get_item_icon(x), true)
			_script_list.set_item_metadata(indx, item_list.get_item_metadata(x))
			_script_list.set_item_tooltip(indx, item_list.get_item_tooltip(x))
			_script_list.set_item_icon_modulate(indx, item_list.get_item_icon_modulate(x))
			_script_list.set_item_custom_fg_color(indx, item_list.get_item_custom_fg_color(x))
	
	update_list_selection()
	
func update_list_selection() -> void:
	if update_selections_callback.is_valid():
		update_selections_callback.call(_array_list)
	
func _item_selected(i : int) -> void:
	item_selected.emit(i)
	
func _update_list() -> void:
	updated.emit()
	_on_update_list()
	
func get_editor_list() -> ItemList:
	return _editor_list
	
func get_selected_id() -> int:
	for x : int in range(_editor_list.item_count):
		if _editor_list.is_selected(x):
			return x
	return -1
	
func remove(index : int) -> void:
	if _editor_list.item_count > index and index > -1:
		_editor_list.item_clicked.emit(index, _editor_list.get_local_mouse_position(), MOUSE_BUTTON_MIDDLE)
		
func item_count() -> int:
	return _editor_list.item_count
	
func _select() -> void:
	if _selet_queue > -1 and _editor_list.item_count > _selet_queue:
		_editor_list.select(_selet_queue, true)
		_editor_list.item_selected.emit(_selet_queue)
		_update_list.call_deferred()
	_selecting = false

func update_list() -> void:
	_on_update_list()

func select(i : int) -> void:
	if i > -1 and _editor_list.item_count > i:
		_selet_queue = i
		if _selecting:
			return
		_selecting = true
		_select.call_deferred()

func is_selected(i : int) -> bool:
	if _editor_list.item_count > i and i > -1:
		return _editor_list.is_selected(i)
	return false

func get_item_tooltip(item : int) -> String:
	if _editor_list.item_count > item and item > -1:
		return _editor_list.get_item_tooltip(item)
	return ""

func get_item_icon(item : int) -> Texture2D:
	if _editor_list.item_count > item and item > -1:
		return _editor_list.get_item_icon(item)
	return null

func get_item_icon_modulate(item : int) -> Color:
	if _editor_list.item_count > item and item > -1:
		return _editor_list.get_item_icon_modulate(item)
	return Color.WHITE
	
func get_item_text(item : int) -> String:
	if _editor_list.item_count > item and item > -1:
		return _editor_list.get_item_text(item)
	return ""

func reset() -> void:
	if is_instance_valid(_editor_list):
		_editor_list.visible = true
		if _editor_list.draw.is_connected(_on_update_list):
			_editor_list.draw.disconnect(_on_update_list)
		if _editor_list.item_selected.is_connected(_item_selected):
			_editor_list.item_selected.disconnect(_item_selected)
		if _editor_list.property_list_changed.is_connected(_on_property):
			_editor_list.property_list_changed.disconnect(_on_property)

	if is_instance_valid(_editor_filesearch):
		_editor_filesearch.visible = true
		
	if is_instance_valid(_script_filesearch):
		_script_filesearch.queue_free()
	
	if is_instance_valid(_script_list):
		_script_list.queue_free()

func _on_move_item_by_index(from : int, to : int) -> void:
	if from == to:
		return
		
	for x : ItemList in [_script_list, _editor_list]:
		if !is_instance_valid(x):
			return
		for y : int in [from, to]:
			if x.item_count <= y or y < 0:
				return
	
	var values : Array[int] = [from, to]
	
	for v : int in range(0, values.size(), 1):
		if _script_list.get_item_tooltip(v) != _editor_list.get_item_tooltip(v):
			var value = -1
			var st : String = _script_list.get_item_tooltip(from)
			
			for x : int in _editor_list.item_count:
				if st == _editor_list.get_item_tooltip(x):
					value = x
					break
			
			if value == -1:
				return
				
			values[v] = value
			
	move_item.emit(values[0], values[1])
