@tool
class_name TemplateExporter
extends RefCounted

# Associated serializer (can be null)
var _serializer: SerializationService = null

# Override these methods in child classes
func get_exporter_name() -> String:
	return "Base Exporter"

func get_default_extension() -> String:
	return ""

func get_supported_extensions() -> PackedStringArray:
	return PackedStringArray([])

func get_format_options() -> Array:
	# Return an array of dictionaries with options for the exporter
	# Each dictionary should have:
	# {
	#   "name": String,       # Name displayed in UI
	#   "property": String,   # Property name
	#   "type": int,          # Type (checkbox, dropdown, etc.)
	#   "value": Variant      # Default value
	# }
	return []

func export_templates(templates: TemplateDataStructure, file_path: String, options: Dictionary = {}) -> bool:
	# Export the templates to the specified file with the given options
	# Return true if successful, false otherwise
	return false

# Set serializer to use for this exporter
func set_serializer(serializer: SerializationService) -> void:
	_serializer = serializer

# Get the currently assigned serializer
func get_serializer() -> SerializationService:
	return _serializer

func get_file_filters() -> PackedStringArray:
	# Return file filters for the file dialog
	var extensions = get_supported_extensions()
	var filters = PackedStringArray()

	for ext in extensions:
		filters.append("*." + ext + " ; " + ext.to_upper() + " Files")

	return filters
