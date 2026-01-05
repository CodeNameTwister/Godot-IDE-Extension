@tool
extends "./../../../core/editor/tools/editor_tool.gd"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _build_tool(control : Node) -> MickeyTool:
	if control is ScriptEditorBase:
		return null
	if control.name.begins_with("@"):
		return null
	
	var mickey : MickeyTool = null
	for x : Node in control.get_children():
		if x is RichTextLabel:
			var canvas : VBoxContainer = VBoxContainer.new()
			canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
			canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
			var childs : Array[Node] = control.get_children()
			for n : Node in childs:
				control.remove_child(n)
				canvas.add_child(n)
					
			canvas.size = control.size
			mickey = MickeyToolRoute.new(control, canvas, canvas)
			break
	return mickey

func _handler(control : Node) -> MickeyTool:
	var mickey : MickeyTool = null
	if control is RichTextLabel:
		var canvas : VBoxContainer = VBoxContainer.new()
		canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		if canvas.get_child_count() < 1:
			var childs : Array[Node] = control.get_children()
			for n : Node in childs:
				control.remove_child(n)
				canvas.add_child(n)
				
		canvas.size = control.size
		mickey = MickeyToolRoute.new(control, canvas, canvas)
	return mickey
