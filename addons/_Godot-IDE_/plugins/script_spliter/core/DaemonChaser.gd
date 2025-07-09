@tool
extends Node
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Spliter
#	https://github.com/CodeNameTwister/Script-Spliter
#
#	Script Spliter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
var callback : Callable
var end_callback : Callable
var index : int = 0
var back_to : int = 0
var buffer : Dictionary

func set_current_index(current : int) -> void:
	back_to = current

func run(new_callback : Callable, new_end_callback : Callable) -> void:
	callback = new_callback
	end_callback = new_end_callback
	index = 0
	set_process(true)

func _ready() -> void:
	set_process(false)
	
func _back() -> void:
	if callback.is_valid():
		callback.call(back_to, false)
	
func update_index() -> int:
	index = callback.call(index, true)
	return index
	
func dispose() -> void:
	set_process(false)
	_back()
	if end_callback.is_valid():
		end_callback.call(buffer)
		buffer = {}
	
func _process(__: float) -> void:
	var root : SceneTree = get_tree()
	if !root or !root.root.has_focus():
		dispose()
		return
	elif !callback.is_valid() or 0 > update_index():
		dispose()
		return
	index += 1
