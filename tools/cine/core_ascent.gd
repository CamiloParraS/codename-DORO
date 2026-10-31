## The Core's Ascent, built into areas/core/core.tscn by CoreCine.build: the finale's Epilogue plays over the lift rising out
## of the shaft the Descent went down (the same DescentCab and its Shaft strip, sliding the other way). The camera
## pulls back from the Operative, rises behind the car as the floors pass, and climbs out into the Harbour's sky.
## One clip; what the floors show, the sky and the shake come from three sets (ascent_set.gd): Pallas calm, Nike half dead,
## Gorgo on fire. Data in metres, car-relative (CoreCine.CAB). The take is short; the finale holds its last frame while
## the Epilogue's lines finish.
class_name CoreAscent
extends RefCounted

const LENGTH := 9.0
const FLOORS := 9        # one every FLOOR_GAP up the strip
const FLOOR_GAP := 3.0
const SHAKE := 1.0       # degrees at the rise out of the shaft, at trauma 1
const SKYLINE := [[-34.0, 6.0, 7.0], [-20.0, 4.0, 11.0], [-6.0, 7.0, 6.0], [14.0, 5.0, 14.0], [30.0, 8.0, 9.0], [48.0, 5.0, 8.0]]  # x, width, height
## horizon, zenith, glow, fog depth end, per ending: calm blue dawn, grey with smoke, black and red.
const SKIES := {
	pallas = [Color(0.66, 0.8, 0.95), Color(0.2, 0.36, 0.7), Color(1.0, 0.85, 0.7), 260.0],
	nike = [Color(0.56, 0.56, 0.57), Color(0.28, 0.28, 0.3), Color(0.8, 0.6, 0.4), 160.0],
	gorgo = [Color(0.6, 0.12, 0.06), Color(0.02, 0.0, 0.0), Color(1.0, 0.25, 0.1), 110.0],
}


static func build(b: Object, car: Node3D, cine: Node3D) -> void:
	var strip: Node3D = car.get_node("Shaft")
	var set := Node3D.new()
	set.name = "Ascent"
	set.visible = false
	set.set_script(load("res://areas/core/ascent_set.gd"))
	strip.add_child(set)
	set.set("skies", _skies(b))
	_pallas(b, _group(set, "AscentPallas"))
	_nike(b, _group(set, "AscentNike"))
	_gorgo(b, _group(set, "AscentGorgo"))
	_skyline(cine)
	_take(cine)


static func _group(parent: Node, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.visible = false
	parent.add_child(n)
	return n


## The Area's Mood sky, recoloured per ending (a copy: the Area's own never changes).
static func _skies(b: Object) -> Dictionary:
	var mood: Environment = b._root.get_node("Mood").environment
	var out := {}
	for v in SKIES:
		var s: Array = SKIES[v]
		var e: Environment = mood.duplicate()
		e.sky = mood.sky.duplicate()
		var m: ShaderMaterial = mood.sky.sky_material.duplicate()
		m.set_shader_parameter("horizon", s[0])
		m.set_shader_parameter("zenith", s[1])
		m.set_shader_parameter("glow", 1.0)
		e.sky.sky_material = m
		e.fog_light_color = s[0]
		e.fog_depth_end = s[3]
		e.volumetric_fog_enabled = false
		e.ambient_light_color = s[0].lerp(s[1], 0.4)
		e.ambient_light_energy = 0.9
		out[v] = e
	return out


static func _led(b: Object, parent: Node, name: String, y: float, colour: Color, energy: float) -> void:
	var m := MeshInstance3D.new()
	m.name = name
	m.mesh = b._box_mesh(Vector3(0.16, 0.16, 0.08), b._glow_mat(colour, energy))
	m.position = Vector3(2.4, y, 0.2)
	parent.add_child(m)


static func _floor_y(i: int) -> float:
	return 1.5 + FLOOR_GAP * i


## Quiet: clean, dark, silent floors, one steady green status LED on each.
static func _pallas(b: Object, set: Node3D) -> void:
	for i in FLOORS:
		_led(b, set, "Led%d" % i, _floor_y(i), Color(0.3, 1.0, 0.45), 3.0)


## Mixed: every other floor dead, and a few lamps swinging on their wires.
static func _nike(b: Object, set: Node3D) -> void:
	for i in FLOORS:
		_led(b, set, "Led%d" % i, _floor_y(i), Color(0.3, 1.0, 0.45) if i % 2 == 0 else Color(0.25, 0.1, 0.1), 3.0 if i % 2 == 0 else 0.0)
	for i in [1, 4, 6]:
		var sway := Node3D.new()
		sway.name = "Sway%d" % i
		sway.position = Vector3(-1.4, _floor_y(i) + 1.2, 0.9)
		set.add_child(sway)
		var wire := MeshInstance3D.new()
		wire.mesh = b._box_mesh(Vector3(0.03, 0.7, 0.03), b._mat("metal", Color(0.2, 0.2, 0.22)))
		wire.position.y = -0.35
		sway.add_child(wire)
		var bulb := MeshInstance3D.new()
		bulb.mesh = b._box_mesh(Vector3(0.2, 0.2, 0.2), b._glow_mat(Color(1.0, 0.75, 0.3), 3.0))
		bulb.position.y = -0.75
		sway.add_child(bulb)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.3)
		l.omni_range = 4.0
		l.light_energy = 1.2
		l.position.y = -0.75
		sway.add_child(l)


## Loud: fire in the floors, smoke filling the shaft, debris falling, orange light.
static func _gorgo(b: Object, set: Node3D) -> void:
	for i in [1, 3, 5, 7]:
		_led(b, set, "Led%d" % i, _floor_y(i), Color(1.0, 0.2, 0.1), 3.0)
		var l := OmniLight3D.new()
		l.name = "Fire%d" % i
		l.light_color = Color(1.0, 0.5, 0.15)
		l.omni_range = 7.0
		l.light_energy = 2.0
		l.position = Vector3(0.5, _floor_y(i), 1.6)
		set.add_child(l)
		set.add_child(_particles(b, "Flames%d" % i, Vector3(0.5, _floor_y(i) - 0.6, 0.6), Vector3(1.6, 0.2, 0.3), Vector3(0, 2.5, 0.4),
			b._glow_mat(Color(1.0, 0.55, 0.15), 3.0), Vector3(0.35, 0.35, 0.35), 18, 0.9))
	set.add_child(_particles(b, "Smoke", Vector3(0, 2.0, 1.0), Vector3(2.8, 0.5, 0.8), Vector3(0, 2.2, 0.6),
		_flat(Color(0.08, 0.07, 0.07)), Vector3(1.4, 1.4, 1.4), 26, 3.5))
	set.add_child(_particles(b, "Debris", Vector3(0, 15.0, 1.5), Vector3(2.6, 0.2, 0.8), Vector3(0, -9.0, 0),
		_flat(Color(0.2, 0.18, 0.17)), Vector3(0.16, 0.1, 0.12), 14, 2.2))


static func _particles(b: Object, name: String, at: Vector3, extents: Vector3, velocity: Vector3, mat: Material, size: Vector3, amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = name
	p.position = at
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = velocity.normalized()
	p.spread = 12.0
	p.initial_velocity_min = velocity.length() * 0.7
	p.initial_velocity_max = velocity.length()
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.mesh = b._box_mesh(size, mat)
	return p


static func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m


## Silhouettes of the Harbour at the horizon beyond the shaft's mouth, so the rise ends on somewhere. In the world, not on
## the strip that slides; ascent_set.gd shows them with the set.
static func _skyline(cine: Node3D) -> void:
	var sky := Node3D.new()
	sky.name = "AscentSkyline"
	sky.visible = false
	cine.add_child(sky)
	var dark := _flat(Color(0.05, 0.05, 0.07))
	for i in SKYLINE.size():
		var s: Array = SKYLINE[i]
		var m := MeshInstance3D.new()
		m.name = "Block%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(s[1], s[2] + 30.0, 4.0)
		mesh.material = dark
		m.mesh = mesh
		m.position = CoreCine.CAB + Vector3(s[0], 2.0 + s[2] * 0.5 - (s[2] + 30.0) / 2.0, -60.0 - 6.0 * (i % 3))
		sky.add_child(m)


## The take: Phantom Camera rail up and back from the Operative; the strip slides down so the car rises.
static func _take(cine: Node3D) -> void:
	var c := CoreCine.CAB
	var points: Array[Vector3] = [c + Vector3(0.25, 1.75, 1.0), c + Vector3(0, 2.4, 2.8), c + Vector3(0, 4.0, 4.2),
		c + Vector3(0, 9.0, 5.0), c + Vector3(0, 13.0, 5.5)]
	var looks: Array[Vector3] = [c + Vector3(0, 1.6, 0.2), c + Vector3(0, 1.5, -1.5), c + Vector3(0, 5.0, -3.3),
		c + Vector3(0, 13.0, -3.3), c + Vector3(0, 18.0, -40.0)]
	var times: Array[float] = [0.0, 2.2, 5.0, 7.2, LENGTH]
	var p := AreaCine.rail(cine, AscentLogic.KEY, points, looks, times, {fov = 62.0, min_s = 6.0, max_s = 10.0})
	var cam := "%sRig/Cam" % AscentLogic.KEY
	var noise := PhantomCameraNoise3D.new()
	noise.amplitude = 0.0
	noise.frequency = CoreCine.SHAKE_HZ
	noise.rotational_noise = true
	(cine.get_node(cam) as PhantomCamera3D).noise = noise
	AreaCine.track(p, cam + ":noise:amplitude", [0.0, 2.0, 6.0, LENGTH], [0.3 * SHAKE, SHAKE, SHAKE, 0.4 * SHAKE])
	AreaCine.track(p, cam + ":camera_3d_resource:fov", [0.0, 2.2, 6.0, LENGTH], [62.0, 70.0, 66.0, 55.0])
	AreaCine.track(p, "../Operative:position", [0.0], [CoreCine.stand()], true)
	AreaCine.track(p, "../Operative:cine_face", [0.0], [0.0], true)
	AreaCine.track(p, "../Operative:cine_view", [0.0], [0.0], true)
	var car := "../DescentCab"
	AreaCine.track(p, car + ":dark", [0.0], [0.0], true)
	AreaCine.track(p, car + ":gate", [0.0], [0.0], true)
	AreaCine.track(p, car + ":motor", [0.0, 0.6, 7.5, LENGTH], [0.0, 1.0, 1.0, 0.0])
	AreaCine.track(p, car + "/Shaft:position:y", [0.0, 0.5, 8.0, LENGTH], [c.y - 2.5, c.y - 2.5, c.y - 18.0, c.y - 18.0])
