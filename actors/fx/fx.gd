## Cheap in-world feedback, PSX style: chunky unlit shapes, banded colours, no post effects. Static helpers;
## every effect frees itself.
class_name Fx
extends RefCounted

const FLASH_TIME := 0.06


## An unlit, glowing material: reads in any light and through the fog.
static func glow(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m


## A burst of n small cubes thrown out of pos, falling back: dust, sparks, a dart's puff.
static func puff(parent: Node, pos: Vector3, c: Color, n := 8, speed := 2.5, life := 0.45) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.07
	cube.material = glow(c)
	p.mesh = cube
	p.amount = n
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = life
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## A muzzle flash at pos: a bright blob and a short light, gone in FLASH_TIME. Dimmer when suppressed.
static func flash(parent: Node, pos: Vector3, quiet: bool) -> Node3D:
	var f := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.07 if quiet else 0.14
	s.height = s.radius * 2
	s.radial_segments = 6
	s.rings = 3
	s.material = glow(Color(1, 0.85, 0.4))
	f.mesh = s
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.75, 0.35)
	l.light_energy = 0.8 if quiet else 2.5
	l.omni_range = 4.0
	f.add_child(l)
	parent.add_child(f)
	f.global_position = pos
	f.get_tree().create_timer(FLASH_TIME).timeout.connect(f.queue_free)
	return f


## A tracer: a thin glowing streak from `from` to `to`, gone in FLASH_TIME.
static func tracer(parent: Node, from: Vector3, to: Vector3) -> MeshInstance3D:
	var t := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.02, 0.02, from.distance_to(to))
	b.material = glow(Color(1, 0.9, 0.55))
	t.mesh = b
	parent.add_child(t)
	t.global_position = (from + to) / 2.0
	if from.distance_squared_to(to) > 0.0001:
		t.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	t.get_tree().create_timer(FLASH_TIME).timeout.connect(t.queue_free)
	return t


## The Fulton balloon: bright and unlit so it reads from 20 m, tied by a cable to the guard 3 m below it.
## It inflates from nothing over INFLATE s.
const INFLATE := 0.6
static func balloon() -> MeshInstance3D:
	var b := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 8
	s.rings = 4
	s.material = glow(Color(1, 0.45, 0.15))
	b.mesh = s
	var cable := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.02
	c.bottom_radius = 0.02
	c.height = 3.0
	c.radial_segments = 4
	c.material = glow(Color(0.15, 0.15, 0.15))
	cable.mesh = c
	cable.position.y = -1.5
	b.add_child(cable)
	b.scale = Vector3.ONE * 0.05
	return b


## A small glowing marker: the Radio call's red glint, Caution's amber vest light.
static func lamp(c: Color, size: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	box.material = glow(c)
	m.mesh = box
	return m
