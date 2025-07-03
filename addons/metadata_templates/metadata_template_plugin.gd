@tool
extends EditorPlugin

var template_manager
var template_editor_instance
var current_selection: Node
var metadata_button: Button
var info_dialog: AcceptDialog
var preview_button: Button
var template_preview_dialog

func _enter_tree() -> void:
	print("Metadata Templates Plugin: Initializing...")

	# Make sure directories exist
	var dir = DirAccess.open("res://addons/metadata_templates")
	if dir:
		if not dir.dir_exists("scenes"):
			dir.make_dir("scenes")
		if not dir.dir_exists("templates"):
			dir.make_dir("templates")

	# Register the metadata utils singleton with a different autoload name
	if not ProjectSettings.has_setting("autoload/MDUtils"):
		# Add the metadata_utils.gd as an autoload singleton
		add_autoload_singleton("MDUtils", "res://addons/metadata_templates/metadata_utils.gd")

	# Load dependencies with direct file paths
	var template_manager_script = load("res://addons/metadata_templates/template_manager.gd")
	if template_manager_script:
		template_manager = template_manager_script.new()
		template_manager.initialize()

		# Connect to the templates_reloaded signal
		template_manager.connect("templates_reloaded", _on_templates_reloaded)
	else:
		printerr("Failed to load template_manager.gd")
		return

	# Try to load the scene
	var template_editor_scene = load("res://addons/metadata_templates/scenes/template_editor.tscn")
	if not template_editor_scene:
		printerr("Failed to load template_editor.tscn")
		return

	# Instantiate editor UI
	template_editor_instance = template_editor_scene.instantiate()
	if not template_editor_instance:
		printerr("Failed to instantiate template editor")
		return

	# Use the setter method to ensure proper initialization
	if template_editor_instance.has_method("set_template_manager"):
		template_editor_instance.set_template_manager(template_manager)
	else:
		template_editor_instance.template_manager = template_manager
		# Try to initialize manually if the method doesn't exist
		if template_editor_instance.has_method("initialize"):
			template_editor_instance.initialize()

	# Add the editor UI as a main screen tab
	get_editor_interface().get_editor_main_screen().add_child(template_editor_instance)
	template_editor_instance.hide() # Hide until selected

	# Add button to the editor
	metadata_button = Button.new()
	metadata_button.text = "Apply Templates"
	metadata_button.tooltip_text = "Apply metadata templates to the selected node"
	metadata_button.connect("pressed", _on_apply_templates_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, metadata_button)

	# Add Preview button to the editor
	preview_button = Button.new()
	preview_button.text = "Template Preview"
	preview_button.tooltip_text = "Show all nodes with templates applied"
	preview_button.connect("pressed", _on_preview_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, preview_button)

	# Load the Template Preview Dialog
	var preview_dialog_scene = load("res://addons/metadata_templates/scenes/template_preview_dialog.tscn")
	if preview_dialog_scene:
		template_preview_dialog = preview_dialog_scene.instantiate()
		get_editor_interface().get_base_control().add_child(template_preview_dialog)
		template_preview_dialog.hide()

		# Set references
		if template_preview_dialog.has_method("set_template_manager"):
			template_preview_dialog.set_template_manager(template_manager)
		if template_preview_dialog.has_method("set_template_editor"):
			template_preview_dialog.set_template_editor(template_editor_instance)

	# Create a reusable dialog for information messages
	info_dialog = AcceptDialog.new()
	# Make sure it's NOT exclusive to prevent conflicts with other dialogs
	info_dialog.exclusive = false
	get_editor_interface().get_base_control().add_child(info_dialog)

	# Connect to selection changed signal
	get_editor_interface().get_selection().connect("selection_changed", _on_selection_changed)

	# Initially hide the button until something is selected
	metadata_button.visible = false

	print("Metadata Templates Plugin: Initialization complete")

func _exit_tree() -> void:
	# Remove the editor from main screen
	if template_editor_instance:
		if is_instance_valid(template_editor_instance) and template_editor_instance.get_parent():
			template_editor_instance.get_parent().remove_child(template_editor_instance)
		template_editor_instance.queue_free()

	# Remove the singleton when the plugin is disabled
	if ProjectSettings.has_setting("autoload/MDUtils"):
		remove_autoload_singleton("MDUtils")

	# Remove the button
	if metadata_button:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, metadata_button)
		metadata_button.queue_free()

	# Remove the preview button
	if preview_button:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, preview_button)
		preview_button.queue_free()

	# Remove preview dialog
	if template_preview_dialog:
		template_preview_dialog.queue_free()

	# Remove dialog
	if info_dialog:
		info_dialog.queue_free()

	# Save templates when plugin is disabled
	if template_manager:
		template_manager.save_templates()

# Required to make it appear in the top tab bar
func _has_main_screen() -> bool:
	return true

# The label of the tab
func _get_plugin_name() -> String:
	return "Templates"

# Optional: the icon of the tab
func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("NodeInfo", "EditorIcons")

# This function is called when the tab is clicked
func _make_visible(visible: bool) -> void:
	if template_editor_instance:
		template_editor_instance.visible = visible

func _on_selection_changed() -> void:
	var selection = get_editor_interface().get_selection().get_selected_nodes()

	if selection.size() == 1:
		current_selection = selection[0]
		metadata_button.visible = true
		template_editor_instance.set_selected_node(current_selection)
	else:
		current_selection = null
		metadata_button.visible = false
		template_editor_instance.set_selected_node(null)

func _on_apply_templates_button_pressed() -> void:
	if current_selection:
		template_editor_instance.show_apply_templates_dialog(current_selection)

# Function to open the template preview dialog
func _on_preview_button_pressed() -> void:
	if template_preview_dialog:
		template_preview_dialog.populate(get_editor_interface())

# Helper method for displaying information dialogs from the editor
func show_info_dialog(title: String, message: String) -> void:
	# Make sure dialog is initialized
	if not is_instance_valid(info_dialog):
		info_dialog = AcceptDialog.new()
		info_dialog.exclusive = false # Make sure it's not exclusive
		get_editor_interface().get_base_control().add_child(info_dialog)

	# Set properties and show the dialog
	info_dialog.title = title
	info_dialog.dialog_text = message
	info_dialog.popup_centered()

# Handle templates being reloaded from external file changes
func _on_templates_reloaded() -> void:
	# Update the UI when templates are reloaded
	if template_editor_instance:
		template_editor_instance.update_node_type_list()
		template_editor_instance.update_templates_list()

		# Show a notification to the user
		if info_dialog:
			info_dialog.title = "Templates Reloaded"
			info_dialog.dialog_text = "Templates file was modified externally and has been reloaded."
			info_dialog.popup_centered()
