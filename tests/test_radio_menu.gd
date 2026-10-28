@tool
extends McpTestSuite

## Radial radio steps: speaker → recipient → order → place → confirm, back, slices.


func suite_name() -> String:
	return "radio_menu"


func setup() -> void:
	TranslationServer.set_locale("en")  # line() is translated


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


func test_request_hint_is_a_speaker_step_pick_that_needs_no_voiceprint() -> void:
	var m := RadioMenu.new([], ["Dimos"], ["Dock"])
	m.hint_label = "Request hint"
	assert_eq(m.options(), [["Request hint", "hint"]])
	assert_true(m.choose(0))
	assert_true(m.pick.has("hint"))


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


func test_speaker_hover_names_the_voiceprint_owner() -> void:
	var m := _menu()
	m.hint_label = "Request hint"
	assert_eq(m.referents(0), {hot = ["Kostas"], cold = [], place = "", place_hot = false})
	assert_eq(m.referents(1).hot, [], "Request hint names nobody")


func test_single_recipient_hover_keeps_the_speaker_cold() -> void:
	var m := _menu()
	m.choose(0)
	var r := m.referents(1)            # Dimos
	assert_eq(r.hot, ["Dimos"])
	assert_eq(r.cold, ["Kostas"])


func test_all_units_lights_everyone_but_the_speaker() -> void:
	var m := _menu()
	m.choose(0)
	var r := m.referents(m.options().size() - 1)
	assert_eq(r.hot, ["Dimos", "Eleni"])
	assert_eq(r.cold, ["Kostas"])


func test_hq_has_no_referents() -> void:
	var m := RadioMenu.new(["Kostas"], ["Kostas", "Dimos"], ["Dock"], "Kostas")
	m.choose(0)
	assert_eq(m.referents(0).hot, [])
	assert_eq(m.referents(0).cold, ["Kostas"])


func test_radio_point_hover_is_hot_with_both_picks_cold() -> void:
	var m := _menu()
	m.choose(0)
	m.choose(1)
	m.choose(0)                        # go check
	var r := m.referents(1)            # Gatehouse
	assert_eq(r.place, "Gatehouse")
	assert_true(r.place_hot)
	assert_eq(r.hot, [])
	assert_eq(r.cold, ["Kostas", "Dimos"])


func test_confirm_lights_everything_picked() -> void:
	var m := _menu()
	m.choose(0)
	m.choose(1)
	m.choose(0)
	m.choose(0)                        # Dock
	var r := m.referents(0)
	assert_eq(r.hot, ["Kostas", "Dimos"])
	assert_eq(r.cold, [])
	assert_eq(r.place, "Dock")
	assert_true(r.place_hot)


func test_dead_zone_shows_only_the_cold_picks() -> void:
	var m := _menu()
	m.choose(0)
	m.choose(1)                        # order step: both picks are earlier
	var r := m.referents(-1)
	assert_eq(r.hot, [])
	assert_eq(r.cold, ["Kostas", "Dimos"])


func test_a_guard_is_shown_by_his_role_numbered_when_two_share_it() -> void:
	var m := _menu()
	m.roles = {Kostas = "patroller", Dimos = "patroller", Eleni = "observer"}
	assert_eq(m.shown("Kostas"), "Patroller 2", "names sort: Dimos is 1, Kostas 2")
	assert_eq(m.shown("Dimos"), "Patroller 1")
	assert_eq(m.shown("Eleni"), "Observer", "alone in its role: no number")


func test_a_guard_without_a_role_keeps_his_name() -> void:
	var m := _menu()
	m.roles = {Kostas = "patroller"}
	assert_eq(m.shown("Dimos"), "Dimos")
	assert_eq(m.shown("Gone"), "Gone", "left the Area")


func test_the_confirm_line_uses_the_role() -> void:
	var m := _menu()
	m.roles = {Dimos = "gatekeeper"}
	m.choose(0)
	m.choose(1)
	m.choose(0)
	m.choose(0)
	assert_eq(m.line(), "Gatekeeper, go check the Dock.")
