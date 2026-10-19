## Headless suite runner: godot --headless --path . --script tests/support/run.gd -- campaign core ...
## Names are tests/test_<name>.gd; none runs every suite. Exit code 1 if anything failed.
extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var names := Array(OS.get_cmdline_user_args())
	if names.is_empty():
		for f in DirAccess.get_files_at("res://tests"):
			if f.begins_with("test_") and f.ends_with(".gd"):
				names.append(f.trim_prefix("test_").trim_suffix(".gd"))
	var suites := []
	for n in names:
		suites.append(load("res://tests/test_%s.gd" % n).new())
	var runner := McpTestRunner.new()
	var r := runner.run_suites(suites)
	print("passed %d failed %d skipped %d" % [r.passed, r.failed, r.skipped])
	for f in r.get("failures", []):
		print("FAIL ", f.suite, ".", f.test, ": ", f.get("message", ""))
	quit(1 if r.failed else 0)
