@tool
extends "container.gd"
# =============================================================================	
# Author: Twister
# Fancy Filter Script
#
# Addon for Godot
# =============================================================================	


func get_package() -> String:
	return (get_script().resource_path as String).get_base_dir().path_join("tag_viewer.tscn")
