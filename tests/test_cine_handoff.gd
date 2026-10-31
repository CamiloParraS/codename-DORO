@tool
extends McpTestSuite

## The handoff audit: each Mission's intro take ends where control returns, so its last shot IS the shoulder rig (position,
## heading, lens) and the Operative stands on the Area's start spot facing the start way. No pop when the pcams drop away.

const POS_TOL := 0.2        # m
const AIM_TOL := 4.0        # degrees
const FOV := 70.0

var _area: Node


func suite_name() -> String:
	return "cine_handoff"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_every_intro_ends_on_the_shoulder_rig_at_the_start_spot() -> void:
	var checked := 0
	for k in Campaign.MISSIONS.size():
		var key: String = Campaign.cine_of(k).get("intro", "")
		if key == "":
			continue
		_area = load(Campaign.MISSIONS[k].area).instantiate()
		(Engine.get_main_loop() as SceneTree).root.add_child(_area)
		var who := "%s %s" % [_area.name, key]
		var p := Cine.take_of(_area, key)
		var clip := p.get_animation("take")
		var op = _area.get_node("Operative")
		var start: Marker3D = _area.get_node("Spots/OperativeStart")
		# the body
		var at: Vector3 = _end(clip, "../Operative:position", start.position)
		assert_true(at.distance_to(start.position) < 0.1, "%s: the Operative ends on the start spot (%s)" % [who, at])
		var face: float = _end(clip, "../Operative:cine_face", start.rotation.y)
		assert_true(absf(angle_difference(face, start.rotation.y)) < deg_to_rad(5.0), "%s: facing the start way" % who)
		# the rig the player gets
		op.global_position = start.position
		var rig := _rig(op, start.rotation.y)
		var cine_rig: Node3D = _area.get_node("Cine/%sRig" % key)
		var cam: Vector3 = cine_rig.global_transform * _end(clip, "%sRig/Dolly:position" % key, Vector3.ZERO)
		var aim: Vector3 = cine_rig.global_transform * _end(clip, "%sRig/LookTarget:position" % key, Vector3.ZERO)
		assert_true(cam.distance_to(rig.origin) < POS_TOL, "%s: last shot at the rig: %s vs %s" % [who, cam, rig.origin])
		var fwd := (aim - cam).normalized()
		var off := rad_to_deg(fwd.angle_to(-rig.basis.z))
		assert_true(off < AIM_TOL, "%s: aimed like the rig, %.1f degrees off" % [who, off])
		# the lens: a take that sets one ends on the rig's
		var pcam := p.get_node(p.get_meta("pcams")[0]) as PhantomCamera3D
		if pcam.camera_3d_resource != null:
			assert_eq(pcam.fov, FOV, "%s: ends on the rig's lens" % who)
		var fov_track := clip.find_track(NodePath("%sRig/Cam:camera_3d_resource:fov" % key), Animation.TYPE_VALUE)
		if fov_track >= 0:
			assert_eq(_end(clip, "%sRig/Cam:camera_3d_resource:fov" % key, FOV), FOV, "%s: fov track ends at the rig's" % who)
		checked += 1
		_area.free()
	assert_eq(checked, 4, "Harbour, Relay Station, Annex and Core")


## The clip's value on `path` at its last frame, or `fallback` when it has no such track.
func _end(clip: Animation, path: String, fallback: Variant) -> Variant:
	var t := clip.find_track(NodePath(path), Animation.TYPE_VALUE)
	return fallback if t < 0 else clip.value_track_interpolate(t, clip.length)


## The shoulder rig's camera transform for the Operative at its place facing `yaw` (the arms are physics-driven, so it is
## composed from their rest settings: pivot 1.45 up, shoulder arm across, back arm behind, tilted by the resting pitch).
func _rig(op: Node, yaw: float) -> Transform3D:
	var pivot := Transform3D(Basis(Vector3.UP, yaw), op.global_position + Vector3.UP * 1.45)
	var pitch := Basis(Vector3.RIGHT, op._pitch)
	var s: Basis = op._shoulder_arm.basis
	var b: Basis = op._back_arm.basis
	var local := pitch * (s * (Vector3(0, 0, 0.55) + b * Vector3(0, 0, Locomotion.CAM_DIST)))
	return Transform3D(pivot.basis * pitch * s * b, pivot * local)
