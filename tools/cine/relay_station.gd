## The Relay Station's takes, as data in diagram metres [x, y, height] (the frame of tools/build_relay_station.gd; _w turns it
## into world metres). Each take is one static function the builder calls with the Area's `Cine` node (tools/area_cine.gd does
## the rail); a take's stand-in props are mesh-only rigs under their own group, hidden in play and shown by the take.
##   RelayCine.intro(cine)    # "Up the Signal": the signal, the cable, the mast, the valley, then down to the Operative running in
##   RelayCine.outro(cine)    # "Dead Air": he goes up the Fulton line from the helipad (the Chief held on his shoulder) and
##                            # the station's lamps die under him
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


## The cable's cells as flat squares facing the camera (2D pixels, CELL across): cell k (its index in UV.x, its corner
## in UV2) is `tint` once k < `lit`, `dim` before. Unshaded and see-through; nothing glows.
const CELLS := """
shader_type spatial;
render_mode unshaded, shadows_disabled, skip_vertex_transform, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color;
uniform vec4 dim : source_color;
uniform float lit = 0.0;
uniform float size = 0.14;
varying float cell;
void vertex() {
	cell = UV.x;
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz + vec3(UV2 * size, 0.0);
}
void fragment() {
	vec4 c = cell < lit ? tint : dim;
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""


## Where the cable's square pixels sit: one every CELL_GAP along `pts`, each [transform, segment, fraction along it],
## radio first, so a track can light them in the pulse's order.
static func _cell_spots(pts: Array[Vector3]) -> Array:
	var out := []
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := (b - a).normalized()
		var basis := Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
		var n := maxi(int(a.distance_to(b) / CELL_GAP), 1)
		for k in n:
			out.append([Transform3D(basis, a.lerp(b, float(k) / n)), i, float(k) / n])
	return out


## The cells as one baked mesh, a quad per cell collapsed on its centre (the shader opens it to face the camera), cell k's
## index in UV.x and its corner in UV2.
static func _cells(parent: Node, name: String, spots: Array, mat: Material) -> MeshInstance3D:
	var corners := [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in spots.size():
		var at: Vector3 = (spots[k][0] as Transform3D).origin
		for c: Vector2 in corners:
			st.set_uv(Vector2(k, 0.0))
			st.set_uv2(c)
			st.add_vertex(at)
	var p := MeshInstance3D.new()
	p.name = name
	p.mesh = st.commit()
	p.material_override = mat
	p.extra_cull_margin = CELL
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p


## RadioLook's pixel ring (five frames, each a step wider), lying flat at `at`; nearest, unshaded, mint.
static func _ring(parent: Node, name: String, at: Vector3) -> Sprite3D:
	var s := Sprite3D.new()
	s.name = name
	s.texture = RadioLook.RING_ICON
	s.hframes = 5
	s.pixel_size = RING_PX
	s.axis = Vector3.AXIS_Y
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.modulate = SIGNAL
	s.position = at
	s.visible = false
	parent.add_child(s)
	return s


## Where the shoulder rig rests behind `at` facing `yaw` (AreaCine.rig_pose).
static func rig_pose(at: Vector3, yaw: float) -> Array[Vector3]:
	return AreaCine.rig_pose(at, yaw)


# ---- Intro: "Up the Signal" ---------------------------------------------------------------------------------------
# The Spoofing signal sprite (RadioLook's) at the mess's radio, the camera follows a pulse of it along the cable, up the mast
# and out over the valley, where it leaves as a ring, then swoops down as the Operative runs in from the side onto the start
# spot and turns to face the start way. The start is beyond every guard's reach (the test). ~10 s.

const INTRO_KEY := "CineIntro"
const INTRO_LEN := 10.0
const INTRO_START := [8.0, 72.0, 0.0]  # OperativeStart (build_relay_station.gd SPOTS)
const INTRO_FACING := 45.0             # its facing, degrees (START_FACING)
const RADIO := [58.6, 39.4, 4.25]
const SIGNAL := HudPalette.MINT       # the radio's own hue; flat, never a glow
const SIGNAL_DIM := Color(0.16, 0.3, 0.27)  # the cable's cells before the pulse lights them
const RUN_FROM := [-1.0, 80.0, 0.0]    # where he runs in from, off to the side of the final shot (the hill's west edge)
const RUN_T := [7.4, 8.9, 9.3]         # s he sets off, reaches the start spot, has turned to face the start way
const RUN_SPEED := 5.5                 # m/s
const SIGNAL_PX := 0.14                # the sprite's metres per pixel (RadioLook's drifting spark is 0.03)
const RING_FROM := 6.8
const RING_TO := 9.0
const RING_STEP := 0.1                 # s per frame as the ring steps out to its widest frame
const RING_PX := 0.26                  # its metres per pixel: the widest frame (15.5 px radius) is 4 m
const RING_GROW := 15.0                # it then scales out to 60 m by RING_TO, its pixels growing with it
const RING_ECHO := 0.25                # s the dimmer echo trails it
const CELL := 0.14                     # a cable pixel, metres
const CELL_GAP := 0.3                  # one every this far along the run
const CABLE_ALPHA := 0.7               # lit cells; the dark ones are fainter still
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

	var pts: Array[Vector3] = []
	for row in PULSE:
		pts.append(_w(row[1]))
	var spots := _cell_spots(pts)
	var cable := ShaderMaterial.new()  # dark until the pulse passes, then lit a cell at a time behind it
	cable.shader = Shader.new()
	cable.shader.code = CELLS
	cable.set_shader_parameter("tint", Color(SIGNAL, CABLE_ALPHA))
	cable.set_shader_parameter("dim", Color(SIGNAL_DIM, CABLE_ALPHA * 0.8))
	cable.set_shader_parameter("size", CELL)
	_cells(props, "Cable", spots, cable)
	_signal(props, "Pulse", pts[0], SIGNAL_PX * 0.6)
	for n in ["Ring", "RingEcho"]:
		_ring(props, n, pts[pts.size() - 1])

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
	# the cable lights cell by cell as the pulse reaches each one (the pulse moves linearly between its keys)
	var lit_at: Array[float] = [0.0]
	var lit_n: Array[float] = [0.0]
	for k in spots.size():
		var seg: int = spots[k][1]
		lit_at.append(lerpf(PULSE[seg][0], PULSE[seg + 1][0], spots[k][2]))
		lit_n.append(k + 1.0)
	AreaCine.track(player, "IntroProps/Cable:material_override:shader_parameter/lit", lit_at, lit_n, true)
	# the ring leaves the tip: steps out through its five frames, then spreads over the valley, an echo trailing it;
	# it fades in steps, as the chrome does
	for r in [["Ring", 0.0, 0.9], ["RingEcho", RING_ECHO, 0.45]]:
		var path := "IntroProps/%s" % r[0]
		var from: float = RING_FROM + r[1]
		var wide := from + RING_STEP * 4.0
		AreaCine.track(player, path + ":visible", [0.0, from, RING_TO], [false, true, false], true)
		AreaCine.track(player, path + ":frame", [from, from + RING_STEP, from + RING_STEP * 2.0, from + RING_STEP * 3.0, wide], [0, 1, 2, 3, 4], true)
		AreaCine.track(player, path + ":scale", [wide, RING_TO], [Vector3.ONE, Vector3.ONE * RING_GROW * (1.0 - r[1])])
		var a: float = r[2]
		AreaCine.track(player, path + ":modulate", [from, RING_TO - 0.6, RING_TO - 0.4, RING_TO - 0.2],
			[Color(SIGNAL, a), Color(SIGNAL, a * 0.66), Color(SIGNAL, a * 0.33), Color(SIGNAL, 0.0)], true)
	return player




# ---- Outro: "Dead Air" --------------------------------------------------------------------------------------------
# Control ends in the helipad's zone, so the take starts there (the rig's resting pose, no jump). He stops; the Fulton
# balloon goes up and fills over him, the line yanks him off his feet and he rises hanging from it, the Chief held on his
# shoulder (an ill Target never gets a balloon of his own: carry_only). The camera, low on the pad's south-west corner,
# follows him up, then lets him go and turns east to the station as its lamps die from the console outward; the antenna's
# red lamp goes last. The same take serves an Operative carrying nothing. Fade to black over the last 0.6 s. ~10 s.

const OUTRO_KEY := "CineOutro"
const OUTRO_LEN := 10.0
const OUTRO_THIRD_AT := 5.0             # s the line comes in: as he clears the summit
const OUTRO_FROM := [10.5, 14.0, 6.0]   # inside ExtractionPoint (9, 14; 4 m wide), where he comes in from the east
const OUTRO_YAW := PI / 2.0             # facing west, as control leaves him
## The camera: [at s, camera [x, y, h], aim [x, y, h] or "him" (where he is then, chest high)], after the rig pose it starts
## on. High enough at the end that the lamp post at (13.8, 18) sits under the frame.
const OUTRO_SHOTS := [
	[1.2, [11.8, 17.6, 6.8], [10.5, 14.0, 9.5]],     # off his shoulder, low, looking up at the balloon filling
	[3.0, [10.0, 18.6, 7.3], "him"],                 # the yank, and up, drifting to the pad's south-west corner
	[4.6, [8.0, 19.0, 8.8], "him"],
	[6.2, [6.3, 19.2, 11.0], [24.0, 14.0, 22.0]],    # it lets him go and turns east to the station
	[8.0, [6.0, 19.2, 13.0], [30.0, 14.0, 19.0]],    # the lamps die
	[OUTRO_LEN, [5.8, 19.2, 14.0], [42.0, 13.0, 24.0]],  # the antenna's red lamp
]
## The lamps in the order they die ([N of Beacons/LampN, at s]): the console's two, the key cabinet's, the helipad's four.
## N is the index in IDENTITY.beacons (tools/identity/relay_station.gd); Lamp0 is the antenna's red one, which goes last.
const DEAD := [[1, 6.4], [2, 6.7], [3, 7.0], [4, 7.4], [5, 7.6], [6, 7.8], [7, 8.0]]
const FLICKER := [0.0, 8.3, 8.6, 8.9, 9.2]  # the red lamp: on, off, on, off for good
## The helipad's two sodium lamp posts (dressing, NavRegion/Dressing/<name>/Light) go with the pad's beacons: [name, at s].
const POSTS_DEAD := [["LampPost_13p8_18p0", 7.7], ["LampPost_4p6_10p0", 7.9]]


static func outro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "OutroProps"
	props.visible = false  # the balloon, shown by the take
	cine.add_child(props)
	CineFulton.build(props)
	var from := _w(OUTRO_FROM)
	var pose := rig_pose(from, OUTRO_YAW)  # the shot control leaves off on
	var cams: Array[Vector3] = [pose[0]]
	var aims: Array[Vector3] = [pose[1]]
	var ats: Array[float] = [0.0]
	for s in OUTRO_SHOTS:
		ats.append(float(s[0]))
		cams.append(_w(s[1]))
		aims.append(CineFulton.at_time(from, s[0]) + Vector3.UP * 1.5 if s[2] is String else _w(s[2]))
	var player := AreaCine.rail(cine, OUTRO_KEY, cams, aims, ats, {min_s = 8.0, max_s = 11.0})
	player.set_meta("third_at", OUTRO_THIRD_AT)
	AreaCine.track(player, "OutroProps:visible", [0.0], [true], true)
	CineFulton.lift(player, "OutroProps", from, OUTRO_YAW, OUTRO_LEN)

	for d in DEAD:
		var lamp := "../Beacons/Lamp%d" % d[0]
		AreaCine.track(player, lamp + "/Light:light_energy", [0.0, d[1], d[1] + 0.15], [2.0, 2.0, 0.0])
		AreaCine.track(player, lamp + "/Lens:visible", [0.0, d[1]], [true, false], true)
	for p in POSTS_DEAD:
		AreaCine.track(player, "../NavRegion/Dressing/%s/Light:light_energy" % p[0], [0.0, p[1], p[1] + 0.2], [3.0, 3.0, 0.0])
	var red := "../Beacons/Lamp0"
	AreaCine.track(player, red + "/Light:light_energy", FLICKER, [2.0, 2.0, 0.0, 2.0, 0.0], true)
	AreaCine.track(player, red + "/Lens:visible", FLICKER, [true, true, false, true, false], true)
	return player
