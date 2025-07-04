@tool
class_name MetadataFieldManager
extends RefCounted

var metadata_list: VBoxContainer
var metadata_items = []
var template_manager: RefCounted

func _init(p_template_manager: RefCounted, p_metadata_list: VBoxContainer) -> void:
	template_manager = p_template_manager
	metadata_list = p_metadata_list

func clear_fields() -> void:
	for child in metadata_list.get_children():
		child.queue_free()
	metadata_items = []

func add_empty_fields(count: int = 3) -> void:
	for i in range(count):
		add_metadata_field("", "")

func add_metadata_field(key: String, value: String, type_id: int = 0) -> void:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(0.2, 0.23, 0.28)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.34, 0.4)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_right = 3
		style.corner_radius_bottom_left = 3
		style.content_margin_left = 8
		style.content_margin_top = 8
		style.content_margin_right = 8
		style.content_margin_bottom = 8

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var key_label = Label.new()
	key_label.text = "Key:"
	key_label.custom_minimum_size.x = 40
	hbox.add_child(key_label)

	var key_input = LineEdit.new()
	key_input.text = key
	key_input.placeholder_text = "metadata_key"
	key_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(key_input)

	var value_label = Label.new()
	value_label.text = "Value:"
	value_label.custom_minimum_size.x = 50
	hbox.add_child(value_label)

	var value_input = LineEdit.new()
	value_input.text = value
	value_input.placeholder_text = "metadata_value"
	value_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(value_input)

	var type_option = OptionButton.new()
	type_option.add_item("String", 0)
	type_option.add_item("Number", 1)
	type_option.add_item("Boolean", 2)
	type_option.add_item("Array", 3)
	type_option.select(type_id) # Set to the provided type
	type_option.custom_minimum_size.x = 90
	hbox.add_child(type_option)

	var remove_button = Button.new()
	remove_button.text = "✕"
	remove_button.tooltip_text = "Remove this metadata field"
	remove_button.connect("pressed", _on_remove_metadata_field.bind(panel))
	hbox.add_child(remove_button)

	metadata_list.add_child(panel)
	metadata_items.append({"panel": panel, "key": key_input, "value": value_input, "type": type_option})

func _on_remove_metadata_field(panel: PanelContainer) -> void:
	for i in range(metadata_items.size()):
		if metadata_items[i]["panel"] == panel:
			metadata_items.remove_at(i)
			break

	panel.queue_free()

func get_metadata_dict() -> Dictionary:
	var metadata = {}

	for item in metadata_items:
		var key = item["key"].text.strip_edges()
		if key.is_empty():
			continue

		var value_text = item["value"].text
		var type_id = item["type"].get_selected_id()
		var parsed_value

		# Parse value based on type
		match type_id:
			0: # String
				parsed_value = value_text
			1: # Number
				if value_text.is_valid_float():
					parsed_value = float(value_text)
				else:
					parsed_value = 0
			2: # Boolean
				parsed_value = value_text.to_lower() == "true"
			3: # Array
				# Handle array parsing
				parsed_value = []
				var array_str = value_text.strip_edges()
				if array_str.begins_with("[") and array_str.ends_with("]"):
					array_str = array_str.substr(1, array_str.length() - 2)
					var parts = array_str.split(",")
					for part in parts:
						part = part.strip_edges()
						if part.is_valid_float():
							parsed_value.append(float(part))
						elif part.to_lower() == "true":
							parsed_value.append(true)
						elif part.to_lower() == "false":
							parsed_value.append(false)
						elif part.begins_with("\"") and part.ends_with("\""):
							parsed_value.append(part.substr(1, part.length() - 2))
						else:
							parsed_value.append(part)

		# Store both value and type
		metadata[key] = {
			"value": parsed_value,
			"type": type_id
		}

	return metadata

func populate_from_template(template: Dictionary) -> void:
	clear_fields()

	for key in template:
		# Skip the extends key, we handle it separately
		if key == template_manager.EXTENDS_KEY:
			continue

		var value
		var type_id = 0 # default to string

			# Get type and value information from the template
		if template[key] is Dictionary and template[key].has("type") and template[key].has("value"):
			value = template[key].value
			type_id = template[key].type

			# Convert value to string for display
			if type_id == template_manager.TYPE_ARRAY and value is Array:
				value = JSON.stringify(value)
			elif type_id == template_manager.TYPE_BOOLEAN:
				value = str(value).to_lower()
			else:
				value = str(value)
		else:
			# If somehow we get here with incorrect format, use defaults
			value = ""
			type_id = template_manager.TYPE_STRING

		add_metadata_field(key, value, type_id)
