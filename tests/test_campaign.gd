@tool
extends McpTestSuite

## The campaign: Missions as data, their objective steps, and the record moving Mission to Mission.


func test_every_mission_area_runs_the_harbour_script_so_guards_get_their_chatter() -> void:
	for m: Dictionary in Campaign.MISSIONS:
		var a: Node = load(m.area).instantiate()
		var s: Script = a.get_script()
		while s and not s.resource_path.ends_with("harbour/harbour.gd"):
			s = s.get_base_script()
		assert_true(s != null, m.title)
		a.free()


func suite_name() -> String:
	return "campaign"


func test_four_missions_in_index_order_with_their_areas() -> void:
	assert_eq(Campaign.MISSIONS.size(), Aigis.CAPS.size(), "Missions 1-3 and the Core")
	assert_eq(Campaign.MISSIONS[0].area, "res://areas/harbour/harbour.tscn")
	assert_eq(Campaign.MISSIONS[3].area, "res://areas/core/core.tscn", "the Core has its own Area, entered at the Harbour")
	assert_eq(Campaign.MISSIONS[0].targets, [], "Mission 1 has no Target")


## Every intel step names a pickup its Area actually has.
func test_every_intel_step_is_in_its_area() -> void:
	for m: Dictionary in Campaign.MISSIONS:
		assert_true(m.steps.size() > 0, m.title)
		var area: Node = load(m.area).instantiate()
		var names := area.find_children("*", "Area3D", true, false).map(func(n: Node) -> String: return n.name)
		for s: Dictionary in m.steps:
			assert_contains(names, s.intel, "%s: %s" % [m.title, s.intel])
		area.free()


func test_objective_is_the_current_step_then_extraction() -> void:
	assert_eq(Campaign.objective(0, 0), "FIND THE SHIPPING MANIFESTS AT WAREHOUSE A")
	assert_eq(Campaign.objective(0, 1), "COPY THE RELAY STATION'S RADIO LOG AT THE GATEHOUSE")
	assert_eq(Campaign.objective(0, 2), "REACH THE EXTRACTION POINT", "every step done")


## Linear, no replays: each completed Mission moves the record on, and the Core ends the campaign.
func test_a_new_campaign_runs_mission_1_to_done() -> void:
	Campaign.start()
	assert_eq(Campaign.record.mission, 0)
	for i in 4:
		assert_false(Campaign.done(), "before Mission %d" % (i + 1))
		Campaign.record = Aigis.complete_mission(Campaign.record, {})
	assert_true(Campaign.done(), "after the Core")
	Campaign.start()
	assert_false(Campaign.done(), "a new game starts over")
