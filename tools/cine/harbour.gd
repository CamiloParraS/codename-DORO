## The Harbour's takes, as data in diagram metres [x, y, height] (the same frame as tools/build_harbour.gd; _w turns it into
## world metres). Each take is one static function the builder calls with the Area's `Cine` node (tools/area_cine.gd does the
## rail); a take's stand-in props are mesh-only rigs under their own group, hidden in play and shown by the take.
##   HarbourCine.intro(cine)    # "Fog Level": a Metis launch crosses the fog at water level, heading east, the camera rises to the bow and settles
##   HarbourCine.outro(cine)    # "Gap in the Fog": the Operative rises, the spot is empty, a patrol notices, a hidden camera lights its lamp
class_name HarbourCine
extends RefCounted

const MODEL := preload("res://actors/character/character_model.tscn")
const LIFT := preload("res://assets/audio/sfx_fulton_lift.ogg")


## Diagram metres [x, y, height] to world metres (area_kit.gd `_p`).
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


## A value track of any keys, `interp` between them (NEAREST = steps).
static func _value(clip: Animation, path: String, times: Array, values: Array, interp := Animation.INTERPOLATION_LINEAR) -> void:
	var t := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(t, path)
	clip.track_set_interpolation_type(t, interp)
	clip.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE if interp == Animation.INTERPOLATION_NEAREST else Animation.UPDATE_CONTINUOUS)
	for i in times.size():
		clip.track_insert_key(t, times[i], values[i])


## Calls `method(args)` on the node at `path` at `at` seconds.
static func _call(clip: Animation, path: String, at: float, method: StringName, args: Array) -> void:
	var t := clip.add_track(Animation.TYPE_METHOD)
	clip.track_set_path(t, path)
	clip.track_insert_key(t, at, {"method": method, "args": args})


static func _model(parent: Node, name: String, at: Vector3, yaw := 0.0, kind := CharacterModel.Kind.GUARD) -> Node3D:
	var rig := Node3D.new()
	rig.name = name  # the guard's look is picked by its parent's name (CharacterModel)
	rig.position = at
	rig.rotation.y = yaw
	var m := MODEL.instantiate()
	m.kind = kind
	m.name = "Model"
	rig.add_child(m)
	parent.add_child(rig)
	return rig


static func _part(parent: Node, name: String, mesh: Mesh, at: Vector3, c: Color) -> MeshInstance3D:
	var p := MeshInstance3D.new()
	p.name = name
	p.mesh = mesh
	p.position = at
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	p.material_override = m
	parent.add_child(p)
	return p


## The pole camera: a post and a head that faces -Z, with a red lamp on its lens. Mesh-only; the head is "Head".
static func _pole_camera(parent: Node, name: String, base: Array, height: float, yaw: float) -> Node3D:
	var rig := Node3D.new()
	rig.name = name
	rig.position = _w(base)
	var post := CylinderMesh.new()
	post.top_radius = 0.07
	post.bottom_radius = 0.09
	post.height = height
	post.radial_segments = 6
	_part(rig, "Pole", post, Vector3(0, height / 2.0, 0), Color(0.14, 0.15, 0.16))
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = height
	head.rotation.y = yaw
	rig.add_child(head)
	var body := BoxMesh.new()
	body.size = Vector3(0.3, 0.28, 0.7)
	_part(head, "Body", body, Vector3(0, 0.05, -0.15), Color(0.16, 0.17, 0.18))
	var lens := CylinderMesh.new()
	lens.top_radius = 0.09
	lens.bottom_radius = 0.09
	lens.height = 0.1
	var l := _part(head, "Lens", lens, Vector3(0, 0.05, -0.54), Color(0.05, 0.05, 0.06))
	l.rotation.x = PI / 2.0
	var lamp := Fx.lamp(Color(1.0, 0.15, 0.1), 0.1)
	lamp.name = "Lamp"
	lamp.position = Vector3(0, 0.22, -0.4)
	head.add_child(lamp)
	parent.add_child(rig)
	return rig


# ---- Outro: "Gap in the Fog" ------------------------------------------------------------------
# The Operative (his own look, standing) rises into the fog on the Fulton line, the camera comes down on the empty Extraction
# point, the rear guard of a patrol slows and glances at it, and a pole camera hiding behind a crate lights its lamp and turns. Fade to black at the end. ~9.6 s.

const OUTRO_KEY := "CineOutro"
const OUTRO_LEN := 9.6
const OUTRO_THIRD_AT := 5.8  # s the extraction line comes in, over the empty spot
const OUTRO_SPOT := [11.0, 74.0, 0.0]  # the Extraction point
const OUTRO_RISE_T := [0.0, 1.0, 2.5, 4.0, OUTRO_LEN]
const OUTRO_RISE_H := [0.0, 1.0, 7.0, 16.0, 45.0]  # metres the Operative is off the ground
const OUTRO_PATROL_Y := 68.0  # the patrol crosses the slipway mouth east to west
const OUTRO_STOP_AT := 6.4    # the rear guard stops at the mouth (x 12.5) ...
const OUTRO_GO_AT := 8.2      # ... and walks on
const OUTRO_WALK := 1.4       # m/s
const OUTRO_POLE := [14.6, 71.0, 0.0]
const OUTRO_POLE_H := 2.0  # low: its head just clears the crate that hides it
const OUTRO_LAMP_AT := 7.4  # s the lamp lights, the only thing that gives it away

## The camera (one rail): [at s, camera [x, y, h], aim [x, y, h]].
const OUTRO_SHOTS := [
	[0.0, [11.6, 68.4, 0.5], [11.0, 74.0, 3.0]],     # low, wide, on the point; the aim follows the balloon up
	[1.5, [11.6, 68.6, 0.6], [11.0, 74.0, 8.0]],
	[3.0, [11.5, 69.4, 0.8], [11.0, 74.0, 14.0]],
	[4.4, [11.2, 70.4, 1.5], [11.0, 74.0, 0.5]],     # down and in on the spot where the Operative stood
	[5.8, [11.4, 71.0, 1.5], [11.0, 74.0, 0.4]],
	[7.0, [12.0, 72.4, 1.6], [12.4, 68.2, 1.5]],     # round to the patrol's rear guard
	[8.3, [10.5, 72.4, 1.5], [14.6, 71.0, 2.0]],     # creeping up on the crate; the lamp lights
	[OUTRO_LEN, [9.0, 72.2, 1.6], [14.6, 71.0, 2.1]],
]


static func outro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "OutroProps"
	props.visible = false  # the Operative, a patrol and a camera pole that only the take shows
	cine.add_child(props)

	var spot := _w(OUTRO_SPOT)
	var recruit := _model(props, "Recruit", spot, 0.0, CharacterModel.Kind.OPERATIVE)
	var balloon := Fx.balloon()
	balloon.scale = Vector3.ONE
	balloon.position.y = 3.0
	recruit.add_child(balloon)
	var b_stop_x := 12.5  # where the rear guard stops; the lead guard is 2.2 m ahead of him
	var guard_a := _model(props, "PatrolA", _w([b_stop_x - 2.2 + OUTRO_WALK * OUTRO_STOP_AT, OUTRO_PATROL_Y, 0.0]), PI / 2.0)
	var guard_b := _model(props, "PatrolB", _w([b_stop_x + OUTRO_WALK * OUTRO_STOP_AT, OUTRO_PATROL_Y, 0.0]), PI / 2.0)
	var pole := _pole_camera(props, "PoleCamera", OUTRO_POLE, OUTRO_POLE_H, deg_to_rad(30.0))
	var cover := BoxMesh.new()  # a crate in front of the pole: only the head shows over it
	cover.size = Vector3(1.4, 1.5, 0.8)
	_part(props, "Cover", cover, _w(OUTRO_POLE) + Vector3(-0.9, 0.75, 0.2), Color(0.32, 0.3, 0.26))
	var audio := AudioStreamPlayer3D.new()
	audio.name = "Audio"
	audio.bus = &"Ambience"
	audio.position = spot
	props.add_child(audio)

	var cams: Array = OUTRO_SHOTS.map(func(s: Array) -> Array: return s[1])
	var aims: Array = OUTRO_SHOTS.map(func(s: Array) -> Array: return s[2])
	var ats: Array = OUTRO_SHOTS.map(func(s: Array) -> float: return s[0])
	var player := AreaCine.rail(cine, OUTRO_KEY, _ws(cams), _ws(aims), _times(ats), {min_s = 6.0, max_s = 10.0})
	player.set_meta("third_at", OUTRO_THIRD_AT)
	var clip := player.get_animation("take")
	var end := OUTRO_LEN

	# nobody on the point: the Operative is gone from the first frame, and so is the beacon over where he stood
	_value(clip, "../Operative:visible", [0.0], [false], Animation.INTERPOLATION_NEAREST)
	_value(clip, "../ExtractionPoint/Beacon:visible", [0.0], [false], Animation.INTERPOLATION_NEAREST)
	_value(clip, "OutroProps:visible", [0.0], [true], Animation.INTERPOLATION_NEAREST)

	# the Operative and his balloon rise on the line, upright
	_call(clip, "OutroProps/Recruit/Model", 0.0, &"play", ["idle"])
	var heights := OUTRO_RISE_H.map(func(h: float) -> Vector3: return spot + Vector3(0, h, 0))
	_value(clip, "OutroProps/Recruit:position", OUTRO_RISE_T, heights, Animation.INTERPOLATION_CUBIC)

	# the patrol: A keeps walking west; B walks, stops at the slipway mouth, looks at the spot, walks on
	var west := PI / 2.0
	var step := Vector3(-OUTRO_WALK, 0, 0)
	_call(clip, "OutroProps/PatrolA/Model", 0.0, &"play", ["walk", OUTRO_WALK])
	_call(clip, "OutroProps/PatrolB/Model", 0.0, &"play", ["walk", OUTRO_WALK])
	_value(clip, "OutroProps/PatrolA:position", [0.0, end], [guard_a.position, guard_a.position + step * end])
	var stopped: Vector3 = guard_b.position + step * OUTRO_STOP_AT
	_value(clip, "OutroProps/PatrolB:position", [0.0, OUTRO_STOP_AT, OUTRO_GO_AT, end],
		[guard_b.position, stopped, stopped, stopped + step * (end - OUTRO_GO_AT)])
	_call(clip, "OutroProps/PatrolB/Model", OUTRO_STOP_AT, &"play", ["idle"])
	_call(clip, "OutroProps/PatrolB/Model", OUTRO_STOP_AT + 0.3, &"gaze", [spot + Vector3(0, 1.4, 0)])
	_call(clip, "OutroProps/PatrolB/Model", OUTRO_GO_AT - 0.3, &"gaze", [null])
	_call(clip, "OutroProps/PatrolB/Model", OUTRO_GO_AT, &"play", ["walk", OUTRO_WALK])
	_value(clip, "OutroProps/PatrolB:rotation:y", [OUTRO_STOP_AT, OUTRO_STOP_AT + 0.7, OUTRO_GO_AT - 0.2, OUTRO_GO_AT + 0.4],
		[west, 2.4, 2.4, west], Animation.INTERPOLATION_LINEAR_ANGLE)

	# the pole camera sits dark until its lamp lights, then its head swings round and holds on the spot
	_value(clip, "OutroProps/PoleCamera/Head/Lamp:visible", [0.0, OUTRO_LAMP_AT], [false, true], Animation.INTERPOLATION_NEAREST)
	var toward := spot - pole.position
	var face := atan2(-toward.x, -toward.z)
	_value(clip, "OutroProps/PoleCamera/Head:rotation:y", [0.0, OUTRO_LAMP_AT + 0.2, 8.8], [deg_to_rad(30.0), deg_to_rad(30.0), face], Animation.INTERPOLATION_LINEAR_ANGLE)

	# the lift's creak on the line (the Fulton's own sound); the Area's outdoor ambience is the wind
	var t := clip.add_track(Animation.TYPE_AUDIO)
	clip.track_set_path(t, "OutroProps/Audio")
	clip.audio_track_insert_key(t, 0.0, LIFT, 0.0, 0.0)
	return player


## A painted hull texture: white topsides, a blue boot stripe, a dark waterline, lightly streaked.
static func _hull_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:
			var c := Color(0.82, 0.84, 0.86)
			if y >= 22 and y < 26:
				c = Color(0.12, 0.28, 0.5)
			elif y >= 26:
				c = Color(0.16, 0.12, 0.1)
			img.set_pixel(x, y, c.darkened(0.06 * float((x * 7 + y * 13) % 5) / 4.0))
	return ImageTexture.create_from_image(img)


## The Metis launch, bow to -Z, turned to head east: a textured hull with a pointed bow, a deck, a cabin with a windscreen,
## rails and a lamp. Mesh only.
static func _launch(parent: Node) -> Node3D:
	var boat := Node3D.new()
	boat.name = "Boat"
	boat.rotation.y = -PI / 2.0
	parent.add_child(boat)
	var tex := _hull_texture()
	var hull := BoxMesh.new()
	hull.size = Vector3(1.8, 0.8, 3.8)
	var bow := PrismMesh.new()  # a wedge ahead of the hull; turned so its apex points forward
	bow.size = Vector3(1.8, 1.6, 0.8)
	var h := _part(boat, "Hull", hull, Vector3(0, 0.2, 0.6), Color.WHITE)
	var b := _part(boat, "Bow", bow, Vector3(0, 0.2, -2.1), Color.WHITE)
	b.rotation.x = -PI / 2.0
	for part: MeshInstance3D in [h, b]:
		var m := part.material_override as StandardMaterial3D
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var deck := BoxMesh.new()
	deck.size = Vector3(1.5, 0.06, 4.6)
	_part(boat, "Deck", deck, Vector3(0, 0.63, -0.1), Color(0.42, 0.36, 0.3))
	var cabin := BoxMesh.new()
	cabin.size = Vector3(1.3, 0.8, 1.5)
	_part(boat, "Cabin", cabin, Vector3(0, 1.05, 0.8), Color(0.88, 0.89, 0.9))
	var glass := BoxMesh.new()
	glass.size = Vector3(1.2, 0.35, 0.05)
	_part(boat, "Windscreen", glass, Vector3(0, 1.2, 0.03), Color(0.1, 0.16, 0.22)).rotation.x = deg_to_rad(-20.0)
	var rail := BoxMesh.new()
	rail.size = Vector3(0.05, 0.05, 2.0)
	for side in [-1.0, 1.0]:
		_part(boat, "Rail", rail, Vector3(side * 0.7, 0.95, -1.1), Color(0.7, 0.7, 0.72))
	var lamp := Fx.lamp(Color(0.9, 0.95, 1.0), 0.12)
	lamp.name = "Lamp"
	lamp.position = Vector3(0, 1.7, 0.8)
	boat.add_child(lamp)
	return boat


# ---- Intro: "Fog Level" -----------------------------------------------------------------------
# Just above the water, a Metis launch crosses the frame trailing its wake and the camera rises past it to the freighter's
# bow, where the Operative steps aboard onto the start spot; it settles to the shoulder rig, so control returns with no cut.
# The bow is a guard-free start (nearest post 17 m away, past a guard's 16 m reach) and he never leaves it. ~9 s.

const INTRO_KEY := "CineIntro"
const INTRO_LEN := 9.0
const DECK_H := 2.0
const SEA_H := -1.6
const INTRO_START := [73.0, 0.0, DECK_H]  # OperativeStart (build_harbour.gd SPOTS); he faces south, into the ship
const INTRO_TIP := [73.0, -2.0, DECK_H]   # where he comes aboard: the bow tip
const INTRO_STEP_T := [3.0, 5.0]          # s he walks from the tip to the start
const INTRO_WALK := 1.0                   # m/s
const INTRO_BOAT_FROM := [62.0, -9.0, SEA_H + 0.3]  # the launch runs west to east, right to left as the camera sees it
const INTRO_BOAT_TO := [86.0, -9.0, SEA_H + 0.3]
const INTRO_BOAT_T := 5.5

## The camera (one rail): [at s, camera [x, y, h], aim [x, y, h]]. The last two shots are the shoulder rig's resting pose
## behind the start spot (pivot 1.45 up, arm 0.55 across and 2.4 back, tilted 0.25 rad; operative.gd), held for the aim to settle.
const INTRO_SHOTS := [
	[0.0, [68.0, -16.0, SEA_H + 0.8], [62.0, -9.0, SEA_H + 1.0]],   # a hand above the water, on the launch coming in
	[2.0, [68.0, -15.5, SEA_H + 1.2], [72.0, -4.0, 1.0]],            # the launch passes; the aim slides to the hull
	[4.0, [68.0, -9.5, 1.4], [73.0, -1.5, 3.2]],                     # rising up the hull as he steps aboard
	[6.0, [70.0, -6.5, 3.6], [73.0, 0.0, 3.2]],
	[7.8, [72.45, -2.33, 4.04], [72.45, 7.4, 1.57]],
	[INTRO_LEN, [72.45, -2.33, 4.04], [72.45, 7.4, 1.57]],
]


static func intro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "IntroProps"
	props.visible = false  # a launch and its wake, shown by the take; mesh only
	cine.add_child(props)

	var boat := _launch(props)
	boat.position = _w(INTRO_BOAT_FROM)
	for side in [-1.0, 1.0]:  # the V of the wake, flat on the water behind the stern
		var wake := BoxMesh.new()
		wake.size = Vector3(0.5, 0.02, 9.0)
		var w := _part(boat, "Wake%s" % ("L" if side < 0 else "R"), wake, Vector3(side * 1.9, -0.18, 6.8), Color(0.9, 0.95, 1.0, 0.45))
		w.rotation.y = side * deg_to_rad(11.0)
		var m := w.material_override as StandardMaterial3D
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var cams: Array = INTRO_SHOTS.map(func(s: Array) -> Array: return s[1])
	var aims: Array = INTRO_SHOTS.map(func(s: Array) -> Array: return s[2])
	var ats: Array = INTRO_SHOTS.map(func(s: Array) -> float: return s[0])
	var player := AreaCine.rail(cine, INTRO_KEY, _ws(cams), _ws(aims), _times(ats), {min_s = 6.0, max_s = 10.0})
	var clip := player.get_animation("take")

	_value(clip, "IntroProps:visible", [0.0], [true], Animation.INTERPOLATION_NEAREST)
	_value(clip, "IntroProps/Boat:position", [0.0, INTRO_BOAT_T], [_w(INTRO_BOAT_FROM), _w(INTRO_BOAT_TO)])
	# he steps off the bow tip onto the start spot and stands facing south, into the ship (the Area's start facing)
	var face := deg_to_rad(-180.0)  # the OperativeStart marker's yaw
	AreaCine.operative_track(player, _times(INTRO_STEP_T), [_w(INTRO_TIP), _w(INTRO_START)] as Array[Vector3], [face, face] as Array[float], INTRO_WALK)
	return player
