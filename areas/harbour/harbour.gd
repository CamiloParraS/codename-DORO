## The Harbour Area (greybox). Marker groups: spot, sentry_high_point, camera_mount, guard_post,
## guard_post_extra, spoof_place. A guard post's child markers are its patrol route. Every $GuardPosts post
## is staffed, so the Area sets its own guard count. Marker meta (all optional): `hold` (seconds) and
## `scan` (degrees) make a stop that faces the marker's -Z, held that long and swept across that arc (a
## routeless post with `scan` is a scanning post; a sentry high point reads `scan` too); `chat` on a post
## staffs it with a chatting pair. Crawlspaces and Ladders are plain geometry this script never reads.
## Places the Countermeasures MissionRun's plan deploys (Deployment) at those built-in spots.
## Open harbour.tscn and press F6 (Mission 1, nothing deployed), or start it from Free mode.
extends Node3D

const GUARD := preload("res://actors/guard/guard.tscn")

var _was_alerted := false
var _reinforcements := 0  # ever sent, for unique names (a Checkpoint restore removes some, never reuses a name)


func _ready() -> void:
	var deployed: Dictionary = $MissionRun.plan.deployed
	var guards := []
	for post: Marker3D in $GuardPosts.get_children():
		if post.has_meta("chat"):
			guards.append_array(_spawn_chat(post))
		else:
			guards.append(spawn_guard(post))
	# Extra posts: 1 is Stealth L2's patrol, the next ones are Combat L2's guards.
	var extras := Deployment.extra_patrols(deployed) + Deployment.extra_guards(deployed)
	for post: Marker3D in $ExtraGuardPosts.get_children().slice(0, extras):
		guards.append(spawn_guard(post))
	if Deployment.sentries(deployed):
		for spot: Marker3D in $SentryHighPoints.get_children():
			guards.append(spawn_guard(spot, true))
	_spawn_targets(guards)
	if Deployment.pairs(deployed):
		_pair_up(guards.filter(func(g: Guard) -> bool: return g.route.size() > 1))
	$MissionRun.tally.add("spawned", guards.size())  # escorts included, Targets not (they add 3 each)  # the Lethality denominator (reinforcements add theirs)
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


## The Mission's Targets (Campaign data): each on a $TargetPosts route with one escort guard walking it,
## running to $Spots/SafeRoom on alert. Escorts join `guards`, so they get the Countermeasures; Targets don't.
## ponytail: one safe room for all Targets (in the Harbour, the back of the gatehouse).
func _spawn_targets(guards: Array) -> void:
	var names: Array = Campaign.MISSIONS[$MissionRun.record.mission].targets
	for i in names.size():
		var post: Marker3D = $TargetPosts.get_child(i)
		var t := spawn_guard(post, false, true)
		t.name = names[i]
		t.safe_room = $Spots/SafeRoom.global_position
		var escort := spawn_guard(post)
		escort.name = "Escort%d" % (i + 1)
		escort.global_position += escort.global_basis.x * 1.5
		escort.post = escort.global_transform
		guards.append(escort)
	$MissionRun.tally.add("targets", names.size())


## Combat L3: each time an alert goes up from none, the road entry sends guards who head for it.
func _process(_delta: float) -> void:
	var alerted := get_tree().get_nodes_in_group("guards").any(
		func(g: Guard) -> bool: return g.alert.state == GuardAlert.State.ALERT)
	var n := Deployment.reinforcements($MissionRun.plan.deployed)
	if alerted and not _was_alerted and n > 0:
		var entry: Marker3D = $Spots/RoadEntry
		for i in n:
			_reinforcements += 1
			var g := spawn_guard(entry)
			g.name = "GuardRoad%d" % _reinforcements
			g.global_position += Vector3(i * 2.0, 0, 0)
			g.post = g.global_transform
			_equip(g)
			var rng: RandomNumberGenerator = g.rng
			var goal: Vector3 = $Operative.global_position
			if Telegraph.flank(Deployment.combat_level($MissionRun.plan.deployed), rng):
				goal = Telegraph.flank_point(entry.global_position, goal, rng)
				g.telegraph("flank", Telegraph.FLANK_ICON, "startle", "Flanking, go wide!")
			g.on_radio(goal, "reinforcements")
		$MissionRun.tally.add("spawned", n)
	_was_alerted = alerted


## Combat L1 vests, the Takedowns L1 glance and Downs L2's instant alert, on every guard including reinforcements.
func _equip(g: Guard) -> void:
	var deployed: Dictionary = $MissionRun.plan.deployed
	if Deployment.vests(deployed):
		g.wear_vest()
	g.body_hits_to_kill = Deployment.body_hits_to_kill(deployed)
	g.turn_every = Deployment.turn_around_every(deployed)
	g.head_check_level = Deployment.head_check_level(deployed)
	g.radio_check_level = Deployment.radio_check_level(deployed)
	g.instant_down = Deployment.instant_alert_on_down(deployed)


## Takedowns L2: every second patrolling guard walks the first one's route, starting beside it.
func _pair_up(patrols: Array) -> void:
	for i in range(0, patrols.size() - 1, 2):
		var a: Guard = patrols[i]
		var b: Guard = patrols[i + 1]
		b.route = a.route.duplicate()
		b.stops = a.stops.duplicate()
		b.global_position = a.global_position + a.global_basis.x * 1.5
		b.post = b.global_transform


## A chatting pair on a `chat` post: 2 m apart along its X axis, facing each other, each staying on its spot.
func _spawn_chat(post: Marker3D) -> Array:
	var chat := Chat.new()
	var pair := []
	for seat in 2:
		var g := spawn_guard(post)
		g.name = post.name.replace("Post", "Guard") + "AB"[seat]
		g.global_position = post.global_position + post.global_basis.x * (1.0 if seat == 0 else -1.0)
		g.look_at(post.global_position)
		g.post = g.global_transform
		g.route.assign([g.global_position])
		g.stops.assign([{yaw = g.rotation.y, hold = Guard.PAUSE}])
		g.chat = chat
		g.chat_seat = seat
		pair.append(g)
	pair[0].chat_partner = pair[1]
	pair[1].chat_partner = pair[0]
	return pair


## A route point's stop from its Marker meta: {} unless it has `hold` or `scan`.
static func stop_of(m: Marker3D) -> Dictionary:
	if not (m.has_meta("hold") or m.has_meta("scan")):
		return {}
	var s := {yaw = m.global_rotation.y, scan = float(m.get_meta("scan", 0.0))}
	if m.has_meta("hold"):
		s.hold = float(m.get_meta("hold"))
	return s


## sentry: stands on a high point and never leaves it (no route). target: a Mission Target.
func spawn_guard(post: Marker3D, sentry := false, target := false) -> Node3D:
	var g := GUARD.instantiate()
	if target:
		g.target = true
		g.get_node("Model").kind = CharacterModel.Kind.TARGET
	g.name = post.name.replace("Post", "Guard")
	if sentry:
		if post.has_meta("scan"):
			g.stops.append(stop_of(post))
	else:
		g.route.append(post.global_position)
		g.stops.append(stop_of(post))
		for wp: Marker3D in post.get_children():
			g.route.append(wp.global_position)
			g.stops.append(stop_of(wp))
	g.operative = $Operative
	add_child(g)
	g.global_transform = post.global_transform
	g.post = post.global_transform
	return g
