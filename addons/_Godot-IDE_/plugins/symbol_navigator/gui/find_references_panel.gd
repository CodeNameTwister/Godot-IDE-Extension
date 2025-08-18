@tool
extends Control
# =============================================================================	
# Author: GodotIDE Team  
# Symbol Navigator - Find References Bottom Panel
#
# UI for displaying symbol references in the editor's bottom panel
# =============================================================================	

@export var search_bar : LineEdit = null
@export var results_tree : Tree = null
@export var status_label : Label = null
@export var search_button : Button = null
@export var clear_button : Button = null
@export var code_header : Label = null
@export var code_display : TextEdit = null

var _current_symbol : String = ""
var _search_results : Array[Dictionary] = []

func _ready() -> void:
	print("[Find References] Panel _ready() called")
	
	# Force initialization of exported variables if they're null
	_ensure_components_initialized()
	
	# Apply editor theme for better integration
	var editor_control : Control = EditorInterface.get_base_control()
	if editor_control:
		# Apply editor's theme to match the bottom panel style
		var theme = editor_control.get_theme()
		if theme:
			set_theme(theme)
	
	# Connect signals
	if search_button:
		search_button.pressed.connect(_on_search_pressed)
		print("[Find References] Search button connected")
	else:
		print("[Find References] Warning: search_button is null")
		
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
		print("[Find References] Clear button connected")
	else:
		print("[Find References] Warning: clear_button is null")
		
	if search_bar:
		search_bar.text_submitted.connect(_on_search_submitted)
		search_bar.text_changed.connect(_on_search_text_changed)
		print("[Find References] Search bar connected")
	else:
		print("[Find References] Warning: search_bar is null")
		
	if results_tree:
		results_tree.item_activated.connect(_on_item_activated)
		results_tree.item_selected.connect(_on_item_selected)
		print("[Find References] Results tree connected")
	else:
		print("[Find References] Warning: results_tree is null")
	
	# Set up tree columns for split panel layout
	if results_tree:
		results_tree.set_column_titles_visible(true)
		results_tree.set_column_title(0, "File / Reference")
		results_tree.set_column_title(1, "Line")
		results_tree.columns = 2
		
		# Set column ratios for navigation tree
		results_tree.set_column_expand_ratio(0, 3.0)  # File/reference column (main info)
		results_tree.set_column_expand_ratio(1, 1.0)  # Line column (compact)
		print("[Find References] Tree setup completed")
	
	# Initialize UI state
	_update_results_info("Enter a symbol to search")
	_clear_code_display()
	print("[Find References] Initial UI state set")

func _ensure_components_initialized() -> void:
	"""Ensure all exported components are properly initialized"""
	print("[Find References] Initializing components...")
	
	if not search_bar:
		search_bar = _find_component_robust("SearchBar", LineEdit)
		print("[Find References] search_bar result: %s" % str(search_bar))
	
	if not results_tree:
		results_tree = _find_component_robust("ResultsTree", Tree)
		print("[Find References] results_tree result: %s" % str(results_tree))
	
	if not status_label:
		status_label = _find_component_robust("StatusLabel", Label)
		print("[Find References] status_label result: %s" % str(status_label))
	
	if not search_button:
		search_button = _find_component_robust("SearchButton", Button)
		print("[Find References] search_button result: %s" % str(search_button))
	
	if not clear_button:
		clear_button = _find_component_robust("ClearButton", Button)
		print("[Find References] clear_button result: %s" % str(clear_button))
	
	if not code_header:
		code_header = _find_component_robust("CodeHeader", Label)
		print("[Find References] code_header result: %s" % str(code_header))
	
	if not code_display:
		code_display = _find_component_robust("CodeDisplay", TextEdit)
		print("[Find References] code_display result: %s" % str(code_display))
	
	var missing_components = []
	if not search_bar: missing_components.append("search_bar")
	if not results_tree: missing_components.append("results_tree")
	if not status_label: missing_components.append("status_label")
	if not search_button: missing_components.append("search_button")
	if not clear_button: missing_components.append("clear_button")
	if not code_header: missing_components.append("code_header")
	if not code_display: missing_components.append("code_display")
	
	if missing_components.is_empty():
		print("[Find References] All components initialized successfully")
	else:
		print("[Find References] Missing components: %s" % ", ".join(missing_components))

func _debug_print_node_tree(node: Node, indent: int) -> void:
	"""Recursively print the entire node tree for debugging"""
	var indent_str = ""
	for i in range(indent):
		indent_str += "  "
	
	var node_info = "%s%s (%s)" % [indent_str, node.name, node.get_class()]
	if node.get_child_count() > 0:
		node_info += " [%d children]" % node.get_child_count()
	print(node_info)
	
	# Recursively print children (limit depth to prevent spam)
	if indent < 6:
		for child in node.get_children():
			_debug_print_node_tree(child, indent + 1)

func _find_component_robust(component_name: String, component_type) -> Node:
	"""Robust component finder using multiple strategies"""
	var found_component: Node = null
	
	# Strategy 1: Direct NodePath lookup
	var expected_paths = _get_expected_paths(component_name)
	for path in expected_paths:
		found_component = get_node_or_null(path)
		if found_component and _is_correct_type(found_component, component_type):
			print("[Find References] Found %s via path '%s'" % [component_name, path])
			return found_component
	
	# Strategy 2: find_child() search
	found_component = find_child(component_name, true, false)
	if found_component and _is_correct_type(found_component, component_type):
		print("[Find References] Found %s via find_child()" % component_name)
		return found_component
	
	# Strategy 3: Recursive search by type and name
	found_component = _recursive_find_by_type_and_name(self, component_type, component_name)
	if found_component:
		print("[Find References] Found %s via recursive type+name search" % component_name)
		return found_component
	
	# Strategy 4: Recursive search by type only (first match)
	found_component = _recursive_find_by_type(self, component_type)
	if found_component:
		print("[Find References] Found %s via recursive type search (first match)" % component_name)
		return found_component
	
	# Strategy 5: Partial name matching
	found_component = _recursive_find_by_partial_name(self, component_name.to_lower())
	if found_component and _is_correct_type(found_component, component_type):
		print("[Find References] Found %s via partial name matching" % component_name)
		return found_component
	
	print("[Find References] Failed to find %s using all strategies" % component_name)
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
	print("[Find References] === STARTING SEARCH ===")
	print("[Find References] Searching for symbol: '%s'" % symbol)
	
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

func _perform_search() -> void:
	if _current_symbol.is_empty():
		_update_status("Please enter a symbol to search")
		return
	
	_update_status("Searching for references...")
	_clear_results()
	
	# Perform the actual search
	_search_in_project()
	
	# Update UI
	_display_results()
	var result_count = _search_results.size()
	if result_count > 0:
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

func _search_in_file(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
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
	
	# Skip string literals (basic detection)
	if _is_in_string_literal(line, symbol):
		return matches
	
	# Create regex pattern for word boundary matching
	var regex = RegEx.new()
	var pattern = "\\b" + _escape_regex_string(symbol) + "\\b"
	regex.compile(pattern)
	
	var results = regex.search_all(line)
	for result in results:
		var match_pos = result.get_start()
		
		# Additional context-aware filtering
		if _is_valid_symbol_context(line, match_pos, symbol):
			matches.append(match_pos)
	
	return matches

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
		print("[Find References] Error: results_tree is still null after initialization")
		print("[Find References] Attempting fallback display methods...")
		_display_results_fallback()
		return
	
	print("[Find References] Displaying results: %d items found" % _search_results.size())
	
	# Clear the tree completely
	results_tree.clear()
	
	# Clear code display
	_clear_code_display()
	
	if _search_results.is_empty():
		print("[Find References] No search results to display")
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
	
	# Update results info FIRST
	var total_files = file_groups.size()
	var total_refs = _search_results.size()
	print("[Find References] Grouped into %d files, %d total references" % [total_files, total_refs])
	_update_results_info("%d references in %d files" % [total_refs, total_files])
	
	# Create simplified tree structure for navigation
	var items_created = 0
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
		file_item.set_custom_color(0, Color(0.8, 0.9, 1.0))  # Light blue for file headers
		file_item.set_collapsed(false)  # Show references by default
		items_created += 1
		
		# Add individual references
		for result in file_groups[file_path]:
			var ref_item = file_item.create_child()
			ref_item.set_text(0, "  → Line %d" % result["line_number"])
			ref_item.set_text(1, str(result["line_number"]))
			ref_item.set_metadata(0, result)
			
			# Reference item styling
			ref_item.set_custom_color(0, Color(0.9, 0.9, 0.9))  # Standard text color
			ref_item.set_custom_color(1, Color(0.8, 0.8, 0.6))  # Yellow tint for line numbers
			items_created += 1
	
	print("[Find References] Created %d tree items total" % items_created)
	
	# Force tree update
	results_tree.queue_redraw()
	
	# Ensure tree is visible and has proper size
	root = results_tree.get_root()
	if root and root.get_child_count() > 0:
		print("[Find References] Tree has %d file groups with items" % root.get_child_count())
	else:
		print("[Find References] Warning: Tree root has no child items after creation")

func _clear_code_display() -> void:
	"""Clear the code display area"""
	if code_header:
		code_header.text = "Select a reference to view code"
	if code_display:
		code_display.text = ""
		code_display.placeholder_text = "Code content will appear here..."

func _update_results_info(info_text: String) -> void:
	"""Update the results info label in the left panel"""
	print("[Find References] Updating results info: %s" % info_text)
	
	# Ensure components are initialized first
	if not results_tree:
		_ensure_components_initialized()
	
	# Method 1: Try using the direct NodePath first
	var results_info_label = get_node_or_null("MainContainer/MainContent/LeftPanel/ResultsInfo")
	if results_info_label and results_info_label is Label:
		results_info_label.text = info_text
		print("[Find References] Successfully updated ResultsInfo via direct NodePath: %s" % info_text)
		return
	
	# Method 2: Try using parent-child relationship
	if results_tree and results_tree.get_parent():
		var left_panel = results_tree.get_parent()
		print("[Find References] Left panel found: %s" % left_panel.name)
		
		# List all children to debug
		print("[Find References] Left panel children:")
		for i in range(left_panel.get_child_count()):
			var child = left_panel.get_child(i)
			print("  - %s (%s)" % [child.name, child.get_class()])
		
		# Try to find ResultsInfo by searching through children
		for i in range(left_panel.get_child_count()):
			var child = left_panel.get_child(i)
			if child.name == "ResultsInfo" and child is Label:
				child.text = info_text
				print("[Find References] Successfully updated ResultsInfo via parent search: %s" % info_text)
				return
		
		print("[Find References] Error: ResultsInfo Label not found in children")
	else:
		print("[Find References] Error: results_tree or parent is null")
	
	# If we reach here, all methods failed
	print("[Find References] Error: Could not update ResultsInfo via any method")

func _update_code_display(result: Dictionary) -> void:
	"""Update the right panel with code content for the selected reference"""
	if not result.has("file_path") or not result.has("line_number"):
		return
	
	var file_path = result["file_path"]
	var line_number = result["line_number"]
	var file_name = file_path.get_file()
	
	# Update header
	if code_header:
		code_header.text = "%s:%d" % [file_name, line_number]
	
	# Load and display file content
	if code_display:
		var file_content = _load_file_content(file_path)
		if not file_content.is_empty():
			# Show context around the line (e.g., 5 lines before and after)
			var context_content = _get_context_content(file_content, line_number, 5)
			code_display.text = context_content
			
			# Try to scroll to the target line (approximate)
			var lines = context_content.split("\n")
			for i in range(lines.size()):
				if lines[i].contains("►"):  # Our highlight marker
					code_display.scroll_vertical = i * 20  # Approximate line height
					break

func _load_file_content(file_path: String) -> String:
	"""Load the content of a file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var content = file.get_as_text()
	file.close()
	return content

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

func _highlight_symbol_in_line(line: String, symbol: String) -> String:
	"""Highlight symbol in a line of code"""
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
					
					# Ensure the editor gets focus
					code_edit.grab_focus()

func _display_results_fallback() -> void:
	"""Fallback method to display results when Tree component is not available"""
	print("[Find References] Using fallback display method")
	
	# Update results info with the data we have
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
	print("[Find References] Attempting to create fallback Tree component")
	
	# Find the left panel where the tree should be
	var left_panel = get_node_or_null("MainContainer/MainContent/LeftPanel")
	if not left_panel:
		print("[Find References] Cannot find LeftPanel for fallback tree creation")
		return
	
	# Check if there's already a Tree somewhere
	var existing_tree = _recursive_find_by_type(left_panel, Tree)
	if existing_tree:
		results_tree = existing_tree
		print("[Find References] Found existing Tree in LeftPanel, using it")
		# Try displaying results again
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
	
	# Add to the left panel (insert after the header, before the info label)
	var insert_position = 1  # After "ResultsHeader"
	if left_panel.get_child_count() > insert_position:
		left_panel.add_child(new_tree)
		left_panel.move_child(new_tree, insert_position)
	else:
		left_panel.add_child(new_tree)
	
	# Set size flags to expand
	new_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Update our reference
	results_tree = new_tree
	print("[Find References] Created fallback Tree component successfully")
	
	# Try displaying results again
	_display_results()

func _update_status(message: String) -> void:
	if status_label:
		status_label.text = message

# Public method to show this panel in the bottom dock
func show_and_focus() -> void:
	show()
	if search_bar:
		search_bar.grab_focus()
