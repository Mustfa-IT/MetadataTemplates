# Metadata Templates Plugin API Reference

This document provides a comprehensive API reference for the Metadata Templates plugin.

## Table of Contents

- [MetadataUtils (MDUtils)](#metadatautils-mdutils)
- [TemplateManager](#templatemanager)
- [TemplateDataStructure](#templatedatastructure)
- [MetadataServiceRegistry](#metadataserviceregistry)
- [MetadataBackend](#metadatabackend)
- [SerializationService](#serializationservice)
- [ValidationService](#validationservice)
- [TemplateImporter](#templateimporter)
- [TemplateExporter](#templateexporter)
- [Supporting Classes](#supporting-classes)

---

## MetadataUtils (MDUtils)

The `MetadataUtils` class is registered as an autoload singleton with the name `MDUtils`. It provides utility methods for working with node metadata.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TYPE_STRING` | 0 | Represents string metadata type |
| `TYPE_NUMBER` | 1 | Represents numeric metadata type |
| `TYPE_BOOLEAN` | 2 | Represents boolean metadata type |
| `TYPE_ARRAY` | 3 | Represents array metadata type |

### Methods

#### Basic Metadata Checks

```gdscript
func has(node: Node, key: String) -> bool
```
Returns `true` if the node has the specified metadata key.

```gdscript
func has_all(node: Node, keys: Array) -> bool
```
Returns `true` if the node has all the specified metadata keys.

```gdscript
func has_any(node: Node, keys: Array) -> bool
```
Returns `true` if the node has any of the specified metadata keys.

#### Metadata Retrieval

```gdscript
func get_value(node: Node, key: String, default_value = null) -> Variant
```
Gets metadata with a default value if not found.

```gdscript
func get_string(node: Node, key: String, default: String = "") -> String
```
Gets a string value from metadata.

```gdscript
func get_number(node: Node, key: String, default: float = 0.0) -> float
```
Gets a number value from metadata.

```gdscript
func get_bool(node: Node, key: String, default: bool = false) -> bool
```
Gets a boolean value from metadata.

```gdscript
func get_array(node: Node, key: String, default: Array = []) -> Array
```
Gets an array value from metadata.

```gdscript
func get_typed_value(node: Node, key: String, expected_type: int, default = null) -> Variant
```
Gets metadata of a specific type.

#### Metadata Modification

```gdscript
func set_value(node: Node, key: String, value, type: int = -1) -> void
```
Sets a metadata value with the appropriate type. If `type` is not specified, it will be inferred.

```gdscript
func remove(node: Node, key: String) -> void
```
Removes a metadata key from a node.

```gdscript
func remove_many(node: Node, keys: Array) -> void
```
Removes multiple metadata keys from a node.

```gdscript
func clear_all(node: Node) -> void
```
Removes all metadata from a node.

#### Bulk Operations

```gdscript
func copy_metadata(from_node: Node, to_node: Node, replace: bool = true) -> void
```
Copies metadata from one node to another.

```gdscript
func get_all_metadata(node: Node) -> Dictionary
```
Gets all metadata as a dictionary.

```gdscript
func apply_metadata(node: Node, metadata: Dictionary, clear_existing: bool = true) -> void
```
Applies a dictionary of metadata to a node.

### Usage Examples

```gdscript
# Check if a node has specific metadata
if MDUtils.has(my_node, "health"):
    print("Node has health metadata")

# Get metadata with different types
var health = MDUtils.get_number(my_node, "health", 100.0)
var name = MDUtils.get_string(my_node, "character_name", "Unknown")
var is_friendly = MDUtils.get_bool(my_node, "is_friendly", true)
var tags = MDUtils.get_array(my_node, "tags", ["default"])

# Set metadata with explicit types
MDUtils.set_value(my_node, "damage", 25.5, MDUtils.TYPE_NUMBER)
MDUtils.set_value(my_node, "is_boss", true, MDUtils.TYPE_BOOLEAN)

# Clear and copy metadata
MDUtils.clear_all(my_node)
MDUtils.copy_metadata(template_node, my_node)
```

---

## TemplateManager

The `TemplateManager` class manages template creation, loading, saving, and application.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TYPE_STRING` | 0 | Represents string metadata type |
| `TYPE_NUMBER` | 1 | Represents numeric metadata type |
| `TYPE_BOOLEAN` | 2 | Represents boolean metadata type |
| `TYPE_ARRAY` | 3 | Represents array metadata type |
| `EXTENDS_KEY` | "_extends" | Special key used for template inheritance |
| `MERGE_REPLACE_ALL` | 0 | Import strategy: Replace all existing templates |
| `MERGE_KEEP_EXISTING` | 1 | Import strategy: Only add new templates |
| `MERGE_REPLACE_NODE_TYPES` | 2 | Import strategy: Replace templates for node types found in the import file |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `templates` | TemplateDataStructure | The data structure containing all templates |
| `template_file_path` | String | The file path for template storage |
| `importers` | Dictionary | Dictionary mapping file extensions to importers |
| `exporters` | Dictionary | Dictionary mapping file extensions to exporters |

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `templates_reloaded` | none | Emitted when templates are reloaded from the file |

### Methods

#### Initialization and Setup

```gdscript
func initialize() -> void
```
Initializes the template manager, creates directories, registers importers/exporters, and loads templates.

```gdscript
func setup_file_watcher() -> void
```
Sets up a file watcher to detect external changes to the templates file.

#### Template Management

```gdscript
func create_template(template_name: String, node_type: String, metadata: Dictionary) -> void
```
Creates or updates a template with the given name, node type, and metadata.

```gdscript
func delete_template(node_type: String, template_name: String) -> void
```
Deletes a template.

```gdscript
func get_templates_for_node_type(node_type: String) -> Dictionary
```
Returns all templates for a specific node type.

```gdscript
func get_all_node_types() -> Array
```
Returns an array of all node types with templates.

```gdscript
func ensure_node_type_exists(node_type: String) -> void
```
Creates a node type entry if it doesn't exist (without saving).

#### Template Application

```gdscript
func apply_template_to_node(node: Node, node_type: String, template_name: String, clear_existing: bool = true) -> void
```
Applies a template to a node.

```gdscript
func get_merged_template(node_type: String, template_name: String) -> Dictionary
```
Returns a template with all inherited properties merged in.

```gdscript
func get_available_parent_templates(node_type: String, current_template: String = "") -> Array
```
Returns all available parent templates for a node type (for inheritance).

```gdscript
func would_cause_circular_inheritance(node_type: String, child_template: String, parent_template: String) -> bool
```
Checks if adding a parent would cause circular inheritance.

#### Template File Operations

```gdscript
func load_templates() -> void
```
Loads templates from the file.

```gdscript
func save_templates() -> void
```
Saves templates to the file.

```gdscript
func reload_templates_from_disk() -> void
```
Reloads templates from disk after external changes.

#### Import and Export

```gdscript
func export_templates_to_file(file_path: String, options: Dictionary = {}) -> bool
```
Exports templates to a file using the appropriate exporter.

```gdscript
func import_templates_from_file(file_path: String, merge_strategy: int = MERGE_REPLACE_ALL) -> Dictionary
```
Imports templates from a file using the appropriate importer.

```gdscript
func validate_templates_file(file_path: String) -> Dictionary
```
Validates that a file contains valid template data.

```gdscript
func get_available_importers() -> Dictionary
```
Returns a dictionary mapping file extensions to importer names.

```gdscript
func get_available_exporters() -> Dictionary
```
Returns a dictionary mapping file extensions to exporter names.

```gdscript
func get_import_file_filters() -> PackedStringArray
```
Returns file filters for import dialog.

```gdscript
func get_export_file_filters() -> PackedStringArray
```
Returns file filters for export dialog.

### Service Management Methods

```gdscript
func has_active_backend() -> bool
```
Returns `true` if there's an active backend available.

```gdscript
func get_available_backends() -> Dictionary
```
Returns a dictionary mapping backend IDs to their names.

```gdscript
func switch_backend(backend_id: String) -> bool
```
Switches to a different backend by ID. Returns `true` if successful.

```gdscript
func register_backend(backend_id: String, backend: MetadataBackend) -> bool
```
Registers a new backend with the given ID. Returns `true` if successful.

```gdscript
func register_serializer(serializer_id: String, serializer: SerializationService) -> bool
```
Registers a new serializer with the given ID. Returns `true` if successful.

```gdscript
func register_validator(validator_id: String, validator: ValidationService) -> bool
```
Registers a new validator with the given ID. Returns `true` if successful.

### Usage Examples

```gdscript
# Initialize the template manager
var template_manager = TemplateManager.new()
template_manager.initialize()

# Create a new template
var metadata = {
    "health": {"type": template_manager.TYPE_NUMBER, "value": 100},
    "name": {"type": template_manager.TYPE_STRING, "value": "Player"},
    "is_friendly": {"type": template_manager.TYPE_BOOLEAN, "value": true}
}
template_manager.create_template("PlayerCharacter", "Node2D", metadata)

# Apply a template to a node
var my_node = Node2D.new()
template_manager.apply_template_to_node(my_node, "Node2D", "PlayerCharacter")

# Get a merged template (with inheritance)
var merged_template = template_manager.get_merged_template("Node2D", "PlayerCharacter")

# Export templates to a file
template_manager.export_templates_to_file("res://my_templates.json")

# Import templates from a file
template_manager.import_templates_from_file("res://my_templates.json", template_manager.MERGE_KEEP_EXISTING)
```

---

## TemplateDataStructure

The `TemplateDataStructure` class represents the data structure for template storage.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TYPE_STRING` | 0 | Represents string metadata type |
| `TYPE_NUMBER` | 1 | Represents numeric metadata type |
| `TYPE_BOOLEAN` | 2 | Represents boolean metadata type |
| `TYPE_ARRAY` | 3 | Represents array metadata type |
| `EXTENDS_KEY` | "_extends" | Special key used for template inheritance |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `data` | Dictionary | The internal data structure storing templates |

### Methods

#### Template Access

```gdscript
func get_node_types() -> Array
```
Returns an array of all node types.

```gdscript
func has_node_type(node_type: String) -> bool
```
Checks if a node type exists.

```gdscript
func get_templates_for_node_type(node_type: String) -> Dictionary
```
Returns all templates for a specific node type.

```gdscript
func get_template(node_type: String, template_name: String) -> Dictionary
```
Gets a specific template.

```gdscript
func has(key: String) -> bool
```
Dictionary-like method to check if a node type exists.

```gdscript
func has_template(node_type: String, template_name: String) -> bool
```
Checks if a template exists for a specific node type.

#### Template Modification

```gdscript
func set_template(node_type: String, template_name: String, template_data: Dictionary) -> void
```
Adds or updates a template.

```gdscript
func delete_template(node_type: String, template_name: String) -> bool
```
Deletes a template.

#### Data Structure Operations

```gdscript
func duplicate() -> TemplateDataStructure
```
Creates a deep copy of the data structure.

```gdscript
func is_empty() -> bool
```
Checks if the data structure is empty.

```gdscript
func clear() -> void
```
Clears all templates.

```gdscript
func merge_with(other: TemplateDataStructure, strategy: int = 0) -> void
```
Merges with another template data structure.

```gdscript
func count_templates() -> int
```
Counts the total number of templates.

```gdscript
func clean_empty_node_types() -> void
```
Removes empty node types.

### Usage Examples

```gdscript
# Create and manipulate template data structure
var templates = TemplateDataStructure.new()

# Set templates
var template_data = {
    "health": {"type": 1, "value": 100},
    "name": {"type": 0, "value": "Enemy"}
}
templates.set_template("Node2D", "EnemyTemplate", template_data)

# Check if a template exists
if templates.has_template("Node2D", "EnemyTemplate"):
    print("Template exists")

# Get a specific template
var enemy_template = templates.get_template("Node2D", "EnemyTemplate")

# Count templates
var total = templates.count_templates()
print("Total templates: " + str(total))

# Clean up empty node types
templates.clean_empty_node_types()

# Create a duplicate
var templates_copy = templates.duplicate()
```

---

## MetadataServiceRegistry

The `MetadataServiceRegistry` class manages all plugin services and their dependencies.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `SERVICE_BACKEND` | "backend" | Identifier for backend services |
| `SERVICE_SERIALIZER` | "serializer" | Identifier for serializer services |
| `SERVICE_VALIDATOR` | "validator" | Identifier for validator services |
| `SERVICE_CONVERTER` | "converter" | Identifier for converter services |

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `service_registered` | type, id, service | Emitted when a service is registered |
| `active_service_changed` | type, id, service | Emitted when an active service changes |

### Methods

```gdscript
func register_service(type: String, id: String, service) -> bool
```
Registers a service with the given type and ID. Returns `true` if successful.

```gdscript
func set_active_service(type: String, id: String) -> bool
```
Sets the active service for a particular type. Returns `true` if successful.

```gdscript
func set_default_service(type: String, id: String) -> bool
```
Sets the default service for a particular type. Returns `true` if successful.

```gdscript
func get_active_service(type: String)
```
Returns the active service for the given type, or `null` if none exists.

```gdscript
func get_service(type: String, id: String)
```
Returns a specific service by type and ID, or `null` if not found.

```gdscript
func get_services(type: String) -> Dictionary
```
Returns all services of a given type.

```gdscript
func get_active_service_id(type: String) -> String
```
Returns the ID of the active service for a given type.

```gdscript
func get_service_ids(type: String) -> Array
```
Returns an array of all service IDs for a given type.

```gdscript
func has_service(type: String, id: String) -> bool
```
Returns `true` if a service with the given type and ID exists.

### Usage Example

```gdscript
# Create a service registry
var registry = MetadataServiceRegistry.new()

# Register a service
var my_backend = MyCustomBackend.new()
registry.register_service(MetadataServiceRegistry.SERVICE_BACKEND, "my_backend", my_backend)

# Set it as active
registry.set_active_service(MetadataServiceRegistry.SERVICE_BACKEND, "my_backend")

# Get the active service
var active_backend = registry.get_active_service(MetadataServiceRegistry.SERVICE_BACKEND)
```

## MetadataBackend

The `MetadataBackend` class is the base class for all storage backends.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `CAPABILITY_READ` | 1 << 0 | Backend supports reading templates |
| `CAPABILITY_WRITE` | 1 << 1 | Backend supports writing templates |
| `CAPABILITY_LIST` | 1 << 2 | Backend supports listing templates |
| `CAPABILITY_DELETE` | 1 << 3 | Backend supports deleting templates |
| `CAPABILITY_WATCH` | 1 << 4 | Backend supports watching for changes |
| `CAPABILITY_REMOTE` | 1 << 5 | Backend accesses remote resources |

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `templates_modified` | templates | Emitted when templates are modified externally |

### Methods

```gdscript
func get_backend_id() -> String
```
Returns the unique identifier for this backend.

```gdscript
func get_backend_name() -> String
```
Returns the human-readable name for this backend.

```gdscript
func get_capabilities() -> int
```
Returns a bitmask of the backend's capabilities.

```gdscript
func has_capability(capability: int) -> bool
```
Returns `true` if the backend has the specified capability.

```gdscript
func get_configuration_options() -> Array
```
Returns an array of configuration options for this backend.

```gdscript
func load_templates() -> TemplateDataStructure
```
Loads templates from the backend's storage.

```gdscript
func save_templates(templates: TemplateDataStructure) -> bool
```
Saves templates to the backend's storage. Returns `true` if successful.

```gdscript
func start_watching() -> void
```
Starts watching for external changes to the templates.

```gdscript
func stop_watching() -> void
```
Stops watching for external changes.

```gdscript
func get_settings_ui() -> Control
```
Returns a UI control for configuring this backend, or `null` if none is available.

```gdscript
func initialize(config: Dictionary = {}) -> bool
```
Initializes the backend with the given configuration. Returns `true` if successful.

### Implementing a Custom Backend

```gdscript
@tool
class_name MyRemoteBackend
extends MetadataBackend

var _api_url: String = ""
var _api_key: String = ""

func get_backend_id() -> String:
    return "remote_api"

func get_backend_name() -> String:
    return "Remote API Backend"

func get_capabilities() -> int:
    return CAPABILITY_READ | CAPABILITY_WRITE | CAPABILITY_REMOTE

func get_configuration_options() -> Array:
    return [
        {
            "name": "API URL",
            "property": "api_url",
            "type": TYPE_STRING,
            "default_value": "https://api.example.com/templates"
        },
        {
            "name": "API Key",
            "property": "api_key",
            "type": TYPE_STRING,
            "default_value": ""
        }
    ]

func initialize(config: Dictionary = {}) -> bool:
    if config.has("api_url"):
        _api_url = config.api_url
    if config.has("api_key"):
        _api_key = config.api_key
    return !_api_url.is_empty()

func load_templates() -> TemplateDataStructure:
    # Implementation to load from remote API
    # This is a simplified example
    var result = TemplateDataStructure.new()
    var http = HTTPRequest.new()
    # ... HTTP request logic ...
    return result

func save_templates(templates: TemplateDataStructure) -> bool:
    # Implementation to save to remote API
    # This is a simplified example
    var http = HTTPRequest.new()
    # ... HTTP request logic ...
    return true
```

## SerializationService

The `SerializationService` class is the base class for all serialization services.

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `settings_changed` | none | Emitted when serialization settings are changed |

### Methods

```gdscript
func get_serializer_id() -> String
```
Returns the unique identifier for this serializer.

```gdscript
func get_serializer_name() -> String
```
Returns the human-readable name for this serializer.

```gdscript
func get_supported_extensions() -> PackedStringArray
```
Returns the file extensions supported by this serializer.

```gdscript
func get_configuration_options() -> Array
```
Returns an array of configuration options for this serializer.

```gdscript
func serialize(data: Dictionary, options: Dictionary = {}) -> String
```
Converts a data dictionary to a string representation.

```gdscript
func deserialize(text: String, options: Dictionary = {}) -> Dictionary
```
Converts a string representation back to a data dictionary.

```gdscript
func get_file_filters() -> PackedStringArray
```
Returns file filters for open/save dialogs.

```gdscript
func get_settings_ui() -> Control
```
Returns a UI control for configuring this serializer, or `null` if none is available.

```gdscript
func initialize(settings: Dictionary = {}) -> bool
```
Initializes the serializer with the given settings. Returns `true` if successful.

### Implementing a Custom Serializer

```gdscript
@tool
class_name MyXMLSerializer
extends SerializationService

func get_serializer_id() -> String:
    return "xml"

func get_serializer_name() -> String:
    return "XML Serializer"

func get_supported_extensions() -> PackedStringArray:
    return PackedStringArray(["xml"])

func get_configuration_options() -> Array:
    return [
        {
            "name": "Use Attributes",
            "property": "use_attributes",
            "type": TYPE_BOOL,
            "default_value": true
        }
    ]

func serialize(data: Dictionary, options: Dictionary = {}) -> String:
    # Implementation to convert dictionary to XML string
    # This is a simplified example
    var xml = "<templates>\n"
    # ... conversion logic ...
    xml += "</templates>"
    return xml

func deserialize(text: String, options: Dictionary = {}) -> Dictionary:
    # Implementation to parse XML back to dictionary
    # This is a simplified example
    var result = {}
    # ... parsing logic ...
    return result

func initialize(settings: Dictionary = {}) -> bool:
    # Apply settings
    return true
```

## ValidationService

The `ValidationService` class is the base class for all validation services.

### Methods

```gdscript
func get_validator_id() -> String
```
Returns the unique identifier for this validator.

```gdscript
func get_validator_name() -> String
```
Returns the human-readable name for this validator.

```gdscript
func validate_template(template_name: String, node_type: String, template_data: Dictionary) -> Dictionary
```
Validates a single template. Returns a dictionary with `valid` (boolean), `messages` (array), and `data` (dictionary).

```gdscript
func validate_import(templates: TemplateDataStructure) -> Dictionary
```
Validates an entire template collection. Returns a dictionary with `valid` (boolean), `messages` (array), and `data` (TemplateDataStructure).

```gdscript
func get_configuration_options() -> Array
```
Returns an array of configuration options for this validator.

```gdscript
func get_settings_ui() -> Control
```
Returns a UI control for configuring this validator, or `null` if none is available.

### Implementing a Custom Validator

```gdscript
@tool
class_name RequiredFieldValidator
extends ValidationService

var _required_fields = ["id", "name"]

func get_validator_id() -> String:
    return "required_fields"

func get_validator_name() -> String:
    return "Required Fields Validator"

func validate_template(template_name: String, node_type: String, template_data: Dictionary) -> Dictionary:
    var valid = true
    var messages = []

    # Check for each required field
    for field in _required_fields:
        if not template_data.has(field):
            valid = false
            messages.append("Missing required field: " + field)

    return {
        "valid": valid,
        "messages": messages,
        "data": template_data
    }

func get_configuration_options() -> Array:
    return [
        {
            "name": "Required Fields (comma-separated)",
            "property": "required_fields",
            "type": TYPE_STRING,
            "default_value": "id,name"
        }
    ]
```

## TemplateImporter

The `TemplateImporter` class is the base class for template importers.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MERGE_REPLACE_ALL` | 0 | Import strategy: Replace all existing templates |
| `MERGE_KEEP_EXISTING` | 1 | Import strategy: Only add new templates |
| `MERGE_REPLACE_NODE_TYPES` | 2 | Import strategy: Replace templates for node types found in the import file |

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `validation_completed` | result | Emitted when validation is complete |

### Methods

#### Importer Information

```gdscript
func get_importer_name() -> String
```
Returns the name of the importer.

```gdscript
func get_supported_extensions() -> PackedStringArray
```
Returns the file extensions supported by the importer.

#### Import Operations

```gdscript
func validate_file(file_path: String) -> Dictionary
```
Validates if a file contains valid template data.

```gdscript
func import_file(file_path: String) -> TemplateDataStructure
```
Imports templates from a file.

```gdscript
func apply_templates(imported_templates: TemplateDataStructure, existing_templates: TemplateDataStructure, merge_strategy: int) -> TemplateDataStructure
```
Applies imported templates to existing templates using the specified merge strategy.

```gdscript
func count_templates(templates: TemplateDataStructure) -> int
```
Counts the number of templates in the import.

```gdscript
func preview_merge(imported_templates: TemplateDataStructure, existing_templates: TemplateDataStructure, merge_strategy: int) -> Dictionary
```
Previews the result of applying the merge strategy.

### Implementing a Custom Importer

To create a custom importer, extend `TemplateImporter` and override its methods:

```gdscript
@tool
class_name MyImporter
extends TemplateImporter

func get_importer_name() -> String:
    return "My Custom Importer"

func get_supported_extensions() -> PackedStringArray:
    return PackedStringArray(["mycustom"])

func validate_file(file_path: String) -> Dictionary:
    # Implement validation logic
    # Return { "valid": bool, "error": String, "data": TemplateDataStructure }

func import_file(file_path: String) -> TemplateDataStructure:
    # Implement import logic
```

---

## TemplateExporter

The `TemplateExporter` class is the base class for template exporters.

### Methods

#### Exporter Information

```gdscript
func get_exporter_name() -> String
```
Returns the name of the exporter.

```gdscript
func get_default_extension() -> String
```
Returns the default file extension.

```gdscript
func get_supported_extensions() -> PackedStringArray
```
Returns the file extensions supported by the exporter.

```gdscript
func get_format_options() -> Array
```
Returns an array of dictionaries with options for the exporter.

```gdscript
func get_file_filters() -> PackedStringArray
```
Returns file filters for the file dialog.

#### Export Operations

```gdscript
func export_templates(templates: TemplateDataStructure, file_path: String, options: Dictionary = {}) -> bool
```
Exports the templates to a file with the given options.

### Implementing a Custom Exporter

To create a custom exporter, extend `TemplateExporter` and override its methods:

```gdscript
@tool
class_name MyExporter
extends TemplateExporter

func get_exporter_name() -> String:
    return "My Custom Exporter"

func get_default_extension() -> String:
    return "mycustom"

func get_supported_extensions() -> PackedStringArray:
    return PackedStringArray(["mycustom"])

func get_format_options() -> Array:
    return [
        {
            "name": "Pretty Print",
            "property": "pretty_print",
            "type": TYPE_BOOL,
            "value": true
        }
    ]

func export_templates(templates: TemplateDataStructure, file_path: String, options: Dictionary = {}) -> bool:
    # Implement export logic
    # Return true if successful, false otherwise
```

---

## Supporting Classes

### JSONTemplateImporter

Implementation of `TemplateImporter` for JSON files.

### JSONTemplateExporter

Implementation of `TemplateExporter` for JSON files.

### MetadataFieldManager

Manages the UI for editing metadata fields.

### TemplateListManager

Manages the UI for template lists.

### InheritanceViewer

Shows properties inherited from parent templates.

### ParentTemplateManager

Manages the parent template selection UI.

### LocalJSONBackend

Implementation of `MetadataBackend` for local JSON files.

### JSONSerializationService

Implementation of `SerializationService` for JSON format.

---

## Common Patterns and Best Practices

### Working with Templates

1. **Creating Templates**:
   ```gdscript
   var metadata = {
       "key1": {"type": TemplateManager.TYPE_STRING, "value": "value1"},
       "key2": {"type": TemplateManager.TYPE_NUMBER, "value": 100}
   }
   template_manager.create_template("MyTemplate", "Node2D", metadata)
   ```

2. **Applying Templates**:
   ```gdscript
   template_manager.apply_template_to_node(my_node, "Node2D", "MyTemplate")
   ```

3. **Accessing Metadata**:
   ```gdscript
   var value = MDUtils.get_string(my_node, "key1", "default")
   ```

### Template Inheritance

1. **Creating a Template with Inheritance**:
   ```gdscript
   var metadata = {
       "_extends": {"type": TemplateManager.TYPE_STRING, "value": "ParentTemplate"},
       "additional_key": {"type": TemplateManager.TYPE_STRING, "value": "value"}
   }
   template_manager.create_template("ChildTemplate", "Node2D", metadata)
   ```

2. **Getting a Merged Template**:
   ```gdscript
   var merged = template_manager.get_merged_template("Node2D", "ChildTemplate")
   ```

### Import/Export

1. **Exporting Templates**:
   ```gdscript
   template_manager.export_templates_to_file("res://my_templates.json")
   ```

2. **Importing Templates**:
   ```gdscript
   template_manager.import_templates_from_file("res://my_templates.json", TemplateManager.MERGE_KEEP_EXISTING)
   ```

### Custom Types

When adding custom types:

1. Add constants to relevant classes
2. Update UI components to display and edit the type
3. Add utility methods for the new type
4. Test thoroughly

### Working with Services

1. **Registering and Using Custom Backends**:
   ```gdscript
   # Create and register a custom backend
   var my_backend = MyCustomBackend.new()
   my_backend.initialize({"some_setting": "value"})
   template_manager.register_backend("my_backend", my_backend)

   # Switch to the custom backend
   template_manager.switch_backend("my_backend")
   ```

2. **Creating a Backend with Custom Serializer**:
   ```gdscript
   # Create a serializer
   var xml_serializer = MyXMLSerializer.new()
   template_manager.register_serializer("xml", xml_serializer)

   # Create a backend using that serializer
   var backend = LocalJSONBackend.new()
   backend.initialize({"serializer": xml_serializer})
   template_manager.register_backend("xml_files", backend)
   ```

3. **Adding Validation**:
   ```gdscript
   # Create and register a validator
   var validator = RequiredFieldValidator.new()
   template_manager.register_validator("required_fields", validator)

   # Validation happens automatically when appropriate
   ```

---

This API reference is a living document and will be updated as the plugin evolves. Contributions to improve this documentation are welcome!
