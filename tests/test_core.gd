@tool
extends McpTestSuite

## The Core Mission (tools/build_core.gd): the fortified Harbour from the south pier, the freight lift that
## opens a corridor to the Core room, the director in it, and the terminal that hands off to the finale.

const SCENE := "res://areas/core/core.tscn"
const ROOM := Rect2(-74, -18, 20, 20)  # the Core room in world metres (x, z)


func suite_name() -> String:
	return "core"


func test_the_core_mission_runs_in_its_own_area_with_the_director() -> void:
	assert_eq(Campaign.MISSIONS[3].area, SCENE)
	assert_eq(Campaign.MISSIONS[3].targets, ["SECURITY DIRECTOR"])
	assert_eq(Aigis.plan_mission({}, 0.0, 3).budget, 6)
	assert_eq(Aigis.CAPS[3], 3)


func test_only_the_core_waits_for_the_terminal_to_save_the_slot() -> void:
	assert_true(MissionRun.saves_on_commit({mission = 2}))
	assert_false(MissionRun.saves_on_commit({mission = Campaign.MISSIONS.size()}))


## The Harbour again, but landed at the south pier's tip, not on the freighter: the same place, not the same Mission.
func test_it_starts_on_the_south_pier_with_the_freighter_empty() -> void:
	var core: Node = load(SCENE).instantiate()
	var start: Vector3 = core.get_node("Spots/OperativeStart").position
	assert_true(Vector2(start.x, start.z).distance_to(Vector2(52.0 - 40.0, 77.0 - 40.0)) < 0.01, "the pier tip (52, 77)")
	for p: Node3D in core.get_node("GuardPosts").get_children():
		assert_true(p.position.x < 61.0 - 40.0, "%s off the freighter" % p.name)
	core.free()


## The room's second way in: the plant room's stair, the gallery, and a drop through the parapet's gap behind
## crates (playtest 2: no ladder down).
func test_the_gallery_drops_behind_crates_with_core1_beyond_them() -> void:
	var core: Node = load(SCENE).instantiate()
	assert_true(core.has_node("NavRegion/Solid/PlantStair"), "a stair up to the gallery, not a ladder")
	assert_false(core.has_node("Ladders/LadderGallery"), "no ladder down: the Operative drops")
	for n in ["DropCrate1", "DropCrate2", "DropCrate3"]:
		assert_true(core.has_node("NavRegion/Solid/" + n), n)
	var guard: Node3D = core.get_node("GuardPosts/PostCore1")
	var landing := Vector3(-20.0 - 40.0, 0, 26.2 - 40.0)
	assert_true((-guard.basis.z).dot((landing - guard.position).normalized()) < -0.9, "the landing is behind Core1")
	core.free()


## The director, the Core room's own guards and the safe room are inside the room; the room counts a director left
## lying (CoreRoomZone) and the terminal is the Extraction point (playtest 2: the whole room ended the Mission on a dart).
func test_the_room_holds_the_director_a_guard_and_the_extraction_point() -> void:
	var core: Node = load(SCENE).instantiate()
	assert_true(_in_room(core.get_node("TargetPosts/TargetPost1")), "director")
	assert_true(_in_room(core.get_node("Spots/SafeRoom")), "safe room")
	var posts := core.get_node("GuardPosts").get_children().filter(func(p: Node) -> bool: return p.name.begins_with("PostCore"))
	assert_eq(posts.size(), 1)
	for p: Node3D in posts:
		assert_true(_in_room(p), p.name)
	var zone: Area3D = core.get_node("CoreRoomZone")
	var box := (zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
	assert_true(Rect2(zone.position.x - box.size.x / 2, zone.position.z - box.size.z / 2, box.size.x, box.size.z).encloses(ROOM.grow(-1.0)), "the zone covers the room")
	var ep: Node3D = core.get_node("ExtractionPoint")
	assert_true(ep.position.distance_to(core.get_node("CoreTerminal").position) < 1.0, "Extraction is the terminal")
	core.free()


func _in_room(n: Node3D) -> bool:
	return ROOM.has_point(Vector2(n.position.x, n.position.z))


## The lift mouth, the corridor, both sides of the Core room's door and the terminal are on the navmesh.
func test_the_corridor_and_room_are_on_the_navmesh() -> void:
	var core: Node = load(SCENE).instantiate()
	var nm: NavigationMesh = (core.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	var ys := 32.0 - 40.0
	for x in [-30.0, -20.0, -15.0, -8.0, -2.0, 4.0]:  # diagram x: room, by its door, corridor, past the cliff, lift
		assert_true(_on_mesh(nm, Vector3(x - 40.0, 0, ys)), "x=%s" % x)
	assert_true(_on_mesh(nm, core.get_node("TargetPosts/TargetPost1").position))
	assert_true(_on_mesh(nm, core.get_node("Spots/SafeRoom").position))
	core.free()


func test_the_lift_door_blocks_the_corridor_until_intel_lift_is_reached() -> void:
	var core: Node = load(SCENE).instantiate()
	var door: Node = core.get_node("LiftDoor")
	assert_true(door is StaticBody3D)
	assert_ne(door.get_parent().name, "NavRegion", "the navmesh is baked open, the door only blocks bodies")
	core.free()
	var intel := Area3D.new()
	intel.name = "IntelLift"
	intel.set_script(load("res://areas/intel_pickup.gd"))
	var d := StaticBody3D.new()
	d.set_script(load("res://areas/core/lift_door.gd"))
	_root().add_child(intel)
	_root().add_child(d)
	assert_false(d.is_queued_for_deletion())
	intel.reached.emit()
	assert_true(d.is_queued_for_deletion(), "the lift opens")
	intel.free()
	d.free()


func test_the_director_speaks_once_when_the_operative_enters() -> void:
	TranslationServer.set_locale("en")
	var hud := _hud()
	var entry := Area3D.new()
	entry.set_script(load("res://areas/core/core_entry.gd"))
	_root().add_child(entry)
	var op := Node3D.new()
	op.add_to_group("operative")
	entry.body_entered.emit(Node3D.new())
	assert_eq(hud.heard.size(), 0, "only the Operative sets it off")
	entry.body_entered.emit(op)
	entry.body_entered.emit(op)
	assert_eq(hud.heard.size(), 1)
	assert_eq(hud.heard[0][0], "SECURITY DIRECTOR")
	assert_ne(hud.heard[0][1], "core.director.01", "the key is translated")
	entry.free()
	hud.free()
	op.free()


func test_the_terminal_hands_off_to_the_finale_once_the_mission_is_done() -> void:
	var run := _fake("extends Node\nvar ended := false\nfunc _enter_tree() -> void:\n\tadd_to_group(\"mission_plan\")\n")
	var finale := _fake("extends Node\nvar begun := 0\nfunc _enter_tree() -> void:\n\tadd_to_group(\"finale\")\nfunc begin() -> void:\n\tbegun += 1\n")
	var t := Area3D.new()
	t.set_script(load("res://areas/core/core_terminal.gd"))
	_root().add_child(t)
	t.use()
	assert_eq(finale.begun, 0, "not before the director is dealt with")
	run.ended = true
	t.use()
	assert_eq(finale.begun, 1)
	for n in [t, run, finale]:
		n.free()


## A Neutralized Target lying in the Extraction point is done (no carry); lying elsewhere it isn't.
func test_a_choked_target_in_the_extraction_point_counts() -> void:
	var run := MissionRun.new()
	run.record = Aigis.new_record()
	run.record.mission = 3
	var ep := Area3D.new()
	ep.set_script(load("res://areas/extraction_point.gd"))
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	shape.shape = BoxShape3D.new()
	ep.add_child(shape)
	ep.position = Vector3(100, 0, 0)
	var t: Guard = load("res://actors/guard/guard.tscn").instantiate()
	t.add_to_group("targets")
	_root().add_child(ep)
	_root().add_child(run)
	_root().add_child(t)
	t.neutral_left = 10.0
	t.global_position = Vector3(0, 0, 0)
	assert_eq(run._targets_left().size(), 1, "lying outside Extraction")
	t.global_position = Vector3(100.5, 0, 0)
	assert_eq(run._targets_left().size(), 0, "lying in it")
	t.neutral_left = 0.0
	assert_eq(run._targets_left().size(), 1, "awake again")
	for n in [t, run, ep]:
		n.free()


func _hud() -> Node:
	var h := _fake("extends Node\nvar heard := []\nfunc _enter_tree() -> void:\n\tadd_to_group(\"radio_log\")\nfunc say(who: String, text: String) -> void:\n\theard.append([who, text])\n")
	return h


func _fake(src: String) -> Node:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	var n := Node.new()
	n.set_script(s)
	_root().add_child(n)
	return n


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _on_mesh(nm: NavigationMesh, p: Vector3) -> bool:
	var v := nm.get_vertices()
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		for k in range(1, poly.size() - 1):
			var t := [v[poly[0]], v[poly[k]], v[poly[k + 1]]]
			if absf((t[0].y + t[1].y + t[2].y) / 3.0 - p.y) < 1.0 and _in_triangle(p, t[0], t[1], t[2]):
				return true
	return false


func _in_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
	var d1 := (p.x - b.x) * (a.z - b.z) - (a.x - b.x) * (p.z - b.z)
	var d2 := (p.x - c.x) * (b.z - c.z) - (b.x - c.x) * (p.z - c.z)
	var d3 := (p.x - a.x) * (c.z - a.z) - (c.x - a.x) * (p.z - a.z)
	return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))

