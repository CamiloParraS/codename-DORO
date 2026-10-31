@tool
extends McpTestSuite

## The Core's Descent (areas/core/descent_car.gd, tools/cine/core.gd): the lift ride that plays when IntelLift is
## reached, with five lights on the car's panel that show the Dominant Voice before the debate.

const SCENE := "res://areas/core/core.tscn"
const KEY := "CineDescent"

var _area: Node


func suite_name() -> String:
	return "core_descent"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()
	(Engine.get_main_loop() as SceneTree).paused = false


func test_the_lights_come_on_in_table_order_and_the_dominant_one_is_brightest() -> void:
	for dom in ["pallas", "nike", "gorgo"]:
		var e := DescentLogic.energies(5.0, 1.0, dom)
		var top := Aigis.VOICES[e.find(e.max())]
		assert_eq(top, dom, "%s is the brightest" % dom)
		for i in e.size():
			if Aigis.VOICES[i] != dom:
				assert_true(absf(e[i] - e[Aigis.VOICES.find(dom)] * DescentLogic.DIM) < 0.001, "%s dims to 40%%" % Aigis.VOICES[i])
	var mid := DescentLogic.energies(2.5, 0.0, "nike")
	assert_true(mid[0] > 0.0 and mid[1] > 0.0 and mid[2] > 0.0 and mid[3] == 0.0 and mid[4] == 0.0, "two on, the third coming, the rest dark")


func test_the_dominant_voice_is_read_the_way_the_finale_reads_it() -> void:
	for ratio in [0.0, 0.5, 1.0]:
		var rec := Aigis.new_record()
		rec.denominator = 10
		rec.lethality = int(ratio * 10)
		assert_eq(DescentLogic.dominant_of(rec), Finale.from_record(rec).band)


func test_a_light_blips_as_it_comes_on_and_a_skip_blips_nothing() -> void:
	assert_eq(DescentLogic.lit_voice(0.9, 1.1), "promachos")
	assert_eq(DescentLogic.lit_voice(4.9, 5.0), "glaukopis")
	assert_eq(DescentLogic.lit_voice(1.2, 1.4), "")
	assert_eq(DescentLogic.lit_voice(0.0, 5.0), "", "a jump to the end is silent")


func test_the_core_has_a_descent_within_its_length_range() -> void:
	_area = load(SCENE).instantiate()
	var p := Cine.take_of(_area, KEY)
	assert_true(p != null and CineLogic.length_ok(p), "a take of 6 to 10 s")
	assert_true(p.get_animation("take").length <= 10.0)
	assert_eq(p.get_meta("pcams").size(), 2, "the cab shot and the corridor cut")
	assert_true(_area.has_node("DescentCab/Panel"), "the car and its panel")
	assert_true(_area.has_node("Cine/CineDescentRig/Path"), "the rail ticket 10 reuses")


func test_the_operative_rides_in_a_sealed_car_and_ends_at_the_lift_exit() -> void:
	_area = load(SCENE).instantiate()
	var p := Cine.take_of(_area, KEY)
	var clip := p.get_animation("take")
	var path := NodePath("../Operative:position")
	var t := clip.find_track(path, Animation.TYPE_VALUE)
	var first: Vector3 = clip.track_get_key_value(t, 0)
	var last: Vector3 = clip.track_get_key_value(t, clip.track_get_key_count(t) - 1)
	var exit := CoreCine.exit_world()
	assert_true(last.distance_to(exit) < 0.1, "ends at CORE_LIFT_EXIT")
	assert_true(first.distance_to(exit) > 80.0, "rides far from every guard")
	assert_true(first.y > 60.0, "high above the Area")


func test_reaching_the_lift_plays_the_descent_once_and_the_clock_holds() -> void:
	_area = load(SCENE).instantiate()
	var run: MissionRun = _area.get_node("MissionRun")
	run.cine = {none = true}  # the default record is Mission 1, whose intro take the Core has no node for
	(Engine.get_main_loop() as SceneTree).root.add_child(_area)
	var op = _area.get_node("Operative")
	var before: float = run.rank.seconds
	_area._descend()
	_area._descend()
	assert_eq(_area.find_children("CineRunner", "Cine", true, false).size(), 1, "double-fire plays one take")
	assert_true(run.take_playing and op.cine, "input off, clocks held")
	run._physics_process(0.5)
	assert_eq(run.rank.seconds, before, "the Mission clock holds through the ride")
	_area.get_node("MissionRun/CineRunner").skip()
	assert_true(op.global_position.distance_to(CoreCine.exit_world()) < 0.1, "out at the corridor mouth")
	assert_false(op.cine)
	assert_false(run.take_playing)
	var saved: Dictionary = run._checkpoint.operative
	assert_true((saved.xform.origin as Vector3).distance_to(CoreCine.exit_world()) < 0.1, "the Checkpoint is taken at the end, not before")


func test_the_car_lights_follow_the_missions_dominant_voice() -> void:
	_area = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_area)
	var run: MissionRun = _area.get_node("MissionRun")
	run.record.denominator = 10
	run.record.lethality = 10  # the top band
	var car = _area.get_node("DescentCab")
	car.lit = 5.0
	car.settle = 1.0
	var e: Array = Aigis.VOICES.map(func(v: String) -> float:
		return (_area.get_node("DescentCab/Panel/Lamp" + v.capitalize()).mesh.material as StandardMaterial3D).emission_energy_multiplier)
	assert_eq(Aigis.VOICES[e.find(e.max())], DescentLogic.dominant_of(run.record))
	assert_eq(Aigis.VOICES[e.find(e.max())], "gorgo")


func test_the_car_is_walled_in_from_the_inside_only() -> void:
	_area = load(SCENE).instantiate()
	var shell := _area.get_node("DescentCab/ShaftWalls") as MeshInstance3D
	var m := shell.mesh.material as StandardMaterial3D
	assert_eq(m.cull_mode, BaseMaterial3D.CULL_FRONT, "faces point in: seen from inside the car, not from outside")
	var box := AABB(shell.position - shell.mesh.size / 2.0, shell.mesh.size)
	assert_true(box.has_point(CoreCine.stand() + Vector3(0, 1.5, 0)), "the Operative stands inside it")
	assert_true(box.encloses(AABB(CoreCine.CAB - Vector3(1.7, 0.3, 2.2), Vector3(3.4, 3.3, 4.4))), "round the whole cab")
	assert_true(box.position.y < CoreCine.CAB.y - 18.0 and box.end.y > CoreCine.CAB.y + 9.0, "and the shaft strip's travel")
	assert_true(absf(box.get_center().x) > 100.0 and box.position.distance_to(Vector3.ZERO) > 100.0, "far from anything played in")
