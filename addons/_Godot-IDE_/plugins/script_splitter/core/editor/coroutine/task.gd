@tool
extends RefCounted
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
var _task : Array[Callable] = []

func has(callable : Callable) -> bool:
	return _task.has(callable)

func add(task : Callable) -> void:
	if task.is_valid():
		_task.append(task)
		
func update() -> void:
	for task : Callable in _task:
		if task.is_valid():
			task.call()
	_task.clear()
