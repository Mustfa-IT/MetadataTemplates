@tool
class_name ValidationService
extends RefCounted

# Get service ID and name
func get_validator_id() -> String:
	return "abstract_validator"

func get_validator_name() -> String:
	return "Abstract Validator"

# Validate a template before saving
func validate_template(template_name: String, node_type: String, template_data: Dictionary) -> Dictionary:
	# Return a dictionary with {valid: bool, messages: Array, data: Dictionary}
	# If valid is true, data contains the (potentially modified) template
	# If valid is false, messages contains error messages
	return {
		"valid": true,
		"messages": [],
		"data": template_data
	}

# Validate templates on import
func validate_import(templates: TemplateDataStructure) -> Dictionary:
	return {
		"valid": true,
		"messages": [],
		"data": templates
	}

# Get configuration options
func get_configuration_options() -> Array:
	return []

# Get a UI for validator settings
func get_settings_ui() -> Control:
	return null
