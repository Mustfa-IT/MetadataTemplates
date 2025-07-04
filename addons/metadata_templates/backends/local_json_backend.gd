@tool
class_name LocalJSONBackend
extends MetadataBackend

const DEFAULT_TEMPLATES_DIR = "res://addons/metadata_templates/templates/"
const DEFAULT_TEMPLATES_FILE = "templates.json"

# Configuration
var _templates_file_path: String
var _last_modified_time: int = 0
var _file_check_timer: Timer = null
var _file_watch_enabled: bool = true
var _serializer: SerializationService = null

# Initialization flag
var _initialized: bool = false

# Default JSON serializer if none provided
var _default_serializer: SerializationService = null

func _init():
	_templates_file_path = DEFAULT_TEMPLATES_DIR + DEFAULT_TEMPLATES_FILE

func get_backend_id() -> String:
	return "local_json"

func get_backend_name() -> String:
	return "Local JSON Storage"

func get_capabilities() -> int:
	return CAPABILITY_READ | CAPABILITY_WRITE | CAPABILITY_WATCH

func get_configuration_options() -> Array:
	return [
		{
			"name": "Templates Directory",
			"property": "templates_dir",
			"type": TYPE_STRING,
			"default_value": DEFAULT_TEMPLATES_DIR
		},
		{
			"name": "Templates File",
			"property": "templates_file",
			"type": TYPE_STRING,
			"default_value": DEFAULT_TEMPLATES_FILE
		},
		{
			"name": "Watch for Changes",
			"property": "watch_enabled",
			"type": TYPE_BOOL,
			"default_value": true
		}
	]

func initialize(config: Dictionary = {}) -> bool:
	if _initialized:
		stop_watching() # Clean up existing timer

	# Apply configuration
	if config.has("templates_dir"):
		var dir = config.templates_dir
		if not dir.ends_with("/"):
			dir += "/"
		_templates_file_path = dir

	if config.has("templates_file"):
		_templates_file_path += config.templates_file
	else:
		_templates_file_path += DEFAULT_TEMPLATES_FILE

	if config.has("watch_enabled"):
		_file_watch_enabled = config.watch_enabled

	if config.has("serializer"):
		_serializer = config.serializer
	else:
		# Create default JSON serializer if not provided
		if _default_serializer == null:
			_default_serializer = JSONSerializationService.new()
		_serializer = _default_serializer

	# Set up file watching if enabled
	if _file_watch_enabled:
		start_watching()

	_initialized = true
	return true

func load_templates() -> TemplateDataStructure:
	# Check if file exists
	if not FileAccess.file_exists(_templates_file_path):
		return TemplateDataStructure.new()

	# Read the file
	var file = FileAccess.open(_templates_file_path, FileAccess.READ)
	if not file:
		printerr("Failed to open templates file: " + _templates_file_path)
		return TemplateDataStructure.new()

	var json_string = file.get_as_text()
	file.close()

	# Update last modified time
	update_last_modified_time()

	# Deserialize the data
	var data_dict = _serializer.deserialize(json_string)
	if data_dict.is_empty():
		return TemplateDataStructure.new()

	# Create template data structure
	var template_data = TemplateDataStructure.new()
	template_data.data = data_dict
	return template_data

func save_templates(templates: TemplateDataStructure) -> bool:
	# Check initialization
	if not _initialized:
		printerr("Backend not initialized")
		return false

	# Ensure templates directory exists
	var dir_path = _templates_file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive(dir_path)

	# Temporarily disable file watching to prevent recursive reload
	var was_watching = _file_watch_enabled
	_file_watch_enabled = false

	# Serialize the data
	var json_string = _serializer.serialize(templates.data)

	# Write to file
	var file = FileAccess.open(_templates_file_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open templates file for writing: " + _templates_file_path)
		_file_watch_enabled = was_watching
		return false

	file.store_string(json_string)
	file.close()

	# Update the last modified time
	update_last_modified_time()

	# Re-enable file watching
	_file_watch_enabled = was_watching
	return true

func update_last_modified_time() -> void:
	var file = FileAccess.open(_templates_file_path, FileAccess.READ)
	if file:
		file.close()
		var file_info = FileAccess.get_modified_time(_templates_file_path)
		if file_info > 0:
			_last_modified_time = file_info

func start_watching() -> void:
	if not _file_watch_enabled:
		return

	# Create a timer for checking file changes
	_file_check_timer = Timer.new()
	_file_check_timer.wait_time = 2.0 # Check every 2 seconds
	_file_check_timer.one_shot = false
	_file_check_timer.autostart = true

	# Add the timer to the scene tree
	var editor = Engine.get_main_loop().get_root().get_child(0)
	editor.add_child(_file_check_timer)

	# Connect the timer's timeout signal
	_file_check_timer.connect("timeout", check_file_changes)

	print("Template file watcher initialized")

func stop_watching() -> void:
	if _file_check_timer and is_instance_valid(_file_check_timer):
		_file_check_timer.stop()
		_file_check_timer.queue_free()
		_file_check_timer = null

func check_file_changes() -> void:
	if not _file_watch_enabled:
		return

	# Check if the file exists
	if not FileAccess.file_exists(_templates_file_path):
		return

	# Get current modification time
	var current_modified_time = FileAccess.get_modified_time(_templates_file_path)

	# If the file was modified since we last checked
	if current_modified_time != _last_modified_time and current_modified_time > 0:
		print("Templates file changed externally - reloading")

		# Update last modified time
		_last_modified_time = current_modified_time

		# Load the templates and emit the signal
		var templates = load_templates()
		emit_signal("templates_modified", templates)
