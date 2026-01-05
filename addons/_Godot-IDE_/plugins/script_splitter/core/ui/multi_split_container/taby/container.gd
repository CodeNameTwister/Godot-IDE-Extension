@tool
extends PanelContainer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const TAB = preload("./../../../../core/ui/multi_split_container/taby/tab.tscn")
const TIME_WAIT : float = 0.35

const MAX_COLLAPSED : int = 6

@export var container : Control = null
var _dlt : float = 0.0
var _try : int = 0

var buttons : Array[Control] = []
var hbox : Array[HBoxContainer] = []
var pins : PackedStringArray = []

var _enable_update : bool = true

var _reference : TabBar = null

var _select_color : Color = Color.CADET_BLUE:
	set = set_select_color
			
var _updating : bool = false

var style : StyleBox = null

var _behaviour_collapsed : int = MAX_COLLAPSED:
	set(e):
		_behaviour_collapsed = mini(maxi(0, e), MAX_COLLAPSED)

func _enter_tree() -> void:
	modulate.a = 0.0
	z_index = 10
	get_tree().create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

	_setup()
	
func _exit_tree() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.disconnect(_on_change)

func _on_change() -> void:
	var dt : Array = [
		"plugin/script_splitter/behaviour/refresh_warnings_on_saveplugin/script_splitter/editor/list/selected_color"
	]
	
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var changes : PackedStringArray = settings.get_changed_settings()
	
	for c in changes:
		if c in dt:
			_setup()
			break
	
func _setup() -> void:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	if !settings.settings_changed.is_connected(_on_change):
		settings.settings_changed.connect(_on_change)
	
	for x : Array in [
		["_select_color", "plugin/script_splitter/behaviour/refresh_warnings_on_saveplugin/script_splitter/editor/list/selected_color"]
	]:
		if settings.has_setting(x[1]):
			set(x[0], settings.get_setting(x[1]))
		else:
			settings.set_setting(x[1], get(x[0]))
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for x : Variant in hbox:
			if is_instance_valid(x):
				if x.get_parent() == null:
					x.queue_free()
		for x : Variant in buttons:
			if is_instance_valid(x):
				if x.get_parent() == null:
					x.queue_free()

func _on_pressed(btn : Button) -> void:
	if is_instance_valid(_reference):
		for x : int in _reference.tab_count:
			if _reference.get_tab_tooltip(x) == btn.tooltip_text:
				_reference.current_tab = x
				#_reference.tab_clicked.emit(x)
				_reference.tab_clicked.emit(x)
				
func _on_gui_pressed(input : InputEvent, btn : Button) -> void:
	if input.is_pressed():
		if is_instance_valid(_reference):
			for x : int in _reference.tab_count:
				if _reference.get_tab_tooltip(x) == btn.tooltip_text:
					if input is InputEventMouseButton:
						if input.button_index == MOUSE_BUTTON_RIGHT:
							_reference.tab_selected.emit(x)
							_reference.tab_rmb_clicked.emit(x)
							return
						elif input.button_index == MOUSE_BUTTON_MIDDLE:
							_reference.tab_close_pressed.emit(x)
							return
		
func remove_tab(tooltip : String) -> void:
	for x : Control in buttons:
		if x.get_src() == tooltip:
			x.queue_free()
			return

func rename_tab(_tab_name : String, tooltip : String, new_tab_name : String, new_tooltip : String) -> void:
	for x : Button in buttons:
		if x.get_src() == tooltip:
			x.set_src(new_tooltip)
			x.set_text(new_tab_name)
			return
			
func set_select_color(color : Color) -> void:
	_select_color = color.lightened(0.4)
			
func set_ref(tab : TabBar) -> void:
	_reference = tab
	update()
	
func set_enable(e : bool) -> void:
	_enable_update = e
	visible = e
	if e:
		_updating = false
		update()
		return
	for x : Variant in hbox:
		if is_instance_valid(x):
			x.queue_free()
	for x : Variant in buttons:
		if is_instance_valid(x):
			x.queue_free()
	buttons.clear()
	hbox.clear()
	
func _on_pin(btn : Object) -> void:
	if btn:
		if btn.has_method(&"get_src"):
			var value : Variant = btn.call(&"get_src")
			if value is String:
				if value.is_empty():
					return
				var x : int = pins.find(value)
				if x > -1:
					pins.remove_at(x)
				else:
					pins.append(value)
					
				if pins.size() > 30:
					var exist : Dictionary[String, bool] = {}
					for b : Button in buttons:
						exist[b.tooltip_text] = true
					
					for y : int in range(pins.size() - 1, -1, -1):
						if !exist.has(pins[y]):
							pins.remove_at(y)
				_on_rect_change()
				update()
			
func update(fllbck : bool = true) -> void:
	if !_enable_update:
		return
	if _updating:
		return
	_updating = true
	var tab : TabBar = _reference
	if !is_instance_valid(tab):
		set_deferred(&"_updating", false)
		return
		
	for x : int in range(buttons.size() -1, -1, -1):
		var _container : Variant = buttons[x]
		if is_instance_valid(_container):
			continue
		buttons.remove_at(x)
		
	while buttons.size() < tab.tab_count:
		var btn : Control = TAB.instantiate()
		var control : Control = btn.get_button()
		var cls : Button = btn.get_button_close()
		
		if style:
			btn.set(&"theme_override_styles/panel", style)
		if !control.gui_input.is_connected(_on_gui_pressed):
			control.gui_input.connect(_on_gui_pressed.bind(control))
		if !control.pressed.is_connected(_on_pressed):
			control.pressed.connect(_on_pressed.bind(control))
		if !cls.pressed.is_connected(_on_close):
			cls.pressed.connect(_on_close.bind(control))
		if !btn.on_pin.is_connected(_on_pin):
			btn.on_pin.connect(_on_pin)
		buttons.append(btn)
		
	while buttons.size() > tab.tab_count:
		var btn : Variant = buttons.pop_back()
		if is_instance_valid(btn):
			if btn is Node:
				btn.queue_free()
			else:
				btn.free()
				
	if pins.size() > 0:
		var indx : int = 0
		var control : Node = tab.get_parent_control()
		if control:
			for x : int in range(control.get_child_count()):
				if x > -1 and tab.tab_count > x:
					if pins.has(tab.get_tab_tooltip(x)):
						if x != indx:
							if x < control.get_child_count():
								control.move_child(control.get_child(x), indx)
						indx += 1
	
	var alpha_pin : Color = Color.WHITE
	var errors : bool = false
	alpha_pin.a = 0.25
		
	for x : int in range(tab.tab_count):
		var _container : Control = buttons[x]
		var btn : Button = _container.get_button()
		var pin : Button = _container.get_button_pin()
		_container.visible = true
		btn.tooltip_text = tab.get_tab_tooltip(x)
		_container.set_text(tab.get_tab_title(x))
		btn.icon = tab.get_tab_icon(x)
		
		#if fllbck and (btn.tooltip_text.is_empty() or btn.text.begins_with("@VSplitContainer") or btn.text.begins_with("@VBoxContainer")):
			#if btn.text.begins_with("@VSplitContainer") or btn.text.begins_with("@VBoxContainer"):
				#btn.text = "File"
			#errors = true
		
		if pin:
			if pins.has(btn.tooltip_text):
				_container.is_pinned = true
				pin.set(&"theme_override_colors/icon_normal_color",_select_color)
			elif _container.is_pinned:
				_container.is_pinned = false
				pin.set(&"theme_override_colors/icon_normal_color", alpha_pin)
		
		btn.set(&"theme_override_colors/icon_normal_color", Color.GRAY)
		_container.color_rect.visible = false
		_container.modulate.a = 0.85
		
	if tab.current_tab > -1 and tab.current_tab < buttons.size():
		var _container : Control = buttons[tab.current_tab]
		var btn : Button = _container.get_button()
		
		btn.set(&"theme_override_colors/icon_normal_color", _select_color)
		_container.modulate.a = 1.0
		
		var c : ColorRect = _container.color_rect
		c.visible = true
		c.color = _select_color
		
	
		if _behaviour_collapsed < MAX_COLLAPSED:
			var iminor : int = tab.current_tab - _behaviour_collapsed
			var isup : int = tab.current_tab + _behaviour_collapsed
			for x : int in range(tab.tab_count):
				if x < iminor or x > isup:
					var _btn : Control = buttons[x]
					_btn.visible = false
		
	_on_rect_change()
	
	if fllbck and errors:
		Engine.get_main_loop().create_timer(3.0).timeout.connect(update.bind(false))
	
	set_deferred(&"_updating", false)

func _on_close(btn : Button) -> void:
	if is_instance_valid(_reference):
		for x : int in range(0, _reference.tab_count, 1):
			if _reference.get_tab_tooltip(x) == btn.tooltip_text:
				_reference.tab_close_pressed.emit(x)
				break

func _on_gui(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if _behaviour_collapsed < MAX_COLLAPSED:
					_behaviour_collapsed += 1
					update()
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if _behaviour_collapsed > 0:
					_behaviour_collapsed -= 1
					update()
				get_viewport().set_input_as_handled()

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_FILL
	
	item_rect_changed.connect(_on_rect_change)	
	
	if !gui_input.is_connected(_on_gui):
		gui_input.connect(_on_gui)
	
	var bd : Control = EditorInterface.get_base_control()
	if bd:
		style = bd.get_theme_stylebox("panel", "")
		if is_instance_valid(style):
			style = style.duplicate()
			if style is StyleBoxFlat:
				style.border_width_top = 0.0
				style.border_width_left = 0.0
				style.border_width_right = 0.0
				style.border_width_bottom = 0.0
				style.expand_margin_left = 2.0
			style.content_margin_bottom = 0.0
			style.content_margin_top = 0.0
			style.content_margin_left = 0.0
			style.content_margin_right = 0.0
	
	
func _on_rect_change() -> void:
	if !_enable_update:
		return
	_dlt = TIME_WAIT - 0.005
	_try = 0
	set_physics_process(true)
	
func get_reference() -> TabBar:
	return _reference
	
func _physics_process(delta: float) -> void:
	_dlt += delta
	if _dlt < TIME_WAIT:
		return
	_dlt = 0.0
		
	var rsize : Vector2 = get_parent().get_parent().size
	if rsize.x > 10.0:
		for x : Node in container.get_children():
			container.remove_child(x)
			
		for x : Control in buttons:
			var p : Node = x.get_parent()
			if p:
				p.remove_child(x)
			
		var current : HBoxContainer = null
		
		var index : int = 0
		
		var min_size : float = 0.0
		var btn_size : float = 0.0
		for x : Control in buttons:
			var bsize : float = x.get_rect().size.x
			if current == null or (bsize > 0.0 and rsize.x < current.get_minimum_size().x + bsize + 12):
				if hbox.size() > index:
					current = hbox[index]
				else:
					current = HBoxContainer.new()
					current.set(&"theme_override_constants/separation", 4)
					hbox.append(current)
				index += 1
				container.add_child(current)
			current.add_child(x)
			btn_size = maxf(btn_size, x.size.y)
		if current:
			var indx : int = current.get_index() + 1
			min_size = indx * (btn_size) #+ 12.5
		
		if custom_minimum_size.y != min_size:
			_try = 0
			set_physics_process(true)
			custom_minimum_size.y = min_size
			return
	
	_try += 1
	if _try % 5 == 0:
		set_physics_process(false)
