@tool
class_name TemplateManager
extends RefCounted

const TEMPLATES_DIR = "res://addons/metadata_templates/templates/"
const TEMPLATES_FILE = "templates.json"

# Type constants
const TYPE_STRING = 0
const TYPE_NUMBER = 1
const TYPE_BOOLEAN = 2
const TYPE_ARRAY = 3

# Special metadata keys
const EXTENDS_KEY = "_extends"

# Import/Export constants (for backward compatibility)
const MERGE_REPLACE_ALL = 0
const MERGE_KEEP_EXISTING = 1
const MERGE_REPLACE_NODE_TYPES = 2

var templates = TemplateDataStructure.new()
var template_file_path = TEMPLATES_DIR + TEMPLATES_FILE
var last_modified_time = 0
var file_check_timer: Timer = null
var file_watch_enabled = true

# Available importers and exporters
var importers = {}
var exporters = {}
var default_importer = null
var default_exporter = null

# Service registry and backends
var service_registry: MetadataServiceRegistry = null
var _active_backend: MetadataBackend = null
var _initialized: bool = false

# Signal for when templates are reloaded from external changes
signal templates_reloaded

func initialize() -> void:
	# Create templates directory if it doesn't exist
	var dir = DirAccess.open("res://addons/metadata_templates")
	if dir:
		if not dir.dir_exists("templates"):
			dir.make_dir("templates")
		if not dir.dir_exists("importers"):
			dir.make_dir("importers")
		if not dir.dir_exists("exporters"):
			dir.make_dir("exporters")
		if not dir.dir_exists("data"):
			dir.make_dir("data")

	# Initialize service registry
	_init_service_registry()

	# Register default backend and serializer
	_register_default_services()

	# Register importers and exporters (legacy)
	_register_importers_and_exporters()

	# Try loading templates through backend
	if _active_backend:
		templates = _active_backend.load_templates()

		# Connect to backend's templates_modified signal
		if not _active_backend.is_connected("templates_modified", _on_backend_templates_modified):
			_active_backend.connect("templates_modified", _on_backend_templates_modified)
	else:
		# Fall back to legacy loading
		load_templates()

	# Clean up any empty node types
	templates.clean_empty_node_types()

	# Only set up legacy file watcher if no backend or backend doesn't support watching
	if not _active_backend or not _active_backend.has_capability(MetadataBackend.CAPABILITY_WATCH):
		# Setup file watching
		setup_file_watcher()

	# Store initial modification time
	update_last_modified_time()

	_initialized = true

func _init_service_registry() -> void:
	if not service_registry:
		service_registry = MetadataServiceRegistry.new()

		# Connect to signals
		service_registry.connect("active_service_changed", _on_active_service_changed)

func _register_default_services() -> void:
	# Create and register the default JSON serializer
	var json_serializer = JSONSerializationService.new()
	service_registry.register_service(MetadataServiceRegistry.SERVICE_SERIALIZER, "json", json_serializer)

	# Create and register the local JSON backend with the serializer
	var local_backend = LocalJSONBackend.new()
	local_backend.initialize({
		"templates_dir": TEMPLATES_DIR,
		"templates_file": TEMPLATES_FILE,
		"serializer": json_serializer
	})
	service_registry.register_service(MetadataServiceRegistry.SERVICE_BACKEND, "local_json", local_backend)

	# Set active backend
	_active_backend = service_registry.get_active_service(MetadataServiceRegistry.SERVICE_BACKEND)

func _on_active_service_changed(type: String, id: String, service) -> void:
	if type == MetadataServiceRegistry.SERVICE_BACKEND:
		# Clean up old backend
		if _active_backend and _active_backend.is_connected("templates_modified", _on_backend_templates_modified):
			_active_backend.disconnect("templates_modified", _on_backend_templates_modified)
			if _active_backend.has_capability(MetadataBackend.CAPABILITY_WATCH):
				_active_backend.stop_watching()

		# Set new backend
		_active_backend = service

		if _active_backend:
			# Connect to new backend's signals
			if not _active_backend.is_connected("templates_modified", _on_backend_templates_modified):
				_active_backend.connect("templates_modified", _on_backend_templates_modified)

			# Load templates from new backend
			templates = _active_backend.load_templates()
			emit_signal("templates_reloaded")

			# Start watching if supported
			if _active_backend.has_capability(MetadataBackend.CAPABILITY_WATCH):
				_active_backend.start_watching()

func _on_backend_templates_modified(new_templates: TemplateDataStructure) -> void:
	templates = new_templates
	emit_signal("templates_reloaded")

func _register_importers_and_exporters() -> void:
	# Register importers
	var json_importer = JSONTemplateImporter.new()
	importers["json"] = json_importer
	default_importer = json_importer

	# Register exporters
	var json_exporter = JSONTemplateExporter.new()
	exporters["json"] = json_exporter
	default_exporter = json_exporter

# Legacy file watching code - kept for backward compatibility
func setup_file_watcher() -> void:
	# Create a timer for checking file changes
	file_check_timer = Timer.new()
	file_check_timer.wait_time = 2.0 # Check every 2 seconds
	file_check_timer.one_shot = false
	file_check_timer.autostart = true

	# Add the timer to the scene tree through EditorPlugin's process
	var editor = Engine.get_main_loop().get_root().get_child(0)
	editor.add_child(file_check_timer)

	# Connect the timer's timeout signal
	file_check_timer.connect("timeout", check_file_changes)

	print("Template file watcher initialized")

func update_last_modified_time() -> void:
	var file = FileAccess.open(template_file_path, FileAccess.READ)
	if file:
		file.close()
		var file_info = FileAccess.get_modified_time(template_file_path)
		if file_info > 0:
			last_modified_time = file_info

func check_file_changes() -> void:
	if not file_watch_enabled:
		return

	# Check if the file exists
	if not FileAccess.file_exists(template_file_path):
		return

	# Get current modification time
	var current_modified_time = FileAccess.get_modified_time(template_file_path)

	# If the file was modified since we last checked
	if current_modified_time != last_modified_time and current_modified_time > 0:
		print("Templates file changed externally - reloading")
		# Update last modified time
		last_modified_time = current_modified_time
		# Reload templates
		reload_templates_from_disk()

func reload_templates_from_disk() -> void:
	# Temporarily disable file watching to prevent recursive reloads
	file_watch_enabled = false

	# Use the appropriate importer based on file extension
	var file_extension = template_file_path.get_extension().to_lower()
	var importer = importers.get(file_extension, default_importer)

	if importer:
		var imported_templates = importer.import_file(template_file_path)
		if not imported_templates.is_empty():
			print("Successfully loaded templates from disk")
			templates = imported_templates
				# Clean up empty types
			templates.clean_empty_node_types()
			# Emit signal for listeners to update
			emit_signal("templates_reloaded")
		else:
			print("Failed to load templates or file was empty")
	else:
		printerr("No suitable importer found for file extension: " + file_extension)

	# Re-enable file watching
	file_watch_enabled = true

func load_templates() -> void:
	# Try to load templates through backend if available
	if _active_backend:
		var loaded_templates = _active_backend.load_templates()
		if not loaded_templates.is_empty():
			templates = loaded_templates
			return

	# Fall back to legacy loading if no backend or backend failed
	var file_extension = template_file_path.get_extension().to_lower()
	var importer = importers.get(file_extension, default_importer)

	if importer:
		var imported_templates = importer.import_file(template_file_path)
		if not imported_templates.is_empty():
			templates = imported_templates
		else:
			# Initialize with empty templates if file doesn't exist or is empty
			templates = TemplateDataStructure.new()
			save_templates()
	else:
		printerr("No suitable importer found for file extension: " + file_extension)
		templates = TemplateDataStructure.new()
		save_templates()

func save_templates() -> void:
	# Clean empty node types before saving
	templates.clean_empty_node_types()

	# Try to save templates through backend if available
	if _active_backend and _active_backend.has_capability(MetadataBackend.CAPABILITY_WRITE):
		if _active_backend.save_templates(templates):
			# Update the last modified time after saving if not using backend's watch capability
			if not _active_backend.has_capability(MetadataBackend.CAPABILITY_WATCH):
				update_last_modified_time()
			return

	# Fall back to legacy saving
	# Temporarily disable file watching to prevent recursive reload
	file_watch_enabled = false

	# Use the appropriate exporter based on file extension
	var file_extension = template_file_path.get_extension().to_lower()
	var exporter = exporters.get(file_extension, default_exporter)

	if exporter:
		var success = exporter.export_templates(templates, template_file_path)
		if success:
			# Update the last modified time after saving
			update_last_modified_time()
		else:
			printerr("Failed to save templates to: " + template_file_path)
	else:
		printerr("No suitable exporter found for file extension: " + file_extension)

	# Re-enable file watching
	file_watch_enabled = true

func create_template(template_name: String, node_type: String, metadata: Dictionary) -> void:
	templates.set_template(node_type, template_name, metadata)
	save_templates()

func delete_template(node_type: String, template_name: String) -> void:
	if templates.delete_template(node_type, template_name):
		save_templates()

func get_templates_for_node_type(node_type: String) -> Dictionary:
	return templates.get_templates_for_node_type(node_type)

func get_all_node_types() -> Array:
	return templates.get_node_types()

func apply_template_to_node(node: Node, node_type: String, template_name: String, clear_existing: bool = true) -> void:
	var template_data = templates.get_template(node_type, template_name)
	if template_data.is_empty():
		return

	# Clear existing metadata if requested
	if clear_existing:
		var existing_keys = node.get_meta_list()
		for key in existing_keys:
			node.remove_meta(key)

	# Check if this template extends another template
	var extends_template = null
	if template_data.has(EXTENDS_KEY) and template_data[EXTENDS_KEY] is Dictionary and template_data[EXTENDS_KEY].has("value"):
		extends_template = template_data[EXTENDS_KEY].value

	# Apply parent template first if it exists
	if extends_template != null and extends_template is String and extends_template != "":
		# Apply the parent template first (without clearing existing metadata)
		apply_template_to_node(node, node_type, extends_template, false)

	# Apply the template metadata (will override parent values if they exist)
	for key in template_data:
		# Skip the extends key, it's not actual metadata
		if key == EXTENDS_KEY:
			continue

		if template_data[key] is Dictionary and template_data[key].has("value"):
			# New format with type information
			node.set_meta(key, template_data[key].value)
		else:
			# Legacy format fallback
			node.set_meta(key, template_data[key])

	# Add template tracking metadata
	node.set_meta("_template_name", template_name)
	node.set_meta("_template_type", node_type)

# Helper function to get all template names for a node type, including inherited ones
func get_available_parent_templates(node_type: String, current_template: String = "") -> Array:
	var result = []
	var node_templates = templates.get_templates_for_node_type(node_type)

	for template_name in node_templates.keys():
		if template_name != current_template:
			# Check for circular inheritance
			if not would_cause_circular_inheritance(node_type, current_template, template_name):
				result.append(template_name)

	return result

# Check if adding a parent would cause circular inheritance
func would_cause_circular_inheritance(node_type: String, child_template: String, parent_template: String) -> bool:
	# If we're not currently editing a template, there's no risk of circular inheritance
	if child_template.is_empty():
		return false

	var current = parent_template
	var max_depth = 20 # Safety limit for recursion
	var depth = 0
	var node_templates = templates.get_templates_for_node_type(node_type)

	while current != "" and depth < max_depth:
		# If we found our starting template in the inheritance chain, we have a cycle
		if current == child_template:
			return true

		# Get the parent of current template
		var current_template_data = node_templates.get(current, {})
		if current_template_data.has(EXTENDS_KEY) and current_template_data[EXTENDS_KEY] is Dictionary and current_template_data[EXTENDS_KEY].has("value"):
			current = current_template_data[EXTENDS_KEY].value
		else:
			break

		depth += 1

	return false

# Get a template with all inherited properties merged in
func get_merged_template(node_type: String, template_name: String) -> Dictionary:
	var template_data = templates.get_template(node_type, template_name)
	if template_data.is_empty():
		return {}

	var result = {}

	# Check if this template extends another template
	var extends_template = null
	if template_data.has(EXTENDS_KEY) and template_data[EXTENDS_KEY] is Dictionary and template_data[EXTENDS_KEY].has("value"):
		extends_template = template_data[EXTENDS_KEY].value

	# Start with parent template properties if it exists
	if extends_template != null and extends_template is String and extends_template != "":
		result = get_merged_template(node_type, extends_template)

	# Override with this template's properties
	for key in template_data:
		if key != EXTENDS_KEY: # Skip the extends key
			result[key] = template_data[key]

	return result

# Create a node type entry if it doesn't exist, but don't save it until
# a template is actually created for it
func ensure_node_type_exists(node_type: String) -> void:
	templates.set_template(node_type, "", {})

# Export templates to a file using the appropriate exporter
func export_templates_to_file(file_path: String, options: Dictionary = {}) -> bool:
	# Clean empty node types before exporting
	templates.clean_empty_node_types()

	# Determine the exporter based on file extension
	var file_extension = file_path.get_extension().to_lower()
	var exporter = exporters.get(file_extension, default_exporter)

	if exporter:
		return exporter.export_templates(templates, file_path, options)
	else:
		printerr("No suitable exporter found for file extension: " + file_extension)
		return false

# Validate that a file contains valid template data using the appropriate importer
func validate_templates_file(file_path: String) -> Dictionary:
	# Determine the importer based on file extension
	var file_extension = file_path.get_extension().to_lower()
	var importer = importers.get(file_extension, default_importer)

	if importer:
		return importer.validate_file(file_path)
	else:
		return {
			"valid": false,
			"error": "No suitable importer found for file extension: " + file_extension,
			"data": null
		}

# Import templates from a file using the appropriate importer
func import_templates_from_file(file_path: String, merge_strategy: int = MERGE_REPLACE_ALL) -> Dictionary:
	var result = {
		"success": false,
		"error": "",
		"imported_count": 0
	}

	# Validate the file using the appropriate importer
	var file_extension = file_path.get_extension().to_lower()
	var importer = importers.get(file_extension, default_importer)

	if not importer:
		result.error = "No suitable importer found for file extension: " + file_extension
		return result

	var validation = importer.validate_file(file_path)
	if not validation.valid:
		result.error = validation.error
		return result

	# Get the templates from the file
	var imported_templates = validation.data

	# Apply the merge strategy using the importer's implementation
	templates = importer.apply_templates(imported_templates, templates, merge_strategy)

	# Count imported templates
	result.imported_count = importer.count_templates(imported_templates)

	# Save the updated templates
	save_templates()

	result.success = true
	return result

# Get a list of available importers
func get_available_importers() -> Dictionary:
	var result = {}
	for key in importers.keys():
		result[key] = importers[key].get_importer_name()
	return result

# Get a list of available exporters
func get_available_exporters() -> Dictionary:
	var result = {}
	for key in exporters.keys():
		result[key] = exporters[key].get_exporter_name()
	return result

# Get file filters for import dialog
func get_import_file_filters() -> PackedStringArray:
	var filters = PackedStringArray()
	for importer_key in importers.keys():
		var importer = importers[importer_key]
		var extensions = importer.get_supported_extensions()
		for ext in extensions:
			filters.append("*." + ext + " ; " + ext.to_upper() + " Files")
	return filters

# Get file filters for export dialog
func get_export_file_filters() -> PackedStringArray:
	var filters = PackedStringArray()
	for exporter_key in exporters.keys():
		var exporter = exporters[exporter_key]
		var extensions = exporter.get_supported_extensions()
		for ext in extensions:
			filters.append("*." + ext + " ; " + ext.to_upper() + " Files")
	return filters

# Function to check if a backend exists and is active
func has_active_backend() -> bool:
	return _active_backend != null

# Get available backends
func get_available_backends() -> Dictionary:
	var backends = {}
	var backend_services = service_registry.get_services(MetadataServiceRegistry.SERVICE_BACKEND)

	for id in backend_services:
		var backend = backend_services[id]
		backends[id] = backend.get_backend_name()

	return backends

# Switch to a different backend
func switch_backend(backend_id: String) -> bool:
	if service_registry.has_service(MetadataServiceRegistry.SERVICE_BACKEND, backend_id):
		return service_registry.set_active_service(MetadataServiceRegistry.SERVICE_BACKEND, backend_id)
	return false

# Register a backend
func register_backend(backend_id: String, backend: MetadataBackend) -> bool:
	return service_registry.register_service(MetadataServiceRegistry.SERVICE_BACKEND, backend_id, backend)

# Register a serializer
func register_serializer(serializer_id: String, serializer: SerializationService) -> bool:
	return service_registry.register_service(MetadataServiceRegistry.SERVICE_SERIALIZER, serializer_id, serializer)

# Register a validator
func register_validator(validator_id: String, validator: ValidationService) -> bool:
	return service_registry.register_service(MetadataServiceRegistry.SERVICE_VALIDATOR, validator_id, validator)

# Clean up resources when this object is destroyed
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Clean up file timer
		if file_check_timer and is_instance_valid(file_check_timer):
			file_check_timer.stop()
			file_check_timer.queue_free()

		# Clean up backend if it supports watching
		if _active_backend and _active_backend.has_capability(MetadataBackend.CAPABILITY_WATCH):
			_active_backend.stop_watching()
