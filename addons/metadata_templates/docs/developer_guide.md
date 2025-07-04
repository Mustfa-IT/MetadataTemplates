# Metadata Templates Plugin - Developer Guide

This document provides technical information for developers who want to extend, modify, or contribute to the Metadata Templates plugin.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Extension Points](#extension-points)
   - [Adding New Importers](#adding-new-importers)
   - [Adding New Exporters](#adding-new-exporters)
   - [Adding New Metadata Types](#adding-new-metadata-types)
4. [Development Workflow](#development-workflow)
5. [Coding Guidelines](#coding-guidelines)
6. [Testing](#testing)
7. [Contributing](#contributing)

## Architecture Overview

The Metadata Templates plugin follows a modular architecture with clear separation of concerns:

```
addons/metadata_templates/
├── data/               # Core data structures
├── docs/               # Documentation
├── exporters/          # Template exporters
├── importers/          # Template importers
├── metadata_utils.gd   # Singleton for metadata access (MDUtils)
├── scenes/             # UI scenes
├── scripts/            # UI and helper scripts
├── templates/          # Template storage
└── metadata_template_plugin.gd # Main plugin entry point
```

The plugin uses a data-driven approach with these key design principles:
1. Typed metadata (String, Number, Boolean, Array)
2. Template inheritance
3. Format-agnostic storage with importers/exporters
4. Clear separation between data and UI

## Core Components

### TemplateManager

The central component that manages templates, handles loading/saving, and coordinates between UI and data. Key responsibilities:
- Loading/saving templates
- Managing template inheritance
- Applying templates to nodes
- Coordinating importers and exporters

### TemplateDataStructure

The core data structure that represents all templates. Contains methods for:
- Accessing templates and node types
- Adding/removing templates
- Duplicating and merging template collections

### MetadataUtils (MDUtils)

A singleton that provides a clean API for working with metadata on nodes:
- Reading typed metadata
- Writing metadata with type information
- Utility functions for checking, removing, and copying metadata

### UI Components

- **TemplateEditor**: Main editor interface for creating and managing templates
- **InheritanceViewer**: Shows properties inherited from parent templates
- **TemplatePreviewDialog**: Shows templates applied to nodes in the scene
- **TemplateImportPreviewDialog**: Preview before importing templates

### Importers & Exporters

The plugin uses a modular system for importing and exporting templates in different formats:
- Base classes: `TemplateImporter` and `TemplateExporter`
- Default implementations: `JSONTemplateImporter` and `JSONTemplateExporter`

## Extension Points

### Adding New Importers

To support a new file format for importing templates:

1. Create a new class that extends `TemplateImporter`:

```gdscript
@tool
class_name MyFormatImporter
extends TemplateImporter

func get_importer_name() -> String:
    return "My Format Importer"

func get_supported_extensions() -> PackedStringArray:
    return PackedStringArray(["myext"])

func validate_file(file_path: String) -> Dictionary:
    # Validate the file and return:
    # {
    #    "valid": bool,
    #    "error": String,
    #    "data": TemplateDataStructure
    # }

    # Your validation code here

    var result = {
        "valid": true,
        "error": "",
        "data": TemplateDataStructure.new()
    }

    # Parse and populate result.data

    return result

func import_file(file_path: String) -> TemplateDataStructure:
    # Import logic
    var validation = validate_file(file_path)
    if validation.valid:
        return validation.data
    else:
        return TemplateDataStructure.new()
```

2. Register your importer in `TemplateManager._register_importers_and_exporters()`:

```gdscript
func _register_importers_and_exporters() -> void:
    # Existing code...

    # Register your new importer
    var my_importer = MyFormatImporter.new()
    importers["myext"] = my_importer
```

### Adding New Exporters

To support a new file format for exporting templates:

1. Create a new class that extends `TemplateExporter`:

```gdscript
@tool
class_name MyFormatExporter
extends TemplateExporter

func get_exporter_name() -> String:
    return "My Format Exporter"

func get_default_extension() -> String:
    return "myext"

func get_supported_extensions() -> PackedStringArray:
    return PackedStringArray(["myext"])

func get_format_options() -> Array:
    return [
        {
            "name": "Some Option",
            "property": "some_option",
            "type": TYPE_BOOL,
            "value": true
        }
    ]

func export_templates(templates: TemplateDataStructure, file_path: String, options: Dictionary = {}) -> bool:
    # Export templates to file_path using the specified options
    # Return true if successful, false otherwise

    # Your export code here

    return true
```

2. Register your exporter in `TemplateManager._register_importers_and_exporters()`:

```gdscript
func _register_importers_and_exporters() -> void:
    # Existing code...

    # Register your new exporter
    var my_exporter = MyFormatExporter.new()
    exporters["myext"] = my_exporter
```

### Adding New Metadata Types

The plugin currently supports four metadata types: String, Number, Boolean, and Array. To add a new type:

1. Add a new type constant in these files:
   - `template_data_structure.gd`
   - `metadata_utils.gd`
   - `template_manager.gd`

```gdscript
# Add your new type constant
const TYPE_COLOR = 4  # Example for a color type
```

2. Update the `MetadataFieldManager` to support the new type:
   - Add to the type dropdown
   - Add parsing support in `get_metadata_dict()`
   - Add display support in `populate_from_template()`

3. Update `MetadataUtils` to support the new type:
   - Add a getter method (`get_color()`)
   - Update the `get_typed_value()` method
   - Update the `set_value()` method

4. Update `InheritanceViewer` to display the new type
5. Update `TemplatePreviewDialog` to edit the new type

## Development Workflow

1. **Setup**: Fork the repository or create a branch for your feature
2. **Development**:
   - Make your changes
   - Test thoroughly
   - Update documentation as needed
3. **Testing**: Test your changes in different scenarios
4. **Pull Request**: Submit a pull request with a clear description of your changes

## Coding Guidelines

1. **Code Style**:
   - Follow GDScript style guidelines
   - Use clear and descriptive variable names
   - Add comments for complex logic
   - Keep functions focused and small

2. **Class Organization**:
   - Keep related functionality together
   - Use proper access modifiers (`private`, `public`)
   - Document the purpose of each class and method

3. **Signals and Events**:
   - Use signals for loose coupling
   - Document signals and their parameters
   - Connect signals in `_ready()` when possible

4. **Error Handling**:
   - Validate inputs
   - Handle edge cases
   - Use meaningful error messages
   - Avoid silent failures

## Testing

Before submitting changes, test your modifications:

1. **Basic Functionality**:
   - Creating and editing templates
   - Applying templates to nodes
   - Template inheritance
   - Import/export

2. **Edge Cases**:
   - Empty templates
   - Complex inheritance chains
   - Invalid data
   - Large template collections

3. **UI Testing**:
   - Verify that all UI components work correctly
   - Test window resizing
   - Test dialog interactions

## Contributing

1. **Report Issues**: Use the issue tracker to report bugs or suggest features
2. **Discussion**: Discuss major changes before implementation
3. **Pull Requests**: Submit pull requests with clear descriptions
4. **Documentation**: Update documentation for any changes
5. **Testing**: Include test cases for new features

### Contribution Workflow

1. Fork the repository (or create a branch if you're a collaborator)
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test thoroughly
5. Update documentation
6. Commit your changes (`git commit -am 'Add new feature'`)
7. Push to the branch (`git push origin feature/my-feature`)
8. Submit a pull request

## Architecture Diagrams

### Component Interaction

```
┌───────────────────┐      ┌───────────────────┐
│  Template Editor    │◄───►│  Template Manager   │
└────────┬──────────┘      └────────┬──────────┘
         │                          │
         ▼                          ▼
┌───────────────────┐      ┌───────────────────┐
│  UI Components      │      │ Template Data      │
│  - Field Manager    │      │ Structure          │
│  - List Manager     │      └───────┬──────────┘
│  - Preview Dialog   │               │
└───────────────────┘               ▼
                            ┌───────────────────┐
                            │ Importers/          │
                            │ Exporters           │
                            └───────────────────┘
```

### Data Flow

```
┌────────────┐     ┌────────────┐    ┌────────────┐     ┌────────────┐
│ UI Input    │────►│ Template     │────│ Template   │────►│ Node       │
│             │     │ Manager     │     │ Data       │      │ Metadata   │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
      ▲                   │                 ▲
      │                   ▼                 │
      │            ┌────────────┐          │
      └───────────┤ Importers/ │◄─────────┘
                   │ Exporters   │
                   └────────────┘
```

## Additional Resources

- [User Documentation](../README.md)
- [Godot Engine Documentation](https://docs.godotengine.org/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

---

This developer guide is a living document and will be updated as the plugin evolves. Contributions to improve this documentation are welcome!
