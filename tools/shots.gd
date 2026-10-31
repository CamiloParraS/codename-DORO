## The visual pass's fixed screenshots: loads an Area and saves one PNG per SHOTS camera to user://shots/,
## under psx_look and the Area's mood. Needs a window (not --headless):
##   godot --path . --script tools/shots.gd -- harbour
## `-- <area> reach` instead shoots every reach spot the Area's last build wrote (user://reach/<area>.json), each
## from a few metres back along the Operative's path: what the player sees on arriving.
extends SceneTree

## [area scene, {shot: [camera position, look-at point]}] in world metres.
const SHOTS := {
	harbour = ["res://areas/harbour/harbour.tscn", {
		start = [Vector3(31, 5.5, -39), Vector3(31, 2, -18)],
		mid = [Vector3(19, 4.5, -12), Vector3(-12, 1, -6)],
		extraction = [Vector3(15, 4, 20), Vector3(12, 0.5, 38)],
		overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)],
	}],
	harbour_tour = ["res://areas/harbour/harbour.tscn", {
		road = [Vector3(-10, 2.5, -45), Vector3(-8, 1, -20)],
		gatehouse = [Vector3(-3, 2.2, -27), Vector3(6, 1.2, -32)],
		warehouse = [Vector3(-17.5, 3, 9.5), Vector3(-30, 1, 20)],
		lift = [Vector3(-18, 3, -6), Vector3(-34, 1.5, -8)],
		quay = [Vector3(20, 3, -30), Vector3(18, 1, 10)],
		lanes = [Vector3(-12, 2.5, 6), Vector3(4, 1, 22)],
		bow = [Vector3(31, 4, -20), Vector3(31, 2, -37)],
		crane = [Vector3(16, 9.5, -20.5), Vector3(-5, 0, -2)],
		stern = [Vector3(30, 4, 14), Vector3(22, 0.5, 27)],
		shelves = [Vector3(-24, 1.8, 17), Vector3(-24, 1, 24)],
		bridge = [Vector3(20, 6, 5), Vector3(31, 4, 12)],
		ops_control = [Vector3(-18.5, 2.2, -11.8), Vector3(-21, 1.2, -19)],
		ops_lobby = [Vector3(-18, 2.2, -18), Vector3(-21.5, 1.2, -8)],
		ops_locker = [Vector3(-22, 2.2, -4.5), Vector3(-19, 1.0, 0)],
		alley = [Vector3(-15.5, 2.0, 3), Vector3(-15.5, 1.2, -16)],
		liftmouth = [Vector3(-25.5, 2.0, -16), Vector3(-25.5, 1.5, -4)],
		slipway = [Vector3(-29, 3, 26), Vector3(-29, 0.5, 37)],
	}],
	## Each Area's borders from where the Operative stands: what lies past the playable square.
	harbour_edges = ["res://areas/harbour/harbour.tscn", {
		road_out = [Vector3(-10, 2.5, -32), Vector3(-10, 0, -70)],
		north_sea = [Vector3(31, 5, -36), Vector3(50, 0, -80)],
		quay_south = [Vector3(5, 2.5, 22), Vector3(10, -1, 50)],
		pier = [Vector3(12, 2, 28), Vector3(30, -1, 45)],
		cliff = [Vector3(5, 3, -25), Vector3(-45, 14, -55)],
		crane_north = [Vector3(16, 10, -21), Vector3(20, 0, -80)],
		bow_out = [Vector3(42, 7, -56), Vector3(31, 0, -38)],
	}],
	## Candidates for the main menu's backdrop (ui/main_menu/backdrop.png), shot with the HUD hidden.
	menu = ["res://areas/harbour/harbour.tscn", {
		quay = [Vector3(42, 5, 30), Vector3(0, 6, 0)],
		bow = [Vector3(48, 3, -50), Vector3(10, 7, -20)],
		water = [Vector3(55, 1.5, 10), Vector3(20, 6, -10)],
	}],
	relay_station = ["res://areas/relay_station/relay_station.tscn", {overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)]}],
	## World = diagram metres - 40, floor h up. The set dressing pass: Garage, yard, mess, office, summit.
	relay_tour = ["res://areas/relay_station/relay_station.tscn", {
		garage_out = [Vector3(-8, 2.5, 21), Vector3(4, 1.5, 27)],
		garage_in = [Vector3(5, 2.6, 23.5), Vector3(11, 1, 29.5)],
		yard = [Vector3(-26, 3, 32), Vector3(-10, 1, 29)],
		mess = [Vector3(14, 6, 2.5), Vector3(16, 4.2, -2)],
		summit = [Vector3(-12, 9, -2), Vector3(-4, 8, -25)],
		office = [Vector3(28, 12, -10), Vector3(20, 8, -28)],
	}],
	relay_edges = ["res://areas/relay_station/relay_station.tscn", {
		south_drop = [Vector3(-10, 2.5, 30), Vector3(-5, -8, 60)],
		road_out = [Vector3(38, 5.5, 4), Vector3(70, 3, 4)],
		summit_view = [Vector3(-20, 8.5, -20), Vector3(10, 0, 40)],
		summit_north = [Vector3(-10, 8, -15), Vector3(-10, 10, -50)],
		motor_pool = [Vector3(-30, 2.5, 33), Vector3(10, 0, 20)],
		hill_above = [Vector3(-20, 25, 75), Vector3(-10, -10, 40)],
		valley = [Vector3(0, -8, 90), Vector3(0, 4, 30)],
		mast = [Vector3(-20, 9, -12), Vector3(-3, 18, -29)],
	}],
	research_annex = ["res://areas/research_annex/research_annex.tscn", {overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)]}],
	## The ring-shaped lab (level-pass, ticket 22): one shot per room or route the map names.
	annex_tour = ["res://areas/research_annex/research_annex.tscn", {
		start = [Vector3(-35, 2.6, 35.5), Vector3(17, 1.5, 22)],  # behind the Operative, the dock guard under his floodlight
		dock = [Vector3(10, 2.5, 28), Vector3(17, 1.5, 22)],
		front_door = [Vector3(-26, 2, 20), Vector3(-26, 1.2, 14)],
		crawl = [Vector3(-8, 1.2, 29), Vector3(-8, 0.6, 16)],
		north_corridor = [Vector3(-30, 1.7, -10.5), Vector3(13, 1.2, -10.5)],
		south_corridor = [Vector3(12, 1.7, 2.5), Vector3(-31, 1.2, 2.5)],
		clean_room = [Vector3(-7, 1.8, -6), Vector3(1, 1, -2)],
		vault = [Vector3(4, 1.8, -4), Vector3(10, 1, -6)],
		security = [Vector3(5, 1.8, -16), Vector3(11, 1, -19)],
		archive = [Vector3(-2, 1.8, 7), Vector3(-13, 1, 10)],
		hall = [Vector3(14, 1.8, 12), Vector3(2, 1, 6)],
		strip = [Vector3(-32, 2.2, -30), Vector3(20, 1, -30)],
		extraction = [Vector3(20, 2.5, -22), Vector3(30, 0.5, -16)],
	}],
	annex_edges = ["res://areas/research_annex/research_annex.tscn", {
		road_out = [Vector3(0, 2.5, -28), Vector3(0, 0, -70)],
		quarry = [Vector3(19, 3, -2), Vector3(35, -10, 25)],
		west = [Vector3(-35, 2.5, 5), Vector3(-70, 0, 5)],
		south = [Vector3(-20, 2.5, 30), Vector3(-20, 0, 70)],
		north_strip = [Vector3(-32, 2.5, -27), Vector3(30, 0, -32)],
		yard = [Vector3(-30, 2.5, 30), Vector3(10, 0, 28)],
		sky_north = [Vector3(0, 12, -30), Vector3(0, 25, -160)],
		pit = [Vector3(25, 6, -12), Vector3(60, -14, 40)],
	}],
	core = ["res://areas/core/core.tscn", {overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)], yard = [Vector3(19, 4.5, -12), Vector3(-12, 1, -6)],
		entrance = [Vector3(-33, 1.7, -8), Vector3(-45, 2.5, -8)], up45 = [Vector3(-33, 1.7, -8), Vector3(-45, 2.2, -8)], up70 = [Vector3(-34, 2.4, -8), Vector3(-46, 2.0, -8)], up71 = [Vector3(-33, 1.0, -8), Vector3(-45, 2.2, -8)], from_inside = [Vector3(-48, 1.7, -8), Vector3(-30, 2.5, -8)], from_inside_up = [Vector3(-44, 1.7, -8), Vector3(-36, 4, -8)], cliff_side = [Vector3(-38, 16, 10), Vector3(-38, 5, -8)], corridor = [Vector3(-36, 2, -8), Vector3(-54, 1.5, -8)], room = [Vector3(-56, 2.5, -14), Vector3(-72, 1, -4)]}],
}


func _initialize() -> void:
	_shoot.call_deferred()


func _shoot() -> void:
	var args := OS.get_cmdline_user_args()
	var area: String = args[0] if args.size() else "harbour"
	var entry: Array = SHOTS.get(area, [])
	if args.size() > 1 and args[1] == "reach":
		entry = _reach_shots(area)
		area += "_reach"
	if entry.is_empty():
		push_error("no shots for %s" % area)
		quit(1)
		return
	var scene: Node = load(entry[0]).instantiate()
	root.add_child(scene)
	if area == "menu":
		scene.get_node("HudLayer").queue_free()
	var cam := Camera3D.new()
	cam.fov = 70
	scene.add_child(cam)
	DirAccess.make_dir_recursive_absolute("user://shots")
	var shots: Dictionary = entry[1]
	for n in shots:
		cam.look_at_from_position(shots[n][0], shots[n][1])
		cam.make_current()
		await create_timer(3.0).timeout  # PropSkins swap in, shaders compile, the fps average settles
		var path := "user://shots/%s_%s.png" % [area, n]
		root.get_texture().get_image().save_png(path)
		print("saved ", ProjectSettings.globalize_path(path), " at ", Engine.get_frames_per_second(), " fps")
	quit()


## [scene, {spot: [camera, look-at]}] from the build's user://reach/<area>.json, or empty if it never built.
func _reach_shots(area: String) -> Array:
	var path := "user://reach/%s.json" % area
	if not FileAccess.file_exists(path):
		push_error("%s is missing: rebuild with tools/build_%s.gd first" % [path, area])
		return []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var shots := {}
	for n: String in data.shots:
		var s: Array = data.shots[n]
		shots[n] = [Vector3(s[0][0], s[0][1], s[0][2]), Vector3(s[1][0], s[1][1], s[1][2])]
	return [data.scene, shots]
