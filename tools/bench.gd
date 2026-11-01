## Frame-time benchmark: loads each Area, frames the shots.gd `<area>_decor` spots (and the overview, the
## worst case), and samples every spot with vsync and the FPS cap off. Prints a table and writes
## user://bench/<label>.json so two runs compare. Needs a window (not --headless):
##   godot --path . tools/bench.tscn -- <label> [area ...]
## (a scene, not --script, so PsxLook and the other autoloads run). Areas: harbour relay_station research_annex core.
## Guards keep patrolling, so AI, physics and skinning cost are in the numbers; the HUD stays up.
## Columns: avg/p99 frame ms, rcpu (the 3D render's CPU side, mostly draw calls) and gpu ms, pmax and phys (the
## engine's process and physics time: its max over the last second, not a mean), draws and primitives per frame.
##   godot --path . tools/bench.tscn -- compare <label a> <label b>   prints b's avg ms and draws against a's.
extends Node

const SHOTS := preload("res://tools/shots.gd").SHOTS
const AREAS := {
	harbour = ["res://areas/harbour/harbour.tscn", ["harbour_decor", "harbour"]],
	relay_station = ["res://areas/relay_station/relay_station.tscn", ["relay_decor", "relay_station"]],
	research_annex = ["res://areas/research_annex/research_annex.tscn", ["annex_decor", "research_annex"]],
	core = ["res://areas/core/core.tscn", ["core_decor"]],
}
const WARMUP := 1.5   # seconds per spot before sampling: shaders compile, PropSkins swap in
const SAMPLE := 3.0   # seconds sampled per spot

## Diagnostic switches, given after the label: noshadows (every light's shadow off), nosun / noomni (one kind
## of shadow off), noguards (guards stop processing), nohud, nomotion (the tree paused: what still costs when
## nothing moves). They isolate where a frame goes; a plain run passes none.
var _off: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame  # the root is still adding its children
	var args := OS.get_cmdline_user_args()
	var label: String = args[0] if args.size() else "run"
	if label == "compare" and args.size() == 3:
		_compare(args[1], args[2])
		get_tree().quit()
		return
	var areas: Array = []
	for a in args.slice(1):
		if a.begins_with("no"):
			_off.append(a)
		else:
			areas.append(a)
	if areas.is_empty():
		areas = AREAS.keys()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var report := {label = label, gpu = RenderingServer.get_video_adapter_name(), areas = {}}
	for a: String in areas:
		if AREAS.has(a):
			report.areas[a] = await _bench_area(a)
	DirAccess.make_dir_recursive_absolute("user://bench")
	var path := "user://bench/%s.json" % label
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("bench: wrote ", ProjectSettings.globalize_path(path))
	get_tree().quit()


func _bench_area(area: String) -> Dictionary:
	var scene: Node = load(AREAS[area][0]).instantiate()
	get_tree().root.add_child(scene)
	await get_tree().create_timer(3.0).timeout  # title card, first compile
	get_tree().paused = false
	_switch_off(scene)
	var cam := Camera3D.new()
	cam.fov = 70
	scene.add_child(cam)
	var spots := {}
	for key: String in AREAS[area][1]:
		var shots: Dictionary = SHOTS[key][1]
		for n: String in shots:
			if key == area and n != "overview":
				continue
			cam.look_at_from_position(shots[n][0], shots[n][1])
			cam.make_current()
			await get_tree().create_timer(WARMUP).timeout
			spots[n] = await _sample()
	var out := {inventory = _inventory(scene), spots = spots}
	_print_area(area, out)
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return out


func _switch_off(scene: Node) -> void:
	if "nohud" in _off and scene.has_node("HudLayer"):
		scene.get_node("HudLayer").visible = false
	if "noguards" in _off:
		for g in get_tree().get_nodes_in_group("guards"):
			g.process_mode = Node.PROCESS_MODE_DISABLED
	if "nomotion" in _off:
		get_tree().paused = true
	if "nosun" in _off:
		for l in scene.find_children("*", "DirectionalLight3D", true, false):
			l.shadow_enabled = false
	if "noomni" in _off:
		for l in scene.find_children("*", "OmniLight3D", true, false):
			l.shadow_enabled = false
	if "noshadows" in _off:
		for l in scene.find_children("*", "Light3D", true, false):
			l.shadow_enabled = false


## Per-frame wall time plus the engine's own split over SAMPLE seconds.
func _sample() -> Dictionary:
	var vp := get_viewport().get_viewport_rid()
	var ms: Array[float] = []
	var cpu := 0.0
	var gpu := 0.0
	var proc := 0.0
	var phys := 0.0
	var draws := 0.0
	var prims := 0.0
	var objs := 0.0
	var t0 := Time.get_ticks_usec()
	var last := t0
	while Time.get_ticks_usec() - t0 < SAMPLE * 1e6:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ms.append((now - last) / 1000.0)
		last = now
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var n := float(ms.size())
	var sorted := ms.duplicate()
	sorted.sort()
	var total := 0.0
	for m in ms:
		total += m
	return {
		frames = ms.size(), avg_ms = total / n, p99_ms = sorted[int(n * 0.99) - 1], fps = n / SAMPLE,
		render_cpu_ms = cpu / n, gpu_ms = gpu / n, process_max_ms = proc / n, physics_ms = phys / n,
		draw_calls = draws / n, primitives = prims / n, objects = objs / n,
		vram_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
	}


## What the Area holds: the counts that drive draw calls and shadow passes.
func _inventory(scene: Node) -> Dictionary:
	var inv := {meshes = 0, multimesh_instances = 0, omni = 0, spot = 0, directional = 0, shadowed_lights = 0,
		casters = 0, particles = 0, guards = get_tree().get_nodes_in_group("guards").size(), nodes = 0}
	var mats := {}
	var meshes := {}
	var stack: Array[Node] = [scene]
	while stack:
		var n: Node = stack.pop_back()
		inv.nodes += 1
		stack.append_array(n.get_children())
		if n is MeshInstance3D and n.is_visible_in_tree():
			inv.meshes += 1
			if n.mesh:
				meshes[n.mesh] = true
				for s in n.mesh.get_surface_count():
					var m: Material = n.get_active_material(s)
					if m:
						mats[m] = true
			if n.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				inv.casters += 1
		elif n is MultiMeshInstance3D and n.multimesh:
			inv.multimesh_instances += n.multimesh.instance_count
		elif n is Light3D and n.is_visible_in_tree():
			if n is OmniLight3D: inv.omni += 1
			elif n is SpotLight3D: inv.spot += 1
			else: inv.directional += 1
			if n.shadow_enabled:
				inv.shadowed_lights += 1
		elif n is GPUParticles3D or n is CPUParticles3D:
			inv.particles += 1
	inv.unique_meshes = meshes.size()
	inv.unique_materials = mats.size()
	return inv


func _print_area(area: String, out: Dictionary) -> void:
	print("\n== %s  %s" % [area, out.inventory])
	print("%-14s %6s %6s %6s %7s %6s %6s %6s %6s %8s" % ["spot", "fps", "avg", "p99", "rcpu", "gpu", "pmax", "phys", "draws", "prims"])
	for n: String in out.spots:
		var s: Dictionary = out.spots[n]
		print("%-14s %6.0f %6.2f %6.2f %7.2f %6.2f %6.2f %6.2f %6.0f %8.0f" % [n.left(14), s.fps, s.avg_ms, s.p99_ms,
			s.render_cpu_ms, s.gpu_ms, s.process_max_ms, s.physics_ms, s.draw_calls, s.primitives])


func _compare(a: String, b: String) -> void:
	var ra: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://bench/%s.json" % a))
	var rb: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://bench/%s.json" % b))
	for area: String in rb.areas:
		if not ra.areas.has(area):
			continue
		print("
== %s   avg ms %s -> %s   draws" % [area, a, b])
		for n: String in rb.areas[area].spots:
			var sa: Dictionary = ra.areas[area].spots.get(n, {})
			var sb: Dictionary = rb.areas[area].spots[n]
			if sa:
				print("%-14s %6.2f -> %6.2f (%+5.1f%%)   %5.0f -> %5.0f" % [n.left(14), sa.avg_ms, sb.avg_ms,
					100.0 * (sb.avg_ms / sa.avg_ms - 1.0), sa.draw_calls, sb.draw_calls])
