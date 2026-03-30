@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@export var button : Control = null

@export var name_id_button : Button = null
@export var color : ColorRect = null

var _items : Dictionary = {}

func set_tittle(txt : String) -> void:
	if is_instance_valid(name_id_button):
		name_id_button.text = txt
		
func set_color(c : Color) -> void:
	color.color = c
	
func get_color() -> Color:
	return color.color
	
func open() -> void:
	var out : PackedStringArray = PackedStringArray(_items.keys())
	
	for x : int in out.size():
		if out[x].begins_with("uid:"):
			out[x] = ResourceUID.uid_to_path(out[x])
			
	for z : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
		z.create_custom_container(out)
		break
	
func _get_file() -> String:
	return ""
	
func edit() -> void:
	for z : Node in Engine.get_main_loop().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
		var node : Window = ResourceLoader.load((get_script().resource_path).get_base_dir().path_join("./component/edit.tscn")).instantiate()
		node.set_data(get_tittle(), get_color(), get_items())
		z.add_child(node)
		node.popup_centered()
		break

func set_items(data : Dictionary) -> void:
	_items = data
	
func get_tittle() -> String:
	if is_instance_valid(name_id_button):
		return name_id_button.text
	return ""
	
func get_items() -> Dictionary:
	return _items
	
func delete() -> void:
	get_parent().valid_changes()
	queue_free()
	
func _enter_tree() -> void:
	add_to_group(&"__SP_SC_TEMPLATE__")
	
func _exit_tree() -> void:
	remove_from_group(&"__SP_SC_TEMPLATE__")

func _ready() -> void:
	update()
	button.resized.connect(update)
	
	
func valid_changes() -> void:
	get_parent().valid_changes()

func update() -> void:
	
	var b_size : Vector2 = button.get_combined_minimum_size()
	custom_minimum_size = Vector2(b_size.y, b_size.x)
	
	if button.size != b_size:
		button.size = b_size
	
	if abs(button.rotation_degrees) == 90.0:
		if button.rotation_degrees > 0:
			button.position = Vector2(b_size.y, 0)
		else:
			button.position = Vector2(0, b_size.x)
