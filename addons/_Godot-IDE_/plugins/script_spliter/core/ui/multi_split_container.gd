@tool
@icon("icon/MultiSpliter.svg")
extends Container
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	https://github.com/CodeNameTwister/Multi-Split-Container
#
#	Multi-Split-Container addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const SplitContainerItem : Script = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/ui/split_container_item.gd")
const SplitButton : Texture = preload("res://addons/_Godot-IDE_/plugins/script_spliter/core/ui/icon/MultiSpliterButton.svg")

@export_category("Multi-Split Settings")
## Max columns by rows, after added childs this is eparated by row group by columns size!
## [br][br]
## if this value is 0, will not create rows spliters.
@export_range(0.0, 1000.0, 1.0) var max_columns : int = 0:
	set(e):
		max_columns = maxi(0, e)

		if Engine.is_editor_hint():
			for x : int in range(separators_line_offsets.size()):
				separators_line_offsets[x] = 0.0
		for x : LineSep in _separators:
			x.queue_free()

		_separators.clear()
		_first = true
		update()

@export_group("Line Separator", "separator_line")
## Line separator size.
@export var separator_line_size : float = 4.0:
	set(e):
		separator_line_size = max(e, 0.0)
		update()

## Separator line color.
@export var separator_line_color : Color = Color.MAGENTA:
	set(e):
		separator_line_color = e
		if separator_line_color == Color.MAGENTA: # That color reminds me of texture not found errors.
			var root = EditorInterface.get_base_control()
			separator_line_color = root.get_theme_color("base_color", "Editor")
		update()

## Separator line visibility.
@export var separator_line_visible : bool = true:
	set(e):
		separator_line_visible = e
		for l : LineSep in _separators:
			l.visible = separator_line_visible

@export_subgroup("Behaviour", "behaviour_")
## Enable function for auto expand lines container on inside focus.
@export var behaviour_expand_on_focus : bool = true

## Enable function for auto expand lines container on double click in the line.
@export var behaviour_expand_on_double_click : bool = true:
	set(e):
		behaviour_expand_on_double_click = e
		for l : LineSep in _separators:
			l.double_click_handler = behaviour_expand_on_double_click
		
## Enable movement by touching line.	
@export var behaviour_can_move_by_line : bool = true:
	set(e):
		behaviour_can_move_by_line = e
		for l : LineSep in _separators:
			l.draggable = behaviour_can_move_by_line

## This allow expand you current focused container if you shrunk it.
@export var behaviour_can_expand_focus_same_container : bool = false

## Enable smooth when expand container.
@export var behaviour_expand_smoothed : bool = true:
	set(e):
		behaviour_expand_smoothed = e
		if !e:
			if _tween and _tween.is_running():
				_tween.kill()
			_tween = null

## Time speed duration for reset expand container.
@export_range(0.01, 1000.0, 0.01) var behaviour_expand_smoothed_time : float = 0.24:
	set(e):
		behaviour_expand_smoothed_time = maxf(0.01, e)
		if _tween and _tween.is_running():
			_tween.kill()
		_tween = null

## Custom initial offset for separator lines. (TODO: Still Working here!)
@export var separators_line_offsets : Array[float] :
	set(e):
		separators_line_offsets = e

		if Engine.is_editor_hint():
			if separators_line_offsets.size() != _separators.size():
				separators_line_offsets.resize(_separators.size())
		update()

@export_subgroup("Drag Button", "drag_button")

## Set if drag button always be visible (Useful for test button size)
@export var drag_button_always_visible : bool = false:
	set(e):
		drag_button_always_visible = e

		var min_visible_drag_button : float = 0.0
		if drag_button_always_visible:
			min_visible_drag_button = 0.4

		for l : LineSep in _separators:
			if l.button:
				l.button.modulate.a = 0.0
				l.button.min_no_focus_transparense = min_visible_drag_button

## Min size for drag button visible on split lines.
@export_range(1.0, 200.0, 0.1) var drag_button_size : float = 24.0:
	set(e):
		drag_button_size = e
		update()

## Modulate color for the drag button.
@export var drag_button_modulate : Color = Color.MAGENTA:
	set(e):
		drag_button_modulate = e
		if drag_button_modulate == Color.MAGENTA:
			if Engine.is_editor_hint():
				var root : Control = EditorInterface.get_base_control()
				drag_button_modulate = root.get_theme_color("base_color", "Editor").lightened(0.5)
		update()

## Change default drag button icon.
@export var drag_button_icon : Texture = null:
	set(e):
		drag_button_icon = e
		update()

var _separators : Array[LineSep] = []
var _last_container_focus : Node = null
var _frame : int = 1
var _first : bool = true
var _tween : Tween = null

func get_separators() -> Array[LineSep]:
	return _separators

## Get line begin offset limit.
func get_line_seperator_left_offset_limit(index : int) -> float:
	if index < _separators.size():
		var line_sep : LineSep = _separators[index]
		if !line_sep.is_vertical:
			if index < 1:
				return -_separators[index].initial_position.x
			var next : LineSep = _separators[index - 1]
			return (next.initial_position.x + (next.size.x/2.0)) - _separators[index].initial_position.x
		else:
			if index < 1:
				return -_separators[index].initial_position.y
			var next : LineSep = _separators[index - 1]
			return (next.initial_position.y + (next.size.y/2.0)) - _separators[index].initial_position.y
	push_warning("[PLUGIN] Not valid index for line separator!")
	return 0.0

## Get line end offset limit.
func get_line_seperator_right_offset_limit(index : int) -> float:
	if index < _separators.size():
		var line_sep : LineSep = _separators[index]
		if !line_sep.is_vertical:
			if index + 1 == _separators.size():
				return (size.x/2.0) -_separators[index].initial_position.x
			var current : LineSep = _separators[index]
			return (_separators[index + 1].initial_position.x - current.initial_position.x + (current.size.x/2.0))
		else:
			if index + 1 == _separators.size():
				return size.x -_separators[index].initial_position.y
			var current : LineSep = _separators[index]
			return (_separators[index + 1].initial_position.y - current.initial_position.y + (current.size.y/2.0))
	push_warning("[PLUGIN] Not valid index for line separator!")
	return 0.0

# This is function is util when you want expand or constraint manualy offset.
## Update offset of the line
func update_line_separator_offset(index : int, offset : float) -> void:
	var line_sep : LineSep = _separators[index]
	line_sep.offset = offset
	line_sep.force_update()

## Get total line count.
func get_line_separator_count() -> int:
	return _separators.size()

## Get Line reference by index, see get_line_separator_count()
func get_line_separator(index : int) -> LineSep:
	return _separators[index]

## Get if line separator is vertical.
func is_vertical_line_separator(index : int) -> bool:
	if index < _separators.size():
		return _separators[index].is_vertical
	push_warning("[PLUGIN] Not valid index for line separator!")
	return false

## Expand splited container by index container.
func expand_splited_container(node : Node) -> void:
	var same : bool = _last_container_focus == node

	if same and !behaviour_can_expand_focus_same_container:
		return

	_last_container_focus = node

	if !behaviour_expand_on_focus:
		return

	if _tween and _tween.is_running():
		if same:
			return
		_tween.kill()
		_tween = null

	var top_lines : Array[LineSep] = []
	var bottom_lines : Array[LineSep] = []

	var update_required : bool = false

	for line : LineSep in _separators:
		if node in line.top_items:
			update_required = update_required or line.offset < 0.0
			top_lines.append(line)
		elif node in line.bottom_items:
			update_required = update_required or line.offset > 0.0
			bottom_lines.append(line)

	if update_required:
		if behaviour_expand_smoothed:
			_tween = get_tree().create_tween()
			_tween.tween_method(_reset_expanded_lines.bind(top_lines, bottom_lines), 0.0, 1.0, behaviour_expand_smoothed_time)
		else:
			_reset_expanded_lines(1.0, top_lines, bottom_lines)

func _reset_expanded_lines(_lerp : float, top_lines : Array[LineSep], bottom_lines : Array[LineSep]) -> void:
	for iline : int in range(top_lines.size() - 1, -1, -1):
		var line : LineSep = top_lines[iline]
		if is_instance_valid(line):
			if line.offset < 0.0:
				line.offset = lerp(line.offset, 0.0, _lerp)
		else:
			top_lines.remove_at(iline)
			
	for iline : int in range(bottom_lines.size() - 1, -1, -1):
		var line : LineSep = bottom_lines[iline]
		if is_instance_valid(line):
			if line.offset > 0.0:
				line.offset = lerp(line.offset, 0.0, _lerp)
		else:
			bottom_lines.remove_at(iline)

	for line : LineSep in top_lines:
		line.force_update()
	for line : LineSep in bottom_lines:
		line.force_update()

## Get initial position of a separator line.
func get_line_separator_initial_position(index : int) -> Vector2:
	if index < _separators.size():
		return _separators[index].initial_position
	push_warning("[PLUGIN] Not valid index for line separator!")
	return Vector2.ZERO

class DragButton extends Button:
	var _frm : float = 0.0
	var _line_sep : LineSep = null
	var _is_pressed : bool = false

	var is_hover : bool = false

	var _hover : Array[bool] = [false, false]

	var min_no_focus_transparense : float = 0.0:
		set(e):
			min_no_focus_transparense = e
			modulate.a = maxf(modulate.a, min_no_focus_transparense)

	static var DEFAULT_STYLE : StyleBox = null

	func set_drag_icon(new_icon : Texture) -> void:
		if icon != new_icon:
			if new_icon == null:
				icon = SplitButton
				return
			icon = new_icon

	func update_gui() -> void:
		if !_line_sep:
			return

		if _line_sep.is_vertical:
			_line_sep.mouse_default_cursor_shape = Control.CURSOR_VSPLIT
			mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		else:
			_line_sep.mouse_default_cursor_shape = Control.CURSOR_HSPLIT
			mouse_default_cursor_shape = Control.CURSOR_HSPLIT

	func set_line(line_sep : LineSep) -> void:
		if _line_sep:
			if _line_sep.mouse_entered.is_connected(_on_enter):
				_line_sep.mouse_entered.disconnect(_on_enter)
			if _line_sep.mouse_exited.is_connected(_on_exit):
				_line_sep.mouse_exited.disconnect(_on_exit)
			if _line_sep.gui_input.is_connected(_on_input):
				_line_sep.gui_input.disconnect(_on_input)

		_line_sep = line_sep

		if _line_sep:
			if !_line_sep.mouse_entered.is_connected(_on_enter):
				_line_sep.mouse_entered.connect(_on_enter.bind(1))
			if !_line_sep.mouse_exited.is_connected(_on_exit):
				_line_sep.mouse_exited.connect(_on_exit.bind(1))
			if !_line_sep.gui_input.is_connected(_on_input):
				_line_sep.gui_input.connect(_on_input)


	func _init(line_sep : LineSep = null) -> void:
		modulate.a = 0.0

		set_line(line_sep)

		button_down.connect(_on_press)
		button_up.connect(_out_press)
		mouse_entered.connect(_on_enter.bind(0))
		mouse_exited.connect(_on_exit.bind(0))
		
		gui_input.connect(_custom_input)

		icon = SplitButton
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		expand_icon = true

		if null != icon:
			flat = true

		if DEFAULT_STYLE == null:
			DEFAULT_STYLE = StyleBoxEmpty.new()

		focus_mode = Control.FOCUS_CLICK

		set(&"theme_override_styles/focus", DEFAULT_STYLE)
		set(&"theme_override_styles/disabled_mirrored", DEFAULT_STYLE)
		set(&"theme_override_styles/disabled", DEFAULT_STYLE)
		set(&"theme_override_styles/hover_pressed_mirrored", DEFAULT_STYLE)
		set(&"theme_override_styles/hover_pressed", DEFAULT_STYLE)
		set(&"theme_override_styles/hover_mirrored", DEFAULT_STYLE)
		set(&"theme_override_styles/hover", DEFAULT_STYLE)
		set(&"theme_override_styles/pressed_mirrored", DEFAULT_STYLE)
		set(&"theme_override_styles/pressed", DEFAULT_STYLE)
		set(&"theme_override_styles/normal_mirrored", DEFAULT_STYLE)
		set(&"theme_override_styles/normal", DEFAULT_STYLE)

		z_as_relative = true
		z_index = 2000

		update_gui()
		
	func _custom_input(e : InputEvent) -> void:
		if e is InputEventMouseButton:
			if e.pressed and e.double_click:
				get_tree().call_group(&"ScriptSpliter", &"swap", get_parent())

	func _on_input(e : InputEvent) -> void:
		if e is InputEventMouseButton:
			if e.pressed and e.double_click:
				if _line_sep and _line_sep.double_click_handler:
					_line_sep.offset = 0.0
					_line_sep.offset_updated.emit()
			elif e.pressed and _line_sep.draggable and e.button_index == 1:
				button_down.emit()
			elif !e.pressed and _line_sep.draggable and e.button_index == 1:
				button_up.emit()

	func set_line_sep_reference(ref : LineSep) -> void:
		_line_sep = ref

	func _ready() -> void:
		set_process(false)

	func _on_enter(x : int = 0) -> void:
		_hover[x] = true

		_frm = 0.0
		modulate.a = 1.0
		is_hover = true
		set_process(true)

	func _on_exit(x : int = 0) -> void:
		_hover[x] = false

		for h : bool in _hover:
			if h != false:
				return

		_frm = 0.0
		modulate.a = 1.0
		is_hover = false
		set_process(true)

	func _on_press() -> void:
		_is_pressed = true
		_frm = 0.0
		modulate.a = 1.0
		set_process(true)

	func _out_press() -> void:
		_is_pressed = false
		set_process(true)

	func _process(delta : float) -> void:
		if !has_focus() and !is_hover:
			_frm += delta * 0.4
			if _frm >= 1.0:
				_frm = 1.0
				set_process(false)
			modulate.a = lerp(modulate.a, min_no_focus_transparense, _frm)
		if _is_pressed:
			var mpos : Vector2 = _line_sep.get_parent().get_local_mouse_position()
			if mpos != get_rect().get_center():
				_line_sep.update_offset_by_position(mpos)

class UndoredoSplit extends RefCounted:
	var object : SplitContainerItem = null
	var c_objects : Array[Node] = []

class LineSep extends ColorRect:
	signal offset_updated()

	var top_lines : Array[LineSep] = []
	var bottom_lines : Array[LineSep] = []

	var top_items : Array[Control] = []
	var bottom_items : Array[Control] = []

	var is_vertical : bool = false:
		set(e):
			is_vertical = e

			if button:
				button.update_gui()

	var row : int = 0

	var initial_position : Vector2 = Vector2.ZERO
	var offset : float = 0.0

	var min_size_offset : float = 0.0

	var prev_line : LineSep = null
	var next_line : LineSep = null

	var button : DragButton = null

	var double_click_handler : bool = true
	var draggable : bool = true

	func set_next_line(next : LineSep = null) -> void:
		next_line = next
		next.prev_line = self

	func clear() -> void:
		top_items.clear()
		bottom_items.clear()
		top_lines.clear()
		bottom_lines.clear()

	func reset() -> void:
		position = initial_position
		update_items()

	func update_items() -> void:
		if is_vertical:
			for item : Control in top_items:
				item.size.y = position.y - item.position.y 
				if !prev_line:
					item.position.y = 0.0

			for item : Control in bottom_items:
				item.position.y = position.y + size.y

				if next_line:
					item.size.y = next_line.position.y - item.position.y
				else:
					item.size.y = get_parent().size.y - item.position.y
		else:
			for item : Control in top_items:
				item.size.x = position.x - item.position.x + (size.x / 2.0) - 2.0
				if !prev_line:
					item.position.x = 0.0

			for item : Control in bottom_items:
				var diff : float = position.x + (size.x / 2.0) + 2.0
				item.position.x = diff

				if next_line:
					item.size.x = next_line.position.x - item.position.x
				else:
					item.size.x = get_parent().size.x - item.position.x

	func force_update() -> void:
		update_offset_by_position(initial_position + Vector2(offset * int(!is_vertical), offset * int(is_vertical)))

	func get_current_position() -> Vector2:
		return initial_position + Vector2(offset * int(!is_vertical), offset * int(is_vertical))

	func update_offset_by_position(vpos : Vector2) -> void:
		if is_vertical:
			min_size_offset = 0.0
			for x : Control in top_items:
				min_size_offset = maxf(min_size_offset, x.get_minimum_size().y)
			if prev_line:
				prev_line.min_size_offset = 0.0
				for x : Control in prev_line.bottom_items:
					prev_line.min_size_offset = maxf(prev_line.min_size_offset, x.get_minimum_size().y)

			offset = vpos.y - initial_position.y
			offset = minf(offset, get_parent().size.y - (initial_position.y + size.y + min_size_offset))
			offset = maxf(offset, -(initial_position.y - min_size_offset))

			if next_line:
				var val : float = next_line.position.y - (initial_position.y + size.y + min_size_offset)
				if offset > val:
					offset = val
			else:
				var val : float = get_parent().size.y - (initial_position.y + (size.y / 2.0) + min_size_offset)
				if offset > val:
					offset = val
			if prev_line:
				var val : float = -(initial_position.y - (prev_line.position.y + prev_line.size.y + prev_line.min_size_offset))

				if offset < val:
					offset = val
			else:
				var top_size_offset : float = 0.0
				for x : Control in top_items:
					top_size_offset = maxf(top_size_offset, x.get_minimum_size().y)
				offset = maxf(offset, top_size_offset-initial_position.y)

			position.y = initial_position.y + offset

			for line : LineSep in top_lines:
				line.size.y = position.y - line.position.y

			for line : LineSep in bottom_lines:
				line.position.y = position.y + size.y

				if next_line:
					line.size.y = next_line.position.y - line.position.y
				else:
					line.size.y = get_parent().size.y - line.position.y
		else:
			min_size_offset = 0.0
			for x : Control in bottom_items:
				min_size_offset = maxf(min_size_offset, x.get_minimum_size().x)

			if prev_line:
				prev_line.min_size_offset = 0.0
				for x : Control in prev_line.bottom_items:
					prev_line.min_size_offset = maxf(prev_line.min_size_offset, x.get_minimum_size().x)

			offset = vpos.x - initial_position.x
			offset = minf(offset, get_parent().size.x - (initial_position.x + size.x + min_size_offset))
			offset = maxf(offset, -initial_position.x)

			if next_line:
				var val : float = next_line.position.x - (initial_position.x + size.x + min_size_offset)
				if offset > val:
					offset = val
			else:
				var val : float = get_parent().size.x - (initial_position.x + (size.x/2.0) + min_size_offset)
				if offset > val:
					offset = val
			if prev_line:
				var val : float = -(initial_position.x - (prev_line.position.x + prev_line.size.x + prev_line.min_size_offset))

				if offset < val:
					offset = val
			else:
				var top_size_offset : float = 0.0
				for x : Control in top_items:
					top_size_offset = maxf(top_size_offset, x.get_minimum_size().x)
				offset = maxf(offset, top_size_offset-initial_position.x)

			position.x = initial_position.x  + offset
		update_items()

	func _draw() -> void:
		update()

	func update() -> void:
		button.rotation_degrees = 90.0 * int(is_vertical)
		button.pivot_offset = button.size / 2.0
		button.position = size / 2.0 - button.pivot_offset



	func _init() -> void:
		color = Color.RED

	func _ready() -> void:
		name = "SplitLine"
		if button == null:
			button = DragButton.new(self)
			add_child(button, false, Node.INTERNAL_MODE_BACK)

func _test() -> void:
	queue_redraw()

func _init() -> void:
	child_entered_tree.connect(_on_enter)
	child_exiting_tree.connect(_on_exiting)

func update() -> void:
	set_process(true)

func _create_separator() -> Control:
	var line_sep : LineSep = LineSep.new()
	line_sep.offset_updated.connect(update)
	return line_sep

func _undoredo_undo(ur : UndoredoSplit) -> void:
	if !is_instance_valid(ur):
		return

	var split : SplitContainerItem = ur.object
	if is_instance_valid(split):
		if split.get_parent() == self:
			ur.c_objects = split.get_children()
			for x : Node in ur.c_objects:
				split.remove_child(x)
				if x is Control:
					x.visible = false
					add_child(x)
			if is_instance_valid(split) and split.get_parent() == self:
				remove_child(split)

func _update() -> void:
	var items : Array[Control] = []
	for x : Node in get_children():
		if is_instance_valid(x) and x is Control:
			if x.visible and !x.is_queued_for_deletion():
				if x is SplitContainerItem:
					if x.get_child_count() > 0:
						var _is_visible : bool = false
						for y : Node in x.get_children():
							if y is Control and y.visible:
								_is_visible = true
								break
						if !_is_visible:
							continue
					else:
						x.queue_free()
						continue
				elif x is DragButton or x is LineSep:
					x.queue_free()
					continue
				else:
					var container : SplitContainerItem = SplitContainerItem.new()

					add_child(container, true)

					x.reparent(container)
					x = container


				x.size_flags_horizontal = Control.SIZE_FILL
				x.size_flags_vertical = Control.SIZE_FILL
				x.clip_contents = true
				x.custom_minimum_size = Vector2.ZERO
				items.append(x)

	var totals : int = items.size()
	var rows : int = 0

	if max_columns > 0:
		var _totals : int = totals
		rows = 0
		while _totals > max_columns:
			_totals -= max_columns
			rows += 1
		totals -= rows

	if totals < 1:
		for x : int in range(0, _separators.size(), 1):
			_separators[x].queue_free()
			_separators[x] = null
		_separators.clear()

		for x : Control in items:
			x.position = Vector2.ZERO
			x.size = get_rect().size
		return
	else:
		if separator_line_size <= 0.0:
			for x : int in range(0, _separators.size(), 1):
				_separators[x].queue_free()
				_separators[x] = null
			_separators.clear()
		else:
			var sep : int = totals - 1 + rows
			for x : int in range(sep, _separators.size(), 1):
				_separators[x].queue_free()
				_separators[x] = null
			_separators.resize(sep)
			for x : int in range(0, _separators.size(), 1):
				if _separators[x] == null:
					_separators[x] = _create_separator()

	rows += 1
	if max_columns > 1:
		if totals > max_columns:
			totals = max_columns

	var rect_size : Vector2 = get_rect().size
	var start_position : Vector2 = Vector2.ZERO

	var size_split : Vector2 = (rect_size  / Vector2(totals, rows))

	var size_sep : Vector2 = Vector2.ONE * separator_line_size

	if totals > 1:
		size_sep = (size_sep / (totals - 1))

	var item_size : Vector2 = Vector2(size_split.x, size_split.y)
	var line_size : Vector2 = Vector2(separator_line_size, item_size.y)

	var total_items : int = items.size()

	var vpos : Vector2 = Vector2.ZERO
	var current_row : int = 0

	var item_index : int = 0

	var last_vline : LineSep = null
	var last_hline : LineSep = null

	for x : Control in items:
		x.position = Vector2.ZERO
		x.size = x.get_minimum_size()

	for z : int in range(_separators.size()):
		var x : LineSep = _separators[z]

		x.clear()

		start_position.x += 1

		if 0 < max_columns and start_position.x + 1 > max_columns:
			total_items -= max_columns
			start_position.x = 0.0
			start_position.y += 1.0
			current_row += 1
			if total_items <= max_columns and total_items > 0:
				size_split = (rect_size / Vector2(total_items, rows))
				if total_items == 1:
					size_sep = Vector2.ONE * separator_line_size
				else:
					size_sep = ((Vector2.ONE * separator_line_size) / (total_items - 1))
				item_size = Vector2(size_split.x, size_split.y)
				line_size = Vector2(separator_line_size, rect_size.y - x.position.y)

			vpos = Vector2(0.0, start_position.y) * item_size
			x.is_vertical = true

			if x.get_parent() == null:
				add_child(x, false, Node.INTERNAL_MODE_BACK)


			x.row = current_row

			if items.size() > 0:
				var it : int = mini(item_index, items.size() - 1)
				var min_size : float = 0.0

				var _has : bool = false

				for y : int in range(z - 1, -1, -1):
					if it > -1:
						var item : Control = items[it]
						x.top_items.append(item)
						min_size = maxf(item.get_minimum_size().y, min_size)
					it -= 1

					var ln : LineSep = _separators[y]
					if ln.is_vertical:
						_has = true
						break
					x.top_lines.append(ln)
				if !_has:
					for _it : int in range(it, -1, -1):
						var item : Control = items[it]
						x.top_items.append(item)

				if item_index + 1 < items.size():
					it = item_index + 1
					_has = false
					for y : int in range(z + 1, _separators.size(), 1):
						if it < items.size():
							var item : Control = items[it]
							x.bottom_items.append(item)
						it += 1

						var ln : LineSep = _separators[y]
						if ln.is_vertical:
							_has = true
							break
						x.bottom_lines.append(ln)
					if !_has:
						for _it : int in range(it, items.size(), 1):
							var item : Control = items[_it]
							x.bottom_items.append(item)

			var vline_size : Vector2 = Vector2(rect_size.x, separator_line_size)

			x.initial_position = vpos
			x.initial_position.y -= (vline_size.y) / 2.0
			x.position = x.initial_position

			x.button.size = Vector2(drag_button_size, drag_button_size)

			x.set(&"size", vline_size)
			x.update()

			if last_vline:
				last_vline.set_next_line(x)

			last_vline = x
			last_hline = null
			item_index += 1
			continue

		vpos = start_position * item_size

		if x.get_parent() == null:
			add_child(x, false, Node.INTERNAL_MODE_BACK)


		if item_index < items.size():
			var item : Control = items[item_index]
			x.top_items.append(item)
			item_index += 1
			if item_index < items.size():
				if z + 1 < _separators.size():
					if !_separators[z].is_vertical:
						x.bottom_items.append(items[item_index])
				else:
					x.bottom_items.append(items[item_index])

		x.initial_position = vpos
		x.initial_position.x -= (line_size.x) / 2.0

		x.button.size = Vector2(drag_button_size, drag_button_size)

		x.row = current_row
		x.position = x.initial_position

		x.set(&"size", line_size)
		x.update()

		if last_hline:
			last_hline.set_next_line(x)
		last_hline = x

	for x : Control in items:
		x.size = size

	var min_visible_drag_button : float = 0.0
	if drag_button_always_visible:
		min_visible_drag_button = 0.4

	if _first:
		for l : LineSep in _separators:
			l.visible = separator_line_visible
			l.color = separator_line_color
			l.double_click_handler = behaviour_expand_on_double_click
			l.button.self_modulate = drag_button_modulate
			l.button.min_no_focus_transparense = min_visible_drag_button
			l.button.set_drag_icon(drag_button_icon)
			l.draggable = behaviour_can_move_by_line

			l.reset()

	else:
		if separators_line_offsets.size() > 0:
			for l : int in range(0, _separators.size(), 1):
				if l < separators_line_offsets.size():
					_separators[l].offset = separators_line_offsets[l]
					continue
				break

		for l : LineSep in _separators:
			l.visible = separator_line_visible
			l.color = separator_line_color
			l.double_click_handler = behaviour_expand_on_double_click
			l.button.self_modulate = drag_button_modulate
			l.button.min_no_focus_transparense = min_visible_drag_button
			l.button.set_drag_icon(drag_button_icon)
			l.draggable = behaviour_can_move_by_line

			l.force_update()

		if !Engine.is_editor_hint():
			separators_line_offsets.clear()
		else:
			for l : int in range(0, _separators.size(), 1):
				if l < separators_line_offsets.size():
					separators_line_offsets[l] = _separators[l].offset
					continue
				break

func _on_enter(n : Node) -> void:
	n.is_inside_tree()
	if n is SplitContainerItem or (n is Control and !Engine.is_editor_hint()):
		if !n.visibility_changed.is_connected(_on_visible):
			n.visibility_changed.connect(_on_visible)
		if is_node_ready():
			for x : int in range(separators_line_offsets.size()):
				separators_line_offsets[x] = 0.0
		update()

func _on_visible() -> void:
	update()

func _on_exiting(n : Node) -> void:
	if n is SplitContainerItem or (n is Control and !Engine.is_editor_hint()):
		if is_node_ready():
			for x : int in range(separators_line_offsets.size()):
				separators_line_offsets[x] = 0.0
			for x : LineSep in _separators:
				x.offset = 0.0
		if n.visibility_changed.is_connected(_on_visible):
			n.visibility_changed.disconnect(_on_visible)
		update()

func _process(__ : float) -> void:
	if is_node_ready():
		if _frame > 0:
			_frame -= 1
			return
		_update()
		if _first:
			_first = false
		else:
			set_process(false)

func _on_exiting_tree() -> void:
	var vp : Viewport = get_viewport()
	if vp and vp.size_changed.is_connected(update):
		vp.size_changed.disconnect(update)

	var parent : Node = get_parent()
	if parent is Control:
		if parent.item_rect_changed.is_connected(update):
			parent.item_rect_changed.disconnect(update)

func _enter_tree() -> void:
	var vp : Viewport = get_viewport()
	if vp and !vp.size_changed.is_connected(update):
		vp.size_changed.connect(update)

	var parent : Node = get_parent()
	if parent is Control:
		if !parent.item_rect_changed.is_connected(update):
			parent.item_rect_changed.connect(update)

	if !tree_exiting.is_connected(_on_exiting_tree):
		tree_exiting.connect(_on_exiting_tree)

func _on_draw() -> void:
	update()

func _ready() -> void:
	separator_line_color = separator_line_color
	drag_button_modulate = drag_button_modulate

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical =Control.SIZE_EXPAND_FILL

	set_deferred(&"anchor_left", 0.0)
	set_deferred(&"anchor_top", 0.0)
	set_deferred(&"anchor_bottom", 1.0)
	set_deferred(&"anchor_right", 1.0)

	if Engine.is_editor_hint():
		draw.connect(_on_draw)

	if _first:
		update()
