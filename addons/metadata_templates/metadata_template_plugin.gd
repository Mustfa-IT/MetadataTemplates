@tool
extends EditorPlugin

var template_manager
var template_editor_instance
var current_selection: Node
var metadata_button: Button
var info_dialog: AcceptDialog

func _enter_tree() -> void:
	print("Metadata Templates Plugin: Initializing...")

	# Make sure directories exist
	var dir = DirAccess.open("res://addons/metadata_templates")
	if dir:
		if not dir.dir_exists("scenes"):
			dir.make_dir("scenes")
		if not dir.dir_exists("templates"):
			dir.make_dir("templates")

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

	# Create a reusable dialog for information messages
	info_dialog = AcceptDialog.new()
	info_dialog.exclusive = true
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

	# Remove the button
	if metadata_button:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, metadata_button)
		metadata_button.queue_free()

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
		var templates = template_manager.get_templates_for_node_type(current_selection.get_class())
		if templates.size() > 0:
			# Show a popup to select which template to apply
			template_editor_instance.show_apply_templates_dialog(current_selection)
		else:
			# Make sure dialog is initialized before using it
			if not is_instance_valid(info_dialog) or info_dialog == null:
				info_dialog = AcceptDialog.new()
				info_dialog.exclusive = true
				get_editor_interface().get_base_control().add_child(info_dialog)

			# Now safely set properties and show the dialog
			info_dialog.title = "No templates available"
			info_dialog.dialog_text = "No metadata templates found for this node type: " + current_selection.get_class()
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
