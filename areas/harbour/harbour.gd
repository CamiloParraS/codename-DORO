## The Harbour Area (greybox). Marker groups: spot, sentry_high_point, camera_mount, guard_post,
## guard_post_extra, spoof_place. A guard post's child markers are its patrol route.
## Places the Countermeasures MissionRun's plan deploys (Deployment) at those built-in spots.
## Open harbour.tscn and press F6 (Mission 1, nothing deployed), or start it from Free mode.
extends Node3D

const GUARD := preload("res://actors/guard/guard.tscn")
const BASE_GUARDS := 10  # the remaining posts are left for Countermeasure extras

var _was_alerted := false


func _ready() -> void:
	var deployed: Dictionary = $MissionRun.plan.deployed
	var guards := []
	for post: Marker3D in $GuardPosts.get_children().slice(0, BASE_GUARDS):
		guards.append(spawn_guard(post))
	# Extra posts: 1 is Stealth L2's patrol, the next ones are Combat L2's guards.
	var extras := Deployment.extra_patrols(deployed) + Deployment.extra_guards(deployed)
	for post: Marker3D in $ExtraGuardPosts.get_children().slice(0, extras):
		guards.append(spawn_guard(post))
	if Deployment.sentries(deployed):
		for spot: Marker3D in $SentryHighPoints.get_children():
			guards.append(spawn_guard(spot, true))
	if Deployment.pairs(deployed):
		_pair_up(guards.filter(func(g: Guard) -> bool: return g.route.size() > 1))
	$MissionRun.tally.add("spawned", guards.size())  # the Lethality denominator (reinforcements add theirs)
	var helmets := Deployment.helmets(deployed, guards.size())
	for i in guards.size():
		if helmets[i]:
			guards[i].wear_helmet()
		_equip(guards[i])
	$Operative.choke_time = Deployment.choke_time(deployed)
	$Operative.choke_noise = Deployment.choke_noise(deployed)
	if Deployment.cameras(deployed):
		for mount: Marker3D in $CameraMounts.get_children():
			var cam := SecurityCamera.new()
			cam.name = mount.name
			cam.operative = $Operative
			cam.transform = global_transform.affine_inverse() * mount.global_transform  # before _ready reads the yaw
			add_child(cam)


## Combat L3: each time an alert goes up from none, the road entry sends guards who head for it.
func _process(_delta: float) -> void:
	var alerted := get_tree().get_nodes_in_group("guards").any(
		func(g: Guard) -> bool: return g.alert.state == GuardAlert.State.ALERT)
	var n := Deployment.reinforcements($MissionRun.plan.deployed)
	if alerted and not _was_alerted and n > 0:
		var entry: Marker3D = $Spots/RoadEntry
		for i in n:
			var g := spawn_guard(entry)
			g.global_position += Vector3(i * 2.0, 0, 0)
			g.post = g.global_transform
			_equip(g)
			g.on_radio($Operative.global_position, "reinforcements")
		$MissionRun.tally.add("spawned", n)
	_was_alerted = alerted


## Combat L1 vests, the Takedowns L1 glance and Downs L2's instant alert, on every guard including reinforcements.
func _equip(g: Guard) -> void:
	var deployed: Dictionary = $MissionRun.plan.deployed
	if Deployment.vests(deployed):
		g.wear_vest()
	g.body_hits_to_kill = Deployment.body_hits_to_kill(deployed)
	g.turn_every = Deployment.turn_around_every(deployed)
	g.instant_down = Deployment.instant_alert_on_down(deployed)


## Takedowns L2: every second patrolling guard walks the first one's route, starting beside it.
func _pair_up(patrols: Array) -> void:
	for i in range(0, patrols.size() - 1, 2):
		var a: Guard = patrols[i]
		var b: Guard = patrols[i + 1]
		b.route = a.route.duplicate()
		b.global_position = a.global_position + a.global_basis.x * 1.5
		b.post = b.global_transform


## sentry: stands on a high point and never leaves it (no route).
func spawn_guard(post: Marker3D, sentry := false) -> Node3D:
	var g := GUARD.instantiate()
	g.name = post.name.replace("Post", "Guard")
	if not sentry:
		g.route.append(post.global_position)
		for wp: Marker3D in post.get_children():
			g.route.append(wp.global_position)
	g.operative = $Operative
	add_child(g)
	g.global_transform = post.global_transform
	g.post = post.global_transform
	return g
