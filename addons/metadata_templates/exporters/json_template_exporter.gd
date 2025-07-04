@tool
class_name JSONTemplateExporter
extends TemplateExporter

func get_exporter_name() -> String:
	return "JSON Exporter"

func get_default_extension() -> String:
	return "json"

func get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["json"])

func get_format_options() -> Array:
	return [
		{
			"name": "Pretty Print",
			"property": "pretty_print",
			"type": TYPE_BOOL,
			"value": true
		},
		{
			"name": "Indent Size",
			"property": "indent_size",
			"type": TYPE_INT,
			"value": 2,
			"min": 1,
			"max": 8
		}
	]

func export_templates(templates: Dictionary, file_path: String, options: Dictionary = {}) -> bool:
	# Apply default options if not provided
	var pretty_print = options.get("pretty_print", true)
	var indent_size = options.get("indent_size", 2)

	# Construct the indent string
	var indent = ""
	if pretty_print:
		for i in range(indent_size):
			indent += " "

	# Try to write the file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open file for writing: " + file_path)
		return false

	# Convert templates to JSON
	var json_string = ""
	if pretty_print:
		json_string = JSON.stringify(templates, indent)
	else:
		json_string = JSON.stringify(templates)

	# Write to file
	file.store_string(json_string)
	file.close()

	return true
