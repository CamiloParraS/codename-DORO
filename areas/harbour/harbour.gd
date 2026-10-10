## The Harbour Area (greybox). Marker groups: spot, sentry_high_point, camera_mount, guard_post,
## guard_post_extra, spoof_place. A guard post's child markers are its patrol route.
## Places the Countermeasures MissionRun's plan deploys (Deployment) at those built-in spots.
## Open harbour.tscn and press F6 (Mission 1, nothing deployed), or start it from Free mode.
extends Node3D

const GUARD := preload("res://actors/guard/guard.tscn")
const BASE_GUARDS := 10  # the remaining posts are left for Countermeasure extras


func _ready() -> void:
	var deployed: Dictionary = $MissionRun.plan.deployed
	var guards := []
	for post: Marker3D in $GuardPosts.get_children().slice(0, BASE_GUARDS):
		guards.append(spawn_guard(post))
	for post: Marker3D in $ExtraGuardPosts.get_children().slice(0, Deployment.extra_patrols(deployed)):
		guards.append(spawn_guard(post))
	var helmets := Deployment.helmets(deployed, guards.size())
	for i in guards.size():
		if helmets[i]:
			guards[i].wear_helmet()
	if Deployment.cameras(deployed):
		for mount: Marker3D in $CameraMounts.get_children():
			var cam := SecurityCamera.new()
			cam.name = mount.name
			cam.operative = $Operative
			cam.transform = global_transform.affine_inverse() * mount.global_transform  # before _ready reads the yaw
			add_child(cam)


func spawn_guard(post: Marker3D) -> Node3D:
	var g := GUARD.instantiate()
	g.name = post.name.replace("Post", "Guard")
	g.route.append(post.global_position)
	for wp: Marker3D in post.get_children():
		g.route.append(wp.global_position)
	g.operative = $Operative
	add_child(g)
	g.global_transform = post.global_transform
	return g
