@tool
class_name TemplateDataStructure
extends RefCounted

# Types of metadata fields
const TYPE_STRING = 0
const TYPE_NUMBER = 1
const TYPE_BOOLEAN = 2
const TYPE_ARRAY = 3

# Special metadata keys
const EXTENDS_KEY = "_extends"

# The actual template data structure
var data: Dictionary = {}

# Get all node types
func get_node_types() -> Array:
	return data.keys()

# Check if node type exists
func has_node_type(node_type: String) -> bool:
	return data.has(node_type)

# Get all templates for a node type
func get_templates_for_node_type(node_type: String) -> Dictionary:
	if data.has(node_type):
		return data[node_type]
	return {}

# Get a specific template
func get_template(node_type: String, template_name: String) -> Dictionary:
	if data.has(node_type) and data[node_type].has(template_name):
		return data[node_type][template_name]
	return {}

# Add or update a template
func set_template(node_type: String, template_name: String, template_data: Dictionary) -> void:
	if not data.has(node_type):
		data[node_type] = {}
	data[node_type][template_name] = template_data

# Delete a template
func delete_template(node_type: String, template_name: String) -> bool:
	if data.has(node_type) and data[node_type].has(template_name):
		data[node_type].erase(template_name)
		# Remove the node type if it's empty
		if data[node_type].is_empty():
			data.erase(node_type)
		return true
	return false

# Support for dictionary-like 'has' method
# This is needed for compatibility with code that expects dictionary behavior
func has(key: String) -> bool:
	return data.has(key)

# Check if a template exists for a specific node type
func has_template(node_type: String, template_name: String) -> bool:
	if data.has(node_type):
		return data[node_type].has(template_name)
	return false

# Create a deep copy of this data structure
func duplicate() -> TemplateDataStructure:
	var copy = TemplateDataStructure.new()
	copy.data = data.duplicate(true)
	return copy

# Check if a template is empty
func is_empty() -> bool:
	return data.is_empty()

# Clear all templates
func clear() -> void:
	data.clear()

# Merge with another template data structure
func merge_with(other: TemplateDataStructure, strategy: int = 0) -> void:
	match strategy:
		0: # Replace All
			data = other.data.duplicate(true)

		1: # Keep Existing (only add new)
			for node_type in other.data:
				if not data.has(node_type):
					data[node_type] = {}

				for template_name in other.data[node_type]:
					if not data[node_type].has(template_name):
						data[node_type][template_name] = other.data[node_type][template_name].duplicate(true)

		2: # Replace Node Types
			for node_type in other.data:
				data[node_type] = other.data[node_type].duplicate(true)

# Count total number of templates
func count_templates() -> int:
	var count = 0
	for node_type in data:
		count += data[node_type].size()
	return count

# Clean empty node types
func clean_empty_node_types() -> void:
	var empty_types = []
	for node_type in data:
		if data[node_type].is_empty():
			empty_types.append(node_type)

	for node_type in empty_types:
		data.erase(node_type)
