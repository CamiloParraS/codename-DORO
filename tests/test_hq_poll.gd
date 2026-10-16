@tool
extends McpTestSuite

## HQ polls (Downs L1 / L3): who is polled, the 10 s to answer, and the silence that sends a guard.


func suite_name() -> String:
	return "hq_poll"


func _g(n: String, x := 0.0, down := false, dead := false, unseen := 0.0) -> Dictionary:
	return {name = n, pos = Vector3(x, 0, 0), can_answer = not down and not dead, dead = dead, unseen = unseen}


func test_nothing_happens_before_the_interval() -> void:
	var p := HqPoll.new()
	assert_eq(p.tick(HqPoll.INTERVAL - 1.0, [_g("A")], false, 0.0), {})


func test_polls_a_living_guard_every_45_s_and_it_answers_at_once() -> void:
	var p := HqPoll.new()
	var e := p.tick(HqPoll.INTERVAL, [_g("A")], false, 0.0)
	assert_eq(e, {event = "poll", who = "A"})
	assert_eq(p.who, "", "an up guard answers on the spot")
	assert_eq(p.tick(HqPoll.INTERVAL - 1.0, [_g("A")], false, 0.0), {}, "the clock restarted")
	assert_eq(p.tick(1.0, [_g("A")], false, 0.0).event, "poll")


func test_random_poll_is_weighted_toward_down_guards_and_skips_the_dead() -> void:
	var gs := [_g("Up"), _g("Down", 0.0, true), _g("Dead", 0.0, false, true)]
	# weights: Up 1, Down DOWN_WEIGHT, Dead 0
	var total := 1.0 + HqPoll.DOWN_WEIGHT
	assert_eq(HqPoll.pick(gs, false, 0.0), "Up")
	assert_eq(HqPoll.pick(gs, false, 0.5 / total), "Up")
	assert_eq(HqPoll.pick(gs, false, 1.5 / total), "Down")
	assert_eq(HqPoll.pick(gs, false, 0.999), "Down")


func test_no_one_to_poll() -> void:
	assert_eq(HqPoll.pick([_g("Dead", 0.0, false, true)], false, 0.5), "")
	var p := HqPoll.new()
	assert_eq(p.tick(HqPoll.INTERVAL, [], false, 0.0), {})


func test_targeted_poll_takes_the_guard_unseen_longest() -> void:
	var gs := [_g("A", 0.0, false, false, 5.0), _g("B", 0.0, true, false, 90.0), _g("C", 0.0, false, false, 30.0),
		_g("Dead", 0.0, false, true, 500.0)]
	assert_eq(HqPoll.pick(gs, true, 0.0), "B")


func test_a_down_guard_does_not_answer_and_the_silence_sends_someone_to_its_last_position() -> void:
	var p := HqPoll.new()
	var gs := [_g("A"), _g("B", 7.0, true)]
	var e := p.tick(HqPoll.INTERVAL, gs, false, 0.99)
	assert_eq(e, {event = "poll", who = "B"})
	assert_eq(p.who, "B")
	assert_eq(p.tick(HqPoll.ANSWER_TIME - 0.5, gs, false, 0.0), {}, "still waiting")
	e = p.tick(0.6, gs, false, 0.0)
	assert_eq(e, {event = "silence", who = "B", pos = Vector3(7, 0, 0)})
	assert_eq(p.who, "")


func test_polling_is_paused_while_one_is_pending() -> void:
	var p := HqPoll.new()
	var gs := [_g("B", 7.0, true)]
	p.tick(HqPoll.INTERVAL, gs, false, 0.0)
	p.wait = 0.0
	assert_eq(p.tick(1.0, gs, false, 0.0), {})


func test_answering_clears_the_poll() -> void:
	var p := HqPoll.new()
	var gs := [_g("B", 7.0, true)]
	p.tick(HqPoll.INTERVAL, gs, false, 0.0)
	p.answer()
	assert_eq(p.who, "")
	assert_eq(p.tick(HqPoll.ANSWER_TIME + 1.0, gs, false, 0.0), {}, "no silence after an answer")


func test_pending_position_follows_a_carried_guard() -> void:
	var p := HqPoll.new()
	p.tick(HqPoll.INTERVAL, [_g("B", 7.0, true)], false, 0.0)
	var e := p.tick(HqPoll.ANSWER_TIME, [_g("B", 12.0, true)], false, 0.0)
	assert_eq(e.pos, Vector3(12, 0, 0))


func test_nearest_up_guard() -> void:
	var gs := [_g("A", 1.0), _g("B", 10.0), _g("C", 20.0, true), _g("D", 8.0)]
	assert_eq(HqPoll.nearest(gs, Vector3(9, 0, 0), "B"), "D")
	assert_eq(HqPoll.nearest([_g("C", 20.0, true)], Vector3.ZERO, "X"), "")
