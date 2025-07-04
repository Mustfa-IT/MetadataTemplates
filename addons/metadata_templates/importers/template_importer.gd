@tool
class_name TemplateImporter
extends RefCounted

# Import strategy constants (shared across all importers)
const MERGE_REPLACE_ALL = 0
const MERGE_KEEP_EXISTING = 1
const MERGE_REPLACE_NODE_TYPES = 2

# Signal emitted when validation is complete
signal validation_completed(result)

# Override these methods in child classes
func get_importer_name() -> String:
	return "Base Importer"

func get_supported_extensions() -> PackedStringArray:
	return PackedStringArray([])

func validate_file(file_path: String) -> Dictionary:
	# Should return a dictionary with:
	# {
	#   "valid": bool,
	#   "error": String,
	#   "data": Dictionary (parsed template data)
	# }
	return {
		"valid": false,
		"error": "Not implemented in base class",
		"data": {}
	}

func import_file(file_path: String) -> Dictionary:
	# Should return the template data structure
	return {}

# Apply the imported templates based on merge strategy
func apply_templates(imported_templates: Dictionary, existing_templates: Dictionary, merge_strategy: int) -> Dictionary:
	var result = existing_templates.duplicate(true)

	match merge_strategy:
		MERGE_REPLACE_ALL:
			# Replace all templates
			result = imported_templates

		MERGE_KEEP_EXISTING:
			# Only add new templates, keep existing ones
			for node_type in imported_templates:
				if not result.has(node_type):
					result[node_type] = {}

				for template_name in imported_templates[node_type]:
					if not result[node_type].has(template_name):
						result[node_type][template_name] = imported_templates[node_type][template_name]

		MERGE_REPLACE_NODE_TYPES:
			# Replace node types found in the import, but keep others
			for node_type in imported_templates:
				result[node_type] = imported_templates[node_type]

	return result

# Count the number of templates in the import
func count_templates(templates: Dictionary) -> int:
	var count = 0
	for node_type in templates:
		count += templates[node_type].size()
	return count

# Preview the result of applying the merge strategy
func preview_merge(imported_templates: Dictionary, existing_templates: Dictionary, merge_strategy: int) -> Dictionary:
	var preview = {
		"added": [], # New templates that will be added
		"modified": [], # Existing templates that will be modified
		"removed": [], # Existing templates that will be removed
		"unchanged": [] # Existing templates that won't change
	}

	match merge_strategy:
		MERGE_REPLACE_ALL:
			# All existing templates removed, all imported templates added
			for node_type in existing_templates:
				for template_name in existing_templates[node_type]:
					if imported_templates.has(node_type) and imported_templates[node_type].has(template_name):
						preview.modified.append({
							"node_type": node_type,
							"template_name": template_name
						})
					else:
						preview.removed.append({
							"node_type": node_type,
							"template_name": template_name
						})

			for node_type in imported_templates:
				for template_name in imported_templates[node_type]:
					if not (existing_templates.has(node_type) and existing_templates[node_type].has(template_name)):
						preview.added.append({
							"node_type": node_type,
							"template_name": template_name
						})

		MERGE_KEEP_EXISTING:
			# Only add new templates, keep existing ones
			for node_type in imported_templates:
				for template_name in imported_templates[node_type]:
					if existing_templates.has(node_type) and existing_templates[node_type].has(template_name):
						preview.unchanged.append({
							"node_type": node_type,
							"template_name": template_name
						})
					else:
						preview.added.append({
							"node_type": node_type,
							"template_name": template_name
						})

			# All existing templates are kept
			for node_type in existing_templates:
				for template_name in existing_templates[node_type]:
					if not (imported_templates.has(node_type) and imported_templates[node_type].has(template_name)):
						preview.unchanged.append({
							"node_type": node_type,
							"template_name": template_name
						})

		MERGE_REPLACE_NODE_TYPES:
			# Replace node types found in the import
			for node_type in imported_templates:
				for template_name in imported_templates[node_type]:
					if existing_templates.has(node_type) and existing_templates[node_type].has(template_name):
						preview.modified.append({
							"node_type": node_type,
							"template_name": template_name
						})
					else:
						preview.added.append({
							"node_type": node_type,
							"template_name": template_name
						})

				# Existing templates of this node type that aren't in the import will be removed
				if existing_templates.has(node_type):
					for template_name in existing_templates[node_type]:
						if not imported_templates[node_type].has(template_name):
							preview.removed.append({
								"node_type": node_type,
								"template_name": template_name
							})

			# Existing node types not in the import remain unchanged
			for node_type in existing_templates:
				if not imported_templates.has(node_type):
					for template_name in existing_templates[node_type]:
						preview.unchanged.append({
							"node_type": node_type,
							"template_name": template_name
						})

	return preview
