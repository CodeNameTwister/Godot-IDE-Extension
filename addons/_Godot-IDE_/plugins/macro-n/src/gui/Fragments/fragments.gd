@tool
extends Window
# =============================================================================	
# Author: Twister
# Godot-IDE Extension
#
# Macro-N
# =============================================================================	


const IGetAllFragments = preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IGetAllFragments.gd")
const IRemoveFragment = preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/IRemoveFragment.gd")
const ISerializerFragments = preload("res://addons/_Godot-IDE_/plugins/macro-n/src/app/in/ISerializerFragments.gd")

const SCRIPT = preload("res://addons/_Godot-IDE_/shared_resources/Script.svg")
const METHOD_OVERRIDE = preload("res://addons/_Godot-IDE_/shared_resources/MethodOverride.svg")
const DOT = preload("res://addons/_Godot-IDE_/shared_resources/dot.svg")

const EDIT = preload("res://addons/_Godot-IDE_/plugins/macro-n/src/gui/Fragments/component/Edit.tscn")

signal on_create()

@export var container : Node = null

var _GetAllFragments : IGetAllFragments = null
var _RemoveFragment : IRemoveFragment = null
var _SerializerFragments : ISerializerFragments = null

func _ready() -> void:
	set_process(false)
	size = IDE.get_screen_size(0.8)
	size.x = maxi(size.x, 300)
	size.y = maxi(size.y, 300)
	about_to_popup.connect(_about_to_popup)
	close_requested.connect(close)
	
	var control : Control = EditorInterface.get_base_control()
	if !control:
		return
	get_child(0). add_theme_stylebox_override(&"panel", control.get_theme_stylebox(&"panel", &""))
	
	
	
func close() -> void:
	queue_free()
	
func _about_to_popup() -> void:
	set_process(false)
	_make_components(container)

func set_dependencies(res : Array[Variant]) -> void:
	for o : Variant in res:
		if o is IGetAllFragments:
			_GetAllFragments = o
		elif o is IRemoveFragment:
			_RemoveFragment = o
		elif o is ISerializerFragments:
			_SerializerFragments = o
	if !is_instance_valid(_RemoveFragment) or !is_instance_valid(_GetAllFragments) or !is_instance_valid(_SerializerFragments):
		push_warning("Not defined all dependencies!")
		
func _make_component(root : Node, data : Dictionary) -> void:
	var shortcut : LineEdit = LineEdit.new()
	var copy_shortcut : Button = Button.new()
	
	
	var description : LineEdit = LineEdit.new()
	var copy_clipboard : Button = Button.new()
	var show_content : Button = Button.new()
	var update_show_content : Button = Button.new()
	var erase_show_content : Button = Button.new()
	
	
	shortcut.text = data["shortcut"]
	description.text = data["description"]
	show_content.text = ""
	update_show_content.text = ""
	erase_show_content.text = ""
	copy_shortcut.text = ""
	copy_clipboard.text = ""
	
	copy_shortcut.disabled = shortcut.text.length() < 1
	copy_shortcut.tooltip_text = "Copy Macro Shorcut Button"
	copy_clipboard.tooltip_text = "Copy Macro Content Button"
	
	show_content.alignment = HORIZONTAL_ALIGNMENT_CENTER
	update_show_content.alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_show_content.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	shortcut.set_meta(&"origin", shortcut.text)
	description.set_meta(&"origin", description.text)
	show_content.set_meta(&"origin", data["content"])
	show_content.set_meta(&"content", data["content"])
	
	shortcut.tooltip_text = shortcut.text
	description.tooltip_text = description.text
	show_content.tooltip_text = show_content.text
	
	shortcut.text_changed.connect(_on_text.bind(shortcut))
	description.text_changed.connect(_on_text.bind(description))
		
	show_content.icon = SCRIPT
	update_show_content.icon = METHOD_OVERRIDE
	erase_show_content.icon = DOT
	copy_clipboard.icon = DOT
	copy_shortcut.icon = DOT
	
	copy_clipboard.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy_shortcut.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_show_content.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	update_show_content.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	show_content.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	copy_shortcut.modulate = Color.GREEN
	copy_clipboard.modulate = Color.SKY_BLUE
	erase_show_content.modulate = Color.RED
	
	copy_shortcut.pressed.connect(_copy.bind(shortcut))
	copy_clipboard.pressed.connect(_copy.bind(show_content))
	show_content.pressed.connect(_on_content.bind(show_content))
	update_show_content.pressed.connect(_on_update.bind(shortcut, description, show_content))
	erase_show_content.pressed.connect(_on_erase.bind(shortcut))
		
	root.add_child(shortcut)
	root.add_child(copy_shortcut)
	root.add_child(description)
	root.add_child(copy_clipboard)
	root.add_child(show_content)
	root.add_child(update_show_content)
	root.add_child(erase_show_content)
	
	shortcut.custom_minimum_size.x = 350.0
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _copy(content : Node) -> void:
	var txt_content : String = ""
	var type : String = ""
	if content is Button:
		if !content.has_meta(&"content"):
			printerr("Not has content!")
			return
			
		type = "Content"
			
		txt_content = content.get_meta(&"content")
		
	elif content is LineEdit:
		
		if content.text.length() == 0:
			printerr("Not has shortcut content!")
			return
			
		type = "Shortcut"
		txt_content = content.text
		
	var copy : bool = false
	var txt : String = ""
			
	if txt_content.length() > 0:
		DisplayServer.clipboard_set(txt_content)
		txt = ("Macro {0} copied to clipboard!".format([type]))
	else:
		txt = ("Error, Macro {0} not copied to clipboard!".format([type]))
		
	var pop : AcceptDialog = AcceptDialog.new()
		
	pop.title = "Macro-N"
	pop.dialog_text = txt.capitalize()

	for x : Node in pop.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	EditorInterface.popup_dialog_centered(pop)

var _edit : Window

func _on_content(content : Node) -> void:
	if content.has_meta(&"content"):
		var txt : String = content.get_meta(&"content")
		
		if !is_instance_valid(_edit):
			_edit = EDIT.instantiate()
			add_child(_edit)
		_edit.set_origin(content)
		_edit.set_code(txt)
		_edit.popup_centered()
	else:
		printerr("Not defined content!! {0}".format([content]))

func _on_update(shortcut : LineEdit, description : LineEdit, show_content : Node) -> void:
	for x : Node in [shortcut, description, show_content]:
		if !x.has_meta(&"origin"):
			printerr("Not defined origin content! {0}".format([x]))
			return
		
	var changes : PackedStringArray = []
	
	if shortcut.text != shortcut.get_meta(&"origin"):
		changes.append("shortcut".capitalize())
	if description.text != description.get_meta(&"origin"):
		changes.append("description".capitalize())
	if show_content.get_meta(&"content") != show_content.get_meta(&"origin"):
		changes.append("macro_content".capitalize())
		
	
	var pop : AcceptDialog = null
	
	if changes.size() == 0:
		pop = AcceptDialog.new()
	else:
		pop = ConfirmationDialog.new()
		pop.confirmed.connect(_on_confirm_update.bind(shortcut, description, show_content))
	
	pop.title = "Macro-N"
		
	pop.dialog_text = "None changes for be update!"
		
	if changes.size() > 0 :
		pop.dialog_text = "Changes to update:\n{0}".format([", ".join(changes)])

	for x : Node in pop.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	EditorInterface.popup_dialog_centered(pop)
		
		
func _on_confirm_update(shortcut : LineEdit, description : LineEdit, show_content : Control) -> void:
	var done : bool = false
	var origin : String = shortcut.get_meta(&"origin")
	if shortcut.text != origin:
		if OK == _RemoveFragment.execute(origin):
			if OK == _SerializerFragments.execute(shortcut.text, description.text, show_content.get_meta(&"content")):
				shortcut.set_meta(&"origin", shortcut.text)
				description.set_meta(&"origin", description.text)
				done = true
			else:
				printerr("Error, can not save!")
	else:
		if OK == _SerializerFragments.execute(shortcut.text, description.text, show_content.get_meta(&"content")):
			shortcut.set_meta(&"origin", shortcut.text)
			description.set_meta(&"origin", description.text)
			done = true
		else:
			printerr("Error, can not save!")
	
	var pop : AcceptDialog = AcceptDialog.new()
	pop.title = "Macro-N"
	
	if done:
		pop.dialog_text = "Macro updated success!"
	else:
		pop.dialog_text = "Error on trying update Macro!"
	
	for x : Node in pop.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	EditorInterface.popup_dialog_centered(pop)
	
	_update()
	
func _update() -> void:
	set_process(true)
	
func _process(delta: float) -> void:
	set_process(false)
	_make_components(container)

func _on_erase(item : LineEdit) -> void:
	var id : String = ""
	if item.has_meta(&"origin"):
		id = item.get_meta(&"origin")
		
	var pop : ConfirmationDialog = ConfirmationDialog.new()
	pop.title = "Macro-N"
	
	if id.is_empty():
		pop.dialog_text = "Are you sure to remove?"
	else:
		pop.dialog_text = "Are you sure to remove?\n[{0}]".format([id])
	
	for x : Node in pop.get_children(true):
		if x is Label:
			x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	pop.confirmed.connect(_on_confirm_erase.bind(item))
	
	EditorInterface.popup_dialog_centered(pop)
	
func _on_confirm_erase(item : LineEdit) -> void:
	var id : String = ""
	if item.has_meta(&"origin"):
		id = item.get_meta(&"origin")
	else:
		id = item.text
	if _RemoveFragment.execute(id) == OK:
		var pop : AcceptDialog = AcceptDialog.new()
		pop.title = "Macro-N"
		
		pop.dialog_text = "Removed Macro Success!"
		
		for x : Node in pop.get_children(true):
			if x is Label:
				x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		EditorInterface.popup_dialog_centered(pop)
		
		_update()
	else:
		var pop : AcceptDialog = AcceptDialog.new()
		pop.title = "Macro-N"
		
		if id.is_empty():
			pop.dialog_text = "Error on trying find Macro for be remove!"
		else:
			pop.dialog_text = "Error on trying remove Macro:\n{0}".format([id])
		
		for x : Node in pop.get_children(true):
			if x is Label:
				x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		EditorInterface.popup_dialog_centered(pop)
		

func _make_tittle_component(root : Node) -> void:
	var shortcut : Label = Label.new()
	var copy_shortcut : Label = Label.new()
	var description : Label = Label.new()
	var show_content : Label = Label.new()
	var copy_content : Label = Label.new()
	var update_show_content : Label = Label.new()
	var erase_show_content : Label = Label.new()
	
	copy_shortcut.text = "Copy Shorcut"
	shortcut.text = "Shortcut"
	description.text = "Description"
	show_content.text = "Show Content"
	update_show_content.text = "Update"
	erase_show_content.text = "Erase"
	copy_content.text = "Copy Content"
	
	for x : Label in [shortcut, copy_shortcut, description, copy_content, show_content, update_show_content, erase_show_content]:
		x.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		root.add_child(x)
	
func _on_text(txt : String, item : Control) -> void:
	item.set(&"tooltip_text", txt)

func _make_components(root : Node) -> void:
	
	if !is_instance_valid(root):
		printerr("Not define container!")
		return
	
	for x : Node in root.get_children():
		x.queue_free()
		
	var objects : Array[Dictionary] = _GetAllFragments.execute()
	if objects.size() < 1:
		var label : Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.text = "You don't have any macros saved yet!"
		root.add_child(label)
		return
		
	_make_tittle_component(root)
	
	for o : Dictionary in objects:
		var val : String = o["shortcut"]
		if val.is_empty():
			continue
		_make_component(root, o)
	
func create() -> void:
	on_create.emit()
	close()	
