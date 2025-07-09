@tool
extends Button

func _pressed() -> void:
	if owner.has_method(name):
		owner.call(name)
