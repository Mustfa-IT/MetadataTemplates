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

		# Demonstrate using the MetadataUtils singleton
		print("\nAccessing metadata with MetadataUtils singleton:")

		# Get a string with default value if not found
		print("  Name: " + MDUtils.get_string(self, "item_name", "Unnamed Item"))

		# Get a number with default value
		var damage = MDUtils.get_number(self, "damage", 0)
		print("  Damage: " + str(damage))

		# For consumables
		var healing = MDUtils.get_number(self, "healing_amount", 0)
		if healing > 0:
			print("  Healing: " + str(healing))

		# Get a boolean with default value
		var is_quest_item = MDUtils.get_bool(self, "is_quest_item", false)
		print("  Is Quest Item: " + str(is_quest_item))

		# For consumables
		var is_consumable = MDUtils.get_bool(self, "is_consumable", false)
		if is_consumable:
			print("  This item is consumable")

		# Get an array with default value
		var tags = MDUtils.get_array(self, "tags", [])
		print("  Tags: " + str(tags))

		# Show inheritance in action
		print("\nTemplate Inheritance Example:")
		print("  This item inherits base properties but may override some:")
		print("  - Base scale: " + str(MDUtils.get_number(self, "scale_factor", 1.0)))
		print("  - Is quest item: " + str(MDUtils.get_bool(self, "is_quest_item", false)))
		print("  - Item type: " + MDUtils.get_string(self, "weapon_type",
			MDUtils.get_string(self, "consumable_type", "basic")))

	print("===========================")
