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
	relay_station = ["res://areas/relay_station/relay_station.tscn", {overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)]}],
	research_annex = ["res://areas/research_annex/research_annex.tscn", {overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)]}],
	core = ["res://areas/core/core.tscn", {overview = [Vector3(45, 28, 55), Vector3(5, 0, 0)], yard = [Vector3(19, 4.5, -12), Vector3(-12, 1, -6)]}],
}


func _initialize() -> void:
	_shoot.call_deferred()


func _shoot() -> void:
	var area: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() else "harbour"
	var scene: Node = load(SHOTS[area][0]).instantiate()
	root.add_child(scene)
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
