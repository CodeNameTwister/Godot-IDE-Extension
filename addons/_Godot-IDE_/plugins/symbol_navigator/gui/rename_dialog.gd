@tool
extends Window

# =============================================================================
# Symbol Navigator - Rename Dialog
# Author: kyros
# Rename symbols (variables, functions, classes) across the entire project
# 
# Technical Features:
# - Direct source replacement: Instantly update content in open editors
# - Smart symbol matching: Precise word boundary matching with regex
# - State preservation: Maintain user's cursor position and scroll state
# - Quality assurance: Automatic file content verification after batch changes
# 
# User Workflow:
# 1. Select symbol → Press F2 (auto-preview)
# 2. Enter new name → Press Enter or click Rename
# 3. Files modified and editor updates in real-time ✨
# =============================================================================

# UI components
@export var new_name_edit : LineEdit = null
@export var scope_option : OptionButton = null
@export var preview_tree : Tree = null
@export var rename_button : Button = null
@export var cancel_button : Button = null
@export var select_all_button : Button = null
@export var unselect_all_button : Button = null
@export var selection_status : Label = null

# Data
var _current_symbol : String = ""
var _rename_results : Array = []
var _selected_items : Array = []  # Tracks which items are selected for rename
var _file_groups : Dictionary = {}  # Maps file_path to array of result indices
var _file_selections : Dictionary = {}  # Maps file_path to selection state
var _scope_project_wide : bool = true


func _ready() -> void:
	# Find UI components
	_find_ui_components()
	
	# Validate UI components were found
	_validate_ui_components()
	
	# Connect signals
	_connect_signals()
	
	# Setup tree
	_setup_preview_tree()
	
	# Setup dialog display
	_setup_dialog_display()

func _find_ui_components() -> void:
	"""Find and assign UI components"""
	new_name_edit = find_child("NewNameEdit") as LineEdit
	scope_option = find_child("ScopeOption") as OptionButton
	preview_tree = find_child("PreviewTree") as Tree
	rename_button = find_child("RenameButton") as Button
	cancel_button = find_child("CancelButton") as Button
	select_all_button = find_child("SelectAllButton") as Button
	unselect_all_button = find_child("UnselectAllButton") as Button
	selection_status = find_child("SelectionStatus") as Label

func _validate_ui_components() -> void:
	"""Validate that all UI components were found and report missing ones"""
	var missing_components = []
	
	if not new_name_edit:
		missing_components.append("NewNameEdit")
	if not scope_option:
		missing_components.append("ScopeOption")
	if not preview_tree:
		missing_components.append("PreviewTree")
	if not rename_button:
		missing_components.append("RenameButton")
	if not cancel_button:
		missing_components.append("CancelButton")
	if not select_all_button:
		missing_components.append("SelectAllButton")
	if not unselect_all_button:
		missing_components.append("UnselectAllButton")
	if not selection_status:
		missing_components.append("SelectionStatus")
	
	if missing_components.size() > 0:
		push_warning("[Rename Dialog] Missing UI components: " + str(missing_components))

func _connect_signals() -> void:
	"""Connect button signals"""
	var connected_count = 0
	
	if rename_button:
		rename_button.pressed.connect(_on_rename_pressed)
		connected_count += 1
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
		connected_count += 1
	if scope_option:
		scope_option.item_selected.connect(_on_scope_changed)
		connected_count += 1
	if new_name_edit:
		new_name_edit.text_changed.connect(_on_text_changed)
		connected_count += 1
	if select_all_button:
		select_all_button.pressed.connect(_on_select_all_pressed)
		connected_count += 1
	if unselect_all_button:
		unselect_all_button.pressed.connect(_on_unselect_all_pressed)
		connected_count += 1
	if preview_tree:
		preview_tree.item_edited.connect(_on_tree_item_edited)
		connected_count += 1
	
	if connected_count == 0:
		push_warning("[Rename Dialog] No signals connected - UI components may not be properly initialized")
	


func _setup_preview_tree() -> void:
	"""Setup the preview tree columns"""
	if not preview_tree:
		return
		
	preview_tree.columns = 3
	preview_tree.set_column_title(0, "✓")
	preview_tree.set_column_title(1, "File / Location")
	preview_tree.set_column_title(2, "Line")
	preview_tree.set_column_expand_ratio(0, 0.3)  # Checkbox column (narrow)
	preview_tree.set_column_expand_ratio(1, 3.0)  # File/Location column (wide)
	preview_tree.set_column_expand_ratio(2, 0.7)  # Line number column (narrow)
	preview_tree.hide_root = true

func set_symbol(symbol: String) -> void:
	"""Set the symbol to be renamed"""
	_current_symbol = symbol
	
	# Check if UI components are ready
	if not _are_ui_components_ready():
		# Defer the call until the next frame when components should be ready
		call_deferred("_deferred_set_symbol", symbol)
		return
	
	_apply_symbol_to_ui(symbol)

func _are_ui_components_ready() -> bool:
	"""Check if all required UI components are available"""
	return (new_name_edit != null and 
			scope_option != null and 
			preview_tree != null and 
			rename_button != null and 
			cancel_button != null)

func _deferred_set_symbol(symbol: String) -> void:
	"""Deferred version of set_symbol, called when UI is ready"""
	if not _are_ui_components_ready():
		print("[Rename Dialog] ERROR: UI components still not ready after deferral")
		print("[Rename Dialog] new_name_edit: ", new_name_edit)
		print("[Rename Dialog] scope_option: ", scope_option) 
		print("[Rename Dialog] preview_tree: ", preview_tree)
		print("[Rename Dialog] rename_button: ", rename_button)
		print("[Rename Dialog] cancel_button: ", cancel_button)
		return
	
	_apply_symbol_to_ui(symbol)

func _apply_symbol_to_ui(symbol: String) -> void:
	"""Apply the symbol to the UI components"""
	# Update UI
	if new_name_edit:
		new_name_edit.text = symbol
		new_name_edit.select_all()
		new_name_edit.grab_focus()
	
	title = "Rename Symbol: " + symbol
	
	# Automatically trigger preview when symbol is set
	call_deferred("_auto_preview")

func _auto_preview() -> void:
	"""Automatically trigger preview without changing the current name"""
	# Verify UI components are still available
	if not _are_ui_components_ready():
		print("[Rename Symbol] ERROR: UI components not ready during auto-preview")
		return
	
	# Clear previous results
	_rename_results.clear()
	
	# Search for all occurrences
	_search_symbol_occurrences()
	
	# Display results in tree
	_display_preview_results()
	
	# Update status
	if _rename_results.size() == 0:
		print("[Rename Symbol] No occurrences found for symbol: '%s'" % _current_symbol)


func _on_rename_pressed() -> void:
	"""Perform the actual rename operation"""
	# Comprehensive pre-flight checks
	if _rename_results.is_empty():
		_show_error("No preview results. Please click Preview first.")
		return
	
	if not new_name_edit or not is_instance_valid(new_name_edit):
		_show_error("Name input field not available")
		return
		
	var new_name = new_name_edit.text.strip_edges()
	if new_name.is_empty():
		_show_error("New name cannot be empty")
		return
	
	if new_name == _current_symbol:
		_show_error("New name is the same as current symbol")
		return
	
	if _selected_items.is_empty():
		_show_error("No items selected for rename")
		return
	
	# Disable the rename button to prevent double-clicks
	if rename_button:
		rename_button.disabled = true
	
	# Perform batch rename with error handling
	var success = _perform_batch_rename(new_name)
	if not success:
		_show_error("Rename operation failed")
		if rename_button:
			rename_button.disabled = false
		return
	
	if success:
		# Force Godot to refresh the file system
		_refresh_file_system()
		
		# Verify the modifications actually took effect
		var verification_success = _verify_modifications(new_name)
		
		if verification_success:
			# Success - no log needed for normal operation
			var message = "Successfully renamed '%s' to '%s' in %d locations" % [_current_symbol, new_name, _selected_items.size()]
			_show_success(message)
		else:
			# Partial failure - files may be modified but verification failed
			var warning = "Rename completed but verification failed. Please check files manually."
			_show_error(warning)
		
		hide()
	else:
		# Complete operation failure
		_show_error("Rename operation failed. Some files may have been modified.")
	
	# Re-enable the rename button
	if rename_button:
		rename_button.disabled = false

func _on_cancel_pressed() -> void:
	"""Cancel the rename operation"""
	hide()

func _on_scope_changed(index: int) -> void:
	"""Handle scope selection change"""
	_scope_project_wide = (index == 1)  # Assuming index 1 is "Entire Project"
	
	# Re-trigger preview when scope changes
	if not _current_symbol.is_empty():
		call_deferred("_auto_preview")

func _on_text_changed(new_text: String) -> void:
	"""Handle text changes in the name input"""
	# Check for special characters and validate name
	var trimmed_text = new_text.strip_edges()
	var is_valid = _validate_symbol_name(trimmed_text)
	
	# Enable/disable rename button based on text validity
	if rename_button:
		rename_button.disabled = not is_valid
	
	# Special Character Compatibility Check
	if not trimmed_text.is_empty() and not _is_name_compatible(trimmed_text):
		pass  # Silently validate compatibility

func _input(event: InputEvent) -> void:
	"""Handle keyboard shortcuts"""
	if not visible:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				# Enter key triggers rename if valid
				if rename_button and not rename_button.disabled:
					_on_rename_pressed()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				# Escape key cancels
				_on_cancel_pressed()
				get_viewport().set_input_as_handled()
			KEY_A:
				# Ctrl+A for select all
				if event.ctrl_pressed:
					_on_select_all_pressed()
					get_viewport().set_input_as_handled()

func _on_select_all_pressed() -> void:
	"""Select all items for renaming"""
	if not preview_tree:
		return
	
	_selected_items.clear()
	
	# Add all valid indices to selected items
	for i in range(_rename_results.size()):
		_selected_items.append(i)
	
	# Update file selections
	for file_path in _file_groups.keys():
		_file_selections[file_path] = true
	
	# Update checkboxes in tree
	_update_tree_checkboxes(true)
	_update_selection_status()

func _on_unselect_all_pressed() -> void:
	"""Unselect all items"""
	if not preview_tree:
		return
	
	_selected_items.clear()
	
	# Update file selections
	for file_path in _file_groups.keys():
		_file_selections[file_path] = false
	
	# Update checkboxes in tree
	_update_tree_checkboxes(false)
	_update_selection_status()

func _on_tree_item_edited() -> void:
	"""Handle checkbox clicks in tree (both file-level and item-level)"""
	var edited_item = preview_tree.get_edited()
	if not edited_item:
		return
	
	var metadata = edited_item.get_metadata(0)
	if metadata == null:
		return
	
	var is_checked = edited_item.is_checked(0)
	
	if metadata.has("type"):
		if metadata["type"] == "file":
			# Handle file-level checkbox
			_on_file_checkbox_changed(metadata["path"], is_checked)
		elif metadata["type"] == "item":
			# Handle item-level checkbox
			_on_item_checkbox_changed(metadata["index"], is_checked)
	
	_update_selection_status()

func _on_file_checkbox_changed(file_path: String, is_checked: bool) -> void:
	"""Handle file-level checkbox changes"""
	if not _file_groups.has(file_path):
		return
	
	# Update file selection state
	_file_selections[file_path] = is_checked
	
	# Update all items in this file
	for item_data in _file_groups[file_path]:
		var index = item_data["index"]
		
		if is_checked:
			# Add to selected items if not already there
			if index not in _selected_items:
				_selected_items.append(index)
		else:
			# Remove from selected items
			if index in _selected_items:
				_selected_items.erase(index)
	
	# Update the visual state of child checkboxes
	_update_child_checkboxes(file_path, is_checked)

func _on_item_checkbox_changed(index: int, is_checked: bool) -> void:
	"""Handle individual item checkbox changes"""
	if is_checked and index not in _selected_items:
		_selected_items.append(index)
	elif not is_checked and index in _selected_items:
		_selected_items.erase(index)
	
	# Update the parent file's checkbox state based on children
	var file_path = _rename_results[index]["file_path"]
	_update_file_checkbox_state(file_path)

func _update_tree_checkboxes(checked: bool) -> void:
	"""Update all checkboxes in the tree (both files and items)"""
	if not preview_tree:
		return
	
	var root = preview_tree.get_root()
	if not root:
		return
	
	_iterate_tree_items(root, func(item):
		var metadata = item.get_metadata(0)
		if metadata != null and metadata.has("type"):
			# Update both file and item checkboxes
			item.set_checked(0, checked)
	)

func _iterate_tree_items(item: TreeItem, callback: Callable) -> void:
	"""Recursively iterate through tree items"""
	if item:
		callback.call(item)
		var child = item.get_first_child()
		while child:
			_iterate_tree_items(child, callback)
			child = child.get_next()

func _update_child_checkboxes(file_path: String, checked: bool) -> void:
	"""Update all child checkboxes for a file"""
	if not preview_tree:
		return
	
	var root = preview_tree.get_root()
	if not root:
		return
	
	# Find the file item and update its children
	_iterate_tree_items(root, func(item):
		var metadata = item.get_metadata(0)
		if metadata != null and metadata.has("type"):
			if metadata["type"] == "file" and metadata["path"] == file_path:
				# Found the file item, update its children
				var child = item.get_first_child()
				while child:
					child.set_checked(0, checked)
					child = child.get_next()
	)

func _update_file_checkbox_state(file_path: String) -> void:
	"""Update file checkbox based on children selection state (tri-state logic)"""
	if not _file_groups.has(file_path):
		return
	
	# Count selected items in this file
	var selected_count = 0
	var total_count = _file_groups[file_path].size()
	
	for item_data in _file_groups[file_path]:
		var index = item_data["index"]
		if index in _selected_items:
			selected_count += 1
	
	# Update file checkbox state and visual appearance
	var root = preview_tree.get_root()
	if root:
		_iterate_tree_items(root, func(item):
			var metadata = item.get_metadata(0)
			if metadata != null and metadata.has("type"):
				if metadata["type"] == "file" and metadata["path"] == file_path:
					if selected_count == 0:
						# None selected
						item.set_checked(0, false)
						_file_selections[file_path] = false
					elif selected_count == total_count:
						# All selected
						item.set_checked(0, true)
						_file_selections[file_path] = true
					else:
						# Partial selection - show as checked but different visual state
						item.set_checked(0, true)
						_file_selections[file_path] = true
						# In Godot, we can't easily show tri-state, but we track it logically
		)

func _update_selection_status() -> void:
	"""Update the selection status label"""
	if not selection_status:
		return
	
	var total_items = _rename_results.size()
	var selected_items = _selected_items.size()
	var total_files = _file_groups.size()
	var selected_files = 0
	
	# Count how many files have at least one selected item
	for file_path in _file_groups.keys():
		var has_selected = false
		for item_data in _file_groups[file_path]:
			if item_data["index"] in _selected_items:
				has_selected = true
				break
		if has_selected:
			selected_files += 1
	
	selection_status.text = "%d files, %d of %d items selected" % [selected_files, selected_items, total_items]

func _search_symbol_occurrences() -> void:
	"""Search for all occurrences of the symbol"""
	var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
	if not fs:
		return
	
	var root_dir = fs.get_filesystem()
	if not root_dir:
		return
	
	
	if _scope_project_wide:
		_search_in_directory(root_dir)
	else:
		# Current file only
		var current_script = _get_current_script_path()
		if not current_script.is_empty():
			_search_in_file(current_script)

func _search_in_directory(dir: EditorFileSystemDirectory) -> void:
	"""Recursively search in directory"""
	# Search files in current directory
	for i in range(dir.get_file_count()):
		var file_path = dir.get_file_path(i)
		if _is_script_file(file_path):
			_search_in_file(file_path)
	
	# Search subdirectories
	for i in range(dir.get_subdir_count()):
		var subdir = dir.get_subdir(i)
		_search_in_directory(subdir)

func _search_in_file(file_path: String) -> void:
	"""Search for symbol occurrences in a single file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("[Rename Dialog] Cannot open file: %s" % file_path)
		return
	
	# Safety check for file size to prevent memory issues
	var file_size = file.get_length()
	if file_size > 10 * 1024 * 1024:  # 10MB limit
		push_warning("[Rename Dialog] Skipping large file: %s (%d bytes)" % [file_path, file_size])
		file.close()
		return
	
	var line_number = 1
	var max_lines = 10000  # Prevent infinite loops
	while not file.eof_reached() and line_number <= max_lines:
		var line = file.get_line()
		var occurrences = _find_symbol_in_line(line, _current_symbol)
		
		for occurrence in occurrences:
			var result = {
				"file_path": file_path,
				"line_number": line_number,
				"line_content": line.strip_edges(),
				"column": occurrence["column"],
				"match_start": occurrence["start"],
				"match_end": occurrence["end"]
			}
			_rename_results.append(result)
		
		line_number += 1
	
	file.close()
	
	if line_number > max_lines:
		push_warning("[Rename Dialog] File too long, search truncated: %s" % file_path)

func _find_symbol_in_line(line: String, symbol: String) -> Array:
	"""Find all occurrences of symbol in a line, ensuring word boundaries"""
	var occurrences = []
	
	var regex = RegEx.new()
	var pattern = "\\b" + _escape_regex_string(symbol) + "\\b"
	if regex.compile(pattern) != OK:
		return occurrences
	
	var search_from = 0
	while true:
		var result = regex.search(line, search_from)
		if not result:
			break
		
		occurrences.append({
			"column": result.get_start(),
			"start": result.get_start(),
			"end": result.get_end(),
			"match": result.get_string()
		})
		
		search_from = result.get_end()
	
	return occurrences

func _escape_regex_string(text: String) -> String:
	"""Escape special regex characters"""
	var special_chars = ["\\", ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|"]
	var escaped = text
	for char in special_chars:
		escaped = escaped.replace(char, "\\" + char)
	return escaped

func _display_preview_results() -> void:
	"""Display the preview results in the tree"""
	if not preview_tree:
		return
	
	preview_tree.clear()
	_selected_items.clear()
	_file_groups.clear()
	_file_selections.clear()
	
	if _rename_results.is_empty():
		var root = preview_tree.create_item()
		var no_results = root.create_child()
		no_results.set_text(1, "No occurrences found")  # Column 1 (File/Location)
		no_results.set_text(2, "")  # Column 2 (Line)
		_update_selection_status()
		return
	
	var root = preview_tree.create_item()
	
	# Group by file and store in class variables
	for i in range(_rename_results.size()):
		var result = _rename_results[i]
		var file_path = result["file_path"]
		if not _file_groups.has(file_path):
			_file_groups[file_path] = []
		_file_groups[file_path].append({"index": i, "result": result})
	
	# Initialize file selections (all selected by default)
	for file_path in _file_groups.keys():
		_file_selections[file_path] = true
	
	# Display grouped results
	for file_path in _file_groups.keys():
		var file_item = root.create_child()
		var file_name = file_path.get_file()
		
		# Column 0: File-level checkbox (selected by default)
		file_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		file_item.set_checked(0, true)  # Default to selected
		file_item.set_editable(0, true)
		
		# Column 1: File name and count
		file_item.set_text(1, "%s (%d occurrences)" % [file_name, _file_groups[file_path].size()])
		
		# Column 2: Empty for file headers
		file_item.set_text(2, "")
		file_item.set_custom_color(1, Color(0.8, 0.9, 1.0))
		
		# Store file path as metadata for file-level checkbox handling
		file_item.set_metadata(0, {"type": "file", "path": file_path})
		
		# Add occurrences with checkboxes
		for item_data in _file_groups[file_path]:
			var result = item_data["result"]
			var index = item_data["index"]
			
			var ref_item = file_item.create_child()
			
			# Column 0: Checkbox (selected by default)
			ref_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			ref_item.set_checked(0, true)  # Default to selected
			ref_item.set_editable(0, true)
			
			# Column 1: File/Location info
			var line_content = result["line_content"]
			if line_content.length() > 60:
				line_content = line_content.substr(0, 57) + "..."
			ref_item.set_text(1, "  → Line %d: %s" % [result["line_number"], line_content])
			
			# Column 2: Line number
			ref_item.set_text(2, str(result["line_number"]))
			
			# Store the index as metadata for tracking
			ref_item.set_metadata(0, {"type": "item", "index": index})
			
			# Add to selected items (all selected by default)
			_selected_items.append(index)
	
	_update_selection_status()

func _perform_batch_rename(new_name: String) -> bool:
	"""Execute batch rename operation - core functionality"""
	var files_to_modify = {}
	
	# Group modifications by file (only selected items)
	for i in _selected_items:
		if i >= 0 and i < _rename_results.size():
			var result = _rename_results[i]
			var file_path = result["file_path"]
			if not files_to_modify.has(file_path):
				files_to_modify[file_path] = []
			files_to_modify[file_path].append(result)
	
	var success_count = 0
	var total_files = files_to_modify.size()
	
	# Process each file
	for file_path in files_to_modify.keys():
		var modifications = files_to_modify[file_path]
		
		if _modify_file(file_path, modifications, new_name):
			success_count += 1
		else:
			# Only log errors
			print("Error: Failed to modify %s" % file_path.get_file())
	
	# Only log if there were failures
	if success_count != total_files:
		print("Warning: Only %d/%d files modified successfully" % [success_count, total_files])
	
	return success_count == total_files

func _modify_file(file_path: String, modifications: Array, new_name: String) -> bool:
	"""Modify all symbol occurrences in a single file"""
	# Read file content
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var lines = []
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	
	# Sort by line and column (reverse order for safe replacement)
	modifications.sort_custom(func(a, b): return a["line_number"] > b["line_number"] or (a["line_number"] == b["line_number"] and a["column"] > b["column"]))
	
	# Apply all modifications
	for mod in modifications:
		var line_idx = mod["line_number"] - 1
		if line_idx >= 0 and line_idx < lines.size():
			var old_line = lines[line_idx]
			var start_pos = mod["match_start"]
			var end_pos = mod["match_end"]
			
			# Execute symbol replacement
			var new_line = old_line.substr(0, start_pos) + new_name + old_line.substr(end_pos)
			lines[line_idx] = new_line
	
	# Write back to file
	file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false
	
	for line in lines:
		file.store_line(line)
	file.close()
	
	return true

func _get_current_script_path() -> String:
	"""Get the path of the currently open script"""
	var script_editor : ScriptEditor = EditorInterface.get_script_editor()
	if not script_editor:
		return ""
	
	# Method 1: Try to get current script directly
	var current_script = script_editor.get_current_script()
	if current_script and current_script.resource_path != "":
		return current_script.resource_path
	
	# Method 2: Try through current editor
	var current_editor = script_editor.get_current_editor()
	if current_editor:
		if current_editor is ScriptEditorBase:
			var base_editor = current_editor.get_base_editor()
			if base_editor and base_editor is CodeEdit:
				# Try to get script from the editor
				var script = current_editor.get_edited_resource()
				if script and script.resource_path != "":
					return script.resource_path
	
	# Method 3: Try through editor selection
	var editor_selection = EditorInterface.get_selection()
	if editor_selection:
		var selected = editor_selection.get_selected_nodes()
		if selected.size() > 0:
			var node = selected[0]
			var script = node.get_script()
			if script and script.resource_path != "":
				return script.resource_path
	
	return ""

func _is_script_file(file_path: String) -> bool:
	"""Check if file is a script file we should search in"""
	var extension = file_path.get_extension().to_lower()
	return extension in ["gd", "cs", "cpp", "h", "hpp", "c", "py", "js", "ts"]

func _show_error(message: String) -> void:
	"""Show error message"""
	print("[Rename Symbol] Error: %s" % message)
	# Could also show a popup or status message

func _validate_symbol_name(name: String) -> bool:
	"""Validate that the symbol name is valid for renaming"""
	if name.is_empty():
		return false
	
	if name == _current_symbol:
		return false
	
	# Check for basic identifier rules (letters, numbers, underscore)
	var regex = RegEx.new()
	if regex.compile("^[a-zA-Z_][a-zA-Z0-9_]*$") != OK:
		return true  # Fallback to allowing anything if regex fails
	
	return regex.search(name) != null

func _is_name_compatible(name: String) -> bool:
	"""Check if the name contains only standard ASCII characters"""
	for i in range(name.length()):
		var char_code = name.unicode_at(i)
		# Allow only standard ASCII printable characters (32-126)
		# Plus common programming characters
		if char_code < 32 or char_code > 126:
			return false
	return true

func _show_success(message: String) -> void:
	"""Show success message"""
	print("[Rename Symbol] ✅ SUCCESS: %s" % message)

func _refresh_file_system() -> void:
	"""Direct source replacement for immediate synchronization - core functionality"""
	# Collect all modified file paths (only selected items)
	var modified_files : PackedStringArray = PackedStringArray()
	for i in _selected_items:
		if i >= 0 and i < _rename_results.size():
			var result = _rename_results[i]
			if result.has("file_path"):
				var file_path = result["file_path"]
				if file_path not in modified_files:
					modified_files.append(file_path)
	
	# Limit the number of files to prevent system overload
	if modified_files.size() > 100:
		push_warning("[Rename Dialog] Large number of files to refresh: %d" % modified_files.size())
	
	# Force reload with direct source replacement
	_force_reload(modified_files)

func _replace_src(path: String, new_text: String) -> void:
	"""Replace source code in open editors - prevents user from losing work state"""
	var item_list: ItemList = IDE.get_script_list()
	var editor_container: TabContainer = IDE.get_script_editor_container()
	
	# Check API availability
	if not is_instance_valid(item_list) or not is_instance_valid(editor_container):
		push_warning("[Rename Dialog] IDE components not available for source replacement")
		return
	
	if item_list.item_count != editor_container.get_tab_count():
		push_warning("[Rename Dialog] Script list and editor container count mismatch")
		return
	
	# Find and update open file editors
	for x: int in item_list.item_count:
		if path == item_list.get_item_tooltip(x):
			var control: Control = editor_container.get_tab_control(x)
			if control is ScriptEditorBase:
				var editor: Control = control.get_base_editor()
				if editor is CodeEdit:
					# Save user's current view state
					var scroll_h: int = editor.scroll_horizontal
					var scroll_v: int = editor.scroll_vertical
					var caret_line: int = editor.get_caret_line()
					var caret_column: int = editor.get_caret_column()
					
					# Replace source content
					editor.text = new_text
					
					# Restore user's view state (scroll position, cursor position)
					editor.scroll_horizontal = scroll_h
					editor.scroll_vertical = scroll_v
					editor.set_caret_line(caret_line)
					editor.set_caret_column(caret_column)
					return

func _force_reload(files: PackedStringArray, type_hint: String = "") -> void:
	"""Force reload files, bypassing cache and updating open editors"""
	for file: String in files:
		if not ResourceLoader.exists(file):
			continue
		
		if ResourceLoader.has_cached(file):
			# Bypass cache to load fresh content
			var resource: Resource = ResourceLoader.load(file, type_hint, ResourceLoader.CACHE_MODE_IGNORE)
			if resource is Script:
				# Directly replace source in open editors
				_replace_src(resource.resource_path, resource.source_code)






func _verify_modifications(new_name: String) -> bool:
	"""Verify that modifications were successfully applied to the file - Quality Assurance Mechanism"""
	var files_to_check = {}
	for i in _selected_items:
		if i >= 0 and i < _rename_results.size():
			var result = _rename_results[i]
			var file_path = result["file_path"]
			if not files_to_check.has(file_path):
				files_to_check[file_path] = []
			files_to_check[file_path].append(result)
	
	var verified_files = 0
	var total_files = files_to_check.size()
	
	# Validate modification results file by file
	for file_path in files_to_check.keys():
		if _verify_file_modifications(file_path, files_to_check[file_path], new_name):
			verified_files += 1
			# Show details only on failures
		else:
			print("  ❌ Verification failed: %s" % file_path.get_file())
	
	var success = verified_files == total_files
	if not success:
		print("  ⚠️ Verification: %d/%d files verified" % [verified_files, total_files])
	
	return success

func _verify_file_modifications(file_path: String, modifications: Array, new_name: String) -> bool:
	"""Verify that modifications in a single file were successful"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var lines = []
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	
	# Check each modification
	for mod in modifications:
		var line_idx = mod["line_number"] - 1
		if line_idx >= 0 and line_idx < lines.size():
			var line = lines[line_idx]
			# Check if the new name exists
			if not new_name in line:
				return false
		else:
			return false
	
	return true



func _show_sync_warning() -> void:
	"""Show warning about synchronization issues"""
	print("[Rename Symbol] ⚠️ Files were modified but verification had issues")


func _on_close_requested() -> void:
	_on_cancel_pressed()


func _on_focus_exited() -> void:
	_on_cancel_pressed()


func _setup_dialog_display() -> void:
	"""Setup dialog size and position for proper display"""
	# Get optimal size for dialog
	var optimal_size = _get_optimal_dialog_size()
	size = optimal_size
	
	# Center the dialog manually
	_center_dialog()

func _get_optimal_dialog_size() -> Vector2i:
	"""Calculate optimal dialog size based on content and DPI"""
	# Base size for rename dialog
	var base_size = Vector2i(800, 600)
	
	# Get screen info for DPI awareness
	var screen = DisplayServer.screen_get_size()
	var dpi_scale = DisplayServer.screen_get_scale()
	
	# Apply DPI scaling if needed
	if dpi_scale > 1.0:
		base_size = Vector2i(
			int(base_size.x * min(dpi_scale, 1.5)),
			int(base_size.y * min(dpi_scale, 1.5))
		)
	
	# Ensure minimum size for rename dialog with code preview
	base_size.x = max(base_size.x, 700)
	base_size.y = max(base_size.y, 500)
	
	# Ensure it fits on screen (leave 100px margin)
	base_size.x = min(base_size.x, screen.x - 100)
	base_size.y = min(base_size.y, screen.y - 100)
	
	return base_size

func _center_dialog() -> void:
	"""Manually center the dialog on screen"""
	var screen_size = DisplayServer.screen_get_size()
	var dialog_size = size
	
	# Calculate centered position
	var centered_pos = Vector2i(
		(screen_size.x - dialog_size.x) / 2,
		(screen_size.y - dialog_size.y) / 2
	)
	
	# Ensure dialog stays on screen
	centered_pos.x = max(0, centered_pos.x)
	centered_pos.y = max(0, centered_pos.y)
	
	# Set position
	position = centered_pos
