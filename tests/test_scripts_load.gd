@tool
extends McpTestSuite

## Every runtime script parses and loads. A parse error only shows when the scene loads in play.

const DIRS := ["res://actors", "res://ai", "res://areas", "res://audio", "res://missions", "res://ui"]


func suite_name() -> String:
	return "scripts_load"


func _scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(d), out)


func test_every_script_loads() -> void:
	var paths := []
	for d in DIRS:
		_scripts(d, paths)
	assert_true(paths.size() > 30)
	for p: String in paths:
		var s: GDScript = load(p)
		assert_true(s != null and s.can_instantiate(), "%s does not parse" % p)
