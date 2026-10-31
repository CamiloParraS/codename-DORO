## Authoring helpers for takes (cinematics/cine.gd plays them): the Area builders pass data only, in metres, and get
## the nodes back under a `Cine` node. Static, so the builders and the test room both call it.
##   var cine := AreaCine.root(area)
##   AreaCine.rail(cine, "CineIntro", points, looks, times)       # one pcam on a Path3D, aim leading and lagging
##   AreaCine.relay(cine, "CineOutro", shots, length)             # a chain of pcams the host tweens between
##   AreaCine.operative_track(player, times, points, faces)       # the Operative walks, in the take's own time
## Every take is an AnimationPlayer named per take, with the clip "take", rooted at the Cine node, and metadata `pcams`
## (the take's PhantomCamera3Ds, relative to the player), `min_s` / `max_s` (its length range; default CineLogic.RANGE).
## The builders then own the result (`_own`), as they do any other node they add.
class_name AreaCine
extends RefCounted

const LIVE := 10  # a playing take's pcam priority, above OperativeCam.PRIORITY
const DAMPING := 0.25


## The Cine node under `parent`.
static func root(parent: Node) -> Node3D:
	var n := Node3D.new()
	n.name = "Cine"
	parent.add_child(n)
	return n


## A rail: the pcam (follow PATH on a Path3D through `points`, look-at SIMPLE) rides a Dolly that slides along the path
## while a LookTarget slides through `looks`; look-at damping gives it a hand-held lag. `times[i]` is when the Dolly is at
## points[i] (seconds, ascending, from 0). Options: fov (0 = leave the lens), damping, min_s, max_s.
static func rail(cine: Node, name: String, points: Array[Vector3], looks: Array[Vector3], times: Array[float], opts := {}) -> AnimationPlayer:
	assert(points.size() >= 2 and points.size() == looks.size() and points.size() == times.size(), "a rail needs matching points, looks and times")
	var rig := Node3D.new()
	rig.name = name + "Rig"
	cine.add_child(rig)
	var path := Path3D.new()
	path.name = "Path"
	path.curve = _curve(points)
	rig.add_child(path)
	var dolly := Node3D.new()
	dolly.name = "Dolly"
	dolly.position = points[0]
	rig.add_child(dolly)
	var aim := Node3D.new()
	aim.name = "LookTarget"
	aim.position = looks[0]
	rig.add_child(aim)
	var cam := _pcam(rig, "Cam", opts)
	cam.follow_mode = PhantomCamera3D.FollowMode.PATH
	cam.follow_path = path
	cam.follow_target = dolly
	cam.look_at_mode = PhantomCamera3D.LookAtMode.SIMPLE
	cam.look_at_target = aim
	cam.look_at_damping = opts.get("damping", true)
	cam.look_at_damping_value = DAMPING
	cam.tween_resource.duration = 0.0  # the first shot of a take is where it begins
	var player := _player(cine, name, times[times.size() - 1], opts)
	var clip := player.get_animation("take")
	_track(clip, "%s/Dolly:position" % rig.name, times, points, Animation.INTERPOLATION_CUBIC)
	_track(clip, "%s/LookTarget:position" % rig.name, times, looks, Animation.INTERPOLATION_CUBIC)
	_steps(clip, "%s/Cam:priority" % rig.name, [0.0], [LIVE])
	player.set_meta("pcams", [NodePath("../%s/Cam" % rig.name)])
	return player


## A relay: each shot {pos, look, at (s it takes over), tween (s the host blends to it, default 0.4), transition} is its own pcam;
## the clip raises their priority in turn, so the host tweens between them. `length` is the take's length.
static func relay(cine: Node, name: String, shots: Array[Dictionary], length: float, opts := {}) -> AnimationPlayer:
	var rig := Node3D.new()
	rig.name = name + "Rig"
	cine.add_child(rig)
	var player := _player(cine, name, length, opts)
	var clip := player.get_animation("take")
	var pcams := []
	for i in shots.size():
		var s: Dictionary = shots[i]
		var aim := Node3D.new()
		aim.name = "Look%d" % i
		aim.position = s.look
		rig.add_child(aim)
		var cam := _pcam(rig, "Cam%d" % i, opts)
		cam.position = s.pos
		cam.look_at_mode = PhantomCamera3D.LookAtMode.SIMPLE
		cam.look_at_target = aim
		cam.tween_resource.duration = 0.0 if i == 0 else s.get("tween", 0.4)
		cam.tween_resource.transition = s.get("transition", PhantomCameraTween.TransitionType.SINE)
		_steps(clip, "%s/Cam%d:priority" % [rig.name, i], [float(s.at)], [LIVE + i])
		pcams.append(NodePath("../%s/Cam%d" % [rig.name, i]))
	player.set_meta("pcams", pcams)
	return player


## The Operative's body in the take: position through `points` at `times` and (optionally) its heading `faces` (radians).
## With `walk` > 0 it also plays the walking clip at that speed, m/s.
static func operative_track(player: AnimationPlayer, times: Array[float], points: Array[Vector3], faces: Array[float] = [], walk := 0.0) -> void:
	var clip := player.get_animation("take")
	_track(clip, "../Operative:position", times, points, Animation.INTERPOLATION_LINEAR)
	if not faces.is_empty():
		var t := clip.add_track(Animation.TYPE_VALUE)
		clip.track_set_path(t, "../Operative:cine_face")
		clip.track_set_interpolation_type(t, Animation.INTERPOLATION_LINEAR_ANGLE)
		clip.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
		for i in times.size():
			clip.track_insert_key(t, times[i], faces[i])
	if walk > 0.0:
		var ends: Array = [times[0], times[times.size() - 1]]
		_steps(clip, "../Operative:moving", ends, [true, false])
		_steps(clip, "../Operative:velocity", ends, [Vector3(0, 0, -walk), Vector3.ZERO])


## Where the shoulder rig rests behind `at` (world) facing `yaw` (radians, a marker's): [camera, aim]. Pivot 1.45 up, arm
## 0.55 across and 2.4 back, tilted 0.25 rad (operative.gd): a take that starts or ends here hands over with no jump.
static func rig_pose(at: Vector3, yaw: float) -> Array[Vector3]:
	var f := Vector3(-sin(yaw), 0, -cos(yaw))
	var cam := at + Vector3.UP * (1.45 + 2.4 * sin(0.25)) - f * 2.4 * cos(0.25) + f.cross(Vector3.UP) * 0.55
	var reach := 7.4 + 2.4 * cos(0.25)
	var aim := cam + f * reach
	aim.y = cam.y - reach * tan(0.25)
	return [cam, aim]


## A hard cut inside a take (hide it under a dark pulse): a static pcam at `pos` looking at `look`, raised at `at` seconds above
## the take's others with no tween. Joins the take's `pcams`. `rig` is the player's `<Name>Rig` node (rail and relay make it).
static func cut_to(player: AnimationPlayer, name: String, pos: Vector3, look: Vector3, at: float, opts := {}) -> PhantomCamera3D:
	var rig := player.get_parent().get_node(player.name + "Rig")
	var aim := Node3D.new()
	aim.name = name + "Look"
	aim.position = look
	rig.add_child(aim)
	var cam := _pcam(rig, name, opts)
	cam.position = pos
	cam.look_at_mode = PhantomCamera3D.LookAtMode.SIMPLE
	cam.look_at_target = aim
	cam.tween_resource.duration = 0.0
	_steps(player.get_animation("take"), "%s/%s:priority" % [rig.name, name], [at], [LIVE + 5])
	var pcams: Array = player.get_meta("pcams")
	pcams.append(NodePath("../%s/%s" % [rig.name, name]))
	player.set_meta("pcams", pcams)
	return cam


## A track on the take's clip: `path` (from the Cine node, "Node:property" or "Node:resource:property") through `values` at `times`.
## `step` holds each value until the next key (a flag, a teleport); otherwise it blends linearly.
static func track(player: AnimationPlayer, path: String, times: Array, values: Array, step := false) -> void:
	var clip := player.get_animation("take")
	if step:
		_steps(clip, path, times, values)
		return
	var t := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(t, path)
	clip.track_set_interpolation_type(t, Animation.INTERPOLATION_LINEAR)
	clip.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
	for i in times.size():
		clip.track_insert_key(t, times[i], values[i])


static func _pcam(rig: Node, name: String, opts: Dictionary) -> PhantomCamera3D:
	var cam := PhantomCamera3D.new()
	cam.name = name
	cam.priority = 0
	cam.tween_on_load = false
	cam.tween_resource = PhantomCameraTween.new()
	cam.tween_resource.transition = PhantomCameraTween.TransitionType.SINE
	if opts.get("fov", 0.0) > 0.0:
		cam.camera_3d_resource = Camera3DResource.new()
		cam.camera_3d_resource.fov = opts.fov
	rig.add_child(cam)
	return cam


static func _player(cine: Node, name: String, length: float, opts: Dictionary) -> AnimationPlayer:
	var player := AnimationPlayer.new()
	player.name = name
	player.root_node = NodePath("..")  # the Cine node: tracks name "<Name>Rig/Dolly:position" and "../Operative:position"
	var clip := Animation.new()
	clip.length = length
	var lib := AnimationLibrary.new()
	lib.add_animation("take", clip)
	player.add_animation_library("", lib)
	if opts.has("min_s"):
		player.set_meta("min_s", opts.min_s)
	if opts.has("max_s"):
		player.set_meta("max_s", opts.max_s)
	cine.add_child(player)
	return player


## A value track of Vector3 keys.
static func _track(clip: Animation, path: String, times: Array[float], values: Array[Vector3], interp: int) -> void:
	var t := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(t, path)
	clip.track_set_interpolation_type(t, interp)
	clip.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
	for i in times.size():
		clip.track_insert_key(t, times[i], values[i])


## A track that steps (priority, flags): no blending between keys.
static func _steps(clip: Animation, path: String, times: Array, values: Array) -> void:
	var t := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(t, path)
	clip.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	for i in times.size():
		clip.track_insert_key(t, times[i], values[i])


## A smooth curve through the points (Catmull-Rom tangents), so the pcam's closest-point projection follows the dolly.
static func _curve(points: Array[Vector3]) -> Curve3D:
	var c := Curve3D.new()
	for i in points.size():
		var prev := points[maxi(i - 1, 0)]
		var next := points[mini(i + 1, points.size() - 1)]
		var tangent := (next - prev) / 6.0
		c.add_point(points[i], -tangent, tangent)
	return c
