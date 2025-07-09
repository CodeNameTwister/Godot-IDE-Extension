@tool
@icon("icon/MultiSpliterItem.svg")
extends Control
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	https://github.com/CodeNameTwister/Multi-Split-Container
#
#	Multi-Split-Container addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var focus_handler : bool = false

## Expand if tight by spliter
func show_splited_container() -> void:
	var parent : Node = get_parent()
	if parent.has_method(&"expand_splited_container"):
		parent.call(&"expand_splited_container", self)


func _ready() -> void:
	set_process(false)

	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL

	set_deferred(&"anchor_left", 0.0)
	set_deferred(&"anchor_top", 0.0)
	set_deferred(&"anchor_bottom", 1.0)
	set_deferred(&"anchor_right", 1.0)

func _init() -> void:
	name = "SplitContainerItem"

	child_exiting_tree.connect(_on_child_exiting_tree)
	child_entered_tree.connect(_on_child_entered_tree)
	
func _on_visible() -> void:
	var _visible : bool = false
	for x : Node in get_children():
		if x is Control:
			if x.visible:
				_visible = true
				break
	visible = _visible

func _on_child_entered_tree(n : Node) -> void:
	if n is Control:
		n.size = size
		n.set_anchor(SIDE_LEFT, 0.0)
		n.set_anchor(SIDE_RIGHT, 1.0)
		n.set_anchor(SIDE_TOP, 0.0)
		n.set_anchor(SIDE_BOTTOM, 1.0)
		if !n.visibility_changed.is_connected(_on_visible):
			n.visibility_changed.connect(_on_visible)

func _disconnect(n : Node) -> void:
	if n is Control:
		if n.visibility_changed.is_connected(_on_visible):
			n.visibility_changed.disconnect(_on_visible)
	for x : Node in n.get_children():
		_disconnect(x)

func _on_child_exiting_tree(n : Node) -> void:
	_disconnect(n)

func _enter_tree() -> void:
	var c : Node = get_parent()
	if c is Control:
		size = c.size
