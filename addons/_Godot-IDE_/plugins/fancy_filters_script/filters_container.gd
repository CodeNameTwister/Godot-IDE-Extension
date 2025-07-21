@tool
extends ScrollContainer

func _ready() -> void:
	mouse_entered.connect(_on_mouse)
	_out_mouse()
	
func _process(_delta: float) -> void:
	if is_inside_tree():
		if get_global_rect().has_point(get_global_mouse_position()):
			return
	_out_mouse()
	
func _on_mouse() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	set_process(true)
	
func _out_mouse() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	set_process(false)
