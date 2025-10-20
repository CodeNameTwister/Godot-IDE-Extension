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
