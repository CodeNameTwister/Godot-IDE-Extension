@tool
extends Node
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


signal notification(what : int)

func _notification(what: int) -> void:
	notification.emit(what)
		
func panic() -> void:
	if !tree_exiting.is_connected(_on_exiting):
		tree_exiting.connect(_on_exiting)
	
func _on_exiting() -> void:
	notification.emit(NOTIFICATION_PREDELETE)
