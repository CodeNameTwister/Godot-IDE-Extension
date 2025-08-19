@tool
extends EditorPlugin
# =============================================================================	
# Author: GodotIDE Team
# Symbol Navigator
#
# Find references and rename symbols across the project
# =============================================================================	

const FIND_REFERENCES_PANEL_UI = preload("res://addons/_Godot-IDE_/plugins/symbol_navigator/gui/find_references_panel.tscn")
const RENAME_SYMBOL_UI = preload("res://addons/_Godot-IDE_/plugins/symbol_navigator/gui/rename_dialog.tscn")

var _find_references_panel : Control = null
var _find_references_panel_button : Button = null
var _rename_dialog : Window = null

# Input shortcuts
var _find_references_input : InputEventKey = null
var _rename_symbol_input : InputEventKey = null

# Menu items
var _context_menu_plugin : EditorPlugin = null

func _init() -> void:
	# Initialize shortcuts
	_setup_shortcuts()

func _setup_shortcuts() -> void:
	# Find references shortcut (Shift+F12)
	var find_input : Variant = IDE.get_config("symbol_navigator", "find_references_input")
	if find_input is InputEventKey:
		_find_references_input = find_input
	else:
		_find_references_input = InputEventKey.new()
		_find_references_input.pressed = true
		_find_references_input.shift_pressed = true
		_find_references_input.keycode = KEY_F12
		IDE.set_config("symbol_navigator", "find_references_input", _find_references_input)

	# Rename symbol shortcut (F2)
	var rename_input : Variant = IDE.get_config("symbol_navigator", "rename_symbol_input")
	if rename_input is InputEventKey:
		_rename_symbol_input = rename_input
	else:
		_rename_symbol_input = InputEventKey.new()
		_rename_symbol_input.pressed = true
		_rename_symbol_input.keycode = KEY_F2
		IDE.set_config("symbol_navigator", "rename_symbol_input", _rename_symbol_input)

func _enter_tree() -> void:
	# Plugin is activated
	if IDE.debug:
		print("[Symbol Navigator] Plugin activated")
	
	# Set up bottom panel for find references
	_setup_bottom_panel()

func _exit_tree() -> void:
	# Clean up bottom panel
	if is_instance_valid(_find_references_panel):
		remove_control_from_bottom_panel(_find_references_panel)
		_find_references_panel.queue_free()
		_find_references_panel = null
		_find_references_panel_button = null
	
	# Clean up rename dialog
	if is_instance_valid(_rename_dialog):
		_rename_dialog.queue_free()
		_rename_dialog = null
	
	if IDE.debug:
		print("[Symbol Navigator] Plugin deactivated")

func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
		
	# Handle find references shortcut
	if event.is_match(_find_references_input):
		_open_find_references()
		
	# Handle rename symbol shortcut  
	elif event.is_match(_rename_symbol_input):
		_open_rename_dialog()

func _open_find_references() -> void:
	var current_symbol = _get_symbol_at_cursor()
	if current_symbol.is_empty():
		push_warning("[Symbol Navigator] No symbol found at cursor")
		return
	
	# Ensure the bottom panel is set up
	if not is_instance_valid(_find_references_panel):
		_setup_bottom_panel()
	
	if is_instance_valid(_find_references_panel):
		# Make the bottom panel visible first
		make_bottom_panel_item_visible(_find_references_panel)
		
		# Try to call search_symbol with error handling
		if _find_references_panel.has_method("search_symbol"):
			_find_references_panel.search_symbol(current_symbol)
			if _find_references_panel.has_method("show_and_focus"):
				_find_references_panel.show_and_focus()
		else:
			push_warning("[Symbol Navigator] Panel search_symbol method not available, using fallback...")
			# Just show the panel even if we can't search
			if _find_references_panel.has_method("show_and_focus"):
				_find_references_panel.show_and_focus()
	else:
		push_error("[Symbol Navigator] Failed to create or access find references panel")

func _open_rename_dialog() -> void:
	var current_symbol = _get_symbol_at_cursor()
	if current_symbol.is_empty():
		push_warning("[Symbol Navigator] No symbol found at cursor")
		return
		
	print("[Symbol Navigator] Opening rename dialog for symbol: ", current_symbol)
		
	if not is_instance_valid(_rename_dialog):
		print("[Symbol Navigator] Creating new rename dialog instance")
		_rename_dialog = RENAME_SYMBOL_UI.instantiate()
		add_child(_rename_dialog)
		
		# Wait for the dialog to be ready before calling methods on it
		if not _rename_dialog.is_node_ready():
			print("[Symbol Navigator] Dialog not ready, waiting for ready signal")
			await _rename_dialog.ready
		
		print("[Symbol Navigator] Dialog ready, setting symbol")
	
	_rename_dialog.set_symbol(current_symbol)
	_rename_dialog.popup_with_saved_state()

# Get symbol at current cursor position
func _get_symbol_at_cursor() -> String:
	var script_editor : ScriptEditor = EditorInterface.get_script_editor()
	if not script_editor:
		return ""
		
	var current_editor = script_editor.get_current_editor()
	if not current_editor:
		return ""
		
	var code_edit : CodeEdit = current_editor.get_base_editor()
	if not code_edit:
		return ""
		
	var caret_line = code_edit.get_caret_line()
	var caret_column = code_edit.get_caret_column()
	var line_text = code_edit.get_line(caret_line)
	
	# Extract word at cursor position
	return _extract_word_at_position(line_text, caret_column)

# Extract word at specific column position in text
func _extract_word_at_position(text: String, column: int) -> String:
	if text.is_empty() or column < 0 or column >= text.length():
		return ""
	
	# Word boundary characters
	var word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	
	# Find start of word
	var start = column
	while start > 0 and word_chars.contains(text[start - 1]):
		start -= 1
	
	# Find end of word
	var end = column
	while end < text.length() and word_chars.contains(text[end]):
		end += 1
	
	if start == end:
		return ""
	
	return text.substr(start, end - start)

func _setup_bottom_panel() -> void:
	"""Set up the find references bottom panel"""
	if is_instance_valid(_find_references_panel):
		return  # Already set up
	
	# Create the panel instance
	_find_references_panel = FIND_REFERENCES_PANEL_UI.instantiate()
	
	if not _find_references_panel:
		push_error("[Symbol Navigator] Failed to instantiate find references panel")
		return
	
	# Simple validation - just check if it's a Control
	if not _find_references_panel is Control:
		push_error("[Symbol Navigator] Panel is not a Control node")
		_find_references_panel.queue_free()
		_find_references_panel = null
		return
	
	# Add it to the bottom panel with a tab
	_find_references_panel_button = add_control_to_bottom_panel(_find_references_panel, "Find References")
	
	if IDE.debug:
		print("[Symbol Navigator] Bottom panel 'Find References' added successfully")
