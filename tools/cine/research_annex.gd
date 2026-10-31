## The Research Annex's takes, as data in diagram metres [x, y, height] (the frame of tools/build_research_annex.gd; _w turns it
## into world metres). Each take is one static function the builder calls with the Area's `Cine` node.
##   AnnexCine.intro(cine)    # "Twelve Months": high over the Annex the world dims and the Mission's steps light up through the
##                            # walls (dock guard, vault, files, the researcher), then down to the Operative at the fence's hole
##   AnnexCine.outro(cine)    # "Memory Loss": he goes up the Fulton line from the north-east yard (the Researcher held on his
##                            # shoulder), and the vault's mark (Aigis's memory) stutters and goes dark
## Stand-ins sit under their own hidden group, shown by the take; no colliders, no Guard. CineMark does the radio-look marks.
class_name AnnexCine
extends RefCounted

const DIM_SHADER := preload("res://ui/radio/radio_dim.gdshader")


static func _w(v: Array) -> Vector3:
	return Vector3(v[0] - 40.0, v[2], v[1] - 40.0)


static func _ws(rows: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for r in rows:
		out.append(_w(r))
	return out


static func _times(rows: Array) -> Array[float]:
	var out: Array[float] = []
	for r in rows:
		out.append(float(r))
	return out


## Sets of a shot table [[at, cam, aim], ...] as the rail's three arrays.
static func _rail(cine: Node, key: String, shots: Array, opts: Dictionary) -> AnimationPlayer:
	var cams: Array = shots.map(func(s: Array) -> Array: return s[1])
	var aims: Array = shots.map(func(s: Array) -> Array: return s[2])
	var ats: Array = shots.map(func(s: Array) -> float: return s[0])
	return AreaCine.rail(cine, key, _ws(cams), _ws(aims), _times(ats), opts)


## The radio mode's world dim (RadioLook), darker: a camera-locked quad the take fades through `shader_parameter/amount`.
static func _dim(parent: Node, desat: float, dark: float) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = DIM_SHADER
	m.set_shader_parameter("amount", 0.0)
	m.set_shader_parameter("desat", desat)
	m.set_shader_parameter("dark", dark)
	var q := MeshInstance3D.new()
	q.name = "Dim"
	q.mesh = QuadMesh.new()
	q.custom_aabb = AABB(Vector3.ONE * -1e5, Vector3.ONE * 2e5)  # never culled
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(q)
	return q


static func _mark(parent: Node, name: String, at: Array, target := "", tag := "") -> CineMark:
	var m := CineMark.new()
	m.name = name
	m.position = _w(at)
	m.target = target
	m.tag = tag
	parent.add_child(m)
	return m


# ---- Intro: "Twelve Months" -------------------------------------------------------------------
# High over the yard's south-west corner, the whole Annex below. The world dims to the radio mode's grey and the Mission's
# steps light up through roofs and walls in order, each a beam with its tag: the dock guard who has the vault code, the vault
# in the heart of the lab, the files in the Archive, and the lead researcher at her bench. The dim lifts and the camera comes
# down to the fence, where the Operative walks in through its hole to the start spot; it settles to the shoulder rig, so
# control returns with no cut. The start is 22 m or more from every post and the walk never leaves its 8 m. ~10 s.

const INTRO_KEY := "CineIntro"
const INTRO_LEN := 10.0
const INTRO_THIRD_AT := 6.0      # the Mission's name comes in as the camera comes down, after the marks
const START := [8.0, 72.0, 0.0]  # OperativeStart (build_research_annex.gd SPOTS)
const START_FACING := 45.0       # degrees, the marker's yaw
const GAP := [10.5, 75.8]        # the middle of the fence's hole
const WALK_IN := [  # [at s, x, y, yaw]: from outside the fence, through the hole, to the start spot
	[6.2, 10.5, 79.0, 0.0], [7.2, 10.5, 76.0, 0.0], [8.3, 8.3, 72.5, 0.5], [8.8, START[0], START[1], -START_FACING * PI / 180.0],
]
const WALK_SPEED := 2.2
## The marks, in the Mission's step order: [node, at [x, y, h] (a guard's post: where the mark waits if he is missing),
## the Area node it follows ("" stays put), its tag (lines.csv), s it lights].
const MARKS := [
	["MarkCode", [57.0, 62.0, 0.0], "GuardA9", "cine.m3.code", 1.6],
	["MarkVault", [47.0, 36.0, 0.0], "", "cine.m3.vault", 2.3],
	["MarkFiles", [27.0, 50.0, 0.0], "", "cine.m3.files", 3.0],
	["MarkTarget", [16.0, 34.0, 0.0], "LEAD RESEARCHER", "cine.m3.target", 3.7],  # Campaign's Target name for Mission 3
]
const DIM_T := [0.8, 1.4, 5.6, 6.2]  # s the dim starts, is full, starts to lift, is gone
const MARKS_OFF := 5.9
## The fog pulled back while the camera is high (Mood's depth fog, 40-140 m in play), back to the Area's own by FOG_T[2].
const FOG_T := [0.0, 5.6, 6.8]
const FOG_BEGIN := [70.0, 70.0, 40.0]
const FOG_END := [220.0, 220.0, 140.0]


## The shoulder rig's resting pose behind the start spot (pivot 1.45 up, 0.55 across and 2.33 back, aimed 7.4 ahead and down).
static func _rig_pose() -> Array:
	var yaw := -deg_to_rad(START_FACING)  # the marker is turned by minus its facing (build_research_annex.gd _marker)
	var f := Vector2(-sin(yaw), -cos(yaw))  # forward in the diagram's x, y
	var r := Vector2(cos(yaw), -sin(yaw))
	var cam := Vector2(START[0], START[1]) + r * 0.55 - f * 2.33
	var aim := Vector2(START[0], START[1]) + f * 7.4
	return [[cam.x, cam.y, 2.04], [aim.x, aim.y, -0.43]]


static func intro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "IntroProps"
	props.visible = false
	cine.add_child(props)
	_dim(props, 0.85, 0.45)
	for m in MARKS:
		_mark(props, m[0], m[1], m[2], m[3])

	var pose := _rig_pose()
	var shots := [
		[0.0, [4.0, 86.0, 22.0], [32.0, 46.0, 0.0]],    # high over the yard's south-west corner: the whole Annex
		[2.6, [6.0, 84.0, 20.0], [33.0, 46.0, 0.0]],    # a slow drift while the marks come up
		[5.4, [7.0, 83.0, 17.0], [30.0, 50.0, 0.0]],
		[6.6, [10.5, 84.0, 7.0], [10.5, 76.0, 1.0]],    # down behind him at the fence, the aim on the hole
		[7.4, [10.5, 79.5, 2.2], [10.0, 74.0, 1.2]],    # on his heels as he goes through
		[8.2, [9.8, 75.5, 2.1], [8.3, 71.5, 1.2]],      # through the hole after him (x 9.5-11.5)
		[8.8, pose[0], pose[1]],
		[INTRO_LEN, pose[0], pose[1]],
	]
	var player := _rail(cine, INTRO_KEY, shots, {min_s = 8.0, max_s = 11.0})
	player.set_meta("third_at", INTRO_THIRD_AT)
	AreaCine.track(player, "IntroProps:visible", [0.0, INTRO_LEN], [true, false], true)
	AreaCine.track(player, "IntroProps/Dim:material_override:shader_parameter/amount", DIM_T, [0.0, 1.0, 1.0, 0.0])
	AreaCine.track(player, "../Mood:environment:fog_depth_begin", FOG_T, FOG_BEGIN)
	AreaCine.track(player, "../Mood:environment:fog_depth_end", FOG_T, FOG_END)
	for m in MARKS:
		AreaCine.track(player, "IntroProps/%s:lit" % m[0], [0.0, m[4], MARKS_OFF], [false, true, false], true)
	var ats: Array[float] = []
	var pts: Array[Vector3] = []
	var yaws: Array[float] = []
	for r in WALK_IN:
		ats.append(r[0])
		pts.append(_w([r[1], r[2], 0.0]))
		yaws.append(r[3])
	AreaCine.operative_track(player, ats, pts, yaws, WALK_SPEED)
	return player


# ---- Outro: "Memory Loss" ---------------------------------------------------------------------------------------
# Control ends in the Extraction point's zone in the north-east yard. He stops; the Fulton balloon goes up and fills over
# him, the line yanks him off his feet and he rises hanging from it, the Researcher held on his shoulder (an ill Target never
# gets a balloon of her own: carry_only). The camera, low in the yard, follows him up, then turns back to the Annex: the world
# greys and the vault's mark, the one the intro lit, stutters and goes dark. ~10 s.

const OUTRO_KEY := "CineOutro"
const OUTRO_LEN := 10.0
const OUTRO_THIRD_AT := 5.0      # s the line comes in: as he clears the roofs
const OUTRO_FROM := [67.6, 24.4, 0.0]  # inside ExtractionPoint (70, 24; 4 m wide), on its west side
const OUTRO_YAW := -PI / 2.0     # facing east, as he comes in
const VAULT := [47.0, 36.0, 0.0]
const VAULT_LIT := [6.4, 8.8, 9.0, 9.15, 9.35]  # on; a stutter; dark for good
const OUTRO_DIM_T := [6.2, 7.0]
## [at s, camera, aim]: aim "him" is where he is then, chest high.
const OUTRO_SHOTS := [
	[1.2, [64.6, 28.4, 1.4], [67.6, 24.4, 3.0]],    # low in the yard's south-west, looking up at the balloon filling
	[3.0, [64.4, 28.6, 1.8], "him"],                # the yank, and up
	[4.6, [64.0, 29.0, 4.0], "him"],
	[6.4, [63.6, 29.6, 8.5], [52.0, 33.0, 4.0]],    # it lets him go and turns back to the Annex, onto the vault
	[8.0, [63.8, 30.4, 11.5], [47.0, 36.0, 1.0]],
	[OUTRO_LEN, [64.2, 31.0, 13.0], [47.0, 36.0, 0.5]],
]


static func outro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "OutroProps"
	props.visible = false
	cine.add_child(props)
	CineFulton.build(props)
	_dim(props, 0.7, 0.25)
	_mark(props, "MarkVault", VAULT)

	var from := _w(OUTRO_FROM)
	var pose := AreaCine.rig_pose(from, OUTRO_YAW)  # control's last frame: no jump into the take
	var cams: Array[Vector3] = [pose[0]]
	var aims: Array[Vector3] = [pose[1]]
	var ats: Array[float] = [0.0]
	for r: Array in OUTRO_SHOTS:
		ats.append(r[0])
		cams.append(_w(r[1]))
		aims.append(CineFulton.at_time(from, r[0]) + Vector3.UP * 1.5 if r[2] is String else _w(r[2]))
	var player := AreaCine.rail(cine, OUTRO_KEY, cams, aims, ats, {min_s = 8.0, max_s = 11.0})
	player.set_meta("third_at", OUTRO_THIRD_AT)
	AreaCine.track(player, "OutroProps:visible", [0.0], [true], true)
	CineFulton.lift(player, "OutroProps", from, OUTRO_YAW, OUTRO_LEN)
	AreaCine.track(player, "OutroProps/Dim:material_override:shader_parameter/amount", OUTRO_DIM_T, [0.0, 1.0])
	AreaCine.track(player, "OutroProps/MarkVault:lit", [0.0] + VAULT_LIT, [false, true, false, true, false, false], true)
	return player
