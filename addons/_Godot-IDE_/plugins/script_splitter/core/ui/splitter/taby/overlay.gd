@tool
extends ColorRect
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const FILE_IN = preload("res://addons/_Godot-IDE_/plugins/script_splitter/assets/file_in.png")


const NORMAL : float = 0.0
const FILL : float = 0.65

var _dt : float = 0.0
var _fc : float = 0.0
var _ec : float = 1.0

var _ref : TabBar = null
var _container : Control = null

var txt : TextureRect = null

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
	
	if is_instance_valid(ref):
		_container = ref.get_parent()
	else:
		_container = null
		
	_update()
	set_process(true)
	
func stop(tab : TabBar = null) -> bool:
	set_process(false)
	visible = false
	if is_instance_valid(tab) and tab == _ref:
		var container : Node = _ref.get_parent()
		if is_instance_valid(_container) and _container == container:
			return get_global_rect().has_point(get_global_mouse_position())
	return false
	
func get_container() -> Node:
	for x : Node in get_tree().get_nodes_in_group(&"__SC_SPLITTER__"):
		if x == _container:
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
	visible = false
	
	txt = TextureRect.new()
	
	add_child(txt)
	
	txt.texture = FILE_IN
	txt.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	txt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _update() -> void:
	if is_instance_valid(_container):
		for x : Node in get_tree().get_nodes_in_group(&"__SC_SPLITTER__"):
			if x == _container:
				continue
			var root : Node = x.get_parent()
			if root is Control:
				var rect : Rect2 = root.get_global_rect()
				if rect.has_point(get_global_mouse_position()):
					size = root.size
					global_position = root.global_position
					txt.global_position = get_global_rect().get_center() - (txt.texture.get_size() * 0.5)
					if !visible:
						visible = true
					return
		
		_fc = NORMAL
		_ec = FILL
		_dt = 0.0
		modulate.a = _fc
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
	
