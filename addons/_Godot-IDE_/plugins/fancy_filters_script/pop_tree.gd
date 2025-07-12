@tool
extends Popup
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	


@export var override_copy_button : Button

var callback : Callable

func _ready() -> void:
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return
	get_child(0). add_theme_stylebox_override(&"panel", control.get_theme_stylebox(&"panel", &""))
	

func enable_copy_override(e : bool) -> void:
	override_copy_button.disabled = !e
	
func override_copy() -> void:
	if callback.is_valid():
		callback.call(&"override_copy")
	close()

func copy() -> void:
	if callback.is_valid():
		callback.call(&"copy")
	close()
	
func close() -> void:
	hide()
	queue_free()
	
func goto() -> void:
	if callback.is_valid():
		callback.call(&"goto")


func _on_popup_hide() -> void:
	close()


func _on_close_requested() -> void:
	close()
