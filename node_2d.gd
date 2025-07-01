extends Node2D

@export var test: Variant
@export var show_metadata_visually: bool = true

# This is a demo of the metadata templates plugin
func _ready():
	print("\n=== METADATA TEMPLATES DEMO ===")
	print("This node demonstrates the use of metadata templates")
	print("Apply a template to this node using the 'Apply Templates' button in the editor")

	# Print all metadata for this node
	var meta_keys: Array[StringName] = get_meta_list()
	if meta_keys.is_empty():
		print("No metadata found for node:", name)
		print("Try applying a template to this node!")
	else:
		print("Metadata for node:", name)
		for key in meta_keys:
			print("  %s: %s (%s)" % [key, str(get_meta(key)), typeof(get_meta(key))])

		# Demonstrate using the metadata values
		use_metadata_values()

	print("===========================")

# This function demonstrates how to use the metadata values
func use_metadata_visually() -> void:
	if not show_metadata_visually:
		return

	# Visualize metadata if it exists
	if has_meta("color"):
		# If the template contains a color value, use it
		var color_value = get_meta("color")
		if color_value is String:
			# Parse color string in hex format
			modulate = Color(color_value)
			print("Applied color from metadata: ", color_value)

	if has_meta("scale_factor") and get_meta("scale_factor") is float:
		var scale_factor = get_meta("scale_factor")
		scale = Vector2(scale_factor, scale_factor)
		print("Applied scale from metadata: ", scale_factor)

# Use metadata values for gameplay purposes
func use_metadata_values() -> void:
	# Apply visual changes first
	use_metadata_visually()

	# Demonstrate using item_id from template
	if has_meta("item_id"):
		var item_id = get_meta("item_id")
		print("Using item_id: ", item_id)

		# Example of how you might use this in a game
		if item_id is String and item_id.begins_with("quest_"):
			print("This is a quest item!")

	# Demonstrate working with boolean metadata
	if has_meta("is_quest_item") and get_meta("is_quest_item") is bool:
		var is_quest = get_meta("is_quest_item")
		print("Quest item status: ", is_quest)

	# Demonstrate working with array metadata
	if has_meta("test_array") and get_meta("test_array") is Array:
		var array = get_meta("test_array")
		print("Array contents: ")
		for i in range(array.size()):
			print("  - Index ", i, ": ", array[i])

	# Demonstrate numeric metadata
	if has_meta("damage") and (get_meta("damage") is float or get_meta("damage") is int):
		var damage = get_meta("damage")
		print("Item deals ", damage, " damage")

# Check if node has a specific set of metadata keys (useful for gameplay logic)
func has_required_metadata(required_keys: Array) -> bool:
	for key in required_keys:
		if not has_meta(key):
			return false
	return true

# Get a formatted description of the item based on metadata
func get_item_description() -> String:
	var description = ""

	if has_meta("item_name"):
		description += str(get_meta("item_name"))
	else:
		description += "Unknown Item"

	if has_meta("item_description"):
		description += "\n" + str(get_meta("item_description"))

	if has_meta("damage"):
		description += "\nDamage: " + str(get_meta("damage"))

	if has_meta("is_quest_item") and get_meta("is_quest_item"):
		description += "\n[Quest Item]"

	return description
