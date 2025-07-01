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

	# Add the editor UI as a main screen tab instead of a dock
	# This will place it alongside the AssetLib tab
	add_control_to_bottom_panel(template_editor_instance, "Templates")

	# Don't set minimum size on the panel - allow natural resizing
	var panel = template_editor_instance.get_parent()
	if panel and panel.has_method("set_custom_minimum_size"):
		panel.set_custom_minimum_size(Vector2(0, 0))

	# Make the panel visible initially to ensure it's sized correctly
	make_bottom_panel_item_visible(template_editor_instance)

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
	# Remove the editor from bottom panel instead of dock
	if template_editor_instance:
		remove_control_from_bottom_panel(template_editor_instance)
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
