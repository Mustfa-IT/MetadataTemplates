@tool
class_name ParentTemplateManager
extends RefCounted

var template_manager: RefCounted
var parent_template_option: OptionButton
var current_node_type: String = ""

func _init(p_template_manager: RefCounted, p_option_button: OptionButton) -> void:
	template_manager = p_template_manager
	parent_template_option = p_option_button

func update_parent_template_dropdown(node_type: String, current_template: String = "") -> void:
	current_node_type = node_type

	if not parent_template_option or not template_manager:
		return

	parent_template_option.clear()

	# Add "None" option
	parent_template_option.add_item("None", 0)
	parent_template_option.set_item_metadata(0, "")

	# Get available parent templates
	var parent_templates = template_manager.get_available_parent_templates(node_type, current_template)

	# Add available parent templates
	for i in range(parent_templates.size()):
		var parent_name = parent_templates[i]
		parent_template_option.add_item(parent_name, i + 1)
		parent_template_option.set_item_metadata(i + 1, parent_name)

	# Set current parent if exists
	var current_parent = ""
	if not current_template.is_empty():
		var templates = template_manager.get_templates_for_node_type(node_type)
		if templates.has(current_template):
			var template = templates[current_template]
			if template.has(template_manager.EXTENDS_KEY) and template[template_manager.EXTENDS_KEY] is Dictionary:
				current_parent = template[template_manager.EXTENDS_KEY].value

	# Select the current parent
	if current_parent:
		for i in range(parent_template_option.get_item_count()):
			if parent_template_option.get_item_metadata(i) == current_parent:
				parent_template_option.select(i)
				break
	else:
		parent_template_option.select(0) # Select "None"

func get_selected_parent() -> String:
	if parent_template_option.get_selected_id() > 0:
		return parent_template_option.get_item_metadata(parent_template_option.get_selected_id())
	return ""
