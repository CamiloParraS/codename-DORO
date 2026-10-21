@tool
extends McpTestSuite

## Scanner and Magazine rules: charges, cycling, carrying, resupply, the throw arc.


func suite_name() -> String:
	return "items"


func test_starts_with_3_scanner_charges_and_4_magazines() -> void:
	var i := Items.new()
	assert_eq(i.charges, 3)
	assert_eq(i.magazines, 4)
	assert_eq(i.label(), "SCAN")
	assert_eq(i.count(), 3)


func test_cycling_wraps_both_ways() -> void:
	var i := Items.new()
	i.cycle(1)
	assert_eq(i.label(), "MAG")
	assert_eq(i.count(), 4)
	i.cycle(1)
	assert_eq(i.label(), "SCAN")
	i.cycle(-1)
	assert_eq(i.label(), "MAG")


func test_scanner_runs_10_s_and_spends_a_charge() -> void:
	var i := Items.new()
	assert_true(i.use_scanner())
	assert_eq(i.charges, 2)
	assert_true(i.scanning())
	i.tick(9.9)
	assert_true(i.scanning())
	i.tick(0.2)
	assert_false(i.scanning())


func test_scanner_with_no_charges_does_nothing() -> void:
	var i := Items.new()
	i.charges = 0
	assert_false(i.use_scanner())
	assert_false(i.scanning())


func test_magazine_cannot_be_thrown_while_carrying() -> void:
	var i := Items.new()
	assert_false(i.throw(true))
	assert_eq(i.magazines, 4)
	assert_true(i.throw(false))
	assert_eq(i.magazines, 3)


func test_magazine_runs_out() -> void:
	var i := Items.new()
	i.magazines = 0
	assert_false(i.can_throw(false))


func test_refill_restores_both() -> void:
	var i := Items.new()
	i.use_scanner()
	i.throw(false)
	i.refill()
	assert_eq(i.charges, 3)
	assert_eq(i.magazines, 4)


func test_arc_lands_15_m_out_on_level_ground() -> void:
	var pts := Items.arc(Vector3(0, 1, 0), Vector3(0, 0, -1), 300, 0.01)
	var down := pts.size() - 1
	for k in pts.size():
		if k > 0 and pts[k].y <= 1.0:
			down = k
			break
	assert_true(absf(-pts[down].z - 15.0) < 0.3, "landed %s" % pts[down])
	assert_true(absf(pts[down].x) < 0.001)


func test_the_crate_works_once_and_a_checkpoint_copy_remembers() -> void:
	var i := Items.new()
	var t := Tranq.new()
	var r := Rifle.new()
	i.charges = 0
	t.loaded = 0
	t.reserve = 0
	var before: Items = MissionRun.copy(i)
	assert_true(i.resupply([t, r]))
	assert_eq(i.charges, Items.SCANNER_CHARGES)
	assert_eq(t.loaded + t.reserve, Tranq.new().total)
	i.charges = 0
	assert_false(i.resupply([t, r]), "spent")
	assert_eq(i.charges, 0)
	var after: Items = MissionRun.copy(i)
	assert_false(after.resupply([t, r]), "a restore to a Checkpoint after use keeps it spent")
	assert_true(before.resupply([t, r]), "a restore to one before use gives the crate back")
