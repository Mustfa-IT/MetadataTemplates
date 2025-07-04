![image](https://github.com/user-attachments/assets/4de7f8b9-a8a9-4b58-bca4-1a8134d66315)

# Metadata Templates Plugin Documentation

## Introduction

The Metadata Templates plugin for Godot 4.x provides a powerful, reusable system for managing node metadata. With this plugin, you can create, edit, and apply metadata templates to your nodes, making it easy to maintain consistent data across similar objects in your game.

## Features

- Create and manage metadata templates for different node types
- Intuitive editor UI integrated into Godot
- Template inheritance system
- Metadata type system (string, number, boolean, array)
- Convenient utilities for accessing metadata in your game code
- External templates file that can be version controlled
- Import/export templates for sharing across projects
- Swappable backend storage services (local JSON, custom backends)
- Customizable serialization services (JSON, custom formats)
- Optional validation services for metadata

## Installation

1. Copy the `addons/metadata_templates` folder into your project's `addons` directory
2. Enable the plugin in Project > Project Settings > Plugins
3. The plugin adds a new "Templates" tab in the main editor interface

## Getting Started

### Accessing the Plugin

The plugin adds two main interfaces to the editor:

1. A dedicated **Templates** tab in the main editor interface
2. An **Apply Templates** button in the canvas editor when a node is selected

### Creating Your First Template

1. Select the **Templates** tab in the editor
2. Choose a node type from the dropdown (or add a new one)
    you can also select the node in the scene tree too
3. Click the **+** button to create a new template
4. Give your template a name
5. Add metadata fields with keys, values, and types
6. Click **Save Template**

### Applying Templates to Nodes

1. Select a node in the scene tree
2. Click the **Apply Templates** button in the canvas editor toolbar
3. Choose a template from the list
4. The metadata will be applied to the node

## Template Inheritance

Templates can inherit properties from other templates of the same node type.

### Creating a Template with Inheritance

1. When creating a new template, select a parent template from the "Extends Template" dropdown
2. The new template will inherit all metadata from the parent
3. You can override inherited values by defining them in the child template
4. Toggle "Show Inherited" to view properties coming from the parent template

### Inheritance Rules

- A template can only inherit from other templates of the same node type
- Circular inheritance is prevented automatically
- Child templates override parent properties with the same name
- Multiple levels of inheritance are supported (grandparent, great-grandparent, etc.)

## Import/Export Templates

The plugin allows you to share templates between projects or with other team members.

### Exporting Templates

1. Click the **Export Templates** button in the Templates tab
2. Choose a location and filename to save the templates as a JSON file
3. All current templates will be saved to the selected file

### Importing Templates

1. Click the **Import Templates** button in the Templates tab
2. Select a JSON file containing templates to import
3. A preview dialog shows you exactly what templates will be added, overwritten, or kept
4. Choose a merge strategy:
   - **Replace All Templates**: Removes all existing templates and uses only the imported ones
   - **Only Add New Templates**: Keeps existing templates and only adds templates that don't already exist
   - **Replace Node Types**: Replaces templates for node types in the imported file, but keeps other node types
5. The preview dynamically updates to show how each strategy affects your templates

### Sharing Templates

Templates are stored in standard JSON format, making them easy to share:
- Between different projects
- With team members
- In version control systems
- As part of asset packages

## Using Metadata in Your Code

### Direct Access

You can access metadata directly using Godot's built-in methods:

```gdscript
# Check if a node has metadata
if node.has_meta("health"):
    # Get metadata
    var health = node.get_meta("health")
    print("Health:", health)
```

### Using the MDUtils Singleton

The plugin provides a convenient singleton for accessing metadata with type conversion and default values:

```gdscript
# Get a string value with a default if not found
var item_name = MDUtils.get_string(node, "item_name", "Unknown Item")

# Get a number with default value
var damage = MDUtils.get_number(node, "damage", 0)

# Get a boolean with default value
var is_quest_item = MDUtils.get_bool(node, "is_quest_item", false)

# Get an array with default value
var tags = MDUtils.get_array(node, "tags", [])
```

## MDUtils API Reference

The `MDUtils` singleton provides the following methods:

| Method | Description |
|--------|-------------|
| `has(node, key)` | Returns true if node has the specified metadata key |
| `has_all(node, keys)` | Returns true if node has all the specified metadata keys |
| `has_any(node, keys)` | Returns true if node has any of the specified metadata keys |
| `get_value(node, key, default)` | Gets metadata with a default value if not found |
| `get_string(node, key, default)` | Gets a string value from metadata |
| `get_number(node, key, default)` | Gets a number value from metadata |
| `get_bool(node, key, default)` | Gets a boolean value from metadata |
| `get_array(node, key, default)` | Gets an array value from metadata |
| `get_typed_value(node, key, type, default)` | Gets metadata of specific type |
| `set_value(node, key, value, type)` | Sets a metadata value with the appropriate type |
| `remove(node, key)` | Removes a metadata key from a node |
| `remove_many(node, keys)` | Removes multiple metadata keys from a node |
| `clear_all(node)` | Removes all metadata from a node |
| `copy_metadata(from_node, to_node, replace)` | Copies metadata from one node to another |
| `get_all_metadata(node)` | Gets all metadata as a dictionary |
| `apply_metadata(node, metadata, clear_existing)` | Applies a dictionary of metadata to a node |

## Metadata Types

The plugin supports four basic types of metadata:

1. **String** - Text values
2. **Number** - Integer or floating-point numbers
3. **Boolean** - True/false values
4. **Array** - Lists of values

When editing templates, you can specify the type for each metadata field, ensuring proper conversion when applied to nodes.

## Advanced Features

### External Templates File

Templates are stored in a JSON file at `res://addons/metadata_templates/templates/templates.json` which can be version controlled with your project. The plugin automatically detects external changes to this file and reloads templates as needed.

### Swappable Backends

The plugin now supports a service-based architecture that allows you to:

1. **Change Storage Backends**: By default, templates are stored in a local JSON file, but you can create and register custom backends for:
   - Remote storage (database, cloud)
   - Alternative formats
   - Encrypted storage

2. **Custom Serialization**: Choose or create serialization services to control how templates are stored:
   - Default JSON serialization
   - Custom formats (XML, YAML, etc)
   - Compressed or encrypted storage

3. **Validation Services**: Add optional validation rules for metadata:
   - Ensure data consistency
   - Enforce project-specific requirements
   - Convert between formats

For developers interested in extending these capabilities, see the Developer Guide.

### Template Management

- Add/remove node types as needed
- Create, edit, and delete templates
- View and manage template inheritance
- Preview inherited properties
- Import/export templates for sharing between projects

## Developer Documentation

If you're interested in extending or contributing to the Metadata Templates plugin, refer to these developer resources:

- [Developer Guide](addons/metadata_templates/docs/developer_guide.md) - Architecture overview, extension points, and contribution workflow
- [API Reference](addons/metadata_templates/docs/api_reference.md) - Detailed documentation for all classes, methods, and properties

These guides provide comprehensive information for developers who want to customize the plugin, add new features, or understand the internal workings.

## Examples

### RPG Item System

```gdscript
# Define a base item template with common properties
# Then create specialized templates that inherit from it:
# - WeaponItem (inherits from ItemBase)
# - ConsumableItem (inherits from ItemBase)
# - QuestItem (inherits from ItemBase)

# When using items in code:
func use_item(item_node):
    var item_name = MDUtils.get_string(item_node, "item_name", "Unknown Item")
    var is_consumable = MDUtils.get_bool(item_node, "is_consumable", false)

    if is_consumable:
        var healing = MDUtils.get_number(item_node, "healing_amount", 0)
        player.heal(healing)
        print("Used " + item_name + " and healed " + str(healing) + " points")
    elif MDUtils.has(item_node, "damage"):
        var damage = MDUtils.get_number(item_node, "damage", 0)
        print("Used " + item_name + " and dealt " + str(damage) + " damage")
```

## Tips and Best Practices

1. Use consistent naming conventions for metadata keys
2. Create base templates and use inheritance for specialized variations
3. Document your metadata schema for team reference
4. Use the MDUtils singleton for type-safe access to metadata
5. Prefer metadata for configuration over hardcoded values
6. Use template inheritance to avoid duplicating common properties
7. Export templates to share them between projects and team members

## Troubleshooting

- If templates don't appear in the list, make sure you've selected the correct node type
- If applied metadata doesn't work, check if the template was successfully applied
- If inheritance doesn't work, ensure there are no circular references
- If importing templates fails, verify the JSON file format is correct

---

**Plugin Version:** 1.1.0
**Author:** Mustafa-IT
**License:** MIT
