@tool
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

func _ready() -> void:
	set_physics_process(false)
	for n : Node in get_children():
		_c(n)
		
func _physics_process(_delta: float) -> void:
	set_physics_process(false)
	var bsize : Vector2 = get_combined_minimum_size()
	if bsize != size:
		size = bsize
	
func _c(n : Node) -> void:
	if n is Control:
		n.resized.connect(_draw)
	for x : Node in n.get_children():
		_c(x)

func _draw() -> void:
	var bsize : Vector2 = get_combined_minimum_size()
	if bsize != size:
		set_physics_process(true)
