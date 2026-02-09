@tool
extends "./../../../core/editor/tools/editor_tool.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
		
func _use_expand() -> bool:
	var settings : EditorSettings = EditorInterface.get_editor_settings()
	var setting : String = "plugin/script_splitter/editor/document_helper_unwrapped"
	if settings:
		if settings.has_setting(setting):
			var variant : Variant = settings.get_setting(setting)
			if variant is bool:
				return variant
		settings.set_setting(setting, false)
	return false
				
func _build_tool(control : Node) -> MickeyTool:
	if control is ScriptEditorBase:
		return null
	if control.name.begins_with("@"):
		return null
		
	var expanded : bool = _use_expand()
	
	var mickey : MickeyTool = null
	for x : Node in control.get_children():
		if x is RichTextLabel:
			var canvas : VBoxContainer = VBoxContainer.new()
			var childs : Array[Node] = control.get_children()
			
			canvas.size = control.size
			canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
			canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			for n : Node in childs:
				control.remove_child(n)
				
				if n is RichTextLabel and expanded:
					n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					n.size_flags_vertical = Control.SIZE_EXPAND_FILL
					n.autowrap_mode = TextServer.AUTOWRAP_OFF
					n.custom_minimum_size.x = maxf(1000.0, DisplayServer.screen_get_size().x) * maxf(EditorInterface.get_editor_scale(), 1.0)
					n.size = canvas.size
				
					var c : ScrollContainer = ScrollContainer.new()
					canvas.add_child(c)
					c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					c.size_flags_vertical = Control.SIZE_EXPAND_FILL
					c.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
					c.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
					
					c.add_child(n)
					_on_load.call_deferred(c)
					continue
					
				canvas.add_child(n)
					
			mickey = MickeyToolRoute.new(control, canvas, canvas)
			break
	return mickey
	
func _on_load(sc : ScrollContainer) -> void:
	var bar : HScrollBar = sc.get_h_scroll_bar()
	for __ : int in range(50):
		await Engine.get_main_loop().process_frame
		if !is_instance_valid(bar):
			return
		if bar.max_value > 10.0:
			break
	if sc.scroll_horizontal < 1.0:
		sc.scroll_horizontal = int((bar.max_value - bar.page) * 0.25)

func _handler(control : Node) -> MickeyTool:
	var mickey : MickeyTool = null
	if control is RichTextLabel:
		var canvas : VBoxContainer = VBoxContainer.new()
		var expanded : bool = _use_expand()
		
		canvas.size = control.size
		canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		canvas.size = control.size
		
		if canvas.get_child_count() < 1:
			var childs : Array[Node] = control.get_children()
			
			for n : Node in childs:
				control.remove_child(n)
				
				if n is RichTextLabel and expanded:
					n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					n.size_flags_vertical = Control.SIZE_EXPAND_FILL
					n.autowrap_mode = TextServer.AUTOWRAP_OFF
					n.custom_minimum_size.x = maxf(1000.0, DisplayServer.screen_get_size().x) * maxf(EditorInterface.get_editor_scale(), 1.0)
					n.size = canvas.size
				
					var c : ScrollContainer = ScrollContainer.new()
					canvas.add_child(c)
					c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					c.size_flags_vertical = Control.SIZE_EXPAND_FILL
					c.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
					c.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
					
					c.add_child(n)
					_on_load.call_deferred(c)
					continue
					
				canvas.add_child(n)
				
		mickey = MickeyToolRoute.new(control, canvas, canvas)
	return mickey
