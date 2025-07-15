@tool
extends Control
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	
@export var _type_members : TabContainer
@export var _accessibility : TabContainer

@export var sorty_name_enabled : CheckBox

@export var order_name_check : CheckBox
@export var order_name_button : Button

@export var background_color : Button
@export var use_dots : Button

const NORMAL_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/up.svg")
const INVERT_ICON : Texture2D = preload("res://addons/_Godot-IDE_/shared_resources/down.svg")

signal on_update_order(data : Dictionary)

enum TYPE_ORDER{
	NONE = 0,
	NORMAL = 1,
	INVERT = 2
}

var name_order : TYPE_ORDER = TYPE_ORDER.NORMAL
	
func use_background_color_in_script_info() -> void:
	IDE.set_config("fancy_filters_script", "use_background_color_in_script_info", background_color.button_pressed)
	
func use_dots_as_item_icons() -> void:
	IDE.set_config("fancy_filters_script", "use_dots_as_item_icons", use_dots.button_pressed)
	
func update_settings() -> void:
	var order : Variant = IDE.get_config("fancy_filters_script", "members_order_by")
	var name_type : Variant = IDE.get_config("fancy_filters_script", "name_order_by")
	var background_pressed : Variant = IDE.get_config("fancy_filters_script", "use_background_color_in_script_info")
	var use_dots_pressed: Variant = IDE.get_config("fancy_filters_script", "use_dots_as_item_icons")
	if !(order is Array):
		order = []
	if !(name_type is int):
		name_type = 0
	if !(background_pressed is bool):
		background_pressed = false
	if !(use_dots_pressed is bool):
		use_dots_pressed = false
	use_dots.button_pressed = use_dots_pressed
	background_color.button_pressed = background_pressed
	
	name_order = name_type
	
	order_name_check.button_pressed = name_order != 0
	
	if name_order == TYPE_ORDER.INVERT:
		order_name_button.icon = INVERT_ICON
	else:
		order_name_button.icon = NORMAL_ICON
	
	for x : Node in _type_members.get_children():
		match x.name:
			&"Properties":
				for z : int in range(order.size()):
					if order[z] == 0:
						_type_members.move_child(x, z)
			&"Methods":
				for z : int in range(order.size()):
					if order[z] == 1:
						_type_members.move_child(x, z)
			&"Signals":
				for z : int in range(order.size()):
					if order[z] == 2:
						_type_members.move_child(x, z)
			&"Constant":
				for z : int in range(order.size()):
					if order[z] == 3:
						_type_members.move_child(x, z)
	order_name_button.disabled = !order_name_check.button_pressed

func _ready() -> void:
	update_settings()

func order_name_check_button() -> void:
	order_name_button.disabled = !order_name_check.button_pressed
	if order_name_check.button_pressed == false:
		IDE.set_config("fancy_filters_script", "name_order_by", 0)
	else:
		if order_name_button.icon == INVERT_ICON:
			name_order = TYPE_ORDER.INVERT
		else:
			name_order = TYPE_ORDER.NORMAL
		IDE.set_config("fancy_filters_script", "name_order_by", name_order)

func order_name() -> void:
	if name_order == TYPE_ORDER.NORMAL:
		name_order = TYPE_ORDER.INVERT
		order_name_button.icon = INVERT_ICON
	else:
		name_order = TYPE_ORDER.NORMAL
		order_name_button.icon = NORMAL_ICON
	if order_name_check.button_pressed == false:
		IDE.set_config("fancy_filters_script", "name_order_by", 0)
	else:
		IDE.set_config("fancy_filters_script", "name_order_by", name_order)

func set_settings() -> void:
	var new_order : Array[int] = []
	
	for x : Node in _type_members.get_children():
		match x.name:
			&"Properties":
				new_order.append(0)
			&"Methods":
				new_order.append(1)
			&"Signals":
				new_order.append(2)
			&"Constant":
				new_order.append(3)
		
	IDE.set_config("fancy_filters_script", "members_order_by", new_order)
