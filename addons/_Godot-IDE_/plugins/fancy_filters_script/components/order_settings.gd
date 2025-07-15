@tool
extends Control
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	

@export var container : Control = null

func _ready() -> void:
	var p : Node = get_parent()
	if !p.child_entered_tree.is_connected(_on_child):
		p.child_entered_tree.connect(_on_child)

	visibility_changed.connect(_on_visible)
	
func _on_child(n : Node) -> void:
	var p : Node = get_parent()
	if is_instance_valid(p) and !p.is_queued_for_deletion():
		if p.get_child_count() > 0:
			p.move_child.call_deferred(self, p.get_child_count() - 1)

func _on_visible() -> void:
	if visible:
		var packed : PackedScene = ResourceLoader.load("res://addons/_Godot-IDE_/plugins/fancy_filters_script/components/settings.tscn")
		if packed:
			var c : Control = packed.instantiate()
			container.add_child(c)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
	else:
		for x : Node in container.get_children():
			x.queue_free()
