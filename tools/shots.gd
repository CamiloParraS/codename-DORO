## The visual pass's fixed screenshots: loads an Area and saves one PNG per SHOTS camera to user://shots/,
## under psx_look and the Area's mood. Needs a window (not --headless):
##   godot --path . --script tools/shots.gd -- harbour
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
	annex_edges = ["res://areas/research_annex/research_annex.tscn", {
		road_out = [Vector3(0, 2.5, -28), Vector3(0, 0, -70)],
		quarry = [Vector3(15, 3, -2), Vector3(35, -10, 25)],
		west = [Vector3(-28, 2.5, 10), Vector3(-70, 0, 10)],
		south = [Vector3(-20, 2.5, 30), Vector3(-20, 0, 70)],
		north_strip = [Vector3(-30, 2.5, -20), Vector3(30, 0, -36)],
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
	var area: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() else "harbour"
	var scene: Node = load(SHOTS[area][0]).instantiate()
	root.add_child(scene)
	if area == "menu":
		scene.get_node("HudLayer").queue_free()
	var cam := Camera3D.new()
	cam.fov = 70
	scene.add_child(cam)
	DirAccess.make_dir_recursive_absolute("user://shots")
	var shots: Dictionary = SHOTS[area][1]
	for n in shots:
		cam.look_at_from_position(shots[n][0], shots[n][1])
		cam.make_current()
		await create_timer(3.0).timeout  # PropSkins swap in, shaders compile, the fps average settles
		var path := "user://shots/%s_%s.png" % [area, n]
		root.get_texture().get_image().save_png(path)
		print("saved ", ProjectSettings.globalize_path(path), " at ", Engine.get_frames_per_second(), " fps")
	quit()
