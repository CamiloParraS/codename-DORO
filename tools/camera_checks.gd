## Shoulder-camera check in the Harbour's tight spots (the 3 m alley, the lift hall, Operations' rooms): for each spot,
## yaw, pitch, shoulder and stance, the camera must sit in open space (nothing within 0.1 m) and see the Operative's
## head. Prints PASS/FAIL. Run as a scene so the autoloads exist:
##   godot --headless --fixed-fps 60 --path . tools/camera_checks.tscn
extends Node

## [name, x, y] in diagram metres (tools/build_harbour.gd).
const SPOTS := [
	["alley mid", 24.5, 31.0], ["alley north end", 24.5, 21.0], ["alley south end", 24.5, 41.0],
	["lift hall", 15.5, 31.0], ["lift hall north end", 15.5, 22.5], ["lift mouth", 12.0, 31.0],
	["control room", 19.0, 24.0], ["lobby", 19.0, 32.0], ["locker room", 20.0, 38.5],
]
var fails := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rec := Aigis.new_record()
	rec.mission = 1
	var area: Node = load("res://areas/harbour/harbour.tscn").instantiate()
	area.get_node("MissionRun").record = rec
	add_child(area)
	for i in 30:
		await get_tree().physics_frame
	var op: Node3D = area.get_node("Operative")
	for g in get_tree().get_nodes_in_group("guards"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	for s in SPOTS:
		var bad := 0
		var worst := INF
		for crouch in [false, true]:
			for shoulder in [1.0, -1.0]:
				for pitch in [-0.5, 0.0, 0.5]:
					for k in 8:
						op.global_position = Vector3(s[1] - 40.0, 0.05, s[2] - 40.0)
						op.velocity = Vector3.ZERO
						op.crouching = crouch
						op._apply_crouch()
						op.shoulder = shoulder
						op._apply_shoulder()
						op._yaw = k * PI / 4
						op._pitch = pitch
						for i in 12:
							await get_tree().physics_frame
						var d := _clearance(op)
						worst = minf(worst, d)
						if d < 0.1:
							bad += 1
		check(bad == 0, "%s: camera clear of walls and sees the Operative (%d bad of 96, closest %.2f m)" % [s[0], bad, worst])
	print("camera_checks: %d failed" % fails)
	get_tree().quit(1 if fails else 0)


## Metres between the camera and the nearest wall; 0 if it is inside one or cannot see the Operative's head.
func _clearance(op: Node3D) -> float:
	var space: PhysicsDirectSpaceState3D = op.get_world_3d().direct_space_state
	var cam: Vector3 = op.camera.global_position
	var head: Vector3 = op.global_position + Vector3.UP * (0.95 if op.crouching else 1.45)
	var ray := PhysicsRayQueryParameters3D.create(cam, head, 1, [op.get_rid()])
	if space.intersect_ray(ray):
		return 0.0
	var best := 1.0
	for dir in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var q := PhysicsRayQueryParameters3D.create(cam, cam + dir, 1, [op.get_rid()])
		var h := space.intersect_ray(q)
		if h:
			best = minf(best, cam.distance_to(h.position))
	return best


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1
