@tool
extends VSeparator
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var _delta : float = 0.0
var _ref : Control = null

func _ready() -> void:
	visible = false
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(_ref != null)

func update(ref : Control) -> void:
	_ref = ref
	_delta = 0.0
	visible = _ref != null
	set_process(visible)
	
func delete() -> void:
	_delta = 10.0
	_ref = null
	queue_free()

func _process(delta: float) -> void:
	_delta += delta
	if _delta < 0.5:
		return
	if is_instance_valid(_ref) and is_inside_tree():
		if _ref.get_global_rect().has_point(get_global_mouse_position()):
			return
			
	if !is_queued_for_deletion():
		queue_free()

func _get_drag_data(__ : Vector2) -> Variant:
	if !_ref:
		return null
	return _ref.owner.button_main._get_drag_data(__)
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _ref:
		_ref.owner.button_main._drop_data(_at_position, data)
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if !_ref:
		return false
	return _ref.owner.button_main._can_drop_data(at_position, data)

func get_selected_color() -> Color:
	if !_ref:
		return Color.GRAY
	return _ref.owner.get_selected_color()
