## The Operative's camera under Phantom Camera: one PhantomCameraHost on the real Camera3D (so the PSX look pass keeps
## working) and a GameplayCam pcam that mirrors the shoulder rig. A take raises its own pcams above GameplayCam;
## handing back is the take's pcams dropping below it.
##
## Priority is never below 0 in Phantom Camera, so GameplayCam sits at PRIORITY and a take's idle pcams at 0.
## No Camera3DResource on GameplayCam: the host then leaves camera.fov alone, and operative.gd's alarm punch-in,
## aim and look fov keep working as they did.
class_name OperativeCam
extends RefCounted

const PRIORITY := 1
const HAND_BACK := 0.5  # s the host tweens from a take's last shot to the rig


## Adds the host under `camera` and GameplayCam under `rig` (the arm the camera hangs from, at identity).
static func build(camera: Camera3D, rig: Node3D) -> PhantomCamera3D:
	var host := PhantomCameraHost.new()
	host.name = "PhantomCameraHost"
	host.interpolation_mode = PhantomCameraHost.InterpolationMode.IDLE  # the rig is moved per frame, not per physics tick
	camera.add_child(host)
	var pcam := PhantomCamera3D.new()
	pcam.name = "GameplayCam"
	pcam.follow_mode = PhantomCamera3D.FollowMode.NONE
	pcam.look_at_mode = PhantomCamera3D.LookAtMode.NONE
	pcam.priority = PRIORITY
	pcam.tween_on_load = false
	pcam.tween_resource = PhantomCameraTween.new()
	pcam.tween_resource.duration = HAND_BACK
	pcam.tween_resource.transition = PhantomCameraTween.TransitionType.SINE
	pcam.tween_resource.ease = PhantomCameraTween.EaseType.EASE_IN_OUT
	pcam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rig.add_child(pcam)
	return pcam


static func host_of(camera: Camera3D) -> PhantomCameraHost:
	return camera.get_node_or_null("PhantomCameraHost") as PhantomCameraHost
