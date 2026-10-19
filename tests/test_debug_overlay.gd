@tool
extends McpTestSuite

## The F3 overlay's text: why Aigis deployed what it did, and Glaukopis's last judgement.


func suite_name() -> String:
	return "debug_overlay"


func test_it_shows_the_profile_voices_lethality_plan_and_glaukopis_doubt() -> void:
	var rec := Aigis.new_record()
	rec.points = Aigis.preset_profile("ghost")
	rec.mission = 3
	var plan := Aigis.plan_mission(rec.points, Aigis.lethality_ratio(rec), rec.mission)
	var o: Node = load("res://ui/debug_overlay/debug_overlay.gd").new()
	var text: String = o._aigis(rec, plan, null)
	for word in ["PROFILE", "VOICES", "Dominant", "LETHALITY", "ratio", "band", "projected ending", "PLAN", "budget", "pinned"]:
		assert_contains(text, word)
	var g := Glaukopis.new()
	g.last = {doubt = 55, exposed = true, reasons = [[40, "seen speaking"], [15, "too many"]]}
	var radio := Node.new()
	radio.set_script(preload("res://tests/support/radio_stub.gd"))
	radio.glaukopis = g
	radio.add_to_group("radio")
	(Engine.get_main_loop() as SceneTree).root.add_child(radio)
	(Engine.get_main_loop() as SceneTree).root.add_child(o)
	var field: String = o._field(MissionTally.new())
	radio.free()
	o.free()
	assert_contains(field, "GLAUKOPIS")
	assert_contains(field, "doubt 55  EXPOSED")
	assert_contains(field, "+40 seen speaking")
