@tool
extends MarginContainer

var template_manager: RefCounted
var current_node_type: String = ""
var current_template_name: String = ""
var editing_template: bool = false
var selected_node: Node = null
var metadata_items = []
var ui_ready = false

# References to UI elements - update paths to match the new UI structure
@onready var node_type_option = $VBoxContainer/HeaderPanel/VBoxContainer/NodeTypeSection/HBoxContainer/NodeTypeOption
@onready var templates_list = $VBoxContainer/TemplatesPanel/VBoxContainer/TemplatesList
@onready var metadata_editor = $VBoxContainer/MetadataEditor
@onready var template_name_field = $VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer/TemplateName
@onready var metadata_list = $VBoxContainer/MetadataEditor/VBoxContainer/ScrollContainer/MetadataList
@onready var add_type_dialog = $AddTypeDialog
@onready var node_type_input = $AddTypeDialog/VBoxContainer/NodeTypeInput
@onready var apply_template_dialog = $ApplyTemplateDialog
@onready var template_options = $ApplyTemplateDialog/VBoxContainer/TemplateOptions

func _ready() -> void:
		# Set sensible minimum size that allows resizing
		custom_minimum_size = Vector2(550, 400)

		# Don't enforce minimum size on parent window
		if get_parent() and get_parent() is Window:
				get_parent().min_size = Vector2(0, 0)

		# Remove the resized connection - let Godot handle resizing normally
		if is_connected("resized", _on_resized):
				disconnect("resized", _on_resized)

		# Connect signals - updated to match the new UI structure
		if is_instance_valid(node_type_option) and is_instance_valid(templates_list):
				node_type_option.connect("item_selected", _on_node_type_selected)
				$VBoxContainer/HeaderPanel/VBoxContainer/NodeTypeSection/HBoxContainer/AddTypeButton.connect("pressed", _on_add_type_button_pressed)
				$VBoxContainer/TemplatesPanel/VBoxContainer/ButtonContainer/NewTemplateButton.connect("pressed", _on_new_template_button_pressed)
				$VBoxContainer/TemplatesPanel/VBoxContainer/ButtonContainer/EditTemplateButton.connect("pressed", _on_edit_template_button_pressed)
				$VBoxContainer/TemplatesPanel/VBoxContainer/ButtonContainer/DeleteTemplateButton.connect("pressed", _on_delete_template_button_pressed)
				$VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer2/AddMetadataButton.connect("pressed", _on_add_metadata_button_pressed)
				$VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer2/SaveButton.connect("pressed", _on_save_button_pressed)
				$VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer2/CancelButton.connect("pressed", _on_cancel_button_pressed)
				templates_list.connect("item_selected", _on_template_selected)

				# Connect double-click (item_activated) signal for opening the template editor
				templates_list.connect("item_activated", _on_template_double_clicked)

				add_type_dialog.connect("confirmed", _on_add_type_dialog_confirmed)
				apply_template_dialog.connect("confirmed", _on_apply_template_dialog_confirmed)

				ui_ready = true
				print("UI components found and connected")
		else:
				print("Warning: UI components not found, connections not established")

		# We'll delay the UI update until the template_manager is properly set
		# by the plugin script
		print("Template editor ready - waiting for template manager")

		# Initialize UI if template_manager is already set
		if template_manager and ui_ready:
				initialize()

		# Apply custom styling to buttons
		var buttons = [
				$VBoxContainer/HeaderPanel/VBoxContainer/NodeTypeSection/HBoxContainer/AddTypeButton,
				$VBoxContainer/TemplatesPanel/VBoxContainer/ButtonContainer/NewTemplateButton,
				$VBoxContainer/TemplatesPanel/VBoxContainer/ButtonContainer/EditTemplateButton,
				$VBoxContainer/TemplatesPanel/VBoxContainer/ButtonContainer/DeleteTemplateButton,
				$VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer2/AddMetadataButton,
				$VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer2/SaveButton,
				$VBoxContainer/MetadataEditor/VBoxContainer/HBoxContainer2/CancelButton
		]

		for button in buttons:
				if is_instance_valid(button):
						button.add_theme_constant_override("h_separation", 8)

		# Clean example items from templates list
		if is_instance_valid(templates_list):
				templates_list.clear()

# This function will be called once the template manager is properly set
func initialize() -> void:
		if template_manager and ui_ready:
				print("Template manager assigned - initializing UI")
				update_node_type_list()
		else:
				print("Warning: Cannot initialize - template_manager or UI not ready")

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

func update_templates_list() -> void:
		if not template_manager or not ui_ready:
				printerr("Cannot update templates list: template_manager or UI not ready")
				return

		if not is_instance_valid(templates_list):
				printerr("Cannot update templates list: templates_list is not valid")
				return

		templates_list.clear()

		if current_node_type.is_empty():
				return

		var templates = template_manager.get_templates_for_node_type(current_node_type)
		for template_name in templates:
				templates_list.add_item(template_name)

func _on_node_type_selected(index: int) -> void:
		current_node_type = node_type_option.get_item_text(index)
		update_templates_list()

# Setter for template_manager that properly initializes the UI
func set_template_manager(manager: RefCounted) -> void:
		template_manager = manager
		# Initialize the UI once the template manager is set and UI is ready
		if ui_ready:
				initialize()

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
				update_templates_list()

func _on_new_template_button_pressed() -> void:
		if current_node_type.is_empty():
				return

		editing_template = false
		current_template_name = ""
		template_name_field.text = ""

		# Clear metadata items
		for child in metadata_list.get_children():
				child.queue_free()
		metadata_items = []

		# Add a few empty metadata fields to start with
		for i in range(3):
				_add_metadata_field("", "")

		metadata_editor.visible = true

func _on_edit_template_button_pressed() -> void:
		var selected_items = templates_list.get_selected_items()
		if selected_items.size() == 0 or current_node_type.is_empty():
				return

		var template_name = templates_list.get_item_text(selected_items[0])
		current_template_name = template_name

		# Use the common function to open the editor
		_open_template_editor(template_name)

func _on_delete_template_button_pressed() -> void:
		var selected_items = templates_list.get_selected_items()
		if selected_items.size() == 0 or current_node_type.is_empty():
				return

		var template_name = templates_list.get_item_text(selected_items[0])
		template_manager.delete_template(current_node_type, template_name)
		update_templates_list()

func _on_template_selected(index: int) -> void:
		# Called when a template is selected in the list
		pass

func _on_add_metadata_button_pressed() -> void:
		_add_metadata_field("", "")

func _add_metadata_field(key: String, value: String, type_id: int = 0) -> void:
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
		remove_button.connect("pressed", _remove_metadata_field.bind(panel))
		hbox.add_child(remove_button)

		metadata_list.add_child(panel)
		metadata_items.append({"panel": panel, "key": key_input, "value": value_input, "type": type_option})

func _remove_metadata_field(panel: PanelContainer) -> void:
		for i in range(metadata_items.size()):
				if metadata_items[i]["panel"] == panel:
						metadata_items.remove_at(i)
						break

		panel.queue_free()

func _on_save_button_pressed() -> void:
		var template_name = template_name_field.text.strip_edges()
		if template_name.is_empty() or current_node_type.is_empty():
				return

		# Collect metadata from UI
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

		# Save the template
		template_manager.create_template(template_name, current_node_type, metadata)

		# Update UI and hide editor
		update_templates_list()
		metadata_editor.visible = false

func _on_cancel_button_pressed() -> void:
		metadata_editor.visible = false

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
								update_templates_list()
								break

				if not found and not node_type.is_empty():
						current_node_type = node_type

						# Just ensure the node type exists temporarily, but don't save it yet
						if template_manager and not template_manager.templates.has(current_node_type):
								# Use the new method that doesn't save empty node types
								template_manager.ensure_node_type_exists(current_node_type)

						update_node_type_list()
						update_templates_list()

func show_apply_templates_dialog(node: Node) -> void:
		if not node:
				return

		var node_type = node.get_class()
		var templates = template_manager.get_templates_for_node_type(node_type)

		template_options.clear()
		for template_name in templates:
				template_options.add_item(template_name)

		if template_options.item_count > 0:
				apply_template_dialog.popup_centered()

func _on_apply_template_dialog_confirmed() -> void:
		if selected_node and template_options.get_selected_items().size() > 0:
				var template_name = template_options.get_item_text(template_options.get_selected_items()[0])
				var node_type = selected_node.get_class()
				template_manager.apply_template_to_node(selected_node, node_type, template_name)

func _on_resized() -> void:
		# This function now allows natural resizing
		# No need to enforce minimum size as Godot's layout system will handle it
		pass

# Handle double-clicks on templates in the list
func _on_template_double_clicked(index: int) -> void:
		# Get the template name from the selected index
		var template_name = templates_list.get_item_text(index)

		# Set the current template name
		current_template_name = template_name

		# Open the editor with this template
		_open_template_editor(template_name)

# Common function to open the template editor with a specific template
func _open_template_editor(template_name: String) -> void:
		if current_node_type.is_empty() or template_name.is_empty():
				return

		# Set the template name field
		template_name_field.text = template_name

		# Clear existing metadata fields
		for child in metadata_list.get_children():
				child.queue_free()
		metadata_items = []

		# Populate metadata fields
		var templates = template_manager.get_templates_for_node_type(current_node_type)
		if templates.has(template_name):
				var template = templates[template_name]
				for key in template:
						var value
						var type_id = 0 # default to string

						# Check if this is using the new format with type information
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
								# Legacy format
								value = str(template[key])

								# Try to guess the type
								if template[key] is float or template[key] is int:
										type_id = template_manager.TYPE_NUMBER
								elif template[key] is bool:
										type_id = template_manager.TYPE_BOOLEAN
										value = value.to_lower()
								elif template[key] is Array:
										type_id = template_manager.TYPE_ARRAY
										value = JSON.stringify(template[key])

						_add_metadata_field(key, value, type_id)

		editing_template = true
		metadata_editor.visible = true
