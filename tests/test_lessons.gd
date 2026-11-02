@tool
extends McpTestSuite

## Mission 1's deck lessons (missions/lessons.gd): in order, each waits for the player, and a later one done closes
## the earlier ones so none ever blocks the Mission.


func suite_name() -> String:
	return "lessons"


func _f(over := {}) -> Dictionary:
	var f := {crouched = false, scanning = false, o1_down = false, y = 0.0, recorded = false, off_deck = false}
	f.merge(over, true)
	return f


func test_lessons_go_in_order_and_wait() -> void:
	var l := Lessons.new()
	assert_eq(l.update(_f()), 0, "crouch first")
	assert_eq(l.update(_f()), 0, "it waits: no timer")
	assert_eq(l.update(_f({crouched = true})), 1, "then the Scanner")
	assert_eq(l.update(_f()), 1, "standing up again doesn't undo it")
	assert_eq(l.update(_f({scanning = true})), 2, "then O1")
	assert_eq(l.update(_f({y = Lessons.PAST_O1_Y + 1.0})), 3, "past him: step 1's own objective")
	assert_eq(Lessons.line(3), "", "the smoke break has no line of its own")
	assert_eq(l.update(_f({recorded = true})), Lessons.EXIT, "then off the ship")
	assert_eq(l.update(_f({off_deck = true})), -1, "and the deck is done")


func test_a_later_lesson_done_closes_the_earlier_ones() -> void:
	var l := Lessons.new()
	assert_eq(l.update(_f({o1_down = true})), 3, "took O1 down before crouching: crouch and Scanner are behind him")
	var walked := Lessons.new()
	assert_eq(walked.update(_f({off_deck = true})), -1, "left the deck at once: no lesson holds him")


func test_a_line_names_the_real_binding_in_words() -> void:
	assert_contains(Lessons.line(0), Prompts.word("crouch"))
	assert_contains(Lessons.line(Lessons.EXIT), Prompts.word("radio"))
	assert_false(Lessons.line(0).contains("{key}"))
