@tool
extends McpTestSuite

## The bark selector: event -> sound folder, per-guard cooldown, a name-seeded voice pitch.


func suite_name() -> String:
	return "bark"


func test_events_map_to_their_folders() -> void:
	assert_eq(Bark.dir(&"suspicion"), "res://assets/audio/barks/suspicion")
	assert_eq(Bark.dir(&"chase"), "res://assets/audio/barks/chase")
	assert_eq(Bark.dir(&"pain"), "res://assets/audio/grunts/pain")
	assert_eq(Bark.dir(&"choke"), "res://assets/audio/grunts/choke")
	assert_eq(Bark.dir(&"contact"), "res://assets/audio/grunts/radio")
	assert_eq(Bark.dir(&"resolved"), "res://assets/audio/barks/radio")


func test_every_event_has_a_folder() -> void:
	for e: StringName in Bark.EVENTS:
		assert_true(DirAccess.dir_exists_absolute(Bark.dir(e)), str(e))


func test_radio_events_take_only_their_lines() -> void:
	assert_true(Bark.wants(&"contact", "CONTACT! (804954346).ogg"))
	assert_true(Bark.wants(&"contact", "Contact! Send reinforcements!.ogg"))
	assert_false(Bark.wants(&"contact", "Sure (804956791).ogg"))
	assert_true(Bark.wants(&"resolved", "Situation resolved. Heading back to posts.ogg"))
	assert_false(Bark.wants(&"resolved", "Heard a noise just now. Approaching to investigate.ogg"))
	assert_true(Bark.wants(&"pain", "anything.ogg"))
	assert_false(Bark.wants(&"pain", "anything.txt"))


func test_only_radio_events_use_the_radio_bus() -> void:
	assert_true(Bark.on_radio(&"contact"))
	assert_true(Bark.on_radio(&"resolved"))
	assert_false(Bark.on_radio(&"spotted"))


func test_a_guard_repeats_an_event_only_after_its_cooldown() -> void:
	var b := Bark.new()
	assert_true(b.request("Guard1", &"suspicion", 10.0))
	assert_false(b.request("Guard1", &"suspicion", 10.0 + Bark.COOLDOWN - 0.1))
	assert_true(b.request("Guard1", &"suspicion", 10.0 + Bark.COOLDOWN))


func test_cooldowns_are_per_guard_and_per_event() -> void:
	var b := Bark.new()
	assert_true(b.request("Guard1", &"suspicion", 0.0))
	assert_true(b.request("Guard2", &"suspicion", 0.0))
	assert_true(b.request("Guard1", &"spotted", 0.0))


func test_caution_chatter_waits_longer() -> void:
	var b := Bark.new()
	assert_true(b.request("Guard1", &"caution", 0.0))
	assert_false(b.request("Guard1", &"caution", Bark.COOLDOWN + 1.0))


func test_pitch_is_seeded_by_name_within_range() -> void:
	assert_eq(Bark.pitch("Guard3"), Bark.pitch("Guard3"))
	var seen := {}
	for i in 12:
		var p := Bark.pitch("Guard%d" % i)
		assert_true(p >= 0.92 and p <= 1.08, str(p))
		seen[p] = true
	assert_true(seen.size() > 3)
