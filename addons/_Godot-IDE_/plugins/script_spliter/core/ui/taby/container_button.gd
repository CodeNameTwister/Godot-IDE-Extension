@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

signal on_pin(button : Object)

@export var color_rect : ColorRect
@export var button_main : Button
@export var button_close : Button
@export var button_pin : Button

var is_pinned : bool = false

func _ready() -> void:
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	_on_exit()
	
func _on_enter() -> void:
	if !is_pinned:
		button_pin.set(&"theme_override_colors/icon_normal_color", Color.WHITE)
	button_close.set(&"theme_override_colors/font_color", Color.WHITE)
	

func _on_exit() -> void:
	var c : Color = Color.WHITE
	c.a = 0.25
	button_close.set(&"theme_override_colors/font_color", c)
	if !is_pinned:
		button_pin.set(&"theme_override_colors/icon_normal_color", c)
	

func get_button_pin() -> Button:
	return button_pin

func _on_pin_pressed() -> void:
	on_pin.emit(self)

func set_close_visible(e : bool) -> void:
	button_close.visible = e 

func set_src(src : String) -> void:
	button_main.tooltip_text = src
	
func get_src() -> String:
	return button_main.tooltip_text

func set_text(txt : String) -> void:
	button_main.text = txt

func get_button() -> Button:
	return button_main

func get_button_close() -> Button:
	return button_close
