## The Core's intro take, "Out of the Water", built into areas/core/core.tscn by CoreCine.build. The Operative begins under the
## sea off the south pier's tip, the camera low at the waterline; he swims in, climbs the pier ladder and walks to the start
## spot, and the camera rises to the shoulder rig behind it so control returns with no cut. The water is the Area's own
## backdrop plane (-1.6 m); the Sea trigger is off until he is out (it would end the run). Data in diagram metres
## [x, y, height], the frame of tools/build_core.gd. ~8 s.
class_name CoreIntro
extends RefCounted

const KEY := "CineIntro"
const LENGTH := 8.0
const START := [52.0, 77.0, 0.0]   # OperativeStart (tools/core/zone_quay.gd), facing north
const LADDER := [52.0, 79.45]      # on the pier tip's south face (the tip is at y 79.3)
const WALK_SPEED := 1.2
const WALK_FROM := 5.4             # s he is on his feet
const OUT_AT := 4.9                # s the Sea trigger is live again: he is above the quay's edge
## [at s, x, y, height]: under the surface, to the ladder, up it, onto the deck, to the start spot. Head below -1.6 until ~2 s.
const SWIM := [
	[0.0, 52.0, 80.8, -3.5], [1.2, 52.0, 80.8, -3.5], [2.8, 52.0, 80.1, -1.5], [4.2, 52.0, 79.75, -0.4],
	[5.0, 52.0, 79.55, 0.5], [5.8, 52.0, 78.7, 0.0], [7.2, START[0], START[1], 0.0],
]
const SHOTS := [  # [at s, camera, aim]
	[0.0, [53.2, 85.0, -1.2], [52.0, 79.4, -0.6]],     # at the waterline, the pier's underside and its ladder
	[2.0, [53.0, 84.0, -1.25], [52.0, 79.6, -0.9]],
	[3.4, [52.9, 83.2, -1.0], [52.0, 79.8, -0.6]],     # the head breaks the surface
	[5.0, [53.2, 82.2, 0.4], [52.0, 79.6, 0.8]],       # up the ladder
	[6.4, [52.8, 81.0, 1.5], [52.0, 77.8, 1.2]],
]


static func _w(v: Array) -> Vector3:
	return Vector3(v[0] - 40.0, v[2], v[1] - 40.0)


## The shoulder rig's resting pose behind the start spot (pivot 1.45 up, 0.55 across, 2.33 back, aimed 7.4 ahead and down),
## facing north: the marker's yaw is 0.
static func _rig_pose() -> Array:
	return [[START[0] + 0.55, START[1] + 2.33, 2.04], [START[0], START[1] - 7.4, -0.43]]


static func intro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "IntroProps"
	props.visible = false
	cine.add_child(props)
	_ladder(props)
	props.add_child(_droplets())
	var pose := _rig_pose()
	var shots: Array = SHOTS + [[7.6, pose[0], pose[1]], [LENGTH, pose[0], pose[1]]]
	var cams: Array[Vector3] = []
	var aims: Array[Vector3] = []
	var ats: Array[float] = []
	for s in shots:
		ats.append(float(s[0]))
		cams.append(_w(s[1]))
		aims.append(_w(s[2]))
	var p := AreaCine.rail(cine, KEY, cams, aims, ats, {min_s = 6.0, max_s = 10.0})
	AreaCine.track(p, "IntroProps:visible", [0.0], [true], true)
	var times: Array[float] = []
	var pts: Array[Vector3] = []
	var faces: Array[float] = []
	for r in SWIM:
		times.append(r[0])
		pts.append(_w([r[1], r[2], r[3]]))
		faces.append(0.0)
	AreaCine.operative_track(p, times, pts, faces)
	AreaCine.track(p, "../Operative:cine_view", [0.0], [0.0], true)
	AreaCine.track(p, "../Operative:moving", [0.0, WALK_FROM, 7.2], [false, true, false], true)
	AreaCine.track(p, "../Operative:velocity", [0.0, WALK_FROM, 7.2], [Vector3.ZERO, Vector3(0, 0, -WALK_SPEED), Vector3.ZERO], true)
	AreaCine.track(p, "../DescentCab:dark", [0.0], [0.0], true)  # a take seeked after the Descent must not inherit its black
	AreaCine.track(p, "../Sea:monitoring", [0.0, OUT_AT], [false, true], true)
	AreaCine.track(p, "IntroProps/Droplets:emitting", [0.0, 2.9, 4.1], [false, true, false], true)
	return p


## A ladder down the pier tip's face, into the water: two rails and rungs.
static func _ladder(props: Node3D) -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.55, 0.57, 0.6)
	var ladder := Node3D.new()
	ladder.name = "Ladder"
	ladder.position = _w([LADDER[0], LADDER[1], 0.0])
	props.add_child(ladder)
	for side in [-0.3, 0.3]:
		var rail := MeshInstance3D.new()
		rail.mesh = _box(Vector3(0.05, 3.4, 0.05), steel)
		rail.position = Vector3(side, -1.1, 0.0)
		ladder.add_child(rail)
	for i in 8:
		var rung := MeshInstance3D.new()
		rung.mesh = _box(Vector3(0.6, 0.04, 0.04), steel)
		rung.position = Vector3(0.0, 0.5 - i * 0.4, 0.0)
		ladder.add_child(rung)


## The spray as his head breaks the surface: one burst of small bright drops, off until the take lights it.
static func _droplets() -> CPUParticles3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.9, 1.0)
	var p := CPUParticles3D.new()
	p.name = "Droplets"
	p.position = _w([52.0, 80.1, -1.5])
	p.emitting = false
	p.amount = 24
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.85
	p.direction = Vector3.UP
	p.spread = 40.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -9.0, 0)
	p.mesh = _box(Vector3(0.04, 0.04, 0.04), mat)
	return p


static func _box(size: Vector3, mat: Material) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	m.material = mat
	return m
