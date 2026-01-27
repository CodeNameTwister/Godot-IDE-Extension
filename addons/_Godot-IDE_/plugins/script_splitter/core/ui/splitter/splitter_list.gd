@tool
extends ItemList
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

signal move_item_by_index(from : int, to : int)

var _ss: Callable
var _delta : int = 0
var _list : ItemList = null
var _dragged_item_index: int = -1

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

func update() -> void:
	_delta = 0
	set_physics_process(true)
	
func set_list(item : ItemList) -> void:
	_list = item

func set_reference(scall : Callable) -> void:
	_ss = scall
	
func changes(list : ItemList) -> bool:
	if list.item_count != item_count:
		return true
		
	for x : int in list.item_count:
		if is_selected(x) != is_selected(x) or \
		get_item_text(x) != list.get_item_text(x) or\
		get_item_icon(x) != list.get_item_icon(x) or \
		get_item_icon_modulate(x) != list.get_item_icon_modulate(x) or \
		get_item_tooltip(x) != list.get_item_tooltip(x):
			return true
			
	return false
	
func _physics_process(__ : float) -> void:
	_delta += 1
	if _delta < 10:
		return
	set_physics_process(false)
	if !_ss.is_valid():
		return
	if !changes(_list):
		return
	_ss.call()

func _get_drag_data(at_position: Vector2) -> Variant:
	var item_index : int = get_item_at_position(at_position)
	
	if item_index != -1:
		_dragged_item_index = item_index
		
		var drag_preview : HBoxContainer = HBoxContainer.new()
		var icon : TextureRect = TextureRect.new()
		var label : Label = Label.new()
		
		drag_preview.set(&"theme_override_constants/separation", 0)
		icon.texture = get_item_icon(0)
		icon.modulate = get_item_icon_modulate(0)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		label.text = get_item_text(item_index)
		drag_preview.add_child(icon)
		drag_preview.add_child(label)
		
		set_drag_preview(drag_preview)
		var tp : String = get_item_tooltip(item_index)
		
		for x : Node in Engine.get_main_loop().get_nodes_in_group(&"SP_TAB_BUTTON"):
			if x is Control:
				if tp == x.tooltip_text and x.has_method(&"_on_input"):
					var ip : InputEventMouseButton = InputEventMouseButton.new()
					ip.button_index = MOUSE_BUTTON_LEFT
					ip.pressed = true
					x.call(&"_on_input", ip)
		
		return item_index
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_INT and data > -1 and data == _dragged_item_index:
		var drop_index : int = get_item_at_position(at_position)
		
		return drop_index != -1 and drop_index != data
		
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_INT or data < 0 or data != _dragged_item_index:
		return
	var from_index : int = data as int
	var to_index : int = get_item_at_position(at_position)
	
	if from_index != -1 and to_index != -1:
		move_item_by_index.emit(from_index, to_index)
		
	_dragged_item_index = -1
