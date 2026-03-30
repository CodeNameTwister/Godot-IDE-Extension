@tool
extends Window
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const EDITOR_SLOT = preload("editor_slot.tscn")
const CONFIRM = preload("confirm.tscn")

var tool : Object = null
var _current : String = ""

@export var tname : LineEdit
@export var tcolor : ColorPickerButton
@export var titems : VBoxContainer
@export var add_button : Button
@export var current_file : Label

func _x(n : Node, t : StyleBox) -> void:
	if n is Control:
		n.add_theme_stylebox_override("panel", t)
		
	for z : Node in n.get_children():
		_x(z, t)
		
func apply() -> void:
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		if x.get_tittle() == _current:
			x.set_tittle(tname.text)
			x.set_color(tcolor.color)
			x.valid_changes()
	sorte()
	cancel()
	
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
	
func _on_canceled() -> void:
	for x : Node in get_children():
		if x is Popup:
			x.hide()
	
func _on_accept() -> void:
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		if x.get_tittle() == _current:
			x.valid_changes()
			x.queue_free()
	cancel()
	
func add() -> void:
	var cp : String = ""
	for z : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
		cp = z.get_current_editor()
	
	#var path : String = cp	
	if cp.begins_with("res:"):
		var x : int = ResourceLoader.get_resource_uid(cp)
		if x > -1:
			cp = ResourceUID.id_to_text(x)
		
	if cp.is_empty():
		return
		
	add_button.disabled = true
	add_button.text = tr("Already Added")
	#
	#var n : Node = EDITOR_SLOT.instantiate()
	#n.id = cp
	#
	#if path.begins_with("uid:"):
		#path = ResourceUID.uid_to_path(path)
		#
	#n.label.text = path
		#
	#titems.add_child(n)
	
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		if x.get_tittle() == _current:
			var items : Dictionary = x.get_items()
			items[cp] = true
			x.valid_changes()
			set_data(_current, tcolor.color, items)
			break
	
	var sc : ScrollContainer = titems.get_parent().get_parent()
	var vh : HScrollBar = sc.get_h_scroll_bar()
	vh.set_deferred(&"value", vh.max_value)
	
func delete() -> void:
	var pop : Popup = CONFIRM.instantiate()
	pop.accepted.connect(_on_accept)
	pop.canceled.connect(_on_canceled)
	add_child(pop)
	pop.popup_centered()
	
		
func cancel() -> void:
	hide()
		
func _ready() -> void:
	close_requested.connect(_on_hide)
	var gui_base : Control = EditorInterface.get_base_control()
	if gui_base:
		_x(self, gui_base.get_theme_stylebox("panel", "Panel"))
	
func _on_hide() -> void:
	queue_free()
	
func _remove(pth : String) -> void:
	if pth.begins_with("res:"):
		var x : int = ResourceLoader.get_resource_uid(pth)
		if x > -1:
			pth = ResourceUID.id_to_text(x)
		
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SP_SC_TEMPLATE__"):
		if x.get_tittle() == _current:
			var items : Dictionary = x.get_items()
			if items.has(pth):
				items.erase(pth)
				x.valid_changes()
				set_data(_current, tcolor.color, items)
			break
	
func _on_remove(pth : String) -> void:
	var pop : Popup = CONFIRM.instantiate()
	pop.accepted.connect(_remove.bind(pth))
	pop.canceled.connect(_on_canceled)
	add_child(pop)
	pop.popup_centered()
	
func set_data(tn : String, tc : Color, ti : Dictionary) -> void:
	_current = tn
	tname.text = tn
	tcolor.color = tc
	
	var cp : String = ""
	for z : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
		cp = z.get_current_editor()
		
	if cp.begins_with("uid:"):
		cp = ResourceUID.uid_to_path(cp)
	
	for x : Node in titems.get_children():
		x.queue_free()
	
	add_button.disabled = false
	add_button.text = tr("Add")
	current_file.text = cp
	
	
	
	for t : String in ti.keys():
		var n : Node = EDITOR_SLOT.instantiate()
		n.id = t
			
		n.del_button.pressed.connect(_on_remove.bind(t))
		
		if t.begins_with("uid:"):
			t = ResourceUID.uid_to_path(t)
			
		n.label.text = t
		
		if cp == t:
			add_button.disabled = true
			add_button.text = tr("Already added")
			
		titems.add_child(n)
		
	var sc : ScrollContainer = current_file.get_parent()
	var vh : HScrollBar = sc.get_h_scroll_bar()
	vh.set_deferred(&"value", vh.max_value)
	
	sc = titems.get_parent().get_parent()
	vh = sc.get_h_scroll_bar()
	vh.set_deferred(&"value", vh.max_value)
