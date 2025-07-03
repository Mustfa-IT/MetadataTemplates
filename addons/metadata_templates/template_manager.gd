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

var templates = {}
var template_file_path = TEMPLATES_DIR + TEMPLATES_FILE
var last_modified_time = 0
var file_check_timer: Timer = null
var file_watch_enabled = true

# Signal for when templates are reloaded from external changes
signal templates_reloaded

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

	# Setup file watching
	setup_file_watcher()

	# Store initial modification time
	update_last_modified_time()

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

	var file = FileAccess.open(template_file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json_parse = JSON.new()
		var parse_result = json_parse.parse(json_string)

		if parse_result == OK:
			print("Successfully loaded templates from disk")
			templates = json_parse.get_data()
			# Migrate if needed
			migrate_templates_if_needed()
			# Clean up empty types
			clean_empty_node_types()
			# Emit signal for listeners to update
			emit_signal("templates_reloaded")
		else:
			print("Error parsing templates file: ", json_parse.get_error_message())
			print("Error at line: ", json_parse.get_error_line())
			# Keep using existing templates without overwriting

		file.close()

	# Re-enable file watching
	file_watch_enabled = true

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
		else:
			print("Error parsing templates file: ", json_parse.get_error_message())
			print("Error at line: ", json_parse.get_error_line())
			templates = {}
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

	# Temporarily disable file watching to prevent recursive reload
	file_watch_enabled = false

	var file = FileAccess.open(template_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(templates, "  ")
		file.store_string(json_string)
		file.close()

		# Update the last modified time after saving
		update_last_modified_time()

	# Re-enable file watching
	file_watch_enabled = true

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

func apply_template_to_node(node: Node, node_type: String, template_name: String, clear_existing: bool = true) -> void:
	if not templates.has(node_type) or not templates[node_type].has(template_name):
		return

	var template = templates[node_type][template_name]

	# Clear existing metadata if requested
	if clear_existing:
		var existing_keys = node.get_meta_list()
		for key in existing_keys:
			node.remove_meta(key)

	# Check if this template extends another template
	var extends_template = null
	if template.has(EXTENDS_KEY) and template[EXTENDS_KEY] is Dictionary and template[EXTENDS_KEY].has("value"):
		extends_template = template[EXTENDS_KEY].value

	# Apply parent template first if it exists
	if extends_template != null and extends_template is String and extends_template != "":
		# Apply the parent template first (without clearing existing metadata)
		apply_template_to_node(node, node_type, extends_template, false)

	# Apply the template metadata (will override parent values if they exist)
	for key in template:
		# Skip the extends key, it's not actual metadata
		if key == EXTENDS_KEY:
			continue

		if template[key] is Dictionary and template[key].has("value"):
			# New format with type information
			node.set_meta(key, template[key].value)
		else:
			# Legacy format fallback
			node.set_meta(key, template[key])

# Helper function to get all template names for a node type, including inherited ones
func get_available_parent_templates(node_type: String, current_template: String = "") -> Array:
	var result = []

	if templates.has(node_type):
		# Add all templates for this node type except the current one
		for template_name in templates[node_type].keys():
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

	while current != "" and depth < max_depth:
		# If we found our starting template in the inheritance chain, we have a cycle
		if current == child_template:
			return true

		# Get the parent of current template
		var current_template = templates[node_type].get(current, {})
		if current_template.has(EXTENDS_KEY) and current_template[EXTENDS_KEY] is Dictionary and current_template[EXTENDS_KEY].has("value"):
			current = current_template[EXTENDS_KEY].value
		else:
			break

		depth += 1

	return false

# Get a template with all inherited properties merged in
func get_merged_template(node_type: String, template_name: String) -> Dictionary:
	if not templates.has(node_type) or not templates[node_type].has(template_name):
		return {}

	var template = templates[node_type][template_name]
	var result = {}

	# Check if this template extends another template
	var extends_template = null
	if template.has(EXTENDS_KEY) and template[EXTENDS_KEY] is Dictionary and template[EXTENDS_KEY].has("value"):
		extends_template = template[EXTENDS_KEY].value

	# Start with parent template properties if it exists
	if extends_template != null and extends_template is String and extends_template != "":
		result = get_merged_template(node_type, extends_template)

	# Override with this template's properties
	for key in template:
		if key != EXTENDS_KEY: # Skip the extends key
			result[key] = template[key]

	return result

# Create a node type entry if it doesn't exist, but don't save it until
# a template is actually created for it
func ensure_node_type_exists(node_type: String) -> void:
	if not templates.has(node_type):
		templates[node_type] = {}
	# Don't save yet - we'll only save when a template is created

func _notification(what):
	# Clean up the timer when this object is being freed
	if what == NOTIFICATION_PREDELETE:
		if file_check_timer and is_instance_valid(file_check_timer):
			file_check_timer.stop()
			file_check_timer.queue_free()
