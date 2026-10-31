## Saves a PNG of the Scanner on: loads an Area, puts the Operative 10 m south of its first guard, turns the
## Scanner on and waits for the cones to draw. Needs a window (not --headless); the PNG lands in user://shots/scan.png.
##   godot --path . tools/scan_shot.tscn -- harbour
extends Node

const AREAS := {
	harbour = "res://areas/harbour/harbour.tscn",
	core = "res://areas/core/core.tscn",
	relay_station = "res://areas/relay_station/relay_station.tscn",
	research_annex = "res://areas/research_annex/research_annex.tscn",
}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var area: String = AREAS.get(args[0] if args else "harbour", AREAS.harbour)
	add_child(load(area).instantiate())
	await get_tree().create_timer(2.0).timeout
	var op := get_tree().get_first_node_in_group("operative")
	op.items.scan_left = 20.0
	var guards := get_tree().get_nodes_in_group("guards")
	if not guards.is_empty():
		op.global_position = guards[0].global_position + Vector3(0, 0, 10)
	await get_tree().create_timer(1.5).timeout
	DirAccess.make_dir_recursive_absolute("user://shots")
	var path := "user://shots/scan.png"
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", ProjectSettings.globalize_path(path))
	get_tree().quit()
