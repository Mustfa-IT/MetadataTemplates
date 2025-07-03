@tool
class_name TemplateListManager
extends RefCounted

signal template_selected(template_name)
signal template_edit_requested(template_name)
signal template_delete_requested(template_name)

var template_manager: RefCounted
var templates_container: VBoxContainer
var current_node_type: String = ""

func _init(p_template_manager: RefCounted, p_container: VBoxContainer) -> void:
	template_manager = p_template_manager
	templates_container = p_container

func set_node_type(node_type: String) -> void:
	current_node_type = node_type
	update_templates_list()

func update_templates_list() -> void:
	if not is_instance_valid(templates_container):
		printerr("Cannot update templates list: templates_container is not valid")
		return

	if not template_manager:
		printerr("Cannot update templates list: template_manager is null")
		return

	# Clear existing templates
	for child in templates_container.get_children():
		child.queue_free()

	if current_node_type.is_empty():
		return

	# Get editor theme icons
	var edit_icon = templates_container.get_theme_icon("Edit", "EditorIcons")
	var delete_icon = templates_container.get_theme_icon("Remove", "EditorIcons")

	var templates = template_manager.get_templates_for_node_type(current_node_type)

	for template_name in templates:
		# Create a container for each template item with buttons
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Add template name label
		var label = Label.new()
		label.text = template_name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.connect("gui_input", _on_template_label_gui_input.bind(template_name))
		hbox.add_child(label)

		# Add edit button
		var edit_button = Button.new()
		edit_button.icon = edit_icon
		edit_button.tooltip_text = "Edit template"
		edit_button.flat = true
		edit_button.connect("pressed", func(): emit_signal("template_edit_requested", template_name))
		hbox.add_child(edit_button)

		# Add delete button
		var delete_button = Button.new()
		delete_button.icon = delete_icon
		delete_button.tooltip_text = "Delete template"
		delete_button.flat = true
		delete_button.connect("pressed", func(): emit_signal("template_delete_requested", template_name))
		hbox.add_child(delete_button)

		templates_container.add_child(hbox)

func _on_template_label_gui_input(event: InputEvent, template_name: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		emit_signal("template_edit_requested", template_name)
