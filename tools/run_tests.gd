## Headless suite runner for when the godot_ai MCP is down:
## godot --headless --path . tools/run_tests.tscn [-- file_name_substring]
## (a scene, not --script, so the autoloads exist)
## Runs every tests/test_*.gd (or those whose file name contains the argument); exits 1 on a failure.
extends Node


func _ready() -> void:
	await get_tree().process_frame  # the root is busy setting up children during _ready; tree-bound tests need it settled
	var want := OS.get_cmdline_user_args()
	var suites := []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and (want.is_empty() or want[0] in f):
			suites.append(load("res://tests/" + f).new())
	var r := McpTestRunner.new().run_suites(suites, "", "", {}, false)
	print("passed %d failed %d skipped %d" % [r.passed, r.failed, r.skipped])
	for f in r.get("failures", []):
		print("FAIL %s.%s: %s" % [f.suite, f.test, f.get("message", "")])
	get_tree().quit(1 if r.failed > 0 else 0)
