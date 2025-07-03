@tool
class_name TemplateListManager
extends RefCounted

signal template_selected(template_name)
signal template_edit_requested(template_name)
signal template_delete_requested(template_name)

var template_manager: RefCounted
var templates_container: VBoxContainer
var current_node_type: String = ""
var highlighted_template: String = ""
var template_items = {} # Dictionary to store template items by name

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
	template_items.clear()
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
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Add stylebox for highlighting
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.2, 0.23, 0.28)
		stylebox.border_width_left = 2
		stylebox.border_width_top = 2
		stylebox.border_width_right = 2
		stylebox.border_width_bottom = 2
		stylebox.border_color = Color(0.3, 0.34, 0.4)
		stylebox.corner_radius_top_left = 3
		stylebox.corner_radius_top_right = 3
		stylebox.corner_radius_bottom_right = 3
		stylebox.corner_radius_bottom_left = 3
		panel.add_theme_stylebox_override("panel", stylebox)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_child(hbox)

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

		templates_container.add_child(panel)

		# Store reference to the panel for highlighting
		template_items[template_name] = {
			"panel": panel,
			"label": label,
			"stylebox": stylebox
		}

	# Apply highlight to previously highlighted template if it still exists
	if highlighted_template and template_items.has(highlighted_template):
		highlight_template(highlighted_template)

func _on_template_label_gui_input(event: InputEvent, template_name: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			emit_signal("template_edit_requested", template_name)
		else:
			# Single click - highlight and emit selected signal
			highlight_template(template_name)
			emit_signal("template_selected", template_name)

# Highlight the specified template in the list
func highlight_template(template_name: String) -> void:
	# Remove highlight from all templates
	for item_name in template_items:
		var item = template_items[item_name]
		item.stylebox.bg_color = Color(0.2, 0.23, 0.28)
		item.stylebox.border_color = Color(0.3, 0.34, 0.4)
		item.label.add_theme_color_override("font_color", Color.WHITE)

	# Apply highlight to the selected template
	if template_items.has(template_name):
		var item = template_items[template_name]
		item.stylebox.bg_color = Color(0.25, 0.30, 0.45) # Slightly blue background
		item.stylebox.border_color = Color(0.4, 0.6, 1.0) # Bright blue border
		item.label.add_theme_color_override("font_color", Color(0.9, 1.0, 1.0)) # Brighter text
		highlighted_template = template_name
