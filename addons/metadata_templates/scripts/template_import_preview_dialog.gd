@tool
class_name TemplateImportPreviewDialog
extends Window

signal import_confirmed(path, merge_strategy)
signal import_canceled

var template_manager: RefCounted
var import_path: String
var imported_templates: Dictionary = {}
var existing_templates: Dictionary = {}

@onready var tree_view = $MainContainer/HSplitContainer/LeftPanel/TemplateTree
@onready var details_panel = $MainContainer/HSplitContainer/RightPanel/DetailPanel
@onready var template_details = $MainContainer/HSplitContainer/RightPanel/DetailPanel/ScrollContainer/TemplateDetails
@onready var status_label = $MainContainer/StatusBar/StatusLabel
@onready var count_label = $MainContainer/StatusBar/CountLabel
@onready var merge_option = $MainContainer/BottomPanel/MergeOptions
@onready var strategy_description = $MainContainer/BottomPanel/StrategyDescription

# Template status indicators
const STATUS_NEW = 0
const STATUS_OVERWRITE = 1
const STATUS_UNCHANGED = 2
const STATUS_KEEP = 3
const STATUS_REMOVE = 4

# Icons for different statuses
var icon_new: Texture2D
var icon_overwrite: Texture2D
var icon_unchanged: Texture2D
var icon_kept: Texture2D
var icon_removed: Texture2D

# Current merge strategy
var current_merge_strategy: int = 0

# Strategy descriptions
const STRATEGY_DESCRIPTIONS = {
		0: "Replace All Templates: All existing templates will be removed and replaced with imported templates.",
		1: "Keep Existing Templates: Only add new templates, keeping all existing templates unchanged.",
		2: "Replace Node Types: Replace templates for node types found in the import file, but keep other node types."
}

# Update constants for merge strategies to use the importer's constants
const MERGE_REPLACE_ALL = TemplateImporter.MERGE_REPLACE_ALL
const MERGE_KEEP_EXISTING = TemplateImporter.MERGE_KEEP_EXISTING
const MERGE_REPLACE_NODE_TYPES = TemplateImporter.MERGE_REPLACE_NODE_TYPES

func _ready() -> void:
		# Set window properties
		title = "Template Import Preview"
		size = Vector2i(900, 600)
		min_size = Vector2i(700, 500)
		exclusive = false
		transient = true

		# Load icons
		icon_new = get_theme_icon("Add", "EditorIcons")
		icon_overwrite = get_theme_icon("Reload", "EditorIcons")
		icon_unchanged = get_theme_icon("File", "EditorIcons")
		icon_kept = get_theme_icon("Lock", "EditorIcons")
		icon_removed = get_theme_icon("Remove", "EditorIcons")

		# Connect signals
		tree_view.connect("item_selected", _on_template_selected)
		$MainContainer/BottomPanel/ImportButton.connect("pressed", _on_import_button_pressed)
		$MainContainer/BottomPanel/CancelButton.connect("pressed", _on_cancel_button_pressed)
		merge_option.connect("item_selected", _on_merge_strategy_changed)

		# Connect close request
		connect("close_requested", _on_close_requested)

func setup(manager: RefCounted, path: String) -> void:
		template_manager = manager
		import_path = path

		# Determine the appropriate importer based on file extension
		var file_extension = path.get_extension().to_lower()
		var importers = template_manager.get_available_importers()

		# Set default merge strategy
		current_merge_strategy = MERGE_REPLACE_ALL

		# Load templates
		_load_templates()

		# Initialize merge options
		_init_merge_options()

		# Populate the tree
		_populate_tree()

		# Update status
		_update_status()

		# Update the window title to include the format
		if importers.has(file_extension):
				title = "Template Import Preview - " + importers[file_extension]
		else:
				title = "Template Import Preview"

func _load_templates() -> void:
		# Get existing templates
		if template_manager:
				existing_templates = template_manager.templates.duplicate(true)
		else:
				existing_templates = {}

		# Load imported templates
		var validation = template_manager.validate_templates_file(import_path)
		if validation.valid:
				imported_templates = validation.data
		else:
				imported_templates = {}

func _init_merge_options() -> void:
		merge_option.clear()
		merge_option.add_item("Replace All Templates", template_manager.MERGE_REPLACE_ALL)
		merge_option.add_item("Only Add New Templates (Keep Existing)", template_manager.MERGE_KEEP_EXISTING)
		merge_option.add_item("Replace Node Types (Keep Non-Conflicting Types)", template_manager.MERGE_REPLACE_NODE_TYPES)
		merge_option.select(0)

		# Set initial strategy description
		strategy_description.text = STRATEGY_DESCRIPTIONS[current_merge_strategy]

func _populate_tree() -> void:
		tree_view.clear()

		# Create root item
		var root = tree_view.create_item()
		root.set_text(0, "Templates")

		# Calculate totals for display
		var total_templates = 0
		var new_templates = 0
		var overwrite_templates = 0
		var kept_templates = 0
		var removed_templates = 0

		# First, show imported templates
		var imported_root = tree_view.create_item(root)
		imported_root.set_text(0, "Imported Templates")

		for node_type in imported_templates.keys():
				var node_type_item = tree_view.create_item(imported_root)
				node_type_item.set_text(0, node_type)

				# Check if this node type exists in current templates
				var is_new_node_type = !existing_templates.has(node_type)

				# Set appearance based on merge strategy
				if is_new_node_type:
						node_type_item.set_icon(0, icon_new)
						node_type_item.set_text(1, "New Node Type")
				else:
						# Appearance depends on strategy
						match current_merge_strategy:
								template_manager.MERGE_REPLACE_ALL, template_manager.MERGE_REPLACE_NODE_TYPES:
										node_type_item.set_icon(0, icon_overwrite)
										node_type_item.set_text(1, "Will replace existing")
								template_manager.MERGE_KEEP_EXISTING:
										node_type_item.set_icon(0, icon_unchanged)
										node_type_item.set_text(1, "Some templates may be added")

				# Add templates for this node type
				for template_name in imported_templates[node_type].keys():
						var template_item = tree_view.create_item(node_type_item)
						template_item.set_text(0, template_name)

						# Store reference to template data
						template_item.set_metadata(0, {
								"node_type": node_type,
								"template_name": template_name,
								"template_data": imported_templates[node_type][template_name],
								"is_imported": true
						})

						total_templates += 1

						# Check template status based on merge strategy
						var template_status = STATUS_NEW
						var has_existing = existing_templates.has(node_type) and existing_templates[node_type].has(template_name)

						if has_existing:
								match current_merge_strategy:
										template_manager.MERGE_REPLACE_ALL, template_manager.MERGE_REPLACE_NODE_TYPES:
												template_status = STATUS_OVERWRITE
												overwrite_templates += 1
										template_manager.MERGE_KEEP_EXISTING:
												template_status = STATUS_KEEP
												kept_templates += 1
						else:
								template_status = STATUS_NEW
								new_templates += 1

						# Set status icon and text
						match template_status:
								STATUS_NEW:
										template_item.set_icon(0, icon_new)
										template_item.set_text(1, "New")
								STATUS_OVERWRITE:
										template_item.set_icon(0, icon_overwrite)
										template_item.set_text(1, "Will overwrite existing")
								STATUS_KEEP:
										template_item.set_icon(0, icon_kept)
										template_item.set_text(1, "Existing will be kept")

		# Now show existing templates that might be affected
		if not existing_templates.is_empty():
				var existing_root = tree_view.create_item(root)
				existing_root.set_text(0, "Existing Templates")

				for node_type in existing_templates.keys():
						# Skip if there are no templates for this node type
						if existing_templates[node_type].is_empty():
								continue

						var affected = false

						# Check if this node type is affected by the merge
						match current_merge_strategy:
								template_manager.MERGE_REPLACE_ALL:
										# All existing templates are affected
										affected = true
								template_manager.MERGE_REPLACE_NODE_TYPES:
										# Only affected if the node type is in the imported templates
										affected = imported_templates.has(node_type)
								template_manager.MERGE_KEEP_EXISTING:
										# No existing templates are affected
										affected = false

						if affected:
								var node_type_item = tree_view.create_item(existing_root)
								node_type_item.set_text(0, node_type)

								if imported_templates.has(node_type):
										node_type_item.set_icon(0, icon_overwrite)
										node_type_item.set_text(1, "Will be overwritten")
								else:
										node_type_item.set_icon(0, icon_removed)
										node_type_item.set_text(1, "Will be removed")

								# Add existing templates for this node type
								for template_name in existing_templates[node_type].keys():
										var template_item = tree_view.create_item(node_type_item)
										template_item.set_text(0, template_name)

										# Store reference to template data
										template_item.set_metadata(0, {
												"node_type": node_type,
												"template_name": template_name,
												"template_data": existing_templates[node_type][template_name],
												"is_imported": false
										})

										# Check if this template will be overwritten or removed
										var will_be_overwritten = imported_templates.has(node_type) and imported_templates[node_type].has(template_name)

										if will_be_overwritten:
												template_item.set_icon(0, icon_overwrite)
												template_item.set_text(1, "Will be overwritten")
										else:
												# For MERGE_REPLACE_ALL and MERGE_REPLACE_NODE_TYPES
												if current_merge_strategy == template_manager.MERGE_REPLACE_ALL or \
													 (current_merge_strategy == template_manager.MERGE_REPLACE_NODE_TYPES and imported_templates.has(node_type)):
														template_item.set_icon(0, icon_removed)
														template_item.set_text(1, "Will be removed")
														removed_templates += 1

		# Store counts for later use
		tree_view.set_meta("total_templates", total_templates)
		tree_view.set_meta("new_templates", new_templates)
		tree_view.set_meta("overwrite_templates", overwrite_templates)
		tree_view.set_meta("kept_templates", kept_templates)
		tree_view.set_meta("removed_templates", removed_templates)

		# Auto-expand the root
		root.set_collapsed(false)

		# Also expand imported and existing roots
		var child = root.get_first_child()
		while child:
				child.set_collapsed(false)
				child = child.get_next()

func _update_status() -> void:
		var total_templates = tree_view.get_meta("total_templates") if tree_view.has_meta("total_templates") else 0
		var new_templates = tree_view.get_meta("new_templates") if tree_view.has_meta("new_templates") else 0
		var overwrite_templates = tree_view.get_meta("overwrite_templates") if tree_view.has_meta("overwrite_templates") else 0
		var kept_templates = tree_view.get_meta("kept_templates") if tree_view.has_meta("kept_templates") else 0
		var removed_templates = tree_view.get_meta("removed_templates") if tree_view.has_meta("removed_templates") else 0

		status_label.text = "Import file: " + import_path.get_file()

		# Status message depends on merge strategy
		match current_merge_strategy:
				template_manager.MERGE_REPLACE_ALL:
						count_label.text = str(total_templates) + " templates total: " + str(new_templates) + " new, " + str(overwrite_templates) + " overwriting existing, ALL others will be removed"
				template_manager.MERGE_KEEP_EXISTING:
						count_label.text = str(total_templates) + " templates total: " + str(new_templates) + " will be added, " + str(kept_templates) + " existing kept unchanged"
				template_manager.MERGE_REPLACE_NODE_TYPES:
						count_label.text = str(total_templates) + " templates total: " + str(new_templates) + " new, " + str(overwrite_templates) + " overwriting existing, " + str(removed_templates) + " will be removed"

func _on_merge_strategy_changed(index: int) -> void:
		current_merge_strategy = merge_option.get_item_id(index)

		# Update strategy description
		strategy_description.text = STRATEGY_DESCRIPTIONS[current_merge_strategy]

		# Repopulate the tree with the new strategy
		_populate_tree()

		# Update status counts
		_update_status()

		# Clear details panel when strategy changes
		for child in template_details.get_children():
				child.queue_free()

func _on_template_selected() -> void:
		var selected_item = tree_view.get_selected()
		if not selected_item or not selected_item.has_metadata(0):
				details_panel.visible = false
				return

		details_panel.visible = true

		# Clear existing details
		for child in template_details.get_children():
				child.queue_free()

		var metadata = selected_item.get_metadata(0)
		if not metadata:
				return

		# Get template data
		var node_type = metadata.node_type
		var template_name = metadata.template_name
		var template_data = metadata.template_data
		var is_imported = metadata.is_imported

		# Create header
		var header = Label.new()
		header.text = "Template: " + template_name + " (" + node_type + ")"
		header.add_theme_font_size_override("font_size", 16)
		template_details.add_child(header)

		# Add separator
		var separator = HSeparator.new()
		template_details.add_child(separator)

		# Add merge impact information
		var impact_label = Label.new()
		impact_label.add_theme_font_size_override("font_size", 14)

		if is_imported:
				# For imported templates
				var has_existing = existing_templates.has(node_type) and existing_templates[node_type].has(template_name)

				if has_existing:
						match current_merge_strategy:
								template_manager.MERGE_REPLACE_ALL, template_manager.MERGE_REPLACE_NODE_TYPES:
										impact_label.text = "This template will overwrite an existing template"
										impact_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
								template_manager.MERGE_KEEP_EXISTING:
										impact_label.text = "This template will NOT be imported (existing template kept)"
										impact_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
				else:
						impact_label.text = "This is a new template that will be added"
						impact_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
				# For existing templates
				var has_imported = imported_templates.has(node_type) and imported_templates[node_type].has(template_name)

				match current_merge_strategy:
						template_manager.MERGE_REPLACE_ALL:
								if has_imported:
										impact_label.text = "This template will be overwritten"
										impact_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
								else:
										impact_label.text = "This template will be REMOVED"
										impact_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
						template_manager.MERGE_KEEP_EXISTING:
								impact_label.text = "This template will be kept unchanged"
								impact_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
						template_manager.MERGE_REPLACE_NODE_TYPES:
								if imported_templates.has(node_type):
										if has_imported:
												impact_label.text = "This template will be overwritten"
												impact_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
										else:
												impact_label.text = "This template will be REMOVED"
												impact_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
								else:
										impact_label.text = "This template will be kept unchanged"
										impact_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))

		template_details.add_child(impact_label)
		template_details.add_child(HSeparator.new())

		# Check if we have an existing template to compare with
		var show_comparison = false
		var other_data = null
		var comparison_title = ""

		if is_imported and existing_templates.has(node_type) and existing_templates[node_type].has(template_name):
				show_comparison = true
				other_data = existing_templates[node_type][template_name]
				comparison_title = "Comparing with existing template:"
		elif not is_imported and imported_templates.has(node_type) and imported_templates[node_type].has(template_name):
				show_comparison = true
				other_data = imported_templates[node_type][template_name]
				comparison_title = "Will be replaced with:"

		if show_comparison:
				# Show comparison
				var comparison_label = Label.new()
				comparison_label.text = comparison_title
				comparison_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
				template_details.add_child(comparison_label)

				if is_imported:
						_add_template_properties_comparison(template_data, other_data)
				else:
						_add_template_properties_comparison(other_data, template_data)
		else:
				# Just show template properties
				var props_label = Label.new()
				if is_imported:
						props_label.text = "New template properties:"
						props_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
				else:
						props_label.text = "Existing template properties:"
						props_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
				template_details.add_child(props_label)

				_add_template_properties_display(template_data)

func _add_template_properties_comparison(imported_data: Dictionary, existing_data: Dictionary) -> void:
		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("hseparation", 15)
		grid.add_theme_constant_override("vseparation", 8)
		template_details.add_child(grid)

		# Add headers
		var prop_header = Label.new()
		prop_header.text = "Property"
		prop_header.add_theme_font_size_override("font_size", 14)
		grid.add_child(prop_header)

		var current_header = Label.new()
		current_header.text = "Current Value"
		current_header.add_theme_font_size_override("font_size", 14)
		grid.add_child(current_header)

		var new_header = Label.new()
		new_header.text = "New Value"
		new_header.add_theme_font_size_override("font_size", 14)
		grid.add_child(new_header)

		# Add separator row
		for i in range(3):
				var sep = HSeparator.new()
				grid.add_child(sep)

		# Collect all unique keys
		var all_keys = {}
		for key in imported_data.keys():
				all_keys[key] = true
		for key in existing_data.keys():
				all_keys[key] = true

		# Display each property
		for key in all_keys.keys():
				# Skip internal keys
				if key == "_extends":
						continue

				# Property name
				var key_label = Label.new()
				key_label.text = key
				grid.add_child(key_label)

				# Current value
				var current_value = Label.new()
				if existing_data.has(key):
						if existing_data[key] is Dictionary and existing_data[key].has("value"):
								current_value.text = _format_value(existing_data[key].value)
						else:
								current_value.text = "(invalid format)"
				else:
						current_value.text = "(not set)"
						current_value.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				grid.add_child(current_value)

				# New value
				var new_value = Label.new()
				if imported_data.has(key):
						if imported_data[key] is Dictionary and imported_data[key].has("value"):
								new_value.text = _format_value(imported_data[key].value)
						else:
								new_value.text = "(invalid format)"

						# Highlight changes
						if existing_data.has(key) and existing_data[key] is Dictionary and existing_data[key].has("value"):
								var old_val = existing_data[key].value
								var new_val = imported_data[key].value if imported_data[key] is Dictionary and imported_data[key].has("value") else null

								if str(old_val) != str(new_val):
										new_value.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
						else:
								new_value.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
				else:
						new_value.text = "(will be removed)"
						new_value.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
				grid.add_child(new_value)

func _add_template_properties_display(template_data: Dictionary) -> void:
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("hseparation", 15)
		grid.add_theme_constant_override("vseparation", 8)
		template_details.add_child(grid)

		# Add headers
		var prop_header = Label.new()
		prop_header.text = "Property"
		prop_header.add_theme_font_size_override("font_size", 14)
		grid.add_child(prop_header)

		var value_header = Label.new()
		value_header.text = "Value"
		value_header.add_theme_font_size_override("font_size", 14)
		grid.add_child(value_header)

		# Add separator row
		for i in range(2):
				var sep = HSeparator.new()
				grid.add_child(sep)

		# Display each property
		for key in template_data.keys():
				# Skip internal keys
				if key == "_extends":
						continue

				# Property name
				var key_label = Label.new()
				key_label.text = key
				grid.add_child(key_label)

				# Value
				var value_label = Label.new()
				if template_data[key] is Dictionary and template_data[key].has("value"):
						value_label.text = _format_value(template_data[key].value)
				else:
						value_label.text = "(invalid format)"
				grid.add_child(value_label)

func _format_value(value) -> String:
		if value is Array:
				return JSON.stringify(value)
		elif value is bool:
				return "true" if value else "false"
		else:
				return str(value)

func _on_import_button_pressed() -> void:
		# Get selected merge strategy
		var merge_strategy = merge_option.get_selected_id()

		# Emit signal with import path and merge strategy
		emit_signal("import_confirmed", import_path, merge_strategy)

		# Close the dialog
		hide()

func _on_cancel_button_pressed() -> void:
		emit_signal("import_canceled")
		hide()

func _on_close_requested() -> void:
		emit_signal("import_canceled")
		hide()
