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
var _buffer : Dictionary = {}

func execute(value : Variant = null) -> bool:
	var list : BaseList = _manager.get_editor_list()
	if is_instance_valid(value) and value is MickeyTool:
		_update(value, list)
	else:
		var arr : Array[MickeyTool] = _tool_db.get_tools()
		for x : int in range(arr.size() - 1, -1, -1):
			var _tool : Variant = arr[x]
			if !is_instance_valid(_tool):
				arr.remove_at(x)
				continue
			_update(_tool, list)
	
	var dict : Dictionary = {}
	for x : ToolDB.MickeyTool in _tool_db.get_tools():
		if !x.is_valid():
			continue
		var _root : Node = x.get_root_control()
		if dict.has(_root):
			continue
		dict[_root] = true
		if _root.has_method(&"update"):
			_root.call_deferred(&"update")
	return true

func _update(mk : MickeyTool, list : BaseList) -> void:
	if !is_instance_valid(mk) or !mk.is_valid():
		return
	var index : int = mk.get_index()
	if index > -1 and list.item_count() > index:
		var icon : Texture2D = list.get_item_icon(index)
		var modulate : Color = list.get_item_icon_modulate(index)
		if icon and modulate != Color.WHITE and modulate != Color.BLACK:
			var root : Node = mk.get_root()
			var make : bool = true
			if root.has_method(&"set_icon_color"):
				make = root.call(&"set_icon_color", modulate)
			if make:
				if _buffer.has(icon):
					icon = _buffer[icon]
				else:
					var new_icon : Texture2D = mod_image(icon, modulate)
					_buffer[icon] = new_icon
					icon = new_icon
			
		mk.update_metadata(
			list.get_item_text(index), 
			list.get_item_tooltip(index),
			icon
		)
		
func mod_image(icon: Texture2D, modulate_color: Color) -> Texture2D:
	var image : Image = icon.get_image()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	var width : int = image.get_width()
	var height : int = image.get_height()
 
	for x : int in range(width):
		for y : int in range(height):
			var original_color: Color = image.get_pixel(x, y)
			var modulated_color: Color = modulate_color
			if original_color.a > 0.0:
				modulated_color.a = original_color.a
				image.set_pixel(x, y, modulated_color)
	
	return ImageTexture.create_from_image(image)
