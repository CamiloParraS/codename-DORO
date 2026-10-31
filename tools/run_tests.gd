## Headless suite runner for when the godot_ai MCP is down:
## godot --headless --path . tools/run_tests.tscn [-- file_name_substring]
## (a scene, not --script, so the autoloads exist)
## Runs every tests/test_*.gd (or those whose file name contains the argument); exits 1 on a failure.
extends Node


func _ready() -> void:
	await get_tree().process_frame  # the root is busy setting up children during _ready; tree-bound tests need it settled
	var want := OS.get_cmdline_user_args()
	var suites := []
	var broken := []  # suites that don't compile: reported, not run, so the runner still quits
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and (want.is_empty() or want[0] in f):
			var script: Script = load("res://tests/" + f)
			if script and script.can_instantiate():
				suites.append(script.new())
			else:
				broken.append(f)
	var r := McpTestRunner.new().run_suites(suites, "", "", {}, false)
	print("passed %d failed %d skipped %d" % [r.passed, r.failed + broken.size(), r.skipped])
	for f in broken:
		print("FAIL %s: does not compile" % f)
	for f in r.get("failures", []):
		print("FAIL %s.%s: %s" % [f.suite, f.test, f.get("message", "")])
	get_tree().quit(1 if r.failed > 0 or not broken.is_empty() else 0)
