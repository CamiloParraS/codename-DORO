## The Research Annex's takes, as data in diagram metres [x, y, height] (the frame of tools/build_research_annex.gd; _w turns it
## into world metres). Each take is one static function the builder calls with the Area's `Cine` node.
##   AnnexCine.intro(cine)    # "Twelve Months": a dolly down the west lane, the seasons turn, the Operative comes in through the fence's hole
##   AnnexCine.outro(cine)    # "Memory Loss": the carry out to the Extraction point, the camera turning back to the Annex
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
# The Operative walks in through the hole in the south fence (GAP, build_research_annex.gd) to the start spot and ends facing
# its way; the start is 22 m or more from every post and the walk never leaves its 8 m, so no guard's cone can reach him.

const INTRO_KEY := "CineIntro"
const INTRO_LEN := 9.0
const START := [8.0, 72.0, 0.0]  # OperativeStart (build_research_annex.gd SPOTS)
const START_FACING := 45.0       # degrees, the marker's yaw
const CALENDAR := [29.7, 36.9, 1.9]  # on the lab's far wall (WallLabClean), facing west, down the line of sight through the glass
const GAP := [10.5, 75.8]  # the middle of the fence's hole
const WALK_IN := [  # [at s, x, y, yaw]: from outside the fence, through the hole, to the start spot
	[4.0, 10.5, 79.0, 0.0], [5.1, 10.5, 76.5, 0.0], [6.9, 8.3, 72.5, 0.5], [7.4, START[0], START[1], -START_FACING * PI / 180.0],
]
const WALK_SPEED := 2.2
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
		[2.0, [4.9, 30.0, 1.7], [9.0, 36.0, 1.5]],      # the aim swings to the west door
		[3.4, [4.9, 40.0, 1.7], [13.0, 36.5, 1.3]],     # level with the door: through the glass to her bench
		[5.0, [6.0, 62.0, 1.8], [10.5, 76.5, 1.0]],     # on south, the aim on the hole as he comes through
		[6.4, [5.6, 68.0, 1.8], [9.5, 74.5, 1.0]],
		[8.0, pose[0], pose[1]],
		[INTRO_LEN, pose[0], pose[1]],
	]
	var player := _rail(cine, INTRO_KEY, shots, {min_s = 8.0, max_s = 10.0})
	AreaCine.track(player, "IntroProps:visible", [0.0], [true], true)
	var ats: Array[float] = []
	var pts: Array[Vector3] = []
	var yaws: Array[float] = []
	for r in WALK_IN:
		ats.append(r[0])
		pts.append(_w([r[1], r[2], 0.0]))
		yaws.append(r[3])
	AreaCine.operative_track(player, ats, pts, yaws, WALK_SPEED)

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


# ---- Outro: "Memory Loss" ---------------------------------------------------------------------------------------
# The Operative carries the Researcher out of the lab's east side across the north-east yard to the Extraction point, like the
# Relay Station's: over his shoulder, easing wider, then the camera turns back to the Annex while he stands at the pad and
# the black comes in. The Operative is the real one (still carrying: only his position, heading and gait are driven). ~9 s.

const OUTRO_KEY := "CineOutro"
const OUTRO_LEN := 9.0
const OUTRO_THIRD_AT := 4.6   # s the line comes in: as he nears the pad
const WALK_FROM := [57.0, 24.0, 0.0]
const WALK_TO := [68.5, 24.0, 0.0]  # a metre and a half short of the Extraction point (70, 24)
const WALK_T := 5.5           # s the walk lasts
const CARRY_STEP := 1.6       # m/s the carry clip plays at
const WALK_YAW := -PI / 2.0   # facing east

const OUTRO_SHOTS := [
	[0.0, [53.5, 25.6, 2.3], [58.0, 24.0, 1.4]],    # over the shoulder
	[2.5, [58.5, 27.5, 2.6], [64.0, 24.0, 1.3]],    # easing wider
	[4.5, [63.0, 28.6, 3.0], [69.0, 24.0, 1.3]],
	[5.5, [64.0, 20.0, 3.2], [58.0, 25.0, 2.8]],    # he stops; the camera turns back to the Annex
	[7.0, [66.0, 19.0, 4.5], [48.0, 26.0, 4.0]],
	[OUTRO_LEN, [67.0, 19.0, 5.0], [44.0, 26.0, 6.0]],
]


static func outro(cine: Node) -> AnimationPlayer:
	var player := _rail(cine, OUTRO_KEY, OUTRO_SHOTS, {min_s = 8.0, max_s = 10.0})
	player.set_meta("third_at", OUTRO_THIRD_AT)
	var path: Array[Vector3] = [_w(WALK_FROM), _w(WALK_TO)]
	AreaCine.operative_track(player, [0.0, WALK_T] as Array[float], path, [WALK_YAW, WALK_YAW] as Array[float], CARRY_STEP)
	return player
