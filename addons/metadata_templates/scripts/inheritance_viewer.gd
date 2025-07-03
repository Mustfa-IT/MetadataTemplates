@tool
class_name InheritanceViewer
extends RefCounted

var template_manager: RefCounted
var parent_metadata_list: VBoxContainer
var current_node_type: String = ""
var current_template_name: String = ""

func _init(p_template_manager: RefCounted, p_parent_list: VBoxContainer) -> void:
	template_manager = p_template_manager
	parent_metadata_list = p_parent_list

func set_current_template(node_type: String, template_name: String) -> void:
	current_node_type = node_type
	current_template_name = template_name

func clear() -> void:
	for child in parent_metadata_list.get_children():
		child.queue_free()

func toggle_visibility(visible: bool) -> void:
	parent_metadata_list.visible = visible

	if visible:
		load_parent_metadata()

func load_parent_metadata() -> void:
	clear()

	if current_node_type.is_empty() or current_template_name.is_empty() or not template_manager:
		var error_label = Label.new()
		error_label.text = "No template selected"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parent_metadata_list.add_child(error_label)
		return

	# Get the template
	var templates = template_manager.get_templates_for_node_type(current_node_type)
	if not templates.has(current_template_name):
		return

	var template = templates[current_template_name]

	# Check if this template extends another template
	var parent_template_name = ""
	if template.has(template_manager.EXTENDS_KEY) and template[template_manager.EXTENDS_KEY] is Dictionary:
		parent_template_name = template[template_manager.EXTENDS_KEY].value

	if parent_template_name.is_empty():
		# Add a label indicating no parent template
		var label = Label.new()
		label.text = "No parent template selected"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parent_metadata_list.add_child(label)
		return

	# Get the merged parent template (all ancestors merged)
	var parent_data = template_manager.get_merged_template(current_node_type, parent_template_name)

	# If no parent data found, show a message
	if parent_data.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No properties found in parent template"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parent_metadata_list.add_child(empty_label)
		return

	# Add header to indicate parent template data
	var header = Label.new()
	header.text = "Properties inherited from: " + parent_template_name
	header.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	header.add_theme_font_size_override("font_size", 14)
	parent_metadata_list.add_child(header)

	# Show parent metadata as read-only fields
	var found_items = false
	var keys_to_show = []

	# First, collect all keys that should be shown
	for key in parent_data.keys():
		# Skip special keys and keys that are overridden in the current template
		if key == template_manager.EXTENDS_KEY or template.has(key):
			continue

		keys_to_show.append(key)

	# Then add fields for each key
	for key in keys_to_show:
		var value = parent_data[key]
		var type_id = 0

		# Extract value and type from dictionary
		if value is Dictionary and value.has("type") and value.has("value"):
			type_id = value.type
			value = value.value

			# Format for display
			if type_id == template_manager.TYPE_ARRAY and value is Array:
				value = JSON.stringify(value)
			elif type_id == template_manager.TYPE_BOOLEAN:
				value = str(value).to_lower()
			else:
				value = str(value)
		else:
			value = str(value)

		# Create a panel with read-only metadata
		add_inherited_metadata_field(key, str(value), type_id)
		found_items = true

	# If no inherited properties found (all were overridden), show a message
	if not found_items:
		var no_props_label = Label.new()
		no_props_label.text = "All parent properties are overridden in this template"
		no_props_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parent_metadata_list.add_child(no_props_label)

func add_inherited_metadata_field(key: String, value: String, type_id: int = 0) -> void:
	# Create panel with styled outline
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Ensure full width
	panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(0.12, 0.15, 0.2) # Dark blue background
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.6, 1.0) # Bright blue border
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5

	# Main content layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	# Add a clearly visible inheritance indicator
	var inherited_label = Label.new()
	inherited_label.text = "↑" # Up arrow indicating inheritance
	inherited_label.tooltip_text = "Inherited from parent template"
	inherited_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	inherited_label.add_theme_font_size_override("font_size", 16)
	inherited_label.custom_minimum_size.x = 20
	hbox.add_child(inherited_label)

	# Key section
	var key_label = Label.new()
	key_label.text = "Key:"
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.custom_minimum_size.x = 40
	hbox.add_child(key_label)

	var key_value = Label.new()
	key_value.text = key
	key_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_value.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	key_value.add_theme_font_size_override("font_size", 14)
	hbox.add_child(key_value)

	# Value section
	var value_label = Label.new()
	value_label.text = "Value:"
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.custom_minimum_size.x = 50
	hbox.add_child(value_label)

	var value_text = Label.new()
	value_text.text = value
	value_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_text.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	value_text.add_theme_font_size_override("font_size", 14)
	hbox.add_child(value_text)

	# Type indicator
	var type_label = Label.new()
	var type_name = ""
	match type_id:
		0: type_name = "String"
		1: type_name = "Number"
		2: type_name = "Boolean"
		3: type_name = "Array"
	type_label.text = type_name
	type_label.custom_minimum_size.x = 90
	type_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	hbox.add_child(type_label)

	# Add the panel to the parent metadata list
	parent_metadata_list.add_child(panel)
