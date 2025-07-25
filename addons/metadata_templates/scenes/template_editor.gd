@tool
extends MarginContainer

var template_manager: RefCounted
var current_node_type: String = ""
var current_template_name: String = ""
var editing_template: bool = false
var selected_node: Node = null
var ui_ready = false

# References to UI elements
@onready var node_type_option = $VBoxContainer/HeaderPanel/VBoxContainer/NodeTypeSection/HBoxContainer/NodeTypeOption
@onready var templates_container = $VBoxContainer/VSplitContainer/TemplatesPanel/VBoxContainer/TemplatesContainer
@onready var metadata_editor = $VBoxContainer/VSplitContainer/MetadataEditor
@onready var template_name_field = $VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer/TemplateName
@onready var metadata_list = $VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/ScrollContainer/VBoxContainer/MetadataList
@onready var parent_metadata_list = $VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/ScrollContainer/VBoxContainer/ParentMetadataList
@onready var add_type_dialog = $AddTypeDialog
@onready var node_type_input = $AddTypeDialog/VBoxContainer/NodeTypeInput
@onready var apply_template_dialog = $ApplyTemplateDialog
@onready var template_options = $ApplyTemplateDialog/VBoxContainer/TemplateOptions
@onready var add_template_button = $VBoxContainer/VSplitContainer/TemplatesPanel/VBoxContainer/TemplateHeader/AddTemplateButton
@onready var parent_template_option = $VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/ParentTemplateContainer/ParentTemplateOption
@onready var show_inherited_toggle = $VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/ParentTemplateContainer/ShowInheritedToggle
@onready var split_container = $VBoxContainer/VSplitContainer
@onready var export_import_container = $VBoxContainer/HeaderPanel/VBoxContainer/ImportExportSection/HBoxContainer
@onready var export_button = $VBoxContainer/HeaderPanel/VBoxContainer/ImportExportSection/HBoxContainer/ExportButton
@onready var import_button = $VBoxContainer/HeaderPanel/VBoxContainer/ImportExportSection/HBoxContainer/ImportButton
@onready var export_dialog = $ExportDialog
@onready var import_dialog = $ImportDialog
@onready var import_merge_dialog = $ImportMergeDialog
@onready var merge_option_button = $ImportMergeDialog/VBoxContainer/MergeOptionButton
@onready var import_preview_dialog = null

# Component managers
var template_list_manager: TemplateListManager
var metadata_field_manager: MetadataFieldManager
var inheritance_viewer: InheritanceViewer
var parent_template_manager: ParentTemplateManager

func _ready() -> void:
	# Set sensible minimum size that allows resizing
	custom_minimum_size = Vector2(550, 400)

	# Don't enforce minimum size on parent window
	if get_parent() and get_parent() is Window:
		get_parent().min_size = Vector2(0, 0)

	# Initialize the split container with a reasonable default ratio
	if is_instance_valid(split_container):
		split_container.split_offset = 150

	# Initialize component managers once UI is ready
	if is_instance_valid(node_type_option):
		# Set up the Add Template button icon first so it's available for the managers
		add_template_button.icon = get_theme_icon("Add", "EditorIcons")
		add_template_button.flat = true
		add_template_button.connect("pressed", _on_new_template_button_pressed)

		# Connect main UI signals
		node_type_option.connect("item_selected", _on_node_type_selected)
		$VBoxContainer/HeaderPanel/VBoxContainer/NodeTypeSection/HBoxContainer/AddTypeButton.connect("pressed", _on_add_type_button_pressed)
		$VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer2/AddMetadataButton.connect("pressed", _on_add_metadata_button_pressed)
		$VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer2/SaveButton.connect("pressed", _on_save_button_pressed)
		$VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer2/CancelButton.connect("pressed", _on_cancel_button_pressed)
		show_inherited_toggle.connect("toggled", _on_show_inherited_toggled)

		# Connect import/export buttons
		export_button.connect("pressed", _on_export_button_pressed)
		import_button.connect("pressed", _on_import_button_pressed)

		# Set up file dialog filters
		export_dialog.add_filter("*.json", "JSON Files")
		import_dialog.add_filter("*.json", "JSON Files")

		# Connect file dialog signals
		export_dialog.connect("file_selected", _on_export_file_selected)
		import_dialog.connect("file_selected", _on_import_file_selected)

		# Connect merge dialog signals
		import_merge_dialog.connect("confirmed", _on_import_merge_confirmed)

		# Perform delayed initialization after ready
		call_deferred("_initialize_managers_deferred")

		# Load the import preview dialog
		call_deferred("_load_import_preview_dialog")

		ui_ready = true
	else:
		printerr("Warning: UI components not found, connections not established")

	# Update export/import dialog filters to support all formats
	if template_manager:
		export_dialog.clear_filters()
		for filter in template_manager.get_export_file_filters():
			export_dialog.add_filter(filter)

		import_dialog.clear_filters()
		for filter in template_manager.get_import_file_filters():
			import_dialog.add_filter(filter)
	else:
		# Default filters if template_manager isn't available yet
		export_dialog.add_filter("*.json", "JSON Files")
		import_dialog.add_filter("*.json", "JSON Files")

# Perform initialization after _ready to ensure proper node setup
func _initialize_managers_deferred() -> void:
	# Initialize managers (even with null template_manager for now)
	_initialize_managers()

	# Initialize UI if template_manager is already set
	if template_manager:
		initialize()

	# Apply custom styling to buttons
	var buttons = [
		$VBoxContainer/HeaderPanel/VBoxContainer/NodeTypeSection/HBoxContainer/AddTypeButton,
		$VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer2/AddMetadataButton,
		$VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer2/SaveButton,
		$VBoxContainer/VSplitContainer/MetadataEditor/VBoxContainer/HBoxContainer2/CancelButton
	]

	for button in buttons:
		if is_instance_valid(button):
			button.add_theme_constant_override("h_separation", 8)

func _initialize_managers() -> void:
	# Create manager instances (safely handle possible null template_manager)
	template_list_manager = TemplateListManager.new(template_manager, templates_container)
	metadata_field_manager = MetadataFieldManager.new(template_manager, metadata_list)
	inheritance_viewer = InheritanceViewer.new(template_manager, parent_metadata_list)
	parent_template_manager = ParentTemplateManager.new(template_manager, parent_template_option)

	# Connect signals from template list manager
	template_list_manager.connect("template_edit_requested", _on_edit_template_button_pressed)
	template_list_manager.connect("template_delete_requested", _on_delete_template_button_pressed)
	template_list_manager.connect("template_selected", _on_template_selected)

# This function will be called once the template manager is properly set
func initialize() -> void:
	if template_manager and ui_ready:
		# Re-initialize managers with template manager
		_initialize_managers()

		# Update UI
		update_node_type_list()

		# Update the templates list if we have a node type selected
		if not current_node_type.is_empty():
			template_list_manager.set_node_type(current_node_type)
	else:
		printerr("Warning: Cannot initialize - template_manager or UI not ready")

func update_node_type_list() -> void:
	if not template_manager or not ui_ready:
		printerr("Cannot update node type list: template_manager or UI not ready")
		return

	if not is_instance_valid(node_type_option):
		printerr("Cannot update node type list: node_type_option is not valid")
		return

	node_type_option.clear()

	var node_types = template_manager.get_all_node_types()
	var index = 0
	for node_type in node_types:
		node_type_option.add_item(node_type)
		if node_type == current_node_type:
			node_type_option.select(index)
		index += 1

# Setter for template_manager that properly initializes the UI
func set_template_manager(manager: RefCounted) -> void:
	template_manager = manager

	# Initialize the UI once the template manager is set and UI is ready
	if ui_ready:
		initialize()

func _on_node_type_selected(index: int) -> void:
	current_node_type = node_type_option.get_item_text(index)
	template_list_manager.set_node_type(current_node_type)

func _on_add_type_button_pressed() -> void:
	node_type_input.text = ""
	add_type_dialog.popup_centered()

func _on_add_type_dialog_confirmed() -> void:
	if not template_manager:
		printerr("Cannot add type: template_manager is null")
		return

	var new_node_type = node_type_input.text.strip_edges()
	if not new_node_type.is_empty():
		current_node_type = new_node_type

		# Just ensure the node type exists temporarily
		template_manager.ensure_node_type_exists(current_node_type)
		update_node_type_list()
		template_list_manager.set_node_type(current_node_type)

func _on_new_template_button_pressed() -> void:
	if current_node_type.is_empty():
		return

	editing_template = false
	current_template_name = ""
	template_name_field.text = ""

	# Update parent template dropdown
	parent_template_manager.update_parent_template_dropdown(current_node_type)

	# Clear metadata fields and add empty ones
	metadata_field_manager.clear_fields()
	metadata_field_manager.add_empty_fields(3)

	metadata_editor.visible = true

func _on_edit_template_button_pressed(template_name: String) -> void:
	current_template_name = template_name
	# Highlight the template when editing
	if template_list_manager:
		template_list_manager.highlight_template(template_name)
	_open_template_editor(template_name)

func _on_delete_template_button_pressed(template_name: String) -> void:
	template_manager.delete_template(current_node_type, template_name)
	template_list_manager.update_templates_list()

func _on_add_metadata_button_pressed() -> void:
	metadata_field_manager.add_metadata_field("", "")

func _on_save_button_pressed() -> void:
	var template_name = template_name_field.text.strip_edges()
	if template_name.is_empty() or current_node_type.is_empty():
		return

	# Collect metadata from UI
	var metadata = metadata_field_manager.get_metadata_dict()

	# Add parent template if one is selected
	var selected_parent = parent_template_manager.get_selected_parent()
	if not selected_parent.is_empty():
		metadata[template_manager.EXTENDS_KEY] = {
			"value": selected_parent,
			"type": template_manager.TYPE_STRING
		}

	# Save the template
	template_manager.create_template(template_name, current_node_type, metadata)

	# Update UI and hide editor
	template_list_manager.update_templates_list()
	metadata_editor.visible = false

func _on_cancel_button_pressed() -> void:
	metadata_editor.visible = false

func _on_show_inherited_toggled(button_pressed: bool) -> void:
	inheritance_viewer.toggle_visibility(button_pressed)

func set_selected_node(node: Node) -> void:
	selected_node = node

	# Update the UI to show relevant templates for the selected node
	if node and is_instance_valid(node_type_option):
		var node_type = node.get_class()

		# Find the node type in the dropdown or add it
		var found = false
		for i in range(node_type_option.get_item_count()):
			if node_type_option.get_item_text(i) == node_type:
				node_type_option.select(i)
				current_node_type = node_type
				found = true
				template_list_manager.set_node_type(current_node_type)
				break

		if not found and not node_type.is_empty():
			current_node_type = node_type

			# Just ensure the node type exists temporarily, but don't save it yet
			if template_manager and not template_manager.templates.has(current_node_type):
				# Use the new method that doesn't save empty node types
				template_manager.ensure_node_type_exists(current_node_type)

			update_node_type_list()
			template_list_manager.set_node_type(current_node_type)

func show_apply_templates_dialog(node: Node) -> void:
		if not node:
				return

		# Store the selected node for later use
		selected_node = node
		var node_type = node.get_class()

		# Get templates for this node type
		var templates = template_manager.get_templates_for_node_type(node_type)

		# Clear and populate the template options
		template_options.clear()

		for template_name in templates:
				template_options.add_item(template_name)

		# Connect dialog confirmed signal if not already connected
		if not apply_template_dialog.is_connected("confirmed", _on_apply_template_dialog_confirmed):
				apply_template_dialog.connect("confirmed", _on_apply_template_dialog_confirmed)

		# Only show the dialog if we have templates available
		if template_options.item_count > 0:
				apply_template_dialog.popup_centered()
		else:
				var parent = get_parent()
				if parent and parent.has_method("show_info_dialog"):
						parent.show_info_dialog("No Templates Available",
								"No metadata templates found for this node type: " + node_type)

func _on_apply_template_dialog_confirmed() -> void:
		if not is_instance_valid(selected_node):
				return

		# Get the selected template name - FIXED: using get_selected_items() instead of get_selected_id()
		var selected_items = template_options.get_selected_items()
		if selected_items.size() == 0:
				# Fall back to first item if nothing is selected
				if template_options.item_count > 0:
						selected_items = [0] # Use the first item
				else:
						return

		var template_name = template_options.get_item_text(selected_items[0])
		var node_type = selected_node.get_class()

		# Apply the template to the node
		if template_manager:
				template_manager.apply_template_to_node(selected_node, node_type, template_name)

func _open_template_editor(template_name: String) -> void:
	if current_node_type.is_empty() or template_name.is_empty():
		return

	# Set the template name field
	template_name_field.text = template_name

	# Update current template name
	current_template_name = template_name

	# Make sure the template is highlighted in the list
	if template_list_manager:
		template_list_manager.highlight_template(template_name)

	# Update parent template dropdown
	parent_template_manager.update_parent_template_dropdown(current_node_type, template_name)

	# Populate metadata fields from template
	var templates = template_manager.get_templates_for_node_type(current_node_type)
	if templates.has(template_name):
		metadata_field_manager.populate_from_template(templates[template_name])

	# Reset parent metadata display and update inheritance viewer
	inheritance_viewer.set_current_template(current_node_type, template_name)
	inheritance_viewer.clear()

	# Reset toggle button state - set to off by default
	show_inherited_toggle.button_pressed = false
	inheritance_viewer.toggle_visibility(false)

	editing_template = true
	metadata_editor.visible = true

# Override update_templates_list to ensure it calls through to the manager
func update_templates_list() -> void:
	if template_list_manager:
		template_list_manager.set_node_type(current_node_type)
	else:
		printerr("Template list manager not initialized")

func _on_template_selected(template_name: String) -> void:
	# Update the current selected template name
	current_template_name = template_name


func _on_import_file_selected(path: String) -> void:
	if not template_manager:
		printerr("Cannot import: template_manager is null")
		return

	# First validate if the file contains valid templates
	var validation_result = template_manager.validate_templates_file(path)

	if not validation_result.valid:
		# Make sure import dialog is fully closed first
		import_dialog.hide()
		await get_tree().process_frame

		# Show error message
		var dialog = AcceptDialog.new()
		dialog.title = "Import Failed"
		dialog.dialog_text = "Failed to import templates: " + validation_result.error
		dialog.exclusive = true
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		dialog.queue_free()
		return

	# Instead of showing the merge dialog directly, show the preview dialog
	if import_preview_dialog:
		# Hide the import dialog first
		import_dialog.hide()
		await get_tree().process_frame

		# Setup and show the preview dialog
		import_preview_dialog.setup(template_manager, path)
		import_preview_dialog.popup_centered()
	else:
		# Fallback to old behavior if preview dialog isn't available
		import_merge_dialog.set_meta("import_path", path)

		# Make sure import dialog is fully closed before showing merge dialog
		import_dialog.hide()
		await get_tree().process_frame
		import_merge_dialog.popup_centered()

func _on_export_button_pressed() -> void:
	if not template_manager:
		printerr("Cannot export: template_manager is null")
		return

	# Add format selector to export dialog
	var exporters = template_manager.get_available_exporters()
	if exporters.size() > 1:
		# If we have multiple exporters, show a format selection dialog
		var format_dialog = ConfirmationDialog.new()
		format_dialog.title = "Select Export Format"

		var vbox = VBoxContainer.new()
		format_dialog.add_child(vbox)

		var label = Label.new()
		label.text = "Select export format:"
		vbox.add_child(label)

		var format_option = OptionButton.new()
		for format in exporters:
			format_option.add_item(exporters[format], format_option.get_item_count())
			format_option.set_item_metadata(format_option.get_item_count() - 1, format)
		vbox.add_child(format_option)

		add_child(format_dialog)
		format_dialog.popup_centered()

		# Wait for user to select a format
		await format_dialog.confirmed

		var selected_format = format_option.get_selected_metadata()
		if selected_format:
			# Set the current file in the export dialog with the selected format
			var date_string = Time.get_datetime_string_from_system().replace(":", "-")
			export_dialog.current_file = "metadata_templates_" + date_string + "." + selected_format

			# Show the export dialog
			export_dialog.popup_centered()

		format_dialog.queue_free()
	else:
		# Default to JSON if only one exporter is available
		var date_string = Time.get_datetime_string_from_system().replace(":", "-")
		export_dialog.current_file = "metadata_templates_" + date_string + ".json"
		export_dialog.popup_centered()

func _on_export_file_selected(path: String) -> void:
	if not template_manager:
		printerr("Cannot export: template_manager is null")
		return

	# Get the templates to export
	var export_successful = template_manager.export_templates_to_file(path)

	# Make sure export dialog is fully closed first
	export_dialog.hide()
	await get_tree().process_frame

	# Show confirmation or error message
	var dialog = AcceptDialog.new()
	dialog.exclusive = true
	add_child(dialog)

	if export_successful:
		dialog.title = "Export Successful"
		dialog.dialog_text = "Templates exported successfully to:\n" + path
	else:
		dialog.title = "Export Failed"
		dialog.dialog_text = "Failed to export templates to file."

	dialog.popup_centered()
	await dialog.confirmed
	dialog.queue_free()

func _on_import_button_pressed() -> void:
	if not template_manager:
		printerr("Cannot import: template_manager is null")
		return

	import_dialog.popup_centered()

func _on_import_merge_confirmed() -> void:
	var path = import_merge_dialog.get_meta("import_path")
	var merge_strategy = merge_option_button.selected

	# Hide the merge dialog first
	import_merge_dialog.hide()
	await get_tree().process_frame

	# Call our new function to handle the import
	_on_import_preview_confirmed(path, merge_strategy)

func _on_import_preview_confirmed(path: String, merge_strategy: int) -> void:
	# Perform the import
	var import_result = template_manager.import_templates_from_file(path, merge_strategy)

	# Show result dialog
	var dialog = AcceptDialog.new()
	dialog.exclusive = true
	add_child(dialog)

	if import_result.success:
		dialog.title = "Import Successful"
		dialog.dialog_text = "Successfully imported " + str(import_result.imported_count) + " templates."

		# Update the UI
		update_node_type_list()
		if not current_node_type.is_empty():
			template_list_manager.set_node_type(current_node_type)
	else:
		dialog.title = "Import Failed"
		dialog.dialog_text = "Failed to import templates: " + import_result.error

	dialog.popup_centered()
	await dialog.confirmed
	dialog.queue_free()

func _on_import_preview_canceled() -> void:
	# Import was canceled, nothing to do
	pass

func _load_import_preview_dialog() -> void:
	# Create the import preview dialog
	var preview_scene = load("res://addons/metadata_templates/scenes/template_import_preview_dialog.tscn")
	if preview_scene:
		import_preview_dialog = preview_scene.instantiate()
		add_child(import_preview_dialog)
		import_preview_dialog.connect("import_confirmed", _on_import_preview_confirmed)
		import_preview_dialog.connect("import_canceled", _on_import_preview_canceled)
		import_preview_dialog.hide()
