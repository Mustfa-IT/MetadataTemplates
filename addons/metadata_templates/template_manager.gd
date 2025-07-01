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

var templates = {}
var template_file_path = TEMPLATES_DIR + TEMPLATES_FILE

func initialize() -> void:
	# Create templates directory if it doesn't exist
	var dir = DirAccess.open("res://addons/metadata_templates")
	if dir:
		if not dir.dir_exists("templates"):
			dir.make_dir("templates")

	# Load existing templates
	load_templates()

	# Clean up any empty node types
	clean_empty_node_types()

func load_templates() -> void:
	var file = FileAccess.open(template_file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json_parse = JSON.new()
		var parse_result = json_parse.parse(json_string)
		if parse_result == OK:
			templates = json_parse.get_data()
			# Migrate old format templates to new format if needed
			migrate_templates_if_needed()
		file.close()
	else:
		# Initialize with empty templates if file doesn't exist
		templates = {}
		save_templates()

func migrate_templates_if_needed() -> void:
	# Check if templates need to be migrated to the new format with type information
	var needs_migration = false

	for node_type in templates.keys():
		for template_name in templates[node_type].keys():
			var template = templates[node_type][template_name]
			for key in template.keys():
				if not template[key] is Dictionary or not template[key].has("type"):
					needs_migration = true
					break
			if needs_migration:
				break
		if needs_migration:
			break

	# If needed, migrate the templates to include type information
	if needs_migration:
		print("Migrating templates to include type information")
		var migrated_templates = {}

		for node_type in templates.keys():
			migrated_templates[node_type] = {}
			for template_name in templates[node_type].keys():
				migrated_templates[node_type][template_name] = {}
				var template = templates[node_type][template_name]
				for key in template.keys():
					var value = template[key]
					var type = TYPE_STRING

					if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
						type = TYPE_NUMBER
					elif typeof(value) == TYPE_BOOL:
						type = TYPE_BOOLEAN
					elif typeof(value) == TYPE_ARRAY:
						type = TYPE_ARRAY

					migrated_templates[node_type][template_name][key] = {
						"value": value,
						"type": type
					}

		templates = migrated_templates
		save_templates()

func save_templates() -> void:
	# Clean empty node types before saving
	clean_empty_node_types()

	var file = FileAccess.open(template_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(templates, "  ")
		file.store_string(json_string)
		file.close()

# Remove any node types that have no templates
func clean_empty_node_types() -> void:
	var empty_types = []

	# Find all empty node types
	for node_type in templates.keys():
		if templates[node_type].is_empty():
			empty_types.append(node_type)

	# Remove the empty node types
	for node_type in empty_types:
		templates.erase(node_type)

func create_template(template_name: String, node_type: String, metadata: Dictionary) -> void:
	if not templates.has(node_type):
		templates[node_type] = {}

	templates[node_type][template_name] = metadata
	save_templates()

func delete_template(node_type: String, template_name: String) -> void:
	if templates.has(node_type) and templates[node_type].has(template_name):
		templates[node_type].erase(template_name)

		# If this was the last template for this node type, remove the node type
		if templates[node_type].is_empty():
			templates.erase(node_type)

		save_templates()

func get_templates_for_node_type(node_type: String) -> Dictionary:
	if templates.has(node_type):
		return templates[node_type]
	return {}

func get_all_node_types() -> Array:
	return templates.keys()

func apply_template_to_node(node: Node, node_type: String, template_name: String) -> void:
	if not templates.has(node_type) or not templates[node_type].has(template_name):
		return

	var template = templates[node_type][template_name]

	# Clear existing metadata first if requested
	# (This could be optional based on user preference)
	var existing_keys = node.get_meta_list()
	for key in existing_keys:
		node.remove_meta(key)

	# Apply the template metadata
	for key in template:
		if template[key] is Dictionary and template[key].has("value"):
			# New format with type information
			node.set_meta(key, template[key].value)
		else:
			# Legacy format fallback
			node.set_meta(key, template[key])

# Create a node type entry if it doesn't exist, but don't save it until
# a template is actually created for it
func ensure_node_type_exists(node_type: String) -> void:
	if not templates.has(node_type):
		templates[node_type] = {}
	# Don't save yet - we'll only save when a template is created
