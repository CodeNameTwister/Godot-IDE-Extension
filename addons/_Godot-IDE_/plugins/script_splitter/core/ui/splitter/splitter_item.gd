@tool
extends "./../../../core/ui/multi_split_container/split_container_item.gd"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			
var _fms : float = 0.0
			
func _ready() -> void:
	super()
	modulate = Color.DARK_GRAY
	set_physics_process(modulate != Color.WHITE)
	
func _physics_process(delta: float) -> void:
	_fms += delta * 0.24
	if _fms >= 1.0:
		_fms = 1.0
		set_physics_process(false)
	modulate = lerp(modulate, Color.WHITE, _fms)
			
func _enter_tree() -> void:
	super()
	
	add_to_group(&"__SP_IC__")
	var parent : Node = get_parent()
	if parent.has_method(&"expand_splited_container"):
		_on_child(self)
	
func _exit_tree() -> void:
	add_to_group(&"__SP_IC__")
	
func _on_child(n : Node) -> void:
	if n is Control:
		var parent : Node = get_parent()
		if !n.child_entered_tree.is_connected(_on_child):
			n.child_entered_tree.connect(_on_child)
			
		if !n.child_exiting_tree.is_connected(_out_child):
			n.child_exiting_tree.connect(_out_child)
		
		if n.focus_mode != Control.FOCUS_NONE:
			if !n.focus_entered.is_connected(parent.expand_splited_container):
				n.focus_entered.connect(parent.expand_splited_container.bind(self))
				
	for x : Node in n.get_children():
		_on_child(x)

func _out_child(n : Node) -> void:
	if n is Control:
		var parent : Node = get_parent()
		if n.child_entered_tree.is_connected(_on_child):
			n.child_entered_tree.disconnect(_on_child)
			
		if n.child_exiting_tree.is_connected(_out_child):
			n.child_exiting_tree.disconnect(_out_child)
			
		if n.focus_mode != Control.FOCUS_NONE:
			if n.focus_entered.is_connected(parent.expand_splited_container):
				n.focus_entered.disconnect(parent.expand_splited_container)
	for x : Node in n.get_children():
		_out_child(x)
	
