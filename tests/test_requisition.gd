@tool
extends McpTestSuite

## Recruits and Requisition (pw-feel 05): Recruit points from Fultoned guards, the four upgrades, the S-rank
## items, the kit a Mission is played with and the slot file keeping it all.

const DIR := "user://test_requisition"
const OPERATIVE := preload("res://actors/operative/operative.tscn")


func suite_name() -> String:
	return "requisition"


func setup() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func test_a_first_clear_pays_a_point_per_fultoned_guard_and_half_again_on_an_s() -> void:
	var r := Requisition.new()
	r.settle(0, 3, false, true)
	assert_eq(r.points, 3)
	assert_eq(r.signed, 3)
	r.settle(1, 3, true, true)
	assert_eq(r.signed, 4, "3 x 1.5, rounded down")
	assert_eq(r.points, 7, "unspent points carry over")


func test_a_replay_pays_nothing_but_its_first_s_unlocks_the_item() -> void:
	var r := Requisition.new()
	r.settle(1, 5, true, false)
	assert_eq(r.points, 0)
	assert_false(r.due, "no screen after a replay")
	assert_true(r.unlocked("heavy_suppressor"))
	assert_false(r.unlocked("long_scan"))


func test_the_core_unlocks_nothing_and_opens_no_screen() -> void:
	var r := Requisition.new()
	r.settle(3, 2, true, true)
	assert_eq(r.points, 3, "the Core still pays")
	assert_false(r.due)
	assert_eq(r.unlocked_items, [] as Array[String])


func test_the_screen_is_due_after_a_first_clear_only_with_something_to_buy() -> void:
	var r := Requisition.new()
	r.settle(0, 1, false, true)
	assert_true(r.due)
	assert_false(r.worth_opening(), "1 point buys nothing")
	r.settle(1, 1, false, true)
	assert_true(r.worth_opening(), "2 points buy a Magazine pouch")


func test_purchases_fail_below_the_price_or_at_the_cap() -> void:
	var r := Requisition.new()
	r.points = 2
	assert_false(r.buy("scanner"), "3 needed")
	assert_eq(r.points, 2)
	r.points = 100
	assert_true(r.buy("darts"))
	assert_false(r.buy("darts"), "one buy only")
	assert_true(r.buy("magazines"))
	assert_true(r.buy("magazines"))
	assert_false(r.buy("magazines"), "capped at 8")
	assert_eq(r.points, 100 - 5 - 2 - 2)
	assert_false(r.buy("nonsense"))


func test_everything_costs_23() -> void:
	var r := Requisition.new()
	r.points = 23
	for id: String in Requisition.UPGRADES:
		while r.buy(id):
			pass
	assert_eq(r.points, 0)
	assert_eq(r.kit(), {scanner = 5, magazines = 8, fultons = 5, darts = 12,
		scan_time = Items.SCANNER_TIME, suppressor = Rifle.SUPPRESSOR_SHOTS, fulton_time = 3.0})


func test_s_items_change_the_kit() -> void:
	var r := Requisition.new()
	for k in 3:
		r.settle(k, 0, true, true)
	assert_eq(r.kit().scan_time, 15.0)
	assert_eq(r.kit().suppressor, 5)
	assert_eq(r.kit().fulton_time, 2.0)


func test_the_base_kit_is_the_constants() -> void:
	assert_eq(Requisition.BASE, {scanner = Items.SCANNER_CHARGES, magazines = Items.MAGAZINES, fultons = 3,
		darts = Tranq.TOTAL, scan_time = Items.SCANNER_TIME, suppressor = Rifle.SUPPRESSOR_SHOTS, fulton_time = 3.0})


func test_the_slot_keeps_points_purchases_and_items() -> void:
	var r := Requisition.new()
	r.points = 10
	r.buy("scanner")
	r.settle(2, 0, true, false)
	SaveSlots.write(0, Aigis.new_record(), 5, DIR, {}, r.to_dict())
	var back: Requisition = SaveSlots.read(0, DIR).gear
	assert_eq(back.to_dict(), r.to_dict())
	assert_eq(typeof(back.points), TYPE_INT)
	assert_false(back.due, "the screen flag is not saved")


func test_an_old_or_malformed_slot_loads_with_none() -> void:
	var f := FileAccess.open(SaveSlots.path(1, DIR), FileAccess.WRITE)
	f.store_string(JSON.stringify({record = Aigis.new_record(), saved = 5}))
	f.close()
	assert_eq(SaveSlots.read(1, DIR).gear.to_dict(), Requisition.new().to_dict())
	f = FileAccess.open(SaveSlots.path(1, DIR), FileAccess.WRITE)
	f.store_string(JSON.stringify({record = Aigis.new_record(), saved = 5, gear = {points = "x", bought = {scanner = 9, magazines = 1}, items = ["long_scan", 3, "bogus"]}}))
	f.close()
	var g: Requisition = SaveSlots.read(1, DIR).gear
	assert_eq(g.points, 0)
	assert_eq(g.bought, {magazines = 1}, "an over-cap buy is dropped")
	assert_eq(g.unlocked_items, ["long_scan"] as Array[String])


## A Continue rolls the tally back to the Checkpoint's, Fultons included; an abort leaves nothing to bank.
func test_a_continue_restores_the_checkpoint_recruits_and_abort_banks_none() -> void:
	var run := MissionRun.new()
	run.tally.add("fulton")
	var saved: MissionTally = MissionRun.copy(run.tally)
	run.tally.add("fulton")
	run.tally.add("target_fulton")
	assert_eq(run.fultoned(), 2, "Targets give none")
	run.tally = saved
	assert_eq(run.fultoned(), 1)
	run.abort()
	assert_eq(run.fultoned(), 0)
	run.free()


func test_the_operative_wears_its_kit() -> void:
	var r := Requisition.new()
	r.points = 23
	for id: String in Requisition.UPGRADES:
		while r.buy(id):
			pass
	for k in 3:
		r.settle(k, 0, true, true)
	var op: Node = OPERATIVE.instantiate()
	op.equip(r.kit())
	assert_eq(op.items.charges, 5)
	assert_eq(op.items.magazines, 8)
	op.items.use_scanner()
	assert_eq(op.items.scan_left, 15.0)
	op.items.charges = 0
	op.items.refill()
	assert_eq(op.items.charges, 5, "the crate refills to the upgraded size")
	assert_eq(op.fultons, 5)
	assert_eq(op.fulton_time, 2.0)
	assert_eq(op.tranq.loaded, Tranq.LOAD_SIZE, "the load stays 4")
	assert_eq(op.tranq.reserve, 8)
	assert_eq(op.rifle.suppressor, 5)
	op.free()


func test_replays_and_free_mode_get_the_base_kit() -> void:
	var r := Requisition.new()
	r.points = 3
	r.buy("scanner")
	assert_eq(Campaign.kit(r, true).scanner, 4, "a first clear")
	assert_eq(Campaign.kit(r, false), Requisition.BASE, "a replay or Free mode (campaign is false for both)")


func test_the_screen_buys_the_picked_row_and_continue_closes_it() -> void:
	var was := [Campaign.gear, Campaign.slot]
	Campaign.slot = -1  # nothing written
	Campaign.gear = Requisition.new()
	Campaign.gear.points = 3
	Campaign.gear.signed = 2
	var s: Control = load("res://ui/requisition/requisition.gd").new()
	assert_contains(s.lines(), "RECRUITS SIGNED: 2")
	s.row = 0
	s.press()
	assert_eq(Campaign.gear.value("scanner"), 4)
	assert_eq(Campaign.gear.points, 0)
	var closed := [false]
	s.closed.connect(func() -> void: closed[0] = true)
	s.row = Requisition.UPGRADES.size()
	s.press()
	assert_true(closed[0])
	Campaign.gear = was[0]
	Campaign.slot = was[1]
