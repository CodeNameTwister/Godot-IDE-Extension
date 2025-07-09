@tool
extends EditorPlugin

const FANCY_SEARCH : PackedScene = preload("res://addons/_Godot-IDE_/plugins/fancy_search_files/gui/main.tscn")

var pop : Window = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.alt_pressed and event.ctrl_pressed and event.keycode == KEY_SPACE:
			if !is_instance_valid(pop):
				pop = FANCY_SEARCH.instantiate()
				add_child(pop)
			pop.popup_centered()
