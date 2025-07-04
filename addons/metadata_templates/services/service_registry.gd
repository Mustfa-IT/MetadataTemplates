@tool
class_name MetadataServiceRegistry
extends RefCounted

# Service types
const SERVICE_BACKEND = "backend"
const SERVICE_SERIALIZER = "serializer"
const SERVICE_VALIDATOR = "validator"
const SERVICE_CONVERTER = "converter"

# Registry of all services by type
var _services = {
	SERVICE_BACKEND: {},
	SERVICE_SERIALIZER: {},
	SERVICE_VALIDATOR: {},
	SERVICE_CONVERTER: {}
}

# Active services
var _active_services = {
	SERVICE_BACKEND: null,
	SERVICE_SERIALIZER: null,
	SERVICE_VALIDATOR: null,
	SERVICE_CONVERTER: null
}

# Default service IDs
var _default_services = {
	SERVICE_BACKEND: "",
	SERVICE_SERIALIZER: "",
	SERVICE_VALIDATOR: "",
	SERVICE_CONVERTER: ""
}

# Signal when services change
signal service_registered(type, id, service)
signal active_service_changed(type, id, service)

# Register a service
func register_service(type: String, id: String, service) -> bool:
	if not _services.has(type):
		printerr("Unknown service type: " + type)
		return false

	_services[type][id] = service
	emit_signal("service_registered", type, id, service)

	# If this is the first service of this type, set it as default and active
	if _default_services[type].is_empty():
		set_default_service(type, id)
		set_active_service(type, id)

	return true

# Set the active service for a type
func set_active_service(type: String, id: String) -> bool:
	if not _services.has(type) or not _services[type].has(id):
		printerr("Service not found: " + type + "/" + id)
		return false

	_active_services[type] = id
	emit_signal("active_service_changed", type, id, _services[type][id])
	return true

# Set the default service for a type
func set_default_service(type: String, id: String) -> bool:
	if not _services.has(type) or not _services[type].has(id):
		printerr("Service not found: " + type + "/" + id)
		return false

	_default_services[type] = id
	return true

# Get an active service
func get_active_service(type: String):
	var id = _active_services[type]
	if id and _services[type].has(id):
		return _services[type][id]
	return null

# Get a service by ID
func get_service(type: String, id: String):
	if _services.has(type) and _services[type].has(id):
		return _services[type][id]
	return null

# Get all services of a type
func get_services(type: String) -> Dictionary:
	if _services.has(type):
		return _services[type].duplicate()
	return {}

# Get active service ID
func get_active_service_id(type: String) -> String:
	return _active_services[type] if _active_services.has(type) else ""

# Get list of registered service IDs by type
func get_service_ids(type: String) -> Array:
	if _services.has(type):
		return _services[type].keys()
	return []

# Check if a service exists
func has_service(type: String, id: String) -> bool:
	return _services.has(type) and _services[type].has(id)
