@tool
extends McpTestSuite

## Radial radio steps: speaker → recipient → order → place → confirm, back, slices.


func suite_name() -> String:
	return "radio_menu"


func _menu() -> RadioMenu:
	return RadioMenu.new(["Kostas"], ["Kostas", "Dimos", "Eleni"], ["Dock", "Gatehouse"])


func test_go_check_walks_every_step() -> void:
	var m := _menu()
	assert_false(m.choose(0))          # Kostas
	assert_eq(m.step, "to")
	assert_false(m.choose(1))          # Dimos
	assert_eq(m.step, "order")
	assert_false(m.choose(0))          # go check
	assert_eq(m.step, "place")
	assert_false(m.choose(0))          # Dock
	assert_eq(m.step, "confirm")
	assert_true(m.choose(0))           # send
	assert_eq(m.pick.recipients, ["Dimos"])
	assert_false(m.pick.all_units)
	assert_eq(m.line(), "Dimos, go check the Dock.")


func test_all_units_leaves_out_the_speaker() -> void:
	var m := _menu()
	m.choose(0)
	var opts := m.options()
	assert_eq(opts[-1][0], "All units")
	m.choose(opts.size() - 1)
	assert_eq(m.pick.recipients, ["Dimos", "Eleni"])
	assert_true(m.pick.all_units)


func test_hold_and_all_clear_skip_the_place() -> void:
	var m := _menu()
	m.choose(0)
	m.choose(1)
	m.choose(2)                        # all clear
	assert_eq(m.step, "confirm")
	assert_eq(m.line(), "Dimos, all clear, stand down.")
	assert_true(m.back())
	assert_eq(m.step, "order")


func test_back_from_place_and_first_step() -> void:
	var m := _menu()
	assert_false(m.back())             # first step: caller closes
	m.choose(0)
	m.choose(1)
	m.choose(0)
	m.choose(0)
	assert_true(m.back())
	assert_eq(m.step, "place")
	assert_true(m.back())
	assert_eq(m.step, "order")


func test_out_of_range_choice_does_nothing() -> void:
	var m := RadioMenu.new([], ["Dimos"], ["Dock"])
	assert_true(m.options().is_empty())  # no Voiceprints yet
	assert_false(m.choose(0))
	assert_eq(m.step, "speaker")


func test_slice_clockwise_from_top() -> void:
	assert_eq(RadioMenu.slice(Vector2(0, -40), 4), 0)   # up
	assert_eq(RadioMenu.slice(Vector2(40, 0), 4), 1)    # right
	assert_eq(RadioMenu.slice(Vector2(0, 40), 4), 2)    # down
	assert_eq(RadioMenu.slice(Vector2(-40, 0), 4), 3)   # left
	assert_eq(RadioMenu.slice(Vector2(-5, -39), 4), 0)  # just left of top still slice 0
	assert_eq(RadioMenu.slice(Vector2(2, 3), 4), -1)    # dead zone
	assert_eq(RadioMenu.slice(Vector2(0, -40), 0), -1)


func test_report_in_is_offered_only_as_the_polled_guard() -> void:
	var m := RadioMenu.new(["Kostas", "Dimos"], ["Kostas", "Dimos"], ["Dock"], "Kostas")
	m.choose(1)                        # Dimos isn't the polled guard
	assert_eq(m.options()[0][0], "Kostas", "no HQ to report to")
	assert_eq(m.options().filter(func(o): return o[0] == "HQ").size(), 0)
	m = RadioMenu.new(["Kostas", "Dimos"], ["Kostas", "Dimos"], ["Dock"], "Kostas")
	m.choose(0)                        # Kostas
	assert_eq(m.options()[0][0], "HQ")


func test_report_in_walks_to_confirm_and_says_its_line() -> void:
	var m := RadioMenu.new(["Kostas"], ["Kostas", "Dimos"], ["Dock"], "Kostas")
	m.choose(0)
	m.choose(0)                        # HQ
	assert_eq(m.step, "order")
	assert_eq(m.options(), [["Report in", "report_in"]])
	assert_false(m.choose(0))
	assert_eq(m.step, "confirm", "no place step")
	assert_eq(m.pick.order, "report_in")
	assert_eq(m.pick.recipients, [])
	assert_eq(m.line(), "HQ, Kostas here. Nothing to report.")
	assert_true(m.back())
	assert_eq(m.step, "order")


func test_no_pending_poll_means_no_report_in() -> void:
	var m := _menu()
	m.choose(0)
	assert_eq(m.options()[0][0], "Kostas")
	assert_eq(m.options().size(), 4, "three guards and All units")
