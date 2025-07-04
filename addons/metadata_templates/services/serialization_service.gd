@tool
class_name SerializationService
extends RefCounted

# Signal when serialization settings are changed
signal settings_changed

# Get service ID and name
func get_serializer_id() -> String:
	return "abstract_serializer"

func get_serializer_name() -> String:
	return "Abstract Serializer"

# Get supported file extensions
func get_supported_extensions() -> PackedStringArray:
	return PackedStringArray([])

# Get configuration options
func get_configuration_options() -> Array:
	return []

# Serialize data to string
func serialize(data: Dictionary, options: Dictionary = {}) -> String:
	push_error("Abstract method: serialize() must be implemented by subclass")
	return ""

# Deserialize string to data
func deserialize(text: String, options: Dictionary = {}) -> Dictionary:
	push_error("Abstract method: deserialize() must be implemented by subclass")
	return {}

# Get file filters for open/save dialogs
func get_file_filters() -> PackedStringArray:
	var extensions = get_supported_extensions()
	var filters = PackedStringArray()

	for ext in extensions:
		filters.append("*." + ext + " ; " + ext.to_upper() + " Files")

	return filters

# Get a UI for serializer-specific settings
func get_settings_ui() -> Control:
	return null

# Initialize with settings
func initialize(settings: Dictionary = {}) -> bool:
	return true
