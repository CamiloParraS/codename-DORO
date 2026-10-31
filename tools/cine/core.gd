## The Core's takes, built into areas/core/core.tscn by tools/build_core.gd (`CoreCine.build(builder)`). Data in metres.
## The Descent: the freight lift's ride down. The car is a small sealed cab hung far outside the Area (CAB), so no Guard
## can see or reach the Operative inside it; the shaft is a strip that slides past the gate, and a dark pulse hides the cut
## to the corridor (LIFT_EXIT). The cab, its shaft strip and the rail's Path3D are reusable: the Ascent (the finale's
## three endings) builds its take on the same `DescentCab` and `CineDescentRig/Path`.
## Panel lights: the five Voices in table order, brightness from areas/core/descent_car.gd (DescentLogic).
class_name CoreCine
extends RefCounted

const CAB := Vector3(-140, 120, -60)   # world: the cab's floor centre, well off the map
const LIFT_EXIT := [-2.5, 32, 0]       # diagram metres: inside the corridor mouth, facing west (CORE_LIFT_EXIT)
const EXIT_FACE := PI / 2.0            # west, radians
const KEY := "CineDescent"
const LENGTH := 8.6                    # s; the ticket's 20 s compressed, a take is short
const CUT := 7.2                       # s: the Operative is in the corridor and the camera with him, under a dark pulse
const CAR_SCRIPT := "res://areas/core/descent_car.gd"
const LAMPS := {
	promachos = Color(0.95, 0.3, 0.2), nike = Color(1.0, 0.8, 0.2), pallas = Color(0.3, 0.6, 1.0),
	gorgo = Color(0.85, 0.25, 0.95), glaukopis = Color(0.3, 1.0, 0.55),
}
const SHAKE := 1.2        # degrees at the worst of the ride
const SHAKE_HZ := 3.0


static func exit_world() -> Vector3:
	return Vector3(LIFT_EXIT[0] - 40.0, LIFT_EXIT[2], LIFT_EXIT[1] - 40.0)


## Where the Operative stands in the cab (facing -Z, towards the gate).
static func stand() -> Vector3:
	return CAB + Vector3(0, 0.02, 0.3)


## The cab, the shaft strip and the take, under the builder's root.
static func build(b: Object) -> void:
	var car: Node3D = b._group(b._root, "DescentCab")
	car.set_script(load(CAR_SCRIPT))
	_cab(b, car)
	_panel(b, car)
	_gate(b, car)
	_shaft(b, car)
	var lamp := OmniLight3D.new()
	lamp.name = "CabLamp"
	lamp.position = CAB + Vector3(0, 2.4, 0.3)
	lamp.omni_range = 7.0
	lamp.light_energy = 1.4
	lamp.light_color = Color(1.0, 0.85, 0.6)
	car.add_child(lamp)
	var cine: Node3D = AreaCine.root(b._root)
	_descent(cine)
	cine.owner = b._root
	b._own(car)
	b._own(cine)


## Diagram rect of a cab-local rect (x, z, w, d), in the builder's units.
static func _r(x: float, z: float, w: float, d: float) -> Array:
	return [CAB.x + 40.0 + x, CAB.z + 40.0 + z, w, d]


static func _cab(b: Object, car: Node3D) -> void:
	var y := CAB.y
	var steel := Color(0.62, 0.64, 0.66)
	b._box(car, "CabFloor", _r(-1.5, -2.0, 3.0, 4.0), y - 0.3, y, "deck_plate", Color(0.7, 0.7, 0.72))
	b._box(car, "CabRoof", _r(-1.5, -2.0, 3.0, 4.0), y + 2.8, y + 3.0, "metal", steel)
	b._box(car, "CabBack", _r(-1.5, 2.0, 3.0, 0.2), y, y + 2.8, "rust", Color(0.85, 0.8, 0.75))
	b._box(car, "CabWest", _r(-1.7, -2.0, 0.2, 4.2), y, y + 2.8, "rust", Color(0.85, 0.8, 0.75))
	b._box(car, "CabEast", _r(1.5, -2.0, 0.2, 4.2), y, y + 2.8, "rust", Color(0.85, 0.8, 0.75))
	# the gate's frame: two posts and a lintel, hazard-striped
	b._box(car, "GatePostW", _r(-1.5, -2.2, 0.4, 0.3), y, y + 2.8, "hazard", Color.WHITE)
	b._box(car, "GatePostE", _r(1.1, -2.2, 0.4, 0.3), y, y + 2.8, "hazard", Color.WHITE)
	b._box(car, "GateLintel", _r(-1.1, -2.2, 2.2, 0.3), y + 2.5, y + 2.8, "hazard", Color.WHITE)


## The panel on the east wall: five lamps, one per Voice, in Aigis.VOICES order, dark until the take lights them.
static func _panel(b: Object, car: Node3D) -> void:
	var panel: Node3D = b._group(car, "Panel")
	var y := CAB.y
	b._box(panel, "PanelBody", _r(1.32, -1.3, 0.18, 2.0), y + 1.05, y + 1.95, "metal", Color(0.4, 0.42, 0.45))
	for i in Aigis.VOICES.size():
		var voice: String = Aigis.VOICES[i]
		var m := MeshInstance3D.new()
		m.name = "Lamp" + voice.capitalize()
		m.mesh = b._box_mesh(Vector3(0.05, 0.2, 0.2), b._glow_mat(LAMPS[voice], 0.0))
		m.position = Vector3(CAB.x + 1.31, y + 1.5, CAB.z - 1.1 + 0.4 * i)
		panel.add_child(m)


## Two grilles that slide shut across the front; DescentCar moves them with `gate` 0 (open) to 1 (shut).
static func _gate(b: Object, car: Node3D) -> void:
	for side in ["W", "E"]:
		var leaf := Node3D.new()
		leaf.name = "Gate" + side
		var sign := -1.0 if side == "W" else 1.0
		leaf.position = Vector3(CAB.x + sign * 0.55, CAB.y, CAB.z - 1.85)
		car.add_child(leaf)
		for k in 4:
			var bar := MeshInstance3D.new()
			bar.name = "Bar%d" % k
			bar.mesh = b._box_mesh(Vector3(0.1, 2.5, 0.08), b._mat("metal", Color(0.35, 0.35, 0.37)))
			bar.position = Vector3(-sign * (k - 1.5) * 0.3, 1.25, 0)
			leaf.add_child(bar)
		var top := MeshInstance3D.new()
		top.name = "Rail"
		top.mesh = b._box_mesh(Vector3(1.1, 0.12, 0.1), b._mat("hazard", Color.WHITE))
		top.position = Vector3(0, 1.4, 0)
		leaf.add_child(top)


## The strip behind the gate that slides up past it: Harbour concrete, then pipework, then bedrock, top to bottom.
## Unshaded and dimmed (the cab's lamp doesn't reach it); ribs and pipes give the eye something to follow.
static func _shaft(b: Object, car: Node3D) -> void:
	var strip := Node3D.new()
	strip.name = "Shaft"
	strip.position = Vector3(CAB.x, CAB.y - 18.0, CAB.z - 3.3)
	car.add_child(strip)
	var parts := [["Concrete", 18.0, "res://assets/textures/concrete_128.png", Color(0.85, 0.85, 0.88)],
		["Pipework", 9.0, "res://assets/textures/rust_128.png", Color(0.75, 0.55, 0.45)],
		["Bedrock", 0.0, "res://assets/textures/rock_128.png", Color(0.6, 0.52, 0.5)]]
	for p in parts:
		var seg := MeshInstance3D.new()
		seg.name = p[0]
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_texture = load(p[2])
		m.albedo_color = p[3]
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.uv1_scale = Vector3(2, 3, 1)
		seg.mesh = b._box_mesh(Vector3(6, 9, 0.2), m)
		seg.position = Vector3(0, p[1] + 4.5, 0)
		strip.add_child(seg)
	var dark: Material = b._mat("metal", Color(0.12, 0.12, 0.14))
	for i in 18:  # ribs every 1.5 m: concrete lifts and bedrock strata
		var rib := MeshInstance3D.new()
		rib.name = "Rib%d" % i
		rib.mesh = b._box_mesh(Vector3(6, 0.12, 0.1), dark)
		rib.position = Vector3(0, 0.8 + i * 1.5, 0.12)
		strip.add_child(rib)
	for i in 6:  # the pipework: pipes across the shaft, nine metres of them
		var pipe := MeshInstance3D.new()
		pipe.name = "Pipe%d" % i
		pipe.mesh = b._box_mesh(Vector3(6, 0.28, 0.28), b._mat("rust", Color(0.8, 0.55, 0.4)))
		pipe.position = Vector3(0, 9.7 + i * 1.45, 0.22)
		strip.add_child(pipe)


## The take. Times in seconds; every tween is a value track on the cab (DescentCar's properties) or the Operative.
static func _descent(cine: Node3D) -> void:
	var y := CAB.y
	var points: Array[Vector3] = [
		CAB + Vector3(0.1, 1.75, 1.75), CAB + Vector3(0.15, 1.72, 1.7), CAB + Vector3(0.0, 1.65, 1.5),
		CAB + Vector3(-0.1, 1.6, 1.2), CAB + Vector3(0.3, 1.7, 1.4)]
	var panel_at := CAB + Vector3(1.4, 1.5, -0.3)
	var shaft_at := CAB + Vector3(0, 1.4, -3.0)
	var looks: Array[Vector3] = [shaft_at, shaft_at, panel_at, panel_at, shaft_at]
	var times: Array[float] = [0.0, 2.4, 3.4, 6.0, 7.0]
	var p := AreaCine.rail(cine, KEY, points, looks, times, {fov = 70.0, min_s = 6.0, max_s = 10.0})
	p.get_animation("take").length = LENGTH
	var cam := "%sRig/Cam" % KEY
	var noise := PhantomCameraNoise3D.new()
	noise.amplitude = 0.0
	noise.frequency = SHAKE_HZ
	noise.rotational_noise = true
	(cine.get_node("%sRig/Cam" % KEY) as PhantomCamera3D).noise = noise
	AreaCine.track(p, cam + ":noise:amplitude", [0.0, 0.9, 2.6, 6.9, 7.3, LENGTH], [0.0, 0.2 * SHAKE, SHAKE, 0.25 * SHAKE, 0.2 * SHAKE, 0.0])
	AreaCine.track(p, cam + ":camera_3d_resource:fov", [0.0, 3.4, 6.0, 7.0], [70.0, 70.0, 62.0, 70.0])
	# the cab: the Operative stands in it until the cut, the corridor after; the camera rig follows him out
	AreaCine.track(p, "../Operative:position", [0.0, CUT], [stand(), exit_world()], true)
	AreaCine.track(p, "../Operative:cine_face", [0.0, CUT], [0.0, EXIT_FACE], true)
	AreaCine.track(p, "../Operative:cine_view", [0.0, CUT], [0.0, EXIT_FACE], true)
	AreaCine.cut_to(p, "Exit", exit_world() + Vector3(3.3, 2.1, 0.0), exit_world() + Vector3(-4.0, 1.3, 0.0), CUT)
	var car := "../DescentCab"
	AreaCine.track(p, car + ":dark", [0.0, 0.5, 6.9, 7.1, 7.3, 7.7, LENGTH], [1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
	AreaCine.track(p, car + ":gate", [0.0, 0.2, 0.9, LENGTH], [0.0, 0.0, 1.0, 1.0])
	AreaCine.track(p, car + ":motor", [0.0, 0.2, 1.5, 6.9, 7.4, LENGTH], [0.0, 0.6, 1.0, 1.0, 0.2, 0.0])
	AreaCine.track(p, car + ":lit", [0.0, 2.8, 5.55, LENGTH], [0.0, 0.0, 5.0, 5.0])
	AreaCine.track(p, car + ":settle", [0.0, 5.6, 6.2, LENGTH], [0.0, 0.0, 1.0, 1.0])
	AreaCine.track(p, car + "/Shaft:position:y", [0.0, 0.9, 7.0, LENGTH], [y - 18.0, y - 18.0, y - 2.5, y - 2.5])
