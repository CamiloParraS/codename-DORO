## Headless test runner: godot --headless --path . res://tools/run_tests.tscn -- test_save_slots [more suites]
## (no names = every tests/test_*.gd). Exits 1 on any failure. A scene (not --script) so autoloads and the tree exist.
extends Node


func _ready() -> void:
	await get_tree().process_frame  # the root is busy setting up children during _ready
	var names := OS.get_cmdline_user_args()
	if names.is_empty():
		for f in DirAccess.get_files_at("res://tests"):
			if f.begins_with("test_") and f.ends_with(".gd"):
				names.append(f.get_basename())
	var runner := McpTestRunner.new()
	for n in names:
		var suite: McpTestSuite = load("res://tests/%s.gd" % n).new()
		runner.run_suite(suite)
	var r := runner.get_results(true)
	var failed := 0
	for t: Dictionary in r.get("results", []):
		if not t.passed:
			failed += 1
			print("FAIL ", t.suite, ".", t.test, ": ", t.get("message", ""))
	print("passed %d / %d, failed %d" % [r.passed, r.total, failed])
	get_tree().quit(1 if failed else 0)
