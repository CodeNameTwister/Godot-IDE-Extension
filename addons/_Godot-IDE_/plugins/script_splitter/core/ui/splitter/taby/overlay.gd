@tool
extends ColorRect
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const FILE_IN = preload("./../../../../assets/file_in.png")
const SPLIT_SELECTION = preload("./../../../../core/ui/splitter/taby/split_selection/SplitSelection.tscn")

const NORMAL : float = 0.4
const FILL : float = 0.65

var _dt : float = 0.0
var _fc : float = 0.0
var _ec : float = 1.0

var _ref : TabBar = null
var _container : Control = null
var _target : Control = null

var _split_selection : Control = null

var _type_split : StringName = &""

static var _busy : bool = false

func get_type_split() -> StringName:
	return _type_split

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1

func start(ref : TabBar) -> void:
	_fc = NORMAL
	_ec = FILL
	_dt = 0.0
	_ref = ref
	modulate.a = _fc
	_target = null
	
	if is_instance_valid(ref):
		_container = ref.get_parent()
	else:
		_container = null
		
	_update()
	set_process(true)
	
func _reset() -> void:
	for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
		if get_parent() != x:
			reparent(x)
			break
			
static func _free() -> void:
	var sc : SceneTree = Engine.get_main_loop()
	if sc:
		for __ : int in range(0, 5, 1):
			await sc.process_frame
			if !is_instance_valid(sc):
				return
		_busy = false
	
func stop(tab : TabBar = null) -> bool:
	set_process(false)
	var out : bool = false
	if !_busy and mouse_over(_target):
		set_physics_process(true)
		_busy = true
		_type_split = &""
		_free.call_deferred()
		if is_instance_valid(tab) and tab == _ref:
			var container : Node = _ref.get_parent()
			if is_instance_valid(_container) and _container == container:
				out = get_global_rect().has_point(get_global_mouse_position())
				
			for b : Node in _split_selection.get_buttons():
				if b is Control:
					if !b.visible:
						continue
					if b.get_global_rect().has_point(get_global_mouse_position()):
						_type_split = b.name
						break
				
	visible = false
	_container = null
	_target = null
	return out
	
func get_container(ignore_self : bool = true) -> Node:
	for x : Node in get_tree().get_nodes_in_group(&"__SC_SPLITTER__"):
		if ignore_self and x == _container:
			continue
		var root : Node = x.get_parent()
		if root is Control:
			var rect : Rect2 = root.get_global_rect()
			if rect.has_point(get_global_mouse_position()):
				return x
	return null

func _ready() -> void:
	color = Color.DARK_GREEN
	
	set_process(false)
	set_physics_process(false)
	visible = false
	
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var cnt : Control = SPLIT_SELECTION.instantiate()
	
	add_child(cnt)
	
	cnt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cnt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cnt.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_split_selection = cnt

func mouse_over(control: Control) -> bool:
	if null == control or !control.is_visible_in_tree():
		return false
	
	var control_window : Window = control.get_window()
	
	if control_window.get_window_id() != get_window().get_window_id():
		return false
	
	var mp : Vector2i = DisplayServer.mouse_get_position()
	var mouse_window_id = DisplayServer.get_window_at_screen_position(mp)
	
	if  mouse_window_id != control_window.get_window_id():
		return false
		
	return control.get_global_rect().has_point(control.get_global_mouse_position())#mp)
	
func _update() -> void:
	if is_instance_valid(_container):
		var sc : SceneTree = Engine.get_main_loop()
		if sc:
			for x : Node in sc.get_nodes_in_group(&"__SC_SPLITTER__"):
				if x is Control and mouse_over(x):
					var same : bool = x == _container
					
					if same and (!(x is TabContainer) or x.get_child_count() < 2):
						continue
					
					if !visible:
						modulate.a = 0.0
						_fc = NORMAL
						_ec = FILL
						_dt = 0.0
						visible = true
						
					size = x.size
					global_position = x.global_position
						
					
					for y : Control in _split_selection.get_buttons():
						y.visible = same
					
					if _split_selection.file_texture:
						_split_selection.file_texture.modulate.a = float(!same)
					
					_target = x
					return
		
		_fc = NORMAL
		_ec = FILL
		_dt = 0.0
		modulate.a = _fc
		_target = null
		visible = false

func _process(delta: float) -> void:
	_update()
	
	if !visible:
		return
	
	_dt += delta * 2.0
	if _dt >= 1.0:
		modulate.a = _ec
		if _ec == FILL:
			_ec = NORMAL
			_fc = FILL
		else:
			_ec = FILL
			_fc = NORMAL
		_dt = 0.0
		return
	modulate.a = lerpf(_fc, _ec, _dt)
	
func resize() -> void:
	if !is_inside_tree():
		await tree_entered
		
	position = Vector2.ZERO
	reset_size()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	#set_anchors_preset(Control.PRESET_FULL_RECT)
