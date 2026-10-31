## The Research Annex's takes, as data in diagram metres [x, y, height] (the frame of tools/build_research_annex.gd; _w turns it
## into world metres). Each take is one static function the builder calls with the Area's `Cine` node.
##   AnnexCine.intro(cine)    # "Twelve Months": a dolly down the west lane past the researcher's glass, the seasons turn in the light
##   AnnexCine.outro(cine)    # "Memory Loss": the carry along the north corridor, the server racks, one rack's lights go dark
## Stand-in props sit under their own hidden group, shown by the take; mesh only, no colliders, no Guard.
class_name AnnexCine
extends RefCounted

const MOOD := preload("res://tools/area_dressing.gd").MOODS.research_annex


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


## Sets of a shot table [[at, cam, aim], ...] as the rail's three arrays.
static func _rail(cine: Node, key: String, shots: Array, opts: Dictionary) -> AnimationPlayer:
	var cams: Array = shots.map(func(s: Array) -> Array: return s[1])
	var aims: Array = shots.map(func(s: Array) -> Array: return s[2])
	var ats: Array = shots.map(func(s: Array) -> float: return s[0])
	return AreaCine.rail(cine, key, _ws(cams), _ws(aims), _times(ats), opts)


# ---- Intro: "Twelve Months" -------------------------------------------------------------------
# The camera runs south down the west lane, outside the lab, and looks in through the west door and the glass at the lead
# researcher's bench; while it passes, the light turns through four seasons (sun colour, angle and energy, the ambient tint)
# and a wall calendar flips twelve months. It ends on the Area's own light and settles to the shoulder rig behind the start
# spot, so control returns with no cut. The documented cheap form of the ticket: no clutter animation. ~9 s.
# The Operative never moves (the start spot is 22 m or more from every post), so no guard's cone can reach him.

const INTRO_KEY := "CineIntro"
const INTRO_LEN := 9.0
const START := [8.0, 72.0, 0.0]  # OperativeStart (build_research_annex.gd SPOTS)
const START_FACING := 45.0       # degrees, the marker's yaw
const CALENDAR := [29.7, 36.9, 1.9]  # on the lab's far wall (WallLabClean), facing west, down the line of sight through the glass
const MONTHS := 12
## [at s, sun [pitch, yaw] degrees, sun colour, sun energy, ambient colour, ambient energy]. Spring is the Area's own light.
const SEASONS := [
	[0.0, MOOD.sun, MOOD.sun_c, MOOD.sun_e, MOOD.amb, MOOD.amb_e],
	[2.2, [-82, 20], Color(1.0, 0.97, 0.82), 1.55, Color(0.82, 0.84, 0.82), 0.5],       # summer: high and warm
	[4.2, [-30, 70], Color(1.0, 0.62, 0.32), 1.05, Color(0.78, 0.6, 0.48), 0.38],       # autumn: low and orange
	[6.3, [-14, 105], Color(0.68, 0.78, 1.0), 0.7, Color(0.6, 0.68, 0.9), 0.3],         # winter: low, thin and blue
	[8.2, MOOD.sun, MOOD.sun_c, MOOD.sun_e, MOOD.amb, MOOD.amb_e],                      # spring again: the Mission's real values
	[INTRO_LEN, MOOD.sun, MOOD.sun_c, MOOD.sun_e, MOOD.amb, MOOD.amb_e],
]


## The shoulder rig's resting pose behind the start spot (pivot 1.45 up, 0.55 across and 2.33 back, aimed 7.4 ahead and down).
static func _rig_pose() -> Array:
	var yaw := -deg_to_rad(START_FACING)  # the marker is turned by minus its facing (build_research_annex.gd _marker)
	var f := Vector2(-sin(yaw), -cos(yaw))  # forward in the diagram's x, y
	var r := Vector2(cos(yaw), -sin(yaw))
	var cam := Vector2(START[0], START[1]) + r * 0.55 - f * 2.33
	var aim := Vector2(START[0], START[1]) + f * 7.4
	return [[cam.x, cam.y, 2.04], [aim.x, aim.y, -0.43]]


static func intro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "IntroProps"
	props.visible = false
	cine.add_child(props)
	var cal := Label3D.new()
	cal.name = "Calendar"
	cal.text = "01/12"
	cal.font_size = 128
	cal.pixel_size = 0.010
	cal.modulate = Color(0.85, 0.15, 0.12)
	cal.outline_modulate = Color(1, 1, 1)
	cal.outline_size = 24
	cal.position = _w(CALENDAR)
	cal.rotation_degrees.y = -90.0  # faces west
	props.add_child(cal)

	var pose := _rig_pose()
	var shots := [
		[0.0, [4.9, 24.0, 1.7], [5.0, 36.0, 1.6]],      # in the lane, looking down it
		[2.2, [4.9, 30.0, 1.7], [9.0, 36.0, 1.5]],      # the aim swings to the west door
		[4.0, [4.9, 35.0, 1.7], [13.0, 34.5, 1.3]],     # level with the door: through the glass to her bench
		[5.5, [4.9, 41.0, 1.7], [10.0, 35.5, 1.3]],     # past it, still looking back in
		[6.8, [6.0, 55.0, 1.9], [7.0, 66.0, 1.0]],      # on south, the aim leading round to the yard
		[8.0, pose[0], pose[1]],
		[INTRO_LEN, pose[0], pose[1]],
	]
	var player := _rail(cine, INTRO_KEY, shots, {min_s = 8.0, max_s = 10.0})
	AreaCine.track(player, "IntroProps:visible", [0.0], [true], true)

	var at: Array = SEASONS.map(func(s: Array) -> float: return s[0])
	AreaCine.track(player, "../Sun:rotation_degrees", at, SEASONS.map(func(s: Array) -> Vector3: return Vector3(s[1][0], s[1][1], 0)))
	AreaCine.track(player, "../Sun:light_color", at, SEASONS.map(func(s: Array) -> Color: return s[2]))
	AreaCine.track(player, "../Sun:light_energy", at, SEASONS.map(func(s: Array) -> float: return s[3]))
	AreaCine.track(player, "../Mood:environment:ambient_light_color", at, SEASONS.map(func(s: Array) -> Color: return s[4]))
	AreaCine.track(player, "../Mood:environment:ambient_light_energy", at, SEASONS.map(func(s: Array) -> float: return s[5]))

	# the calendar flips a month at a time across the seasons
	var flips: Array = []
	var labels: Array = []
	for m in MONTHS:
		flips.append(float(m) * 8.4 / MONTHS)
		labels.append("%02d/%d" % [m + 1, MONTHS])
	AreaCine.track(player, "IntroProps/Calendar:text", flips, labels, true)
	return player


# ---- Outro: "Memory Loss" ---------------------------------------------------------------------
# Low beside the Operative as he carries the Researcher east along the north corridor; the camera peels off through the
# server room's door and pushes along its racks at status-LED height. One rack's lights stutter amber and go black, then the
# one beside it; the hum sags with them. Holds on the dark rack, then the black. ~9.6 s.
# The Operative is the real one (still carrying: only his position, heading and gait are driven).

const OUTRO_KEY := "CineOutro"
const OUTRO_LEN := 9.6
const OUTRO_THIRD_AT := 5.6   # s the line comes in: as the racks begin to fail
const MEMORY_RACK := "Rack3"  # the "memory": the middle cabinet of the server room's east wall (DRESS, cabinet_b x 43.2)
const NEXT_RACK := "Rack4"    # the row beside it, which follows
const RACKS := {Rack1 = 20.0, Rack2 = 21.3, Rack3 = 22.6, Rack4 = 23.9, Rack5 = 25.2}  # y of each cabinet's centre
const LED_X := 42.55          # in front of the cabinets' faces
const CARRY_FROM := [26.0, 29.4, 0.0]
const CARRY_SPEED := 1.8      # m/s
const GREEN := Color(0.25, 1.0, 0.35)
const AMBER := Color(1.0, 0.6, 0.1)
const BLACK := Color(0, 0, 0)
const HUM := preload("res://assets/audio/ambience_hum.ogg")

const OUTRO_SHOTS := [
	[0.0, [28.5, 30.3, 0.8], [26.0, 29.4, 1.2]],
	[2.0, [31.5, 30.3, 0.8], [29.6, 29.4, 1.2]],
	[4.0, [35.0, 30.2, 0.9], [33.2, 29.4, 1.2]],      # alongside, low, ahead of the carry
	[4.8, [37.6, 29.4, 1.1], [38.0, 26.5, 1.2]],      # peeling off at the server room's door (x 37-39)
	[5.6, [38.4, 26.6, 1.2], [43.2, 24.0, 1.2]],      # in, the racks ahead
	[6.8, [40.5, 25.4, 1.2], [43.2, 22.9, 1.2]],
	[8.0, [41.2, 23.6, 1.2], [43.2, 22.6, 1.2]],      # level with the memory rack
	[OUTRO_LEN, [42.15, 22.85, 1.2], [43.2, 22.6, 1.25]],  # a slow push into one dead LED
]


## One rack's lights: two columns of five, all sharing one material so the take dims them together.
static func _rack(parent: Node, name: String, y: float) -> Node3D:
	var rack := Node3D.new()
	rack.name = name
	parent.add_child(rack)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.02, 0.02)
	mat.emission_enabled = true
	mat.emission = GREEN
	mat.emission_energy_multiplier = 2.5
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.05, 0.05, 0.05)
	for col in 2:
		for row in 5:
			var led := MeshInstance3D.new()
			led.name = "Led%d" % (col * 5 + row)
			led.mesh = mesh
			led.material_override = mat
			led.position = _w([LED_X, y + (col - 0.5) * 0.5, 0.45 + row * 0.3])
			rack.add_child(led)
	return rack


## The rack's lights: green, then `stutter` ([at, colour] steps) ending black.
static func _dim(player: AnimationPlayer, rack: String, steps: Array) -> void:
	var at: Array = [0.0]
	var colours: Array = [GREEN]
	for s in steps:
		at.append(s[0])
		colours.append(s[1])
	AreaCine.track(player, "OutroProps/Racks/%s/Led0:material_override:emission" % rack, at, colours, true)


static func outro(cine: Node) -> AnimationPlayer:
	var props := Node3D.new()
	props.name = "OutroProps"
	props.visible = false
	cine.add_child(props)
	var racks := Node3D.new()
	racks.name = "Racks"
	props.add_child(racks)
	for n in RACKS:
		_rack(racks, n, RACKS[n])
	var hum := AudioStreamPlayer3D.new()
	hum.name = "Hum"
	hum.bus = &"Ambience"
	hum.volume_db = -8.0
	hum.position = _w([LED_X, RACKS[MEMORY_RACK], 1.0])
	props.add_child(hum)

	var player := _rail(cine, OUTRO_KEY, OUTRO_SHOTS, {min_s = 8.0, max_s = 10.0, fov = 70.0})
	player.set_meta("third_at", OUTRO_THIRD_AT)
	AreaCine.track(player, "OutroProps:visible", [0.0], [true], true)

	# he walks on east with her the whole take
	var end_x: float = CARRY_FROM[0] + CARRY_SPEED * OUTRO_LEN
	var path: Array[Vector3] = [_w(CARRY_FROM), _w([end_x, CARRY_FROM[1], 0.0])]
	AreaCine.operative_track(player, [0.0, OUTRO_LEN] as Array[float], path, [-PI / 2.0, -PI / 2.0] as Array[float], CARRY_SPEED)

	# the memory rack stutters amber and dies; the next one follows
	_dim(player, MEMORY_RACK, [[6.0, AMBER], [6.15, BLACK], [6.3, AMBER], [6.45, GREEN], [6.6, AMBER], [7.0, BLACK]])
	_dim(player, NEXT_RACK, [[7.4, AMBER], [7.7, BLACK]])
	# the lens tightens on the dead light
	AreaCine.track(player, "CineOutroRig/Cam:camera_3d_resource:fov", [0.0, 6.8, OUTRO_LEN], [70.0, 70.0, 42.0])
	# the hum sags with the lights and is gone before the black
	AreaCine.track(player, "OutroProps/Hum:volume_db", [0.0, 5.8, 7.8, OUTRO_LEN - 0.8], [-8.0, -8.0, -30.0, -60.0])
	var t := player.get_animation("take").add_track(Animation.TYPE_AUDIO)
	player.get_animation("take").track_set_path(t, "OutroProps/Hum")
	player.get_animation("take").audio_track_insert_key(t, 0.0, HUM, 0.0, 0.0)
	return player
