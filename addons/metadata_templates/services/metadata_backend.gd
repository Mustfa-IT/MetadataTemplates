@tool
class_name MetadataBackend
extends RefCounted

# Backend capabilities
const CAPABILITY_READ = 1 << 0
const CAPABILITY_WRITE = 1 << 1
const CAPABILITY_LIST = 1 << 2
const CAPABILITY_DELETE = 1 << 3
const CAPABILITY_WATCH = 1 << 4
const CAPABILITY_REMOTE = 1 << 5

# Signal for when templates are modified externally
signal templates_modified(templates)

# Backend ID and friendly name
func get_backend_id() -> String:
	return "abstract_backend"

func get_backend_name() -> String:
	return "Abstract Backend"

# Get capabilities of this backend
func get_capabilities() -> int:
	# Default to read-only
	return CAPABILITY_READ

# Check if backend has specific capability
func has_capability(capability: int) -> bool:
	return (get_capabilities() & capability) == capability

# Get configuration options for this backend
# Returns array of dictionaries with {name, property, type, default_value}
func get_configuration_options() -> Array:
	return []

# Load templates from the backend
func load_templates() -> TemplateDataStructure:
	push_error("Abstract method: load_templates() must be implemented by subclass")
	return TemplateDataStructure.new()

# Save templates to the backend
func save_templates(templates: TemplateDataStructure) -> bool:
	push_error("Abstract method: save_templates() must be implemented by subclass")
	return false

# Watch for changes (if supported)
func start_watching() -> void:
	pass

func stop_watching() -> void:
	pass

# Get a UI representation for the backend settings
# Returns a Control that will be shown in the settings panel
func get_settings_ui() -> Control:
	return null

# Initialize the backend with configuration
func initialize(config: Dictionary = {}) -> bool:
	return true
