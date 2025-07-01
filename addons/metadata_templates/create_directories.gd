@tool
extends SceneTree

func _init():
	# Create required directories
	var dir = DirAccess.open("res://")
	if dir:
		if not dir.dir_exists("addons/metadata_templates/scenes"):
			dir.make_dir_recursive("addons/metadata_templates/scenes")
		if not dir.dir_exists("addons/metadata_templates/templates"):
			dir.make_dir_recursive("addons/metadata_templates/templates")
	quit()
