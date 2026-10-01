extends Node
class_name ConfigSeeder

## The bundled default text file, e.g. res://defaults/timings.txt
##
## IMPORTANT: .txt has no Godot importer, so it is NOT automatically included
## in exported builds. Add "*.txt" (or your exact filename) under
## Project Settings -> Export -> Resources -> "Filters to export non-resource
## files/folders", or this will work fine in the editor and then silently
## fail to find the file once you export the game.
@export_file("*.txt") var default_config_path: String = ""

## Where the user's editable copy should live, relative to the user data
## folder. e.g. "configs/timings.txt" -> user://configs/timings.txt
@export var local_path: String = "configs/timings.txt"


func _ready() -> void:
	_seed_config()


func _seed_config() -> void:
	var target_path := "user://%s" % local_path

	if FileAccess.file_exists(target_path):
		return  # Already seeded, or the user already has their own copy — leave it alone.

	# Make sure any subfolders in local_path (e.g. "configs/") exist first.
	var target_dir := target_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(target_dir):
		DirAccess.make_dir_recursive_absolute(target_dir)

	if default_config_path.is_empty():
		push_warning("ConfigSeeder: no default_config_path set, nothing to seed.")
		return

	var src := FileAccess.open(default_config_path, FileAccess.READ)
	if src == null:
		push_warning("ConfigSeeder: could not read default config at %s (error %s)" \
				% [default_config_path, FileAccess.get_open_error()])
		return
	var contents := src.get_as_text()
	src.close()

	var dst := FileAccess.open(target_path, FileAccess.WRITE)
	if dst == null:
		push_warning("ConfigSeeder: could not create %s" % target_path)
		return
	dst.store_string(contents)
	dst.close()
