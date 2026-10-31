## Runs the test room's take for real (host, pcams, frames) and checks what the sync suite cannot:
##   godot --headless --path . tools/cine_check.tscn
## 1. the gameplay pcam is the host's camera before the take, the take's pcam during it, GameplayCam again after it;
## 2. operative.gd's fov (alarm punch-in, aim) survives the host; 3. the camera does not jump at the hand-back.
extends Node

var _fails := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	_fails += 0 if ok else 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _run() -> void:
	var area: Node = load("res://areas/test_room/test_room.tscn").instantiate()
	add_child(area)
	var op = area.get_node("Operative")
	var host := OperativeCam.host_of(op.camera)
	await _frames(5)
	_check(host.get_active_pcam() == op.gameplay_cam, "GameplayCam is the host's camera at rest")
	# fov spike: the host must leave camera.fov to the Operative
	op.camera.fov = 61.0
	Input.action_press("aim")
	await _frames(40)
	Input.action_release("aim")
	_check(absf(op.camera.fov - 50.0) < 1.0, "aim fov 50 survives the host (got %.1f)" % op.camera.fov)
	await _frames(60)
	_check(absf(op.camera.fov - 70.0) < 1.0, "fov back to 70 (got %.1f)" % op.camera.fov)
	var rest: Transform3D = op.camera.global_transform
	_check(rest.is_equal_approx(op.gameplay_cam.global_transform), "camera sits on GameplayCam's transform at rest")

	var run := MissionRun.new()
	run.name = "MissionRun"
	run.cine = {intro = "CineTest"}
	run.campaign = true
	area.add_child(run)
	var cine: Cine = run.get_node("CineRunner")
	await _frames(3)
	var pcam: PhantomCamera3D = host.get_active_pcam() as PhantomCamera3D
	_check(pcam != null and pcam.name == "Cam", "the take's pcam is the host's camera during the take")
	var p0: Vector3 = op.camera.global_position
	await get_tree().create_timer(1.5).timeout
	var p1: Vector3 = op.camera.global_position
	_check(p0.distance_to(p1) > 1.0, "the camera moves along the rail (%.1f m)" % p0.distance_to(p1))
	_check(not get_tree().paused, "the tree is not paused")
	await get_tree().create_timer(2.0).timeout
	_check(not is_instance_valid(cine) or cine.done, "the take ended by itself after ~3.5 s")
	await _frames(2)
	_check(host.get_active_pcam() == op.gameplay_cam, "GameplayCam is the host's camera again")
	_check(not op.cine and not run.take_playing, "control is back")
	var before: Vector3 = op.camera.global_position
	await _frames(40)
	print("hand-back settle: camera moved %.2f m over 40 frames" % before.distance_to(op.camera.global_position))
	_check(op.camera.global_position.distance_to(op.gameplay_cam.global_position) < 0.05, "camera settled on the rig")

	# skip
	var run2 := MissionRun.new()
	run2.name = "MissionRun2"
	run2.cine = {intro = "CineTest"}
	run2.campaign = true
	area.add_child(run2)
	await _frames(3)
	run2.get_node("CineRunner").skip()
	await _frames(2)
	_check(host.get_active_pcam() == op.gameplay_cam, "skip: GameplayCam active")
	_check(op.camera.global_position.distance_to(op.gameplay_cam.global_position) < 0.05, "skip: no half-tween, the camera is on the rig at once")
	print("failures: ", _fails)
	get_tree().quit(1 if _fails else 0)
