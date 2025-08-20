@tool
extends Control
# =============================================================================
# Symbol Navigator - Find References Panel
# Author: kyros
# Bottom panel UI for displaying symbol references with navigation and code preview
# =============================================================================	

@export var search_bar : LineEdit = null
@export var results_tree : Tree = null
@export var status_label : Label = null
@export var search_button : Button = null
@export var clear_button : Button = null
@export var code_header : Label = null
@export var code_display : RichTextLabel = null
@export var case_sensitive_check : CheckBox = null
@export var match_mode_option : OptionButton = null
@export var exclude_dirs_button : Button = null

enum MatchMode {
	WORD_BOUNDARY,    # Word boundary matching (default)
	EXACT,           # Hole line exact match
	STARTS_WITH,     # Start matching
	CONTAINS,        # Include match
	ENDS_WITH        # end match
}

var _current_symbol : String = ""
var _search_results : Array[Dictionary] = []
var _case_sensitive : bool = false
var _match_mode : MatchMode = MatchMode.WORD_BOUNDARY
var _excluded_directories : Array[String] = []

func _ready() -> void:
	# Initialize components and connections
	_ensure_components_initialized()
	
	# Apply editor theme for integration
	var editor_control : Control = EditorInterface.get_base_control()
	if editor_control:
		var theme = editor_control.get_theme()
		if theme:
			set_theme(theme)
	
	# Connect UI signals
	if search_button:
		search_button.pressed.connect(_on_search_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	if search_bar:
		search_bar.text_submitted.connect(_on_search_submitted)
		search_bar.text_changed.connect(_on_search_text_changed)
	if results_tree:
		results_tree.item_activated.connect(_on_item_activated)
		results_tree.item_selected.connect(_on_item_selected)
	if case_sensitive_check:
		case_sensitive_check.toggled.connect(_on_case_sensitive_toggled)
	if match_mode_option:
		match_mode_option.item_selected.connect(_on_match_mode_changed)
		_setup_match_mode_options()
	if exclude_dirs_button:
		exclude_dirs_button.pressed.connect(_on_exclude_dirs_pressed)
	
	# Configure tree columns
	if results_tree:
		results_tree.set_column_titles_visible(true)
		results_tree.set_column_title(0, "File / Reference")
		results_tree.set_column_title(1, "Line")
		results_tree.columns = 2
		results_tree.set_column_expand_ratio(0, 3.0)
		results_tree.set_column_expand_ratio(1, 1.0)
	
	# Initialize UI state
	_update_results_info("Enter a symbol to search")
	_clear_code_display()
	
	# Load saved configuration
	_load_configuration()

func _load_configuration() -> void:
	"""Load saved configuration settings"""
	# Load case sensitivity setting
	var saved_case_sensitive = IDE.get_config("symbol_navigator", "case_sensitive") #if not exist config, return a null
	if saved_case_sensitive is bool:
		_case_sensitive = saved_case_sensitive
	if case_sensitive_check:
		case_sensitive_check.set_pressed_no_signal(_case_sensitive)
	
	# Load match mode setting
	var saved_match_mode = IDE.get_config("symbol_navigator", "match_mode")
	if null != saved_match_mode:
		_match_mode = saved_match_mode as MatchMode
		if match_mode_option:
			match_mode_option.select(saved_match_mode)
	
	# Load excluded directories
	var saved_excluded_dirs = IDE.get_config("symbol_navigator", "excluded_directories")
	if null != saved_excluded_dirs:
		_excluded_directories = saved_excluded_dirs

func _ensure_components_initialized() -> void:
	"""Ensure all exported components are properly initialized"""
	if not search_bar:
		search_bar = _find_component_robust("SearchBar", LineEdit)
	if not results_tree:
		results_tree = _find_component_robust("ResultsTree", Tree)
	if not status_label:
		status_label = _find_component_robust("StatusLabel", Label)
	if not search_button:
		search_button = _find_component_robust("SearchButton", Button)
	if not clear_button:
		clear_button = _find_component_robust("ClearButton", Button)
	if not code_header:
		code_header = _find_component_robust("CodeHeader", Label)
	if not code_display:
		code_display = _find_component_robust("CodeDisplay", TextEdit)
	if not case_sensitive_check:
		case_sensitive_check = _find_component_robust("CaseSensitiveCheck", CheckBox)
	if not match_mode_option:
		match_mode_option = _find_component_robust("MatchModeOption", OptionButton)
	if not exclude_dirs_button:
		exclude_dirs_button = _find_component_robust("ExcludeDirsButton", Button)
	
	# Only log if critical components are missing
	var missing_components = []
	if not search_bar: missing_components.append("search_bar")
	if not results_tree: missing_components.append("results_tree")
	if not status_label: missing_components.append("status_label")
	
	if not missing_components.is_empty():
		print("Error: Missing critical components: %s" % ", ".join(missing_components))


func _find_component_robust(component_name: String, component_type) -> Node:
	"""Robust component finder using multiple strategies"""
	var found_component: Node = null
	
	# Strategy 1: Direct NodePath lookup
	var expected_paths = _get_expected_paths(component_name)
	for path in expected_paths:
		found_component = get_node_or_null(path)
		if found_component and _is_correct_type(found_component, component_type):
			return found_component
	
	# Strategy 2: find_child() search
	found_component = find_child(component_name, true, false)
	if found_component and _is_correct_type(found_component, component_type):
		return found_component
	
	# Strategy 3: Recursive search by type and name
	found_component = _recursive_find_by_type_and_name(self, component_type, component_name)
	if found_component:
		return found_component
	
	# Strategy 4: Recursive search by type only (first match)
	found_component = _recursive_find_by_type(self, component_type)
	if found_component:
		return found_component
	
	# Strategy 5: Partial name matching
	found_component = _recursive_find_by_partial_name(self, component_name.to_lower())
	if found_component and _is_correct_type(found_component, component_type):
		return found_component
	
	return null

func _is_correct_type(node: Node, expected_type) -> bool:
	"""Check if a node is of the expected type"""
	# Use multiple type checking methods for robustness
	if expected_type == LineEdit:
		return node is LineEdit
	elif expected_type == Tree:
		return node is Tree
	elif expected_type == Label:
		return node is Label
	elif expected_type == Button:
		return node is Button
	elif expected_type == TextEdit:
		return node is TextEdit
	elif expected_type == CheckBox:
		return node is CheckBox
	elif expected_type == OptionButton:
		return node is OptionButton
	elif expected_type == RichTextLabel:
		return node is RichTextLabel
	else:
		# Fallback to class name comparison
		return node.get_class() == str(expected_type).get_slice(":", 0)

func _get_expected_paths(component_name: String) -> Array[String]:
	"""Get all possible paths for a component"""
	var paths: Array[String] = []
	
	# Add the standard expected paths
	match component_name:
		"SearchBar":
			paths.append("MainContainer/SearchSection/SearchBar")
		"ResultsTree":
			paths.append("MainContainer/MainContent/LeftPanel/ResultsTree")
		"StatusLabel":
			paths.append("MainContainer/StatusSection/StatusLabel")
		"SearchButton":
			paths.append("MainContainer/SearchSection/SearchButton")
		"ClearButton":
			paths.append("MainContainer/StatusSection/ClearButton")
		"CodeHeader":
			paths.append("MainContainer/MainContent/RightPanel/CodeHeader")
		"CodeDisplay":
			paths.append("MainContainer/MainContent/RightPanel/CodeDisplay")
		"CaseSensitiveCheck":
			paths.append("MainContainer/SearchSection/CaseSensitiveCheck")
		"MatchModeOption":
			paths.append("MainContainer/SearchSection/MatchModeOption")
		"ExcludeDirsButton":
			paths.append("MainContainer/SearchSection/ExcludeDirsButton")
	
	return paths

func _recursive_find_by_type_and_name(node: Node, target_type, target_name: String) -> Node:
	"""Recursively search for a node of the specified type and name"""
	if _is_correct_type(node, target_type) and target_name.to_lower() in node.name.to_lower():
		return node
	
	for child in node.get_children():
		var result = _recursive_find_by_type_and_name(child, target_type, target_name)
		if result:
			return result
	
	return null

func _recursive_find_by_type(node: Node, target_type) -> Node:
	"""Recursively search for a node of the specified type"""
	if _is_correct_type(node, target_type):
		return node
	
	for child in node.get_children():
		var result = _recursive_find_by_type(child, target_type)
		if result:
			return result
	
	return null

func _recursive_find_by_partial_name(node: Node, partial_name: String) -> Node:
	"""Recursively search for a node with a name containing the partial string"""
	if partial_name in node.name.to_lower():
		return node
	
	for child in node.get_children():
		var result = _recursive_find_by_partial_name(child, partial_name)
		if result:
			return result
	
	return null

func search_symbol(symbol: String) -> void:
	"""Start a search for the given symbol and display results"""
	_current_symbol = symbol
	if search_bar:
		search_bar.text = symbol
	
	# Ensure components are ready before search
	_ensure_components_initialized()
	
	_perform_search()

func _on_search_pressed() -> void:
	if search_bar:
		_current_symbol = search_bar.text.strip_edges()
	_perform_search()

func _on_search_submitted(text: String) -> void:
	_current_symbol = text.strip_edges()
	_perform_search()

func _on_search_text_changed(text: String) -> void:
	# Enable/disable search button based on input
	if search_button:
		search_button.disabled = text.strip_edges().is_empty()

func _on_clear_pressed() -> void:
	_clear_results()
	if search_bar:
		search_bar.clear()
		search_bar.grab_focus()
	_update_status("Cleared")
	_update_results_info("Enter a symbol to search")

func _on_case_sensitive_toggled(pressed: bool) -> void:
	_case_sensitive = pressed
	# Save setting
	IDE.set_config("symbol_navigator", "case_sensitive", _case_sensitive)
	# Automatically re-search if we have a current symbol
	if not _current_symbol.is_empty():
		_perform_search()

func _on_match_mode_changed(index: int) -> void:
	_match_mode = index as MatchMode
	# Save setting
	IDE.set_config("symbol_navigator", "match_mode", _match_mode)
	# Automatically re-search if we have a current symbol
	if not _current_symbol.is_empty():
		_perform_search()

func _setup_match_mode_options() -> void:
	if not match_mode_option:
		return
	
	match_mode_option.clear()
	match_mode_option.add_item("Word Boundary")
	match_mode_option.add_item("Exact Match")
	match_mode_option.add_item("Starts With")
	match_mode_option.add_item("Contains")
	match_mode_option.add_item("Ends With")
	match_mode_option.selected = _match_mode

func _on_exclude_dirs_pressed() -> void:
	"""Show dialog to configure excluded directories"""
	_show_exclude_dirs_dialog()

func _show_exclude_dirs_dialog() -> void:
	"""Show a simple dialog to configure excluded directories"""
	var dialog = AcceptDialog.new()
	dialog.title = "Configure Excluded Directories"
	dialog.size = Vector2i(400, 300)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var info_label = Label.new()
	info_label.text = "Enter directory names to exclude from search (one per line):"
	vbox.add_child(info_label)
	
	var text_edit = TextEdit.new()
	text_edit.text = "\n".join(_excluded_directories)
	text_edit.custom_minimum_size = Vector2(380, 200)
	vbox.add_child(text_edit)
	
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	var save_button = Button.new()
	save_button.text = "Save"
	button_container.add_child(save_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	button_container.add_child(cancel_button)
	
	# Add dialog to scene tree
	get_tree().current_scene.add_child(dialog)
	
	# Connect signals
	save_button.pressed.connect(func():
		_save_excluded_directories(text_edit.text)
		dialog.queue_free()
	)
	cancel_button.pressed.connect(func():
		dialog.queue_free()
	)
	
	dialog.popup_centered()

func _save_excluded_directories(text: String) -> void:
	"""Save excluded directories from text input"""
	_excluded_directories.clear()
	var lines = text.split("\n")
	for line in lines:
		var trimmed = line.strip_edges()
		if not trimmed.is_empty():
			_excluded_directories.append(trimmed)
	
	# Save to configuration
	IDE.set_config("symbol_navigator", "excluded_directories", _excluded_directories)
	
	# Update status
	_update_status("Updated excluded directories")
	
	# Re-search if we have a current symbol
	if not _current_symbol.is_empty():
		_perform_search()

func _perform_search() -> void:
	if _current_symbol.is_empty():
		_update_status("Please enter a symbol to search")
		return
	
	_update_status("Searching for references...")
	_clear_results()
	
	# Perform the actual search
	_search_in_project()
	
	# Update UI and show results
	_display_results()
	var result_count = _search_results.size()
	if result_count > 0:
		# Log successful search
		print("Found %d references to '%s'" % [result_count, _current_symbol])
		_update_status("Found %d references to '%s'" % [result_count, _current_symbol])
	else:
		_update_status("No references found for '%s'" % _current_symbol)

func _clear_results() -> void:
	_search_results.clear()
	if results_tree:
		results_tree.clear()
	_clear_code_display()
	_update_results_info("0 references found")

func _search_in_project() -> void:
	var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if not fs:
		return
	
	var root_dir = fs.get_filesystem()
	if root_dir:
		_search_in_directory(root_dir)

func _search_in_directory(dir: EditorFileSystemDirectory) -> void:
	# Check if this directory should be excluded
	var dir_name = dir.get_name()
	if _should_exclude_directory(dir_name):
		return
	
	# Search in files
	for i in range(dir.get_file_count()):
		var file_path = dir.get_file_path(i)
		var file_type = dir.get_file_type(i)
		
		# Only search in script files
		if file_type == "GDScript" or file_path.ends_with(".gd"):
			_search_in_file(file_path)
	
	# Search in subdirectories
	for i in range(dir.get_subdir_count()):
		_search_in_directory(dir.get_subdir(i))

func _should_exclude_directory(dir_name: String) -> bool:
	"""Check if a directory should be excluded from search"""
	for excluded_dir in _excluded_directories:
		if dir_name == excluded_dir or dir_name.begins_with(excluded_dir + "/"):
			return true
	return false

func _search_in_file(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Error: Cannot access file %s" % file_path.get_file())
		return
	
	var line_number = 1
	while not file.eof_reached():
		var line = file.get_line()
		var matches = _find_symbol_in_line(line, _current_symbol)
		
		for match_pos in matches:
			var result = {
				"file_path": file_path,
				"line_number": line_number,
				"line_content": line.strip_edges(),
				"column": match_pos
			}
			_search_results.append(result)
		
		line_number += 1
	
	file.close()

func _find_symbol_in_line(line: String, symbol: String) -> Array[int]:
	var matches: Array[int] = []
	
	# Skip lines that are likely false positives
	var trimmed_line = line.strip_edges()
	
	# Skip comments (but allow commented code for reference)
	if trimmed_line.begins_with("#") and not trimmed_line.contains("func "):
		return matches
	
	# Skip string literals (basic detection) - only for word boundary mode
	if _match_mode == MatchMode.WORD_BOUNDARY and _is_in_string_literal(line, symbol):
		return matches
	
	# Apply case sensitivity
	var search_line = line if _case_sensitive else line.to_lower()
	var search_symbol = symbol if _case_sensitive else symbol.to_lower()
	
	# Create regex pattern based on match mode
	var regex = RegEx.new()
	var pattern = _get_match_pattern(search_symbol)
	if regex.compile(pattern) != OK:
		return matches
	
	var results = regex.search_all(search_line)
	for result in results:
		var match_pos = result.get_start()
		
		# Additional context-aware filtering (only for word boundary mode)
		if _match_mode == MatchMode.WORD_BOUNDARY:
			if _is_valid_symbol_context(line, match_pos, symbol):
				matches.append(match_pos)
		else:
			matches.append(match_pos)
	
	return matches

func _get_match_pattern(symbol: String) -> String:
	var escaped_symbol = _escape_regex_string(symbol)
	
	match _match_mode:
		MatchMode.WORD_BOUNDARY:
			return "\\b" + escaped_symbol + "\\b"
		MatchMode.EXACT:
			return "^" + escaped_symbol + "$"
		MatchMode.STARTS_WITH:
			return "^" + escaped_symbol
		MatchMode.CONTAINS:
			return escaped_symbol
		MatchMode.ENDS_WITH:
			return escaped_symbol + "$"
		_:
			return "\\b" + escaped_symbol + "\\b"

# Check if symbol is inside a string literal
func _is_in_string_literal(line: String, symbol: String) -> bool:
	var in_string = false
	var in_triple_string = false
	var quote_char = ""
	
	# Simple string detection (not perfect but catches most cases)
	for i in range(line.length()):
		var char = line[i]
		
		# Handle triple quotes
		if i < line.length() - 2:
			var triple = line.substr(i, 3)
			if triple == '"""' or triple == "'''":
				if not in_string:
					in_triple_string = not in_triple_string
					quote_char = triple[0]
				continue
		
		# Handle single/double quotes
		if char == '"' or char == "'":
			if not in_triple_string:
				if not in_string:
					in_string = true
					quote_char = char
				elif char == quote_char:
					in_string = false
					quote_char = ""
	
	# If we find the symbol and we're currently in a string, it's probably a false positive
	return (in_string or in_triple_string) and symbol in line

# Check if the symbol appears in a valid context
func _is_valid_symbol_context(line: String, position: int, symbol: String) -> bool:
	# Get context around the symbol
	var start = max(0, position - 10)
	var end = min(line.length(), position + symbol.length() + 10)
	var context = line.substr(start, end - start)
	
	# Skip if it's part of a longer identifier (additional safety)
	if position > 0:
		var prev_char = line[position - 1]
		if _is_identifier_char(prev_char):
			return false
	
	if position + symbol.length() < line.length():
		var next_char = line[position + symbol.length()]
		if _is_identifier_char(next_char):
			return false
	
	return true

func _is_identifier_char(char: String) -> bool:
	return char.is_valid_identifier() or char == "_"

# Escape special regex characters since Godot 4 doesn't have RegEx.escape()
func _escape_regex_string(text: String) -> String:
	var escaped = text
	# Order matters - escape backslash first
	escaped = escaped.replace("\\", "\\\\")
	escaped = escaped.replace(".", "\\.")
	escaped = escaped.replace("^", "\\^")
	escaped = escaped.replace("$", "\\$")
	escaped = escaped.replace("*", "\\*")
	escaped = escaped.replace("+", "\\+")
	escaped = escaped.replace("?", "\\?")
	escaped = escaped.replace("(", "\\(")
	escaped = escaped.replace(")", "\\)")
	escaped = escaped.replace("[", "\\[")
	escaped = escaped.replace("]", "\\]")
	escaped = escaped.replace("{", "\\{")
	escaped = escaped.replace("}", "\\}")
	escaped = escaped.replace("|", "\\|")
	return escaped

func _display_results() -> void:
	# Ensure components are initialized
	if not results_tree:
		_ensure_components_initialized()
	
	if not results_tree:
		print("Error: results_tree component not found")
		_display_results_fallback()
		return
	
	# Clear the tree and code display
	results_tree.clear()
	_clear_code_display()
	
	if _search_results.is_empty():
		_update_results_info("No references found")
		return
	
	# Create root item (hidden)
	var root = results_tree.create_item()
	var file_groups = {}
	
	# Group results by file
	for result in _search_results:
		var file_path = result["file_path"]
		if not file_groups.has(file_path):
			file_groups[file_path] = []
		file_groups[file_path].append(result)
	
	# Update results info
	var total_files = file_groups.size()
	var total_refs = _search_results.size()
	_update_results_info("%d references in %d files" % [total_refs, total_files])
	
	# Create tree structure for navigation
	for file_path in file_groups.keys():
		var file_item = root.create_child()
		var file_name = file_path.get_file()
		var reference_count = file_groups[file_path].size()
		
		# File header in navigation tree
		file_item.set_text(0, "📁 %s (%d)" % [file_name, reference_count])
		file_item.set_text(1, "")
		file_item.set_metadata(0, {"type": "file", "path": file_path})
		
		# File item styling
		file_item.set_selectable(0, false)
		file_item.set_custom_color(0, Color(0.8, 0.9, 1.0))
		file_item.set_collapsed(false)
		
		# Add individual references
		for result in file_groups[file_path]:
			var ref_item = file_item.create_child()
			var line_content = result.get("line_content", "")
			var truncated_content = _truncate_line_content(line_content, 80)
			ref_item.set_text(0, "  → Line %d: %s" % [result["line_number"], truncated_content])
			ref_item.set_text(1, str(result["line_number"]))
			ref_item.set_metadata(0, result)
			
			# Reference item styling
			ref_item.set_custom_color(0, Color(0.9, 0.9, 0.9))
			ref_item.set_custom_color(1, Color(0.8, 0.8, 0.6))
	
	# Force tree update
	results_tree.queue_redraw()

func _clear_code_display() -> void:
	"""Clear the code display area"""
	if code_header:
		code_header.text = "Select a reference to view code"
	if code_display:
		code_display.text = ""
		#Change to set if property placeholder_text not exist Godot 4.4.1
		code_display.set(&"placeholder_text", "Code content will appear here...")

func _update_results_info(info_text: String) -> void:
	"""Update the results info label in the left panel"""
	# Ensure components are initialized first
	if not results_tree:
		_ensure_components_initialized()
	
	# Method 1: Try using the direct NodePath first
	var results_info_label = get_node_or_null("MainContainer/MainContent/LeftPanel/ResultsInfo")
	if results_info_label and results_info_label is Label:
		results_info_label.text = info_text
		return
	
	# Method 2: Try using parent-child relationship
	if results_tree and results_tree.get_parent():
		var left_panel = results_tree.get_parent()
		
		# Try to find ResultsInfo by searching through children
		for i in range(left_panel.get_child_count()):
			var child = left_panel.get_child(i)
			if child.name == "ResultsInfo" and child is Label:
				child.text = info_text
				return
		
		# Log error only if all methods fail
		print("Error: ResultsInfo label not found in UI structure")

func _update_code_display(result: Dictionary) -> void:
	"""Update the right panel with code content for the selected reference"""
	if not result.has("file_path") or not result.has("line_number"):
		return
	
	var file_path = result["file_path"]
	var line_number = result["line_number"]
	var column = result.get("column", 0)
	var file_name = file_path.get_file()
	
	# Update header
	if code_header:
		code_header.text = "%s:%d" % [file_name, line_number]
	
	# Load and display file content with color highlighting
	if code_display:
		var file_content = _load_file_content(file_path)
		if not file_content.is_empty():
			# Show context around the line with BBCode highlighting
			var context_content = _get_context_content_with_highlighting(file_content, line_number, column, 5)
			code_display.text = context_content
			
			# Enable BBCode parsing for color highlighting
			code_display.bbcode_enabled = true

func _load_file_content(file_path: String) -> String:
	"""Load the content of a file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Error: Cannot load file content for %s" % file_path.get_file())
		return ""
	var content = file.get_as_text()
	file.close()
	return content

func _get_context_content_with_highlighting(file_content: String, target_line: int, target_column: int, context_lines: int) -> String:
	"""Get file content with context around the target line, with BBCode color highlighting"""
	var lines = file_content.split("\n")
	var start_line = max(0, target_line - context_lines - 1)
	var end_line = min(lines.size() - 1, target_line + context_lines - 1)
	
	var context_lines_array = []
	for i in range(start_line, end_line + 1):
		var line_content = lines[i]
		var line_num = i + 1
		
		# Add line number prefix
		var prefix = "%3d: " % line_num
		var formatted_line = prefix + line_content
		
		# Apply syntax highlighting to the target line
		if line_num == target_line:
			formatted_line = prefix + _highlight_symbol_with_bbcode(line_content, _current_symbol)
			# Use different background color for target line
			formatted_line = "[bgcolor=#2d2d30]" + formatted_line + "[/bgcolor]"
		
		context_lines_array.append(formatted_line)
	
	return "\n".join(context_lines_array)

# Keep the old function for backward compatibility (if needed elsewhere)
func _get_context_content(file_content: String, target_line: int, context_lines: int) -> String:
	"""Get file content with context around the target line, with highlighting"""
	var lines = file_content.split("\n")
	var start_line = max(0, target_line - context_lines - 1)
	var end_line = min(lines.size() - 1, target_line + context_lines - 1)
	
	var context_lines_array = []
	for i in range(start_line, end_line + 1):
		var line_content = lines[i]
		var line_num = i + 1
		
		# Add line number prefix and highlight target line
		var prefix = "%3d: " % line_num
		if line_num == target_line:
			# Highlight the target line and symbol
			line_content = _highlight_symbol_in_line(line_content, _current_symbol)
			prefix = "►%3d: " % line_num
		else:
			prefix = " %3d: " % line_num
		
		context_lines_array.append(prefix + line_content)
	
	return "\n".join(context_lines_array)

func _truncate_line_content(line: String, max_length: int) -> String:
	"""Truncate line content if it's too long, preserving meaningful code"""
	if line.length() <= max_length:
		return line
	
	# Try to show the beginning and add ellipsis
	var truncated = line.substr(0, max_length - 3)
	return truncated + "..."

func _highlight_symbol_with_bbcode(line: String, symbol: String) -> String:
	"""Highlight symbol in a line of code using BBCode formatting"""
	if symbol.is_empty():
		return line
	
	# Apply case sensitivity for the display
	var search_line = line if _case_sensitive else line.to_lower()
	var search_symbol = symbol if _case_sensitive else symbol.to_lower()
	
	# Create regex pattern based on match mode
	var regex = RegEx.new()
	var pattern = _get_match_pattern(search_symbol)
	if regex.compile(pattern) != OK:
		return line
	
	# Apply highlighting using BBCode
	var highlighted = line
	var results = regex.search_all(search_line)
	
	# Apply highlights from right to left to preserve positions
	results.reverse()
	for result in results:
		var start_pos = result.get_start()
		var end_pos = result.get_end()
		var match_text = line.substr(start_pos, end_pos - start_pos)
		
		# Create highlighted version with yellow background and bold text
		var highlight = "[bgcolor=yellow][color=black][b]%s[/b][/color][/bgcolor]" % match_text
		
		highlighted = highlighted.substr(0, start_pos) + highlight + highlighted.substr(end_pos)
	
	return highlighted

func _highlight_symbol_in_line(line: String, symbol: String) -> String:
	"""Highlight symbol in a line of code (legacy version with symbols)"""
	if symbol.is_empty():
		return line
	
	# Use word boundary matching for better accuracy
	var regex = RegEx.new()
	var pattern = "\\b" + _escape_regex_string(symbol) + "\\b"
	regex.compile(pattern)
	
	var highlighted = regex.sub(line, "►%s◄" % symbol, true)
	return highlighted

func _on_item_activated() -> void:
	var selected = results_tree.get_selected()
	if not selected:
		return
	
	var metadata = selected.get_metadata(0)
	if not metadata or not metadata.has("file_path"):
		return
	
	# Navigate to the reference
	if metadata.has("line_number"):
		_navigate_to_reference(metadata["file_path"], metadata["line_number"], metadata.get("column", 0))

func _on_item_selected() -> void:
	var selected = results_tree.get_selected()
	if not selected:
		return
		
	var metadata = selected.get_metadata(0)
	if metadata:
		if metadata.has("type") and metadata["type"] == "file":
			# File item selected - show file info, clear code display
			var file_path = metadata["path"]
			var relative_path = file_path.replace("res://", "")
			_update_status("📁 %s" % relative_path)
			_clear_code_display()
		elif metadata.has("file_path") and metadata.has("line_number"):
			# Reference item selected - show code content and update status
			_update_code_display(metadata)
			var file_name = metadata["file_path"].get_file()
			var line_num = metadata["line_number"]
			var relative_path = metadata["file_path"].replace("res://", "")
			_update_status("📍 Line %d in %s (%s)" % [line_num, file_name, relative_path])

func _navigate_to_reference(file_path: String, line_number: int, column: int) -> void:
	# Open the file in the script editor
	var script = ResourceLoader.load(file_path)
	if script and script is Script:
		EditorInterface.edit_script(script)
		
		# Navigate to specific line
		var script_editor = EditorInterface.get_script_editor()
		if script_editor:
			script_editor.goto_line(line_number - 1)
			
			# Focus on the specific column if possible
			var current_editor = script_editor.get_current_editor()
			if current_editor:
				var code_edit : CodeEdit = current_editor.get_base_editor()
				if code_edit:
					code_edit.set_caret_line(line_number - 1)
					code_edit.set_caret_column(column)
					code_edit.grab_focus()
	else:
		print("Error: Cannot navigate to %s:%d" % [file_path.get_file(), line_number])

func _display_results_fallback() -> void:
	"""Fallback method to display results when Tree component is not available"""
	var total_refs = _search_results.size()
	if total_refs > 0:
		var file_groups = {}
		for result in _search_results:
			var file_path = result["file_path"]
			if not file_groups.has(file_path):
				file_groups[file_path] = []
			file_groups[file_path].append(result)
		
		var total_files = file_groups.size()
		_update_results_info("%d references in %d files" % [total_refs, total_files])
		
		# Try to create a simple Tree component dynamically
		_create_fallback_tree()
	else:
		_update_results_info("No references found")

func _create_fallback_tree() -> void:
	"""Create a Tree component dynamically when the scene component is missing"""
	# Find the left panel where the tree should be
	var left_panel = get_node_or_null("MainContainer/MainContent/LeftPanel")
	if not left_panel:
		print("Error: Cannot find LeftPanel for tree creation")
		return
	
	# Check if there's already a Tree somewhere
	var existing_tree = _recursive_find_by_type(left_panel, Tree)
	if existing_tree:
		results_tree = existing_tree
		_display_results()
		return
	
	# Create a new Tree component
	var new_tree = Tree.new()
	new_tree.name = "FallbackResultsTree"
	new_tree.columns = 2
	new_tree.column_titles_visible = true
	new_tree.hide_root = true
	new_tree.select_mode = Tree.SELECT_SINGLE
	new_tree.set_column_title(0, "File / Reference")
	new_tree.set_column_title(1, "Line")
	new_tree.set_column_expand_ratio(0, 3.0)
	new_tree.set_column_expand_ratio(1, 1.0)
	
	# Connect signals
	new_tree.item_activated.connect(_on_item_activated)
	new_tree.item_selected.connect(_on_item_selected)
	
	# Add to the left panel
	var insert_position = 1
	if left_panel.get_child_count() > insert_position:
		left_panel.add_child(new_tree)
		left_panel.move_child(new_tree, insert_position)
	else:
		left_panel.add_child(new_tree)
	
	# Set size flags to expand
	new_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Update our reference and try again
	results_tree = new_tree
	_display_results()

func _update_status(message: String) -> void:
	if status_label:
		status_label.text = message

# Public method to show this panel in the bottom dock
func show_and_focus() -> void:
	show()
	if search_bar:
		search_bar.grab_focus()
