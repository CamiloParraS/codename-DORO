## What every headless playthrough (tools/play_*.gd) shares: the fixed frame rate it needs, the guard dump a
## failed check prints, and running one section of it alone. Static, so each playthrough stays a plain Node.
extends RefCounted

const FPS := 60


## True when the engine runs at --fixed-fps FPS: every frame's delta is exactly 1/FPS (the flag is consumed by
## the engine, so it never shows in the command line). Otherwise prints the command to use and quits with 2:
## guard timing follows the frame rate, so a run at real time passes or fails by chance.
static func fixed_fps(node: Node, scene: String) -> bool:
	for i in 3:
		await node.get_tree().process_frame
		if not is_equal_approx(node.get_process_delta_time(), 1.0 / FPS):
			printerr("%s needs a fixed frame rate:\n  godot --headless --fixed-fps %d --path . %s" % [scene.get_file().get_basename(), FPS, scene.trim_prefix("res://")])
			node.get_tree().quit(2)
			return false
	return true


## Every guard in the tree, one line each: what a failed check needs to say why (state, its last reason, whether it
## counts as at its goal, the goal and how far it is, the Area's Alert phase).
static func dump_guards(tree: SceneTree) -> void:
	var phase: String = AlertChain.Phase.keys()[AlertChain.area.phase]
	for g: Guard in tree.get_nodes_in_group("guards"):
		var at := ""  # a patrolling guard walks its route: its goal says nothing
		if g.is_down():
			at = "down"
		elif g.alert.state != GuardAlert.State.PATROL:
			var p := g.goal()
			at = "goal (%.1f, %.1f, %.1f) %.1f m%s" % [p.x, p.y, p.z, g._flat_dist(p), ", arrived" if g.arrived() else ""]
		print("        %-14s %-9s rush=%s call=%s %s | %s  [Area %s]" % [g.name, GuardAlert.State.keys()[g.alert.state],
			g.alert.rushing, AlertChain.area.calling(g), at, g.last_reason, phase])


## The sections to run from the command line's user args: `-- chain` runs that section alone, `-- chain x5` five
## times; no args runs them all, once, in order. Returns the names to run, or [] (and quits with 2) for a name
## the playthrough doesn't have.
static func sections(node: Node, all: Array[String]) -> Array[String]:
	var args := Array(OS.get_cmdline_user_args())
	if args.is_empty():
		return all
	var times := 1
	var out: Array[String] = []
	for a: String in args:
		if a.begins_with("x") and a.substr(1).is_valid_int():
			times = int(a.substr(1))
		elif a in all:
			out.append(a)
		else:
			printerr("no section '%s'; sections: %s" % [a, ", ".join(all)])
			node.get_tree().quit(2)
			return []
	var repeated: Array[String] = []
	for i in times:
		repeated.append_array(out)
	return repeated
