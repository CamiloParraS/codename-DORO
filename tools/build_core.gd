## Builds areas/core/core.tscn, the Core Mission's Area: the Harbour's ground (build_harbour.gd's geometry) with
## its own guards, landed at the south pier, plus the freight lift's way down, cut through the west cliff: a
## closed door, a short corridor, a plant room with a stair up to the Core room's gallery, and the Core room,
## whose terminal is the Extraction point. Bakes the navmesh and prints how far it reaches. Drawn and timed in
## .scratch/pw-feel/prototypes/core-onboarding.html. Change the data in a zone (tools/core/zone_*.gd) and rebuild,
## don't hand-edit the scene.
##   godot --headless --path . --script tools/build_core.gd                          every zone, to areas/core/core.tscn
##   godot --headless --path . --script tools/build_core.gd -- zones=room,access     only those zones, to user://core_zones.tscn
## A focused build keeps the Harbour's ground but leaves out the other zones' geometry, guards and markers, and
## reports reach from the zone's `start`; use it to look at or time one part without the rest.
## Data is in diagram metres (tools/area_builder.gd); the corridor and room lie west of the Harbour's 0-80 square.
extends "res://tools/build_harbour.gd"

const CORE_OUT := "res://areas/core/core.tscn"
const FOCUS_OUT := "user://core_zones.tscn"
const ZONE_DIR := "res://tools/core/"
const ZONES := ["quay", "ops", "access", "room", "counter", "sky"]  # build order; counter's extra posts are order-sensitive
const LIT_COLOUR := Color(0.45, 1.0, 0.55)
const LIT_ENERGY := 1.8  # dimmer than the white lamps' 3.0

var _zones := {}  # zone name -> its D


## The zones this run builds: all of ZONES, or the `zones=a,b` user argument's.
func _pick_zones() -> void:
	var want := ZONES
	for a in OS.get_cmdline_user_args():
		if a.begins_with("zones="):
			want = a.trim_prefix("zones=").split(",")
	for z in want:
		assert(z in ZONES, "unknown zone %s (zones: %s)" % [z, ", ".join(ZONES)])
	for z in ZONES:
		if z in want:
			_zones[z] = load("%szone_%s.gd" % [ZONE_DIR, z]).D
	print("zones: ", ", ".join(_zones.keys()))


## One data key across the active zones: arrays joined in zone order, dictionaries merged.
func _zd(key: String, dict := false) -> Variant:
	var out: Variant = {} if dict else []
	for z in _zones:
		var v: Variant = _zones[z].get(key, {} if dict else [])
		if dict:
			out.merge(v)
		else:
			out.append_array(v)
	return out


func _build() -> void:
	_pick_zones()
	_root = Node3D.new()
	_root.name = "Core"
	_root.set_script(load("res://areas/core/core.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], _land_floor(l[1]), 0, l[1], Color.WHITE)
	for l in _zd("land"):
		_box(land, "Land%d" % land.get_child_count(), l, -1, 0, "stone", Color.WHITE)
	var solid := _group(nav, "Solid")
	for s in SOLID:
		if s[0] != "Cliff":
			_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	for s in _zd("solid") + _zd("seal"):
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_crane_lattice(solid)
	_camera_poles(solid, _zd("cameras"))
	for r in _zd("ramps"):
		_ramp(solid, r)
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	_gangway(solid)
	_dress(nav, DRESS + _zd("dress"))
	_tint_lit_lamps(nav)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)
	var nm := nav.navigation_mesh

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l)
	_backdrop()
	_clifftop_clear_of_the_core()
	_dress(_root.get_node("Backdrop"), BACKDROP_DRESS, false)
	_surroundings()
	_markings(MARKINGS + _zd("markings"))
	_beacons(BEACONS + _zd("beacons"))
	_mood("core")

	# the Operative lands at the south pier's tip facing north; reinforcements come down the road to the
	# surface (SurfaceEntry) and down the lift to the corridor (RoadEntry) once the Operative is below (core.gd)
	var spots := SPOTS.duplicate()
	spots.erase("DeckEntry")
	spots.merge(_zd("spots", true), true)
	spots.SurfaceEntry = SPOTS.RoadEntry
	if not spots.has("OperativeStart") or not _zones.has("quay"):
		spots.OperativeStart = _start()
	var spot_group := _group(_root, "Spots")
	for n in spots:
		_marker(spot_group, n, spots[n], 0, {}, "spot")
	var sentries := _group(_root, "SentryHighPoints")
	for s in _zd("sentries"):
		_marker(sentries, s[0], s[1], s[2], s[3], "sentry_high_point")
	var cams := _group(_root, "CameraMounts")
	for c in _zd("cameras"):
		_marker(cams, c[0], c[1], c[2], {}, "camera_mount")
	_posts("GuardPosts", _zd("posts"), "guard_post")
	_posts("TargetPosts", _zd("target_posts"), "target_post")
	_posts("ExtraGuardPosts", _zd("extra_posts"), "guard_post_extra")
	var spoofs := _group(_root, "SpoofPlaces")
	for n in SPOOFS:
		_marker(spoofs, n, SPOOFS[n], 0, {}, "spoof_place")
	var encounters := _group(_root, "Encounters")  # MissionRun reads which one the Operative is in (the session log)
	for e in _zd("encounters"):
		_marker(encounters, "Encounter%d" % e[0], [e[3][0], e[3][1], 0], 0, {id = e[0], size = Vector2(e[3][2], e[3][3])}, "encounter")
	for n in _zd("exits", true):
		_marker(encounters, n, _zd("exits", true)[n], 0, {}, "encounter_exit")

	_rooms(ROOMS + _zd("rooms"))
	_actors()
	# the lift's door: outside the NavRegion, so the navmesh is open and only bodies are held back
	var door := _box(_root, "LiftDoor", [0.5, 31, 0.5, 2], 0, 3, "metal", Color(0.9, 0.5, 0.2))
	door.owner = _root
	_own(door)
	door.set_script(load("res://areas/core/lift_door.gd"))
	var ep := _area(_root, "ExtractionPoint", spots.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	for ar in _zd("areas"):
		_area(_root, ar[0], ar[1], ar[2], ar[3])
	_core_objectives()
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer
	_save(CORE_OUT if _zones.size() == ZONES.size() else FOCUS_OUT)
	await _report_reach(nm, spots.OperativeStart, _zd("reach", true), {})
	quit()


## The Harbour's Clifftop slab holds the Core's rooms; the sky zone rebuilds it in pieces clear of them.
func _clifftop_clear_of_the_core() -> void:
	if not _zones.has("sky"):
		return
	var bd: Node3D = _root.get_node("Backdrop")
	var old: MeshInstance3D = bd.get_node("Clifftop")
	var material: Material = (old.mesh as BoxMesh).material
	bd.remove_child(old)
	old.free()
	for pc in _zd("clifftop"):
		var r: Array = pc[0]
		var piece := MeshInstance3D.new()
		piece.name = "Clifftop%d" % bd.get_child_count()
		piece.mesh = _box_mesh(Vector3(r[2], pc[2] - pc[1], r[3]), material)
		piece.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (pc[1] + pc[2]) / 2.0, r[1] + r[3] / 2.0 - 40.0)
		_add(bd, piece)


func _tint_lit_lamps(nav: Node3D) -> void:
	for lamp in nav.get_node("Dressing").get_children():
		for at in _zd("lit"):
			var p := _p([at[0], at[1], 0])
			if lamp.name.begins_with("CeilingLamp") and absf(lamp.position.x - p.x) < 0.01 and absf(lamp.position.z - p.z) < 0.01:
				lamp.get_node("Light").light_color = LIT_COLOUR
				lamp.get_node("Light").light_energy = LIT_ENERGY


## The Core's steps under $Intel: the lift panel (a console, as in Mission 1) and the lift (a walk-in).
func _core_objectives() -> void:
	_intel(_zd("intel", true))
	var intel := _root.get_node("Intel")
	for n in _zd("objectives", true):
		var o: Dictionary = _zd("objectives", true)[n]
		var c := _area(intel, n, [o.at[0], o.at[1], o.at[2] + 1.5], Vector3(3, 3, 3), "res://areas/relay_station/relay_console.gd")
		c.set("hold_time", o.console)
		c.set("prompt", o.prompt)
		c.set("sweeps", false)


## Where this run reaches from: the first active zone's `start`.
func _start() -> Array:
	for z in _zones:
		if _zones[z].has("start"):
			return _zones[z].start
	return [52, 77, 0]
