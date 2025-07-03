@tool
class_name TemplatePreviewDialog
extends Window

signal template_modified(node, template_name)

var template_manager: RefCounted
var template_editor: MarginContainer
var node_list: Tree
var metadata_preview: VBoxContainer
var template_info_label: Label
var current_node: Node
var nodes_with_templates = {}
var edited_values = {}

@onready var tree_panel = $HSplitContainer/LeftPanel/NodeList
@onready var details_panel = $HSplitContainer/RightPanel
@onready var template_name_label = $HSplitContainer/RightPanel/VBoxContainer/TemplateNameLabel
@onready var metadata_container = $HSplitContainer/RightPanel/VBoxContainer/ScrollContainer/MetadataContainer
@onready var template_actions = $HSplitContainer/RightPanel/VBoxContainer/ActionsContainer
@onready var change_template_button = $HSplitContainer/RightPanel/VBoxContainer/ActionsContainer/ChangeTemplateButton
@onready var remove_template_button = $HSplitContainer/RightPanel/VBoxContainer/ActionsContainer/RemoveTemplateButton
@onready var save_changes_button = $HSplitContainer/RightPanel/VBoxContainer/ActionsContainer/SaveChangesButton

func _ready() -> void:
	# Setup window properties
	title = "Template Preview"
	size = Vector2i(800, 500)
	min_size = Vector2i(600, 400)

	# Fix window behavior
	unresizable = false
	exclusive = false
	transient = true  # Make it stay on top of the editor window
	always_on_top = true

	# Connect the close request signal
	connect("close_requested", _on_close_requested)

	# Connect signals
	change_template_button.connect("pressed", _on_change_template_button_pressed)
	remove_template_button.connect("pressed", _on_remove_template_button_pressed)
	save_changes_button.connect("pressed", _on_save_changes_pressed)

	# Get the node tree
	node_list = $HSplitContainer/LeftPanel/NodeList
	node_list.connect("item_selected", _on_node_selected)

	# Set up the close button
	var close_button = $HSplitContainer/RightPanel/VBoxContainer/ActionsContainer/CloseButton
	close_button.connect("pressed", _on_close_requested)

	# Hide until populated
	hide()

func _on_close_requested() -> void:
	hide()

# Populate the dialog with all nodes that have templates applied
func populate(editor_interface) -> void:
	# Clear previous entries
	node_list.clear()
	nodes_with_templates.clear()
	edited_values.clear()

	# Clear the metadata container - FIX: replaced clear() with proper child removal
	for child in metadata_container.get_children():
		child.queue_free()

	# Get the root node of the edited scene
	var edited_scene_root = editor_interface.get_edited_scene_root()
	if not edited_scene_root:
		return

	# Create the root item for the tree
	var root_item = node_list.create_item()
	root_item.set_text(0, edited_scene_root.name)

	# Scan for nodes with templates
	_find_nodes_with_templates(edited_scene_root, root_item)

	# Show the dialog if we found nodes with templates
	if nodes_with_templates.size() > 0:
		# Select the first node
		if node_list.get_root() and node_list.get_root().get_child_count() > 0:
			var first_child = node_list.get_root().get_first_child()
			first_child.select(0)
			_on_node_selected()

		# Set position to top left of editor
		position = Vector2i(50, 50)

		# Show the dialog
		show()
	else:
		# Show a message that no nodes with templates were found
		var no_templates_dialog = AcceptDialog.new()
		no_templates_dialog.dialog_text = "No nodes with templates found in the current scene."
		no_templates_dialog.title = "Template Preview"
		add_child(no_templates_dialog)
		no_templates_dialog.popup_centered()
		no_templates_dialog.connect("confirmed", func(): no_templates_dialog.queue_free())

# Recursively find all nodes with templates applied
func _find_nodes_with_templates(node: Node, parent_item) -> void:
	# Check if this node has the template metadata
	if node.has_meta("_template_name") and node.has_meta("_template_type"):
		var template_name = node.get_meta("_template_name")
		var template_type = node.get_meta("_template_type")

		# Store the node in our map
		var node_item = node_list.create_item(parent_item)
		node_item.set_text(0, node.name + " (" + template_name + ")")
		node_item.set_metadata(0, node)
		nodes_with_templates[node] = {
			"template_name": template_name,
			"template_type": template_type,
			"tree_item": node_item
		}

	# Check all children
	for child in node.get_children():
		_find_nodes_with_templates(child, parent_item)

# When a node is selected in the tree
func _on_node_selected() -> void:
	# Get the selected item
	var selected_item = node_list.get_selected()
	if not selected_item:
		return

	# Get the node from the selected item
	current_node = selected_item.get_metadata(0)
	if not current_node:
		return

	# Update the template info
	if nodes_with_templates.has(current_node):
		var info = nodes_with_templates[current_node]
		template_name_label.text = "Template: " + info.template_name + " (" + info.template_type + ")"

		# Display metadata
		_display_node_metadata(current_node)

		# Show the action buttons
		template_actions.visible = true
	else:
		template_name_label.text = "No template applied"
		for child in metadata_container.get_children():
			child.queue_free()
		template_actions.visible = false

# Display all metadata for the selected node
func _display_node_metadata(node: Node) -> void:
	# Clear previous metadata - FIX: replaced clear() with proper child removal
	for child in metadata_container.get_children():
		child.queue_free()

	# Get all metadata
	var meta_list = node.get_meta_list()

	# Skip template tracking metadata
	meta_list = meta_list.filter(func(key): return key != "_template_name" and key != "_template_type")

	if meta_list.is_empty():
		var label = Label.new()
		label.text = "No metadata found on this node."
		metadata_container.add_child(label)
		return

	# Add header
	var header = Label.new()
	header.text = "Node Metadata:"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	metadata_container.add_child(header)

	# Add a separator
	var separator = HSeparator.new()
	metadata_container.add_child(separator)

	# Track edited values for this node
	edited_values[node] = {}

	# Add each metadata item
	for key in meta_list:
		var value = node.get_meta(key)
		var type_name = "Unknown"
		var type_id = 0  # Default to string

		# Determine the type
		if value is String:
			type_name = "String"
			type_id = 0
		elif value is float or value is int:
			type_name = "Number"
			type_id = 1
		elif value is bool:
			type_name = "Boolean"
			type_id = 2
		elif value is Array:
			type_name = "Array"
			type_id = 3
			value = JSON.stringify(value)
		else:
			value = str(value)

		# Create a panel to display this metadata
		var panel = _create_editable_metadata_panel(key, value, type_name, type_id, node)
		metadata_container.add_child(panel)

# Create a panel to display a single editable metadata item
func _create_editable_metadata_panel(key: String, value, type_name: String, type_id: int, node: Node) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.23)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.35, 0.45)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Key row with type
	var key_box = HBoxContainer.new()
	vbox.add_child(key_box)

	var key_label = Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_box.add_child(key_label)

	var type_label = Label.new()
	type_label.text = "(" + type_name + ")"
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	key_box.add_child(type_label)

	# Create an editable control based on the type
	var edit_control

	match type_id:
		0: # String
			edit_control = TextEdit.new()
			edit_control.text = str(value)
			edit_control.custom_minimum_size.y = 60
			edit_control.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY

		1: # Number
			edit_control = SpinBox.new()
			edit_control.min_value = -9999999
			edit_control.max_value = 9999999
			edit_control.step = 0.1
			edit_control.allow_greater = true
			edit_control.allow_lesser = true
			edit_control.value = float(value)

		2: # Boolean
			edit_control = CheckBox.new()
			edit_control.text = "Enabled"
			edit_control.button_pressed = bool(value)

		3: # Array
			edit_control = TextEdit.new()
			edit_control.text = str(value)
			edit_control.custom_minimum_size.y = 80
			edit_control.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			edit_control.add_theme_font_size_override("font_size", 12)

		_: # Default/unknown
			edit_control = LineEdit.new()
			edit_control.text = str(value)

	# Set up the edit control
	edit_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Connect change signal and store the reference
	_connect_value_changed_signal(edit_control, node, key, type_id)

	vbox.add_child(edit_control)

	return panel

# Connect the appropriate value changed signal based on the control type
func _connect_value_changed_signal(control, node, key, type_id) -> void:
	if control is TextEdit:
		control.connect("text_changed", func(): _on_value_changed(node, key, control.text, type_id))
	elif control is LineEdit:
		control.connect("text_changed", func(text): _on_value_changed(node, key, text, type_id))
	elif control is SpinBox:
		control.connect("value_changed", func(value): _on_value_changed(node, key, value, type_id))
	elif control is CheckBox:
		control.connect("toggled", func(toggled): _on_value_changed(node, key, toggled, type_id))

# Handle value changes
func _on_value_changed(node, key, new_value, type_id) -> void:
	if not edited_values.has(node):
		edited_values[node] = {}

	edited_values[node][key] = {
		"value": new_value,
		"type": type_id
	}

# Save edited values to nodes
func _on_save_changes_pressed() -> void:
	# Apply changes for all edited nodes
	for node in edited_values:
		if is_instance_valid(node):
			for key in edited_values[node]:
				var value_data = edited_values[node][key]
				var parsed_value = _parse_value(value_data.value, value_data.type)
				node.set_meta(key, parsed_value)

	# Clear the edited values
	edited_values.clear()

	# Show confirmation
	var confirm = AcceptDialog.new()
	confirm.title = "Changes Saved"
	confirm.dialog_text = "Metadata changes have been saved to nodes."
	add_child(confirm)
	confirm.popup_centered()
	confirm.connect("confirmed", func(): confirm.queue_free())

# Parse the value based on its type
func _parse_value(value, type_id):
	match type_id:
		0: # String
			return str(value)

		1: # Number
			return float(value)

		2: # Boolean
			return bool(value)

		3: # Array
			if typeof(value) == TYPE_STRING:
				# Try to parse the JSON array
				var json = JSON.new()
				var error = json.parse(value)
				if error == OK and json.data is Array:
					return json.data
				# Fallback to simple comma-separated parsing
				var array = []
				var parts = value.strip_edges().trim_prefix("[").trim_suffix("]").split(",")
				for part in parts:
					var clean_part = part.strip_edges()
					if clean_part.is_valid_float():
						array.append(float(clean_part))
					elif clean_part.to_lower() == "true":
						array.append(true)
					elif clean_part.to_lower() == "false":
						array.append(false)
					else:
						array.append(clean_part)
				return array
			return value

	return value

# Open template change dialog
func _on_change_template_button_pressed() -> void:
	if not current_node or not template_manager:
		return

	# This should open a dialog to select a new template for the current node
	# We'll delegate this to the template editor
	if template_editor:
		template_editor.show_apply_templates_dialog(current_node)

	# Since the template may have been changed, we should refresh when the dialog is closed
	await get_tree().create_timer(0.5).timeout # Small delay to ensure template is applied
	_on_node_selected() # Refresh display

# Remove template from node
func _on_remove_template_button_pressed() -> void:
	if not current_node:
		return

	# Remove all metadata from the node
	var meta_list = current_node.get_meta_list()
	for key in meta_list:
		current_node.remove_meta(key)

	# Update the UI
	if nodes_with_templates.has(current_node):
		# Remove the item from the tree
		var item = nodes_with_templates[current_node].tree_item
		if item and item.get_parent():
			item.get_parent().remove_child(item)
		nodes_with_templates.erase(current_node)

	# Clear the display - FIX: replaced clear() with proper child removal
	template_name_label.text = "Template removed"
	for child in metadata_container.get_children():
		child.queue_free()

	# Hide action buttons
	template_actions.visible = false

	# Select another node if possible
	if node_list.get_root() and node_list.get_root().get_child_count() > 0:
		var first_child = node_list.get_root().get_first_child()
		if first_child:
			first_child.select(0)
			_on_node_selected()
	else:
		# No more templates, close the dialog
		hide()

# Set the template manager reference
func set_template_manager(manager: RefCounted) -> void:
	template_manager = manager

# Set the template editor reference
func set_template_editor(editor: MarginContainer) -> void:
	template_editor = editor
