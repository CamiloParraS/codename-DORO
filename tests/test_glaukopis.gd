@tool
extends McpTestSuite

## Glaukopis: one test per doubt rule in the spec's table, the 40 threshold, flagging, commit = false.


func suite_name() -> String:
	return "glaukopis"


## A clean transmission: Kostas tells Dimos to go check the dock, nothing suspicious around.
func _facts(over := {}) -> Dictionary:
	var f := {now = 100.0, speaker = "Kostas", recipients = ["Dimos"], all_units = false, order = "go",
		place = "Dock", seen_by = [], speaker_known_down = false, sees_operative = [], since_alert = INF,
		speaker_busy = false}
	f.merge(over, true)
	return f


func _doubt(over := {}) -> int:
	return Glaukopis.new().judge(_facts(over)).doubt


func test_clean_transmission_has_no_doubt() -> void:
	var j := Glaukopis.new().judge(_facts())
	assert_eq(j.doubt, 0)
	assert_false(j.exposed)
	assert_true(j.reasons.is_empty())


func test_flagged_voiceprint_is_100() -> void:
	var g := Glaukopis.new()
	g.flagged.append("Kostas")
	assert_eq(g.judge(_facts()).doubt, 100)


func test_speaker_is_recipient_is_100() -> void:
	assert_eq(_doubt({recipients = ["Kostas"]}), 100)


func test_recipient_sees_speaker_is_60() -> void:
	assert_eq(_doubt({seen_by = ["Dimos"]}), 60)


func test_two_recipients_seeing_speaker_count_once() -> void:
	assert_eq(_doubt({recipients = ["Dimos", "Eleni"], seen_by = ["Dimos", "Eleni"]}), 60)


func test_speaker_known_down_is_60() -> void:
	assert_eq(_doubt({speaker_known_down = true}), 60)


func test_all_clear_while_recipient_sees_operative_is_100() -> void:
	assert_eq(_doubt({order = "all_clear", place = "", sees_operative = ["Dimos"]}), 100)


func test_other_orders_ignore_recipient_seeing_operative() -> void:
	assert_eq(_doubt({sees_operative = ["Dimos"]}), 0)


func test_all_clear_soon_after_alert_is_30() -> void:
	assert_eq(_doubt({order = "all_clear", place = "", since_alert = 14.9}), 30)
	assert_eq(_doubt({order = "all_clear", place = "", since_alert = 15.0}), 0)
	assert_eq(_doubt({order = "hold", place = "", since_alert = 2.0}), 0)


func test_busy_speaker_is_30_for_all_clear_15_otherwise() -> void:
	assert_eq(_doubt({order = "all_clear", place = "", speaker_busy = true}), 30)
	assert_eq(_doubt({order = "go", speaker_busy = true}), 15)
	assert_eq(_doubt({order = "hold", place = "", speaker_busy = true}), 15)


func test_all_units_is_10() -> void:
	assert_eq(_doubt({recipients = ["Dimos", "Eleni"], all_units = true}), 10)


func test_contradicting_recent_order_is_30_plus_recent() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 100.0}))
	var j := g.judge(_facts({now = 129.0, place = "Gatehouse"}))
	assert_eq(j.doubt, 30 + 15)


func test_contradiction_needs_the_same_guard() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 100.0, recipients = ["Eleni"]}))
	assert_eq(g.judge(_facts({now = 110.0, place = "Gatehouse"})).doubt, 15)


func test_same_order_again_does_not_contradict() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 100.0}))
	assert_eq(g.judge(_facts({now = 110.0})).doubt, 15)


func test_contradiction_expires_after_30s() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 100.0}))
	assert_eq(g.judge(_facts({now = 130.0, order = "hold", place = ""})).doubt, 15)


func test_contradiction_is_30_once_per_judgement() -> void:
	var g := Glaukopis.new()
	g.expose_at = 1000  # keep every order believed
	g.judge(_facts({now = 100.0}))
	g.judge(_facts({now = 105.0, order = "hold", place = ""}))
	assert_eq(g.judge(_facts({now = 110.0, place = "Gatehouse"})).doubt, 30 + 2 * 15)
	g.judge(_facts({now = 120.0, recipients = ["Eleni"], place = "Gatehouse"}))
	assert_eq(g.judge(_facts({now = 125.0, recipients = ["Dimos", "Eleni"], all_units = true})).doubt,
		30 + 10 + 4 * 15)  # both guards contradicted: still +30 once


func test_only_the_latest_order_a_guard_got_counts() -> void:
	var g := Glaukopis.new()
	g.expose_at = 1000
	g.judge(_facts({now = 100.0}))
	g.judge(_facts({now = 105.0, place = "Gatehouse"}))
	assert_eq(g.judge(_facts({now = 110.0, place = "Gatehouse"})).doubt, 2 * 15)


func test_an_exposed_order_was_never_got_so_it_does_not_contradict() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 100.0, speaker = "Aris", seen_by = ["Dimos"]}))  # exposed
	assert_eq(g.judge(_facts({now = 110.0, place = "Gatehouse"})).doubt, 15)


func test_a_refused_order_does_not_contradict() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 100.0}))
	g.history.back().accepted.erase("Dimos")  # the scene: Dimos was alerted and ignored it
	assert_eq(g.judge(_facts({now = 110.0, place = "Gatehouse"})).doubt, 15)


func test_each_transmission_in_last_minute_is_15() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({now = 0.0, recipients = ["A"]}))   # older than 60 s by the end: not counted
	g.judge(_facts({now = 50.0, recipients = ["B"]}))
	g.judge(_facts({now = 60.0, recipients = ["C"]}))
	assert_eq(g.judge(_facts({now = 100.0})).doubt, 30)


func test_threshold_is_40() -> void:
	assert_eq(Glaukopis.EXPOSE_AT, 40)
	var below := Glaukopis.new().judge(_facts({order = "all_clear", place = "", since_alert = 5.0}))
	assert_eq(below.doubt, 30)
	assert_false(below.exposed)
	var at := Glaukopis.new().judge(_facts({order = "all_clear", place = "", since_alert = 5.0,
		recipients = ["Dimos", "Eleni"], all_units = true}))
	assert_eq(at.doubt, 40)
	assert_true(at.exposed)


func test_reasons_add_up_to_doubt() -> void:
	var j := Glaukopis.new().judge(_facts({seen_by = ["Dimos"], speaker_busy = true, all_units = true}))
	assert_eq(j.reasons.size(), 3)
	var sum := 0
	for r in j.reasons:
		sum += r[0]
		assert_true(r[1] is String and r[1] != "")
	assert_eq(sum, j.doubt)
	assert_eq(j.doubt, 85)


func test_exposure_flags_the_voiceprint_for_good() -> void:
	var g := Glaukopis.new()
	g.judge(_facts({seen_by = ["Dimos"]}))
	assert_eq(g.flagged, ["Kostas"] as Array[String])
	var j := g.judge(_facts({now = 1000.0}))  # long after, otherwise clean
	assert_eq(j.doubt, 100)
	assert_true(j.exposed)
	assert_eq(g.flagged.size(), 1)


func test_believed_transmission_flags_nothing() -> void:
	var g := Glaukopis.new()
	g.judge(_facts())
	assert_true(g.flagged.is_empty())


func test_commit_false_changes_nothing() -> void:
	var g := Glaukopis.new()
	var j := g.judge(_facts({seen_by = ["Dimos"]}), false)
	assert_true(j.exposed)
	assert_true(g.flagged.is_empty())
	assert_true(g.history.is_empty())
	assert_true(g.last.is_empty())
	assert_eq(g.judge(_facts({now = 101.0})).doubt, 0)  # no earlier transmission counted


func test_last_judgement_is_kept_for_the_overlay() -> void:
	var g := Glaukopis.new()
	var j := g.judge(_facts({speaker_busy = true}))
	assert_eq(g.last, j)
	assert_eq(g.last.doubt, 15)


func test_lower_threshold_exposes_sooner() -> void:
	var g := Glaukopis.new()
	g.expose_at = 25
	assert_true(g.judge(_facts({order = "all_clear", place = "", since_alert = 5.0})).exposed)
