## The Relay Station's takes, as data in diagram metres [x, y, height] (the frame of tools/build_relay_station.gd; _w turns it
## into world metres). Each take is one static function the builder calls with the Area's `Cine` node (tools/area_cine.gd does
## the rail); a take's stand-in props are mesh-only rigs under their own group, hidden in play and shown by the take.
##   RelayCine.intro(cine)    # "Up the Signal": the signal, the cable, the mast, the valley, then down to the Operative running in
##   RelayCine.outro(cine)    # "Dead Air": the helipad while the station's lamps die behind it, in two takes: CineOutro (carrying
##                            # the Chief) and CineOutroAlone (Cine.variant_key picks one from what he carries)
class_name RelayCine
extends RefCounted

const RAD := PI / 180.0


static func _w(v: Array) -> Vector3:
	return Vector3(v[0] - 40.0, v[2], v[1] - 40.0)


static func _times(rows: Array) -> Array[float]:
	var out: Array[float] = []
	for r in rows:
		out.append(float(r))
	return out


static func _glow(c: Color, energy := 4.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func _part(parent: Node, name: String, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var p := MeshInstance3D.new()
	p.name = name
	mesh.material = mat
	p.mesh = mesh
	p.position = at
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p


## The Spoofing look's radio signal (RadioLook: three pixel-art wave frames, billboarded, unshaded, nearest), at `at`.
static func _signal(parent: Node, name: String, at: Vector3, pixel: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.name = name
	s.texture = RadioLook.SIGNAL_ICON
	s.hframes = 3
	s.pixel_size = pixel
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.position = at
	parent.add_child(s)
	return s


## A thin bar from a to b (a cable run).
static func _bar(parent: Node, name: String, a: Vector3, b: Vector3, mat: Material) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.1, a.distance_to(b))
	var p := _part(parent, name, box, (a + b) / 2.0, mat)
	var d := (b - a).normalized()
	var up := Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT
	p.basis = Basis.looking_at(d, up)


## Where the shoulder rig rests behind `at` (world) facing `yaw` (radians, the marker's): [camera, aim]. The same pose as the
## Harbour's: pivot 1.45 up, arm 0.55 across and 2.4 back, tilted 0.25 rad (operative.gd).
static func rig_pose(at: Vector3, yaw: float) -> Array[Vector3]:
	var f := Vector3(-sin(yaw), 0, -cos(yaw))
	var cam := at + Vector3.UP * (1.45 + 2.4 * sin(0.25)) - f * 2.4 * cos(0.25) + f.cross(Vector3.UP) * 0.55
	var reach := 7.4 + 2.4 * cos(0.25)
	var aim := cam + f * reach
	aim.y = cam.y - reach * tan(0.25)
	return [cam, aim]


# ---- Intro: "Up the Signal" ---------------------------------------------------------------------------------------
# The Spoofing signal sprite (RadioLook's) at the mess's radio, the camera follows a pulse of it along the cable, up the mast
# and out over the valley, where it leaves as a ring, then swoops down as the Operative runs in from the side onto the start
# spot and turns to face the start way. The start is beyond every guard's reach (the test). ~10 s.

const INTRO_KEY := "CineIntro"
const INTRO_LEN := 10.0
const INTRO_START := [8.0, 72.0, 0.0]  # OperativeStart (build_relay_station.gd SPOTS)
const INTRO_FACING := 45.0             # its facing, degrees (START_FACING)
const RADIO := [58.6, 39.4, 4.25]
const SIGNAL := Color(0.45, 0.85, 1.0)
const RUN_FROM := [-1.0, 80.0, 0.0]    # where he runs in from, off to the side of the final shot (the hill's west edge)
const RUN_T := [7.4, 8.9, 9.3]         # s he sets off, reaches the start spot, has turned to face the start way
const RUN_SPEED := 5.5                 # m/s
const SIGNAL_PX := 0.14                # the sprite's metres per pixel (RadioLook's drifting spark is 0.03)
const RING_FROM := 6.8
const RING_TO := 9.0
## The pulse: [at s, [x, y, h]] along the cable, radio to antenna tip. The cable bars join these points.
const PULSE := [
	[1.6, RADIO], [2.5, [52.0, 42.0, 4.3]], [3.5, [44.0, 34.0, 7.4]], [4.4, [41.5, 20.0, 7.6]],
	[5.0, [39.6, 13.9, 9.5]], [6.0, [39.6, 13.9, 18.0]], [6.8, [37.0, 11.0, 34.4]],
]
## The camera (one rail): [at s, camera, aim]. It tails the pulse, then crests the mast and swoops; the last shots are
## the rig's pose, filled in from the start spot.
const INTRO_SHOTS := [
	[0.0, [60.4, 42.0, 4.7], RADIO],               # tight on the radio's grille
	[1.6, [59.3, 40.6, 4.4], RADIO],               # pushing in as the first pulse leaves
	[2.5, [55.5, 44.5, 5.4], [52.0, 42.0, 4.3]],   # out at the door with the cable
	[3.5, [48.5, 38.5, 8.0], [44.0, 34.0, 7.4]],
	[4.4, [45.5, 25.5, 9.8], [41.5, 20.0, 7.6]],
	[5.0, [43.8, 18.5, 11.0], [39.6, 13.9, 9.5]],  # at the mast's foot, rising
	[6.0, [43.5, 16.5, 20.0], [39.6, 13.9, 18.0]],
	[6.8, [42.5, 8.5, 31.5], [37.0, 11.0, 34.4]],  # a quarter turn round the antenna to its tip
	[7.4, [37.0, 1.0, 40.0], [37.0, 45.0, 24.0]],  # the crest: wide over the valley
	[8.4, [22.0, 40.0, 24.0], [8.0, 72.0, 1.6]],   # down the hillside to the start
]


static func intro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "IntroProps"
	props.visible = false  # a radio, a lit cable, the pulse and its ring; shown by the take, mesh only
	cine.add_child(props)

	_signal(props, "Radio", _w(RADIO), SIGNAL_PX)  # the sprite the user swaps for the antenna art later

	var cable := _glow(SIGNAL, 1.0)
	var pts: Array[Vector3] = []
	for row in PULSE:
		pts.append(_w(row[1]))
	for i in pts.size() - 1:
		_bar(props, "Cable%d" % i, pts[i], pts[i + 1], cable)
	_signal(props, "Pulse", pts[0], SIGNAL_PX * 0.6)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.92
	ring.outer_radius = 1.0
	_part(props, "Ring", ring, pts[pts.size() - 1], _glow(SIGNAL, 3.0)).scale = Vector3.ZERO

	var pose := rig_pose(_w(INTRO_START), -INTRO_FACING * RAD)
	var cams: Array[Vector3] = []
	var aims: Array[Vector3] = []
	var ats: Array[float] = []
	for s in INTRO_SHOTS:
		ats.append(float(s[0]))
		cams.append(_w(s[1]))
		aims.append(_w(s[2]))
	for t in [9.2, INTRO_LEN]:  # the handoff: the rig's own resting pose, held for the aim to settle
		ats.append(t)
		cams.append(pose[0])
		aims.append(pose[1])
	var player := AreaCine.rail(cine, INTRO_KEY, cams, aims, ats, {min_s = 6.0, max_s = 10.0})
	AreaCine.track(player, "IntroProps:visible", [0.0, INTRO_LEN], [true, false], true)  # gone again once control returns
	AreaCine.track(player, "IntroProps/Pulse:position", _times(PULSE.map(func(r: Array) -> float: return r[0])), pts)
	AreaCine.track(player, "IntroProps/Pulse:visible", [0.0, 1.6, 6.8], [false, true, false], true)
	var beats: Array[float] = []
	var frames: Array[int] = []
	for i in int(INTRO_LEN / 0.5):  # the waves grow and restart, as in RadioLook's spark
		beats.append(i * 0.5)
		frames.append(i % 3)
	for n in ["Radio", "Pulse"]:
		AreaCine.track(player, "IntroProps/%s:frame" % n, beats, frames, true)
	var run_from := _w(RUN_FROM)
	var run_to := _w(INTRO_START)
	var heading := atan2(-(run_to.x - run_from.x), -(run_to.z - run_from.z))  # the body's yaw for travelling that way
	AreaCine.operative_track(player, _times(RUN_T), [run_from, run_to, run_to] as Array[Vector3], [heading, heading, -INTRO_FACING * RAD] as Array[float], RUN_SPEED)
	AreaCine.track(player, "IntroProps/Ring:scale", [RING_FROM, RING_TO], [Vector3.ONE, Vector3.ONE * 60.0])
	return player


# ---- Outro: "Dead Air" --------------------------------------------------------------------------------------------
# Control ends in the helipad's zone, so the take starts there (the rig's resting pose, no jump): he crosses the pad while the
# station's lamps die behind him, from the console outward, and the antenna's red lamp goes last. Two takes, same length and
# lamps: CineOutro carries the Chief (the carry clip loops under the position track, the Chief rides his shoulder as in play)
# and CineOutroAlone, for an Operative carrying nothing (Cine.variant_key), where he crosses faster, stops and looks back at
# the dying station. Fade to black over the last 0.6 s. ~9 s.

const OUTRO_KEY := "CineOutro"
const OUTRO_LEN := 9.0
const OUTRO_THIRD_AT := 5.5
const OUTRO_FROM := [10.5, 14.0, 6.0]   # inside ExtractionPoint (9, 14; 4 m wide), where he comes in from the east
const OUTRO_TO := [6.0, 14.0, 6.0]      # the pad's far side
const OUTRO_YAW := PI / 2.0             # facing west
const OUTRO_LOOK_YAW := -PI / 2.0       # alone: turned back east to the station
const OUTRO_LOOK_AT := [3.4, 4.2]       # alone: s he stops, s he has turned
## Per version: [m/s the clip plays at, s the walk lasts]. The carry is slow and heavy; alone he is quick.
const OUTRO_WALK := {carry = [1.4, 3.2], alone = [2.0, 2.25]}
const OUTRO_SHOTS := [
	[2.0, [15.0, 17.0, 8.3], [7.5, 14.0, 7.2]],     # easing wider as he crosses the pad
	[4.0, [18.5, 19.5, 9.0], [8.0, 14.0, 7.3]],
	[5.5, [26.0, 19.0, 9.5], [30.0, 12.0, 12.0]],   # he stops; the camera turns back to the station
	[7.0, [29.0, 18.0, 10.5], [38.0, 12.0, 16.0]],
	[OUTRO_LEN, [30.0, 18.0, 11.0], [37.0, 11.0, 26.0]],
]
## The lamps in the order they die ([N of Beacons/LampN, at s]): the console's two, the key cabinet's, the helipad's four.
## N is the index in IDENTITY.beacons (tools/identity/relay_station.gd); Lamp0 is the antenna's red one, which goes last.
const DEAD := [[1, 4.6], [2, 4.9], [3, 5.3], [4, 5.8], [5, 6.1], [6, 6.4], [7, 6.7]]
const FLICKER := [0.0, 6.9, 7.2, 7.5, 7.8]  # the red lamp: on, off, on, off for good


static func outro(cine: Node) -> void:
	_outro(cine, OUTRO_KEY, false)
	_outro(cine, OUTRO_KEY + Cine.ALONE, true)


static func _outro(cine: Node, key: String, alone: bool) -> AnimationPlayer:
	var pose := rig_pose(_w(OUTRO_FROM), OUTRO_YAW)  # the shot control leaves off on
	var cams: Array[Vector3] = [pose[0]]
	var aims: Array[Vector3] = [pose[1]]
	var ats: Array[float] = [0.0]
	for s in OUTRO_SHOTS:
		ats.append(float(s[0]))
		cams.append(_w(s[1]))
		aims.append(_w(s[2]))
	var player := AreaCine.rail(cine, key, cams, aims, ats, {min_s = 6.0, max_s = 10.0})
	player.set_meta("third_at", OUTRO_THIRD_AT)
	var w: Array = OUTRO_WALK.alone if alone else OUTRO_WALK.carry
	var times: Array[float] = [0.0, w[1]]
	var faces: Array[float] = [OUTRO_YAW, OUTRO_YAW]
	if alone:  # he stops, then turns back to look at the station
		times.append_array([OUTRO_LOOK_AT[0], OUTRO_LOOK_AT[1]])
		faces.append_array([OUTRO_YAW, OUTRO_LOOK_YAW])
	var to := _w(OUTRO_TO)
	var points: Array[Vector3] = [_w(OUTRO_FROM), to]
	if alone:
		points.append_array([to, to])
	AreaCine.operative_track(player, times, points, faces)
	AreaCine.track(player, "../Operative:moving", [0.0, w[1]], [true, false], true)  # the walking clip, only while he crosses
	AreaCine.track(player, "../Operative:velocity", [0.0, w[1]], [Vector3(0, 0, -w[0]), Vector3.ZERO], true)
	for d in DEAD:
		var lamp := "../Beacons/Lamp%d" % d[0]
		AreaCine.track(player, lamp + "/Light:light_energy", [0.0, d[1], d[1] + 0.15], [2.0, 2.0, 0.0])
		AreaCine.track(player, lamp + "/Lens:visible", [0.0, d[1]], [true, false], true)
	var red := "../Beacons/Lamp0"
	AreaCine.track(player, red + "/Light:light_energy", FLICKER, [2.0, 2.0, 0.0, 2.0, 0.0], true)
	AreaCine.track(player, red + "/Lens:visible", FLICKER, [true, true, false, true, false], true)
	return player
