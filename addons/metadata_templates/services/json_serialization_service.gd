@tool
class_name JSONSerializationService
extends SerializationService

# Configuration options
var pretty_print: bool = true
var indent_size: int = 2

func get_serializer_id() -> String:
	return "json"

func get_serializer_name() -> String:
	return "JSON Serializer"

func get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["json"])

func get_configuration_options() -> Array:
	return [
		{
			"name": "Pretty Print",
			"property": "pretty_print",
			"type": TYPE_BOOL,
			"default_value": true
		},
		{
			"name": "Indent Size",
			"property": "indent_size",
			"type": TYPE_INT,
			"default_value": 2,
			"min": 1,
			"max": 8
		}
	]

func serialize(data: Dictionary, options: Dictionary = {}) -> String:
	# Apply options
	var use_pretty_print = options.get("pretty_print", pretty_print)
	var use_indent_size = options.get("indent_size", indent_size)

	# Construct the indent string
	var indent = ""
	if use_pretty_print:
		for i in range(use_indent_size):
			indent += " "

	# Convert templates to JSON
	var json_string = ""
	if use_pretty_print:
		json_string = JSON.stringify(data, indent)
	else:
		json_string = JSON.stringify(data)

	return json_string

func deserialize(text: String, options: Dictionary = {}) -> Dictionary:
	# Parse the JSON
	var json = JSON.new()
	var error = json.parse(text)

	if error != OK:
		printerr("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return {}

	var data = json.data
	if not data is Dictionary:
		printerr("Expected Dictionary, got ", typeof(data))
		return {}

	return data

func initialize(settings: Dictionary = {}) -> bool:
	if settings.has("pretty_print"):
		pretty_print = settings.pretty_print
	if settings.has("indent_size"):
		indent_size = settings.indent_size
	return true
