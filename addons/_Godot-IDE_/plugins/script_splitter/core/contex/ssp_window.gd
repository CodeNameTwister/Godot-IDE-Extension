@tool
extends EditorContextMenuPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4f
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const PLUS_SPLIT = preload("./../../assets/plus_row.svg")
const MINUS_SPLIT = preload("./../../assets/minus_row.svg")
const SspEditor = preload("./../../core/ui/splitter/editor/ssp_editor.gd")

var _vsplits : Array[VSplitContainer] = []

func _translate(_str : String) -> String:
	# ...
	return _str

func _popup_menu(_paths : PackedStringArray) -> void:
	var sc : ScriptEditor = EditorInterface.get_script_editor()
	
	if !is_instance_valid(sc.get_current_script()):
		return
	
	var ed : ScriptEditorBase = sc.get_current_editor()
	var be : Control = ed.get_base_editor()
	
	
	if be is CodeEdit:
		if !(be.get_parent() is VSplitContainer):
			add_context_menu_item(_translate("Sub-Split"), _on_sub_split, PLUS_SPLIT)
		else:
			add_context_menu_item(_translate("Remove Sub-Split"), _out_sub_split, MINUS_SPLIT)
	
func is_handled(cnt : Node) -> bool:
	return cnt is CodeEdit and cnt.get_parent() is VSplitContainer
		
	
func split() -> void:
	_on_sub_split(null)
	
func merge(value : Node) -> void:
	_out_sub_split(value)
	
func _out_sub_split(value : Variant = null) -> void:
	var be : Control = null
	if value is CodeEdit:
		be = value
	else:
		var sc : ScriptEditor = EditorInterface.get_script_editor()
		var ed : ScriptEditorBase = sc.get_current_editor()
		be= ed.get_base_editor()
	
	
	if be is CodeEdit:
		if !is_handled(be):
			return
			
		var parent : Node = be.get_parent()
		var index : int = be.get_index()
		
		if !is_instance_valid(parent):
			return
		
		if parent.get_child_count() > index + 1:
			var c : Node = parent.get_child(index + 1)
			if c is CodeEdit:
				_on_focus(c, be)
			
			c.queue_free()
			parent.remove_child(c)
		else:
			if index > 0 and parent.get_child_count() > index:
				var c : Node = parent.get_child(index - 1)
				if c is CodeEdit:
					_on_focus(c, be)
				
				c.queue_free()
				parent.remove_child(c)
				
		if parent.get_child_count() == 1:
			var p : Node = parent.get_parent()
			if p:
				for y : Node in parent.get_children():
					if y.is_queued_for_deletion():
						continue
					if y.has_meta(&"RM"):
						continue
					if y is CodeEdit:
						if y.text_changed.is_connected(_on_text_change):
							y.text_changed.disconnect(_on_text_change)
					parent.remove_child(y)
					p.add_child(y)
					if p.get_child_count() > 1:
						p.move_child(y, 0)
			_vsplits.erase(parent)
			parent.queue_free()
			
		for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
			if x.has_method(&"_io_call"):
				x.call(&"_io_call", &"")

func _on_sub_split(__ : Variant = null) -> void:
	var sc : ScriptEditor = EditorInterface.get_script_editor()
	var ed : ScriptEditorBase = sc.get_current_editor()
	var be : Control = ed.get_base_editor()
	
	if be is CodeEdit:
		var parent : Node = be.get_parent()
		if is_handled(be) or !is_instance_valid(parent):
			return
			
		var z : int = 0
		for x : Node in parent.get_children():
			if x is CodeEdit:
				z += 1
		if z < 2:
			var vsplit : VSplitContainer = null
			if be.get_parent() is VSplitContainer:
				vsplit = be.get_parent()
			else:
				vsplit = VSplitContainer.new()
				var p : Node = be.get_parent()
				if p:
					p.remove_child(be)
				
				parent.add_child(vsplit)
				parent.move_child(vsplit, 0)
				vsplit.add_child(be)
				
				vsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				vsplit.size_flags_vertical= Control.SIZE_EXPAND_FILL
				
				_vsplits.append(vsplit)
			
			var ne : CodeEdit = be.duplicate(0)
			
			ne.set_meta(&"RM", true)
			ne.set_script(SspEditor)
			ne.focus_mode = Control.FOCUS_CLICK
			ne.mouse_filter = Control.MOUSE_FILTER_PASS
			
			ne.selecting_enabled = false
			var nodes : Array[Node] = be.get_parent().get_parent().get_parent().find_children("*","MenuButton",true,false)
			
			for n : Node in nodes:
				if n is MenuButton:
					var mp : PopupMenu = n.get_popup()
					if mp and "%" in (n.get_popup().get_item_text(0)):
						if n.draw.is_connected(_on_update):
							n.draw.disconnect(_on_update)
						n.draw.connect(_on_update.bind(be,ne,n))
			
			be.text_changed.connect(_on_text_change.bind(be, ne))
			
			ne.focus_entered.connect(_on_focus.bind(ne, be))
			ne.gui_input.connect(_on_gui.bind(ne, be))
			
			_on_text_change(be, ne)
			vsplit.add_child(ne)

		for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
			if x.has_method(&"_io_call"):
				x.call(&"_io_call", &"")

func _on_gui(e : InputEvent, f : CodeEdit, t : CodeEdit) -> void:
	if t.has_focus():
		if e.is_pressed():
			if e is InputEventMouseButton:
				if e.button_index == MOUSE_BUTTON_LEFT:
					return
			_on_focus(f, t)
	else:
		if e.is_pressed():
			if e is InputEventMouseButton:
				if e.button_index != MOUSE_BUTTON_RIGHT:
					return
				_on_focus(f, t)
	

func _on_update(f : Variant, t : Variant, r : Variant) -> void:
	if is_instance_valid(f) and is_instance_valid(t):
		t.set(&"theme_override_font_sizes/font_size", f.get(&"theme_override_font_sizes/font_size"))
		return
	if is_instance_valid(r):
		if r.draw.is_connected(_on_update):
			r.draw.disconnect(_on_update)

func _on_focus(f : CodeEdit, t : CodeEdit) -> void:
	if !is_instance_valid(f) or !is_instance_valid(t):
		return
	if f.text != t.text:
		var sv : float = f.scroll_vertical
		var sh : int = f.scroll_horizontal
		f.set(&"text", t.text)
		f.scroll_vertical = sv	
		f.scroll_horizontal = sh
	var sv0 : float = f.scroll_vertical
	var sh0 : int = f.scroll_horizontal
	var sv1 : float = t.scroll_vertical
	var sh1 : int = t.scroll_horizontal
	t.scroll_vertical = sv0
	t.scroll_horizontal = sh0
	f.scroll_vertical = sv1
	f.scroll_horizontal = sh1
	var index : int = t.get_index()
	var p : Node = f.get_parent()
	p.remove_child(f)
	p.add_child(f)
	t.grab_focus()
	
	if p.get_child_count() > index or index == -1:
		p.move_child(f, index)
	
func _on_text_change(ca : CodeEdit, cb : CodeEdit) -> void:
	if cb.has_method(&"set_text_reference"):
		cb.call(&"set_text_reference", ca.text)
		return
	var sv : float = cb.scroll_vertical
	var sh : int = cb.scroll_horizontal
	cb.set(&"text", ca.text)
	cb.scroll_vertical = sv	
	cb.scroll_horizontal = sh
	
func _reorder(index : int, cd : CodeEdit, line : int, column : int) -> void:
	if cd.get_caret_count() <= index:
		cd.add_caret(mini(cd.get_line_count(), line), column)
		return
	cd.set_caret_line(mini(cd.get_line_count(), line), false, true, 0, index)
	cd.set_caret_column(column, false, index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for x : Node in _vsplits:
			if !is_instance_valid(x):
				continue
			var p : Node = x.get_parent()
			for y : Node in x.get_children():
				if y.is_queued_for_deletion():
					continue
				if y.has_meta(&"RM"):
					continue
				if y is CodeEdit:
					for cn : Dictionary in y.text_changed.get_connections():
						var callable : Callable = cn["callable"]
						if !callable.is_valid():
							y.text_changed.disconnect(callable)
					
					for n : Node in x.get_parent().get_parent().get_parent().find_children("*","MenuButton",true,false):
						if n is MenuButton:
							var mp : PopupMenu = n.get_popup()
							if mp and "%" in (n.get_popup().get_item_text(0)):
								for cn : Dictionary in n.draw.get_connections():
									var callable : Callable = cn["callable"]
									if !callable.is_valid():
										n.draw.disconnect(callable)
				x.remove_child(y)
				p.add_child(y)
				if p.get_child_count() > 1:
					p.move_child(y, 0)
			x.queue_free()
			
