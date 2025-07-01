@tool
extends Node

## A utility singleton for accessing and working with node metadata
## Access this as MetadataUtils throughout your code

# Type constants (same as TemplateManager for consistency)
const TYPE_STRING = 0
const TYPE_NUMBER = 1
const TYPE_BOOLEAN = 2
const TYPE_ARRAY = 3

## Returns true if the node has the specified metadata key
func has(node: Node, key: String) -> bool:
	if node == null:
		push_error("MetadataUtils.has(): Node is null")
		return false
	return node.has_meta(key)

## Returns true if the node has all the specified metadata keys
func has_all(node: Node, keys: Array) -> bool:
	if node == null:
		push_error("MetadataUtils.has_all(): Node is null")
		return false

	for key in keys:
		if not node.has_meta(key):
			return false
	return true

## Returns true if the node has any of the specified metadata keys
func has_any(node: Node, keys: Array) -> bool:
	if node == null:
		push_error("MetadataUtils.has_any(): Node is null")
		return false

	for key in keys:
		if node.has_meta(key):
			return true
	return false

## Gets metadata with a default value if not found
func get_value(node: Node, key: String, default_value = null):
	if node == null:
		push_error("MetadataUtils.get_value(): Node is null")
		return default_value

	if node.has_meta(key):
		return node.get_meta(key)
	return default_value

## Gets a string value from metadata (with optional default)
func get_string(node: Node, key: String, default: String = "") -> String:
	var value = get_value(node, key, default)
	if value == null:
		return default
	return str(value)

## Gets a number value from metadata (with optional default)
func get_number(node: Node, key: String, default: float = 0.0) -> float:
	var value = get_value(node, key, default)
	if value == null:
		return default

	if value is int or value is float:
		return float(value)

	# Try to convert string to number
	if value is String and value.is_valid_float():
		return float(value)

	return default

## Gets a boolean value from metadata (with optional default)
func get_bool(node: Node, key: String, default: bool = false) -> bool:
	var value = get_value(node, key, default)
	if value == null:
		return default

	if value is bool:
		return value

	if value is String:
		value = value.to_lower()
		if value == "true" or value == "yes" or value == "1":
			return true
		if value == "false" or value == "no" or value == "0":
			return false

	if value is int or value is float:
		return value > 0

	return default

## Gets an array value from metadata (with optional default)
func get_array(node: Node, key: String, default: Array = []) -> Array:
	var value = get_value(node, key, default)
	if value == null:
		return default

	if value is Array:
		return value

	# If not array, return single item array with the value
	return [value]

## Get metadata of specific type (using the TYPE_ constants)
func get_typed_value(node: Node, key: String, expected_type: int, default = null):
	var value = get_value(node, key, default)

	match expected_type:
		TYPE_STRING:
			return get_string(node, key, "" if default == null else str(default))

		TYPE_NUMBER:
			return get_number(node, key, 0.0 if default == null else float(default))

		TYPE_BOOLEAN:
			return get_bool(node, key, false if default == null else bool(default))

		TYPE_ARRAY:
			return get_array(node, key, [] if default == null else (default if default is Array else [default]))

		_: # Default case
			return value

## Set a metadata value with the appropriate type
func set_value(node: Node, key: String, value, type: int = -1) -> void:
	if node == null:
		push_error("MetadataUtils.set_value(): Node is null")
		return

	# Auto-detect type if not specified
	if type < 0:
		if value is bool:
			type = TYPE_BOOLEAN
		elif value is int or value is float:
			type = TYPE_NUMBER
		elif value is Array:
			type = TYPE_ARRAY
		else:
			type = TYPE_STRING

	# Ensure value has the correct type
	var typed_value
	match type:
		TYPE_STRING:
			typed_value = str(value)
		TYPE_NUMBER:
			if value is String and value.is_valid_float():
				typed_value = float(value)
			elif value is int or value is float:
				typed_value = value
			else:
				typed_value = 0
		TYPE_BOOLEAN:
			if value is String:
				value = value.to_lower()
				typed_value = value == "true" or value == "yes" or value == "1"
			elif value is int or value is float:
				typed_value = value > 0
			else:
				typed_value = bool(value)
		TYPE_ARRAY:
			if value is Array:
				typed_value = value
			else:
				typed_value = [value]
		_:
			typed_value = value

	node.set_meta(key, typed_value)

## Remove a metadata key from a node
func remove(node: Node, key: String) -> void:
	if node == null:
		push_error("MetadataUtils.remove(): Node is null")
		return

	if node.has_meta(key):
		node.remove_meta(key)

## Remove multiple metadata keys from a node
func remove_many(node: Node, keys: Array) -> void:
	if node == null:
		push_error("MetadataUtils.remove_many(): Node is null")
		return

	for key in keys:
		if node.has_meta(key):
			node.remove_meta(key)

## Remove all metadata from a node
func clear_all(node: Node) -> void:
	if node == null:
		push_error("MetadataUtils.clear_all(): Node is null")
		return

	var keys = node.get_meta_list()
	for key in keys:
		node.remove_meta(key)

## Copy metadata from one node to another
func copy_metadata(from_node: Node, to_node: Node, replace: bool = true) -> void:
	if from_node == null or to_node == null:
		push_error("MetadataUtils.copy_metadata(): One of the nodes is null")
		return

	var keys = from_node.get_meta_list()

	for key in keys:
		if replace or not to_node.has_meta(key):
			to_node.set_meta(key, from_node.get_meta(key))

## Get all metadata as a dictionary
func get_all_metadata(node: Node) -> Dictionary:
	var result = {}

	if node == null:
		push_error("MetadataUtils.get_all_metadata(): Node is null")
		return result

	var keys = node.get_meta_list()
	for key in keys:
		result[key] = node.get_meta(key)

	return result

## Apply a dictionary of metadata to a node
func apply_metadata(node: Node, metadata: Dictionary, clear_existing: bool = true) -> void:
	if node == null:
		push_error("MetadataUtils.apply_metadata(): Node is null")
		return

	if clear_existing:
		clear_all(node)

	for key in metadata:
		var value = metadata[key]

		# Handle the new format with type information
		if value is Dictionary and value.has("type") and value.has("value"):
			set_value(node, key, value.value, value.type)
		else:
			set_value(node, key, value)
