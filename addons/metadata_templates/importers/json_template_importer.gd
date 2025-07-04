@tool
class_name JSONTemplateImporter
extends TemplateImporter

func get_importer_name() -> String:
	return "JSON Importer"

func get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["json"])

func validate_file(file_path: String) -> Dictionary:
	var result = {
		"valid": false,
		"error": "",
		"data": TemplateDataStructure.new()
	}

	# Check if the file exists
	if not FileAccess.file_exists(file_path):
		result.error = "File does not exist."
		return result

	# Try to open and read the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		result.error = "Could not open file for reading."
		return result

	# Read the file content
	var json_string = file.get_as_text()
	file.close()

	# Parse the JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		result.error = "Invalid JSON format: " + json.get_error_message() + " at line " + str(json.get_error_line())
		return result

	# Get the data
	var parsed_data = json.get_data()

	# Validate that it's a dictionary (expected format for templates)
	if not parsed_data is Dictionary:
		result.error = "File does not contain valid template data (expected a dictionary)."
		return result

	# Validate the structure of the templates
	for node_type in parsed_data.keys():
		if not parsed_data[node_type] is Dictionary:
			result.error = "Invalid template structure: Node type '" + node_type + "' is not a dictionary."
			return result

		for template_name in parsed_data[node_type].keys():
			if not parsed_data[node_type][template_name] is Dictionary:
				result.error = "Invalid template structure: Template '" + template_name + "' is not a dictionary."
				return result

	# Basic validation passed
	result.valid = true

	# Create and populate the template data structure
	var data_structure = TemplateDataStructure.new()
	data_structure.data = parsed_data.duplicate(true)
	result.data = data_structure

	return result

func import_file(file_path: String) -> TemplateDataStructure:
	var validation = validate_file(file_path)
	if validation.valid:
		return validation.data
	else:
		printerr("Failed to import templates: " + validation.error)
		return TemplateDataStructure.new()
