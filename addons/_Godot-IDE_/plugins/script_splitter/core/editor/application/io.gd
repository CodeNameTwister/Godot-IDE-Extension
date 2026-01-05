@tool
extends "./../../../core/editor/app.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const BaseList = preload("./../../../core/base/list.gd")
const EDITOR = preload("./../../../core/ui/window/editor.tscn")

var expanded : bool = false
var _updating : bool = false

func update() -> void:
	if _updating:
		return
	_updating = true
	_update.call_deferred()

func _update() -> void:
	var base : Manager.BaseContainer = _manager.get_base_container()
	var container : Node = base.get_current_container()
	if is_instance_valid(container):
		if expanded:
			var cb : Node = base.get_container_item(container)
			var ct : Array[Node] = container.get_tree().get_nodes_in_group(&"__SP_BR__")
			for x : Node in container.get_tree().get_nodes_in_group(&"__SP_IC__"):
				var v : bool = cb == x
				for y : Node in x.get_children():
					if y is Control:
						y.visible = v
			
			for __ : int in range(0, 2, 1):
				for x : Node in ct:
					if x is Control:
						var v : bool = false
						for y : Node in x.get_children():
							if y is Control and y.visible:
								v = true
								break
						x.visible = v
		
		var can_split : bool = _can_split(container)
		var can_merge_column : bool = _can_merge_column(base)
		var can_merge_row : bool = _can_merge_row(base)
		var can_sub_split : int = _sub()
		var can_make_float : bool = (container.get_parent() is VBoxContainer)
		
		for x : Node in (Engine.get_main_loop()).get_nodes_in_group(&"__script_splitter__IO__"):
			x.enable(&"SPLIT_COLUMN",can_split)
			x.enable(&"MERGE_COLUMN",can_merge_column)
			x.enable(&"SPLIT_ROW",can_split)
			x.enable(&"MERGE_ROW",can_merge_row)
			x.enable(&"SPLIT_SUB", can_sub_split == 0)
			x.enable(&"MERGE_SPLIT_SUB", can_sub_split == 1)
			x.enable(&"MAKE_FLOATING", can_make_float)

	_updating = false
	
func _can_split(container : Node) -> bool:
	return container != null and container.get_child_count() > 1
	
func _can_merge_column(base : Manager.BaseContainer) -> bool:
	return base != null and base.get_current_splitters().size() > 1
	
func _can_merge_row(base : Manager.BaseContainer) -> bool:
	return base != null and base.get_all_containers().size() > 1
	
func _sub() -> int:
	var sc : ScriptEditor = EditorInterface.get_script_editor()
	
	if !is_instance_valid(sc.get_current_script()):
		return -1
		
	var ed : ScriptEditorBase = sc.get_current_editor()
	var be : Control = ed.get_base_editor()
	
	
	if be is CodeEdit:
		if be.get_parent() is VSplitContainer:
			return 1
		return 0
		
	return -1
	
func _on_pin(btn : Button) -> void:
	var st : String = btn.get_meta(&"I")
	if st.is_empty():
		btn.queue_free()
		return
	
	var bl : Manager.BaseList = _manager.get_editor_list()
	for x : int in bl.item_count():
		if st == bl.get_item_tooltip(x):
			bl.select(x)
			return
	
func _make_pin(tree : SceneTree, fn : String, tp : String, icn : Texture2D, mod : Color) -> void:
	if mod == Color.BLACK:
		mod = Color.WHITE
	for x : Node in tree.get_nodes_in_group(&"__SP_PIN_ROOT__"):
		var btn : Button = Button.new()
		btn.text = fn
		btn.icon = icn
		btn.set_meta(&"I", tp)
		btn.pressed.connect(_on_pin.bind(btn))
		btn.add_to_group(&"__SP_B_PIN__")
		btn.set(&"theme_override_colors/icon_normal_color", mod)
		btn.set(&"theme_override_colors/icon_focus_color", mod)
		btn.set(&"theme_override_colors/icon_pressed_color", mod)
		btn.set(&"theme_override_colors/icon_hover_color", mod)
		btn.set(&"theme_override_colors/icon_hover_pressed_color", mod)
		btn.set(&"theme_override_colors/icon_disabled_color", mod)
		btn.set(&"theme_override_font_sizes/font_size", 12.0)
		x.add_child(btn)

func _remove_pin(tree : SceneTree, tp : String) -> bool:
	for x : Node in tree.get_nodes_in_group(&"__SP_PIN_ROOT__"):
		if x.has_meta(&"I"):
			if x.get_meta(&"I") == tp:
				x.queue_free()
				return true
	return false

func execute(value : Variant = null) -> bool:
	if value == null:
		update()
		return true
		
	if value is StringName:
		if value.is_empty():
			update()
			return true
		
		var base : Manager.BaseContainer = _manager.get_base_container()
		var container : Node = base.get_current_container()
					
		var id : StringName = value
		
		match id:
			&"EXPAND":
				if is_instance_valid(container):
					var ct : Array[Node] = container.get_tree().get_nodes_in_group(&"__SP_BR__")
					if expanded:
						for x : Node in container.get_tree().get_nodes_in_group(&"__SP_IC__"):
							for y : Node in x.get_children():
								if y is Control:
									y.visible = true
						for x : Node in ct:
							if x is Control:
								x.visible = true
					else:			
						var cb : Node = base.get_container_item(container)
						for x : Node in container.get_tree().get_nodes_in_group(&"__SP_IC__"):
							var v : bool = cb == x
							for y : Node in x.get_children():
								if y is Control:
									y.visible = v
						
						for __ : int in range(0, 2, 1):
							for x : Node in ct:
								if x is Control:
									var v : bool = false
									for y : Node in x.get_children():
										if y is Control and y.visible:
											v = true
											break
									x.visible = v
						
					expanded = !expanded
				
					for x : Node in container.get_tree().get_nodes_in_group(&"__script_splitter__IO__"):
						if x.has_method(&"get_button"):
							var button : Button = x.call(&"get_button", id)
							if is_instance_valid(button):
								if expanded:
									button.modulate = Color.GREEN
								else:
									button.modulate = Color.WHITE
		
					return true
			&"PIN":
				for x : MickeyTool in _tool_db.get_tools():
					if x.get_root() == container:
						if container is TabContainer:
							if container.current_tab == x.get_control().get_index():
								var list : Manager.BaseList = _manager.get_editor_list()
								var idx : int = x.get_index()
								
								if list.item_count() > idx and idx > -1:
									var nm : String = list.get_item_text(idx)
									var ps : String = list.get_item_tooltip(idx)
									
									if _remove_pin(container.get_tree(), ps):
										return true
										
									_make_pin(container.get_tree(), nm, ps, list.get_item_icon(idx), list.get_item_icon_modulate(idx))
			&"SPLIT_COLUMN":
				if _can_split(container):
					_manager.split_column.execute()
			&"SPLIT_ROW":
				if _can_split(container):
					_manager.split_row.execute()
			&"MERGE_COLUMN":
				if _can_merge_column(base):
					_manager.merge_tool.execute([null, false])
			&"MERGE_ROW":
				if _can_merge_row(base):
					_manager.merge_tool.execute([null, true])
			&"SPLIT_SUB":
				if _sub() == 0:
					for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
						x.script_split()
						break
			&"MERGE_SPLIT_SUB":
				if _sub() == 1:
					for x : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
						x.script_merge()
						break
			&"MAKE_FLOATING":
				if (container.get_parent() is VBoxContainer):
					for x : ToolDB.MickeyTool in _tool_db.get_tools():
						if x.has(container):
							var y : Node = (_manager._base_container._editor_container.get_parent())
							var new_window : Window = EDITOR.instantiate()
							y.add_child(new_window)
							
							var root : Node = new_window.call(&"get_root")
							root.initialize(null, _manager.get_base_container())
							root.initialize_editor_contianer()
							
							var _root : Node = x.get_root()
							
							x.ochorus(root.call(&"get_current_editor"))
							
							if _root.get_child_count() < 1:
								var item : Node = _manager.get_base_container().get_container_item(_root)	
								if item.get_child_count() == 1:
									var cont : Node = _manager.get_base_container().get_container(_root)
									if cont.get_child_count() == 1:
										cont.queue_free()
									else:
										item.queue_free()
								else:
									if _root.get_parent() is VBoxContainer:
										_root.get_parent().queue_free()
									else:
										_root.queue_free()
								
							new_window.setup()
							new_window.update()
							_manager.update()
							return false
	return false
