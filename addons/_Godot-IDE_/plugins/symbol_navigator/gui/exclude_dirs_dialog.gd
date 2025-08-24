@tool
extends Window

# =============================================================================
# Symbol Navigator - Exclude Directories Dialog
# Author: kyros
# Configure directories to exclude from symbol search
# =============================================================================

# UI components
@export var header_label : Label = null
@export var directories_edit : TextEdit = null
@export var preset_container : VBoxContainer = null
@export var save_button : Button = null
@export var cancel_button : Button = null
@export var validation_label : Label = null

# Preset buttons
var godot_button : Button = null
var git_button : Button = null
var import_button : Button = null
var exports_button : Button = null
var mono_button : Button = null

# Signal emitted when directories are saved
signal directories_saved(directories: Array[String])

# Data
var _current_directories : Array[String] = []
var _preset_directories = {
	".godot": "Godot 4+ engine cache and settings",
	".git": "Git version control files",
	".import": "Godot 3.x import cache files", 
	"exports": "Export output directory",
	".mono": "C# Mono build files and cache",
	"__pycache__": "Python cache files",
	".vs": "Visual Studio files",
	".vscode": "VS Code settings",
	"bin": "Binary output files",
	"obj": "Object files from compilation"
}

func _ready() -> void:
	# Initialize UI components
	_find_ui_components()
	_validate_ui_components()
	_connect_signals()
	
	# Initialize validation label
	if validation_label:
		validation_label.text = ""
		validation_label.modulate = Color.WHITE
	
	# Setup dialog display
	_setup_dialog_display()

func _find_ui_components() -> void:
	"""Find and assign UI components"""
	header_label = find_child("HeaderLabel") as Label
	directories_edit = find_child("DirectoriesEdit") as TextEdit
	preset_container = find_child("PresetContainer") as VBoxContainer
	save_button = find_child("SaveButton") as Button
	cancel_button = find_child("CancelButton") as Button
	validation_label = find_child("ValidationLabel") as Label
	
	# Find preset buttons
	godot_button = find_child("GodotButton") as Button
	git_button = find_child("GitButton") as Button
	import_button = find_child("ImportButton") as Button
	exports_button = find_child("ExportsButton") as Button
	mono_button = find_child("MonoButton") as Button

func _validate_ui_components() -> void:
	"""Validate that all UI components were found"""
	var missing_components = []
	
	if not header_label:
		missing_components.append("HeaderLabel")
	if not directories_edit:
		missing_components.append("DirectoriesEdit")
	if not save_button:
		missing_components.append("SaveButton")
	if not cancel_button:
		missing_components.append("CancelButton")
	
	if not missing_components.is_empty():
		push_warning("[Exclude Dirs Dialog] Missing UI components: " + str(missing_components))

func _connect_signals() -> void:
	"""Connect button signals"""
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if directories_edit:
		directories_edit.text_changed.connect(_on_text_changed)
	
	# Connect preset buttons
	if godot_button:
		godot_button.pressed.connect(_on_preset_pressed.bind(".godot"))
	if git_button:
		git_button.pressed.connect(_on_preset_pressed.bind(".git"))
	if import_button:
		import_button.pressed.connect(_on_preset_pressed.bind(".import"))
	if exports_button:
		exports_button.pressed.connect(_on_preset_pressed.bind("exports"))
	if mono_button:
		mono_button.pressed.connect(_on_preset_pressed.bind(".mono"))

func set_excluded_directories(directories: Array[String]) -> void:
	"""Set the current excluded directories"""
	_current_directories = directories.duplicate()
	
	if directories_edit:
		directories_edit.text = "\n".join(directories)
	
	_validate_directories()

func get_excluded_directories() -> Array[String]:
	"""Get the currently configured directories"""
	if not directories_edit:
		return _current_directories
	
	var directories: Array[String] = []
	var lines = directories_edit.text.split("\n")
	
	for line in lines:
		var trimmed = line.strip_edges()
		if not trimmed.is_empty():
			directories.append(trimmed)
	
	return directories

func _on_save_pressed() -> void:
	"""Handle save button press"""
	var directories = get_excluded_directories()
	
	# Validate directories before saving
	if not _validate_directories():
		return
	
	# Emit signal with the directories
	directories_saved.emit(directories)
	
	# Close dialog
	hide()
	queue_free()

func _on_cancel_pressed() -> void:
	"""Handle cancel button press"""
	hide()
	queue_free()

func _on_close_requested() -> void:
	"""Handle window close request"""
	_on_cancel_pressed()

func _on_text_changed() -> void:
	"""Handle text changes in directories edit"""
	_validate_directories()

func _on_preset_pressed(preset_dir: String) -> void:
	"""Handle preset button press"""
	if not directories_edit:
		return
	
	var current_text = directories_edit.text.strip_edges()
	var lines = current_text.split("\n") if not current_text.is_empty() else []
	
	# Check if directory is already in the list
	var already_exists = false
	for line in lines:
		if line.strip_edges() == preset_dir:
			already_exists = true
			break
	
	if not already_exists:
		# Add the preset directory
		if not current_text.is_empty() and not current_text.ends_with("\n"):
			directories_edit.text += "\n"
		directories_edit.text += preset_dir
		
		# Show feedback
		_show_validation_message("Added: " + preset_dir, "success")
	else:
		# Show feedback that it already exists
		_show_validation_message("Already exists: " + preset_dir, "warning")
	
	# Trigger validation
	_validate_directories()

func _validate_directories() -> bool:
	"""Validate the directory entries"""
	if not directories_edit:
		return true
	
	var directories = get_excluded_directories()
	var issues = []
	var warnings = []
	
	# Check for empty entries (already filtered out in get_excluded_directories())
	
	# Check for duplicates
	var seen_dirs = []
	for dir in directories:
		if dir in seen_dirs:
			issues.append("Duplicate: " + dir)
		else:
			seen_dirs.append(dir)
	
	# Check for invalid directory names
	for dir in directories:
		if not _is_valid_directory_name(dir):
			issues.append("Invalid name: " + dir)
		elif _is_system_directory(dir):
			warnings.append("System directory: " + dir)
	
	# Update validation display
	if not issues.is_empty():
		_show_validation_message("Issues: " + ", ".join(issues), "error")
		if save_button:
			save_button.disabled = true
		return false
	elif not warnings.is_empty():
		_show_validation_message("Warnings: " + ", ".join(warnings), "warning")
		if save_button:
			save_button.disabled = false
		return true
	else:
		var count = directories.size()
		_show_validation_message("✓ %d directories configured" % count, "success")
		if save_button:
			save_button.disabled = false
		return true

func _is_valid_directory_name(dir_name: String) -> bool:
	"""Check if a directory name is valid"""
	if dir_name.is_empty():
		return false
	
	# Check for invalid characters (basic check)
	var invalid_chars = ["<", ">", ":", "\"", "|", "?", "*"]
	for char in invalid_chars:
		if char in dir_name:
			return false
	
	# Check for reserved names (Windows)
	var reserved_names = ["CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"]
	if dir_name.to_upper() in reserved_names:
		return false
	
	return true

func _is_system_directory(dir_name: String) -> bool:
	"""Check if directory is a system directory (warning, not error)"""
	var system_dirs = ["System", "Windows", "Program Files", "Users", "etc", "usr", "var", "tmp"]
	return dir_name in system_dirs

func _show_validation_message(message: String, type: String = "info") -> void:
	"""Show validation message with appropriate color"""
	if not validation_label:
		return
	
	validation_label.text = message
	
	match type:
		"success":
			validation_label.modulate = Color(0.2, 0.8, 0.2, 1.0)  # Green
		"warning":
			validation_label.modulate = Color(1.0, 0.8, 0.2, 1.0)  # Orange
		"error":
			validation_label.modulate = Color(0.9, 0.2, 0.2, 1.0)  # Red
		_:
			validation_label.modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	"""Handle keyboard shortcuts"""
	if not visible:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				# Ctrl+Enter saves
				if event.ctrl_pressed:
					if save_button and not save_button.disabled:
						_on_save_pressed()
					get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				# Escape key cancels
				_on_cancel_pressed()
				get_viewport().set_input_as_handled()

func _setup_dialog_display() -> void:
	"""Setup dialog size and position for proper display"""
	# Get optimal size for dialog
	var optimal_size = _get_optimal_dialog_size()
	size = optimal_size
	
	# Center the dialog manually
	_center_dialog()

func _get_optimal_dialog_size() -> Vector2i:
	"""Calculate optimal dialog size based on content and DPI"""
	# Base size for exclude dirs dialog
	var base_size = Vector2i(600, 450)
	
	# Get screen info for DPI awareness
	var screen = DisplayServer.screen_get_size()
	var dpi_scale = DisplayServer.screen_get_scale()
	
	# Apply DPI scaling if needed
	if dpi_scale > 1.0:
		base_size = Vector2i(
			int(base_size.x * min(dpi_scale, 1.5)),
			int(base_size.y * min(dpi_scale, 1.5))
		)
	
	# Ensure minimum size
	base_size.x = max(base_size.x, 500)
	base_size.y = max(base_size.y, 400)
	
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
