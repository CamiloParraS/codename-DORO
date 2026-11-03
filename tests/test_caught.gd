@tool
extends McpTestSuite

## Caught: a Countermeasure catching the Operative, said once per COOLDOWN while its Habit is deployed.

const CSV := "res://text/lines.csv"


func suite_name() -> String:
	return "caught"


func test_a_moment_speaks_only_while_its_habit_is_deployed() -> void:
	var c := Caught.new({"headshots": 1}, "the Marksman")
	assert_eq(c.line(&"helmet", 0.0), "caught.helmet.1")
	assert_eq(c.line(&"vest", 0.0), "", "Combat has nothing deployed")
	assert_eq(Caught.new().line(&"helmet", 0.0), "", "Mission 1: nothing deployed")


func test_the_area_says_each_moment_once_per_cooldown() -> void:
	var c := Caught.new({"headshots": 1, "downs": 2})
	assert_ne(c.line(&"helmet", 10.0), "")
	assert_eq(c.line(&"helmet", 10.0 + Caught.COOLDOWN - 1.0), "", "too soon")
	assert_ne(c.line(&"found", 11.0), "", "another moment has its own cooldown")
	assert_eq(c.line(&"helmet", 10.0 + Caught.COOLDOWN, 3), "caught.helmet.2", "variants wrap")


func test_every_moment_maps_to_a_habit_and_has_its_lines() -> void:
	var f := FileAccess.open(CSV, FileAccess.READ)
	var t := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3:
			t[r[0]] = [r[1], r[2]]
	for m: StringName in Caught.MOMENTS:
		assert_true(Caught.MOMENTS[m] in Aigis.HABITS, str(m))
		for v in Caught.VARIANTS:
			var k := "caught.%s.%d" % [m, v + 1]
			assert_true(t.has(k), k)
			if t.has(k) and not (m in [&"found"] and v == 1):
				assert_true("{name}" in t[k][0] and "{name}" in t[k][1], k + " names the Operative in both languages")


func test_hq_says_the_radio_moments() -> void:
	assert_true(Caught.by_hq(&"silence"))
	assert_true(Caught.by_hq(&"camera"))
	assert_false(Caught.by_hq(&"helmet"))
