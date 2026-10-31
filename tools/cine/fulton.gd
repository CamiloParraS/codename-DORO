## The Operative's Fulton out of an outro, mesh only: he stands on the Extraction point, the balloon goes up and fills over
## him, the line yanks him off his feet (`lift_off`) and he rises hanging from it (`hang`). Whoever is on his shoulder rides
## up held: Mission 2 and 3's ill Targets never get a balloon of their own (carry_only), they go up the line with him.
##   CineFulton.build(props)                                       # the balloon (hidden until it inflates) and its sounds
##   CineFulton.lift(player, "OutroProps", at, face, length)       # tracks: balloon, sounds, the Operative's height and pose
##   CineFulton.height(t)                                          # metres he is off the ground t s into the take
class_name CineFulton
extends RefCounted

const LAUNCH := preload("res://assets/audio/sfx_fulton_launch.ogg")
const LIFT := preload("res://assets/audio/sfx_fulton_lift.ogg")
const INFLATE := [0.4, 1.2]   # s the balloon goes up, s it is full
const YANK := 1.6             # s the line goes taut and he leaves the ground
const GRIP := 0.45            # s after the yank he is hanging from the line
const TIE := 4.6              # m from his feet up to the balloon node (the cable hangs 3 m from it, down to his hands)
const STEP := 0.1             # s between keys of the rise (linear between them, so balloon and body stay together)


static func build(props: Node) -> void:
	var b := Fx.balloon()
	b.name = "Balloon"
	b.scale = Vector3.ZERO
	props.add_child(b)
	for n in ["LaunchAudio", "LiftAudio"]:
		var a := AudioStreamPlayer.new()
		a.name = n
		a.bus = &"SFX"
		props.add_child(a)


## Metres off the ground `t` s into the take: nothing until the yank, a snatch up off the ground, then a steady climb that
## keeps accelerating out of the top of the frame.
static func height(t: float) -> float:
	var u := maxf(t - YANK, 0.0)
	return 2.2 * (1.0 - exp(-5.0 * u)) + 1.2 * u + 0.45 * u * u  # 6 m 2 s after, 14 m at 4 s, ~44 m at 8.4 s


## The take's Fulton: the Operative stands at `at` facing `face` for the whole take and goes up the line; the balloon
## (under `props`) inflates over him, then rides TIE above him. Only his position, heading, gait and pose are driven.
static func lift(player: AnimationPlayer, props: String, at: Vector3, face: float, length: float) -> void:
	var times: Array[float] = [0.0]
	var body: Array[Vector3] = [at]
	var t := YANK
	while t < length + STEP:
		times.append(minf(t, length))
		body.append(at + Vector3.UP * height(minf(t, length)))
		t += STEP
	var faces: Array[float] = []
	for i in times.size():
		faces.append(face)
	AreaCine.operative_track(player, times, body, faces)
	AreaCine.track(player, "../Operative:moving", [0.0], [false], true)
	AreaCine.track(player, "../Operative:velocity", [0.0], [Vector3.ZERO], true)
	AreaCine.track(player, "../Operative:cine_clip", [0.0, YANK, YANK + GRIP], ["", "lift_off", "hang"], true)
	var tied: Array = body.map(func(p: Vector3) -> Vector3: return p + Vector3.UP * TIE)
	AreaCine.track(player, props + "/Balloon:position", times, tied)
	AreaCine.track(player, props + "/Balloon:scale", [0.0, INFLATE[0], INFLATE[1]], [Vector3.ZERO, Vector3.ONE * 0.05, Vector3.ONE])
	var clip := player.get_animation("take")
	for s in [[props + "/LaunchAudio", LAUNCH, INFLATE[0]], [props + "/LiftAudio", LIFT, YANK]]:
		var a := clip.add_track(Animation.TYPE_AUDIO)
		clip.track_set_path(a, s[0])
		clip.audio_track_insert_key(a, s[2], s[1], 0.0, 0.0)
	AreaCine.track(player, "../ExtractionPoint/Beacon:visible", [0.0], [false], true)  # the balloon is the marker now


## Where he is (feet) `t` s into the take, standing at `at`.
static func at_time(at: Vector3, t: float) -> Vector3:
	return at + Vector3.UP * height(t)
