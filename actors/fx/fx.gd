## Cheap in-world feedback, PSX style: chunky unlit shapes, banded colours, no post effects. Static helpers;
## every effect frees itself.
class_name Fx
extends RefCounted

const FLASH_TIME := 0.06
const FLASH_ICON := preload("res://assets/ui/icons/flash.svg")
const BALLOON_ICON := preload("res://assets/ui/icons/fulton_balloon.svg")
const RING_ICON := preload("res://assets/ui/icons/ring.svg")
const DASH_ICON := preload("res://assets/ui/icons/dash.svg")


## An unlit, glowing material: reads in any light and through the fog.
static func glow(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m


## A pixel-art sprite for the world: nearest-filtered and unlit, `billboard` to face the camera. `size` is metres per art pixel.
static func pixel_sprite(tex: Texture2D, size: float, billboard := true) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = size
	if billboard:
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return s


## A burst of n small square pixels thrown out of pos, falling back: dust, sparks, a dart's puff.
static func puff(parent: Node, pos: Vector3, c: Color, n := 8, speed := 2.5, life := 0.45) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var px := QuadMesh.new()
	px.size = Vector2.ONE * 0.08
	var mat := glow(c)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	px.material = mat
	p.mesh = px
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


## A muzzle flash at pos: a pixel star and a short light, gone in FLASH_TIME. Dimmer when suppressed.
static func flash(parent: Node, pos: Vector3, quiet: bool) -> Node3D:
	var f := MeshInstance3D.new()
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.75, 0.35)
	l.light_energy = 0.8 if quiet else 2.5
	l.omni_range = 4.0
	f.add_child(l)
	var star := pixel_sprite(FLASH_ICON, 0.016 if quiet else 0.032)
	star.modulate = Color(1, 0.85, 0.4)
	f.add_child(star)
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
	var b := MeshInstance3D.new()  # the node that scales; the art is its second child
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
	var art := pixel_sprite(BALLOON_ICON, 0.125)  # 16 px across = the old 2 m sphere
	art.modulate = Color(1, 0.45, 0.15)
	art.position.y = -0.2
	b.add_child(art)
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


const RADIO_FILL := preload("res://actors/fx/radio_fill.gdshader")
const BEACON_PERIOD := 1.05


## A radio-mode fill (see radio_fill.gdshader): drawn over the world dim, through walls and fog.
static func radio_fill(c: Color, hatch := false, pulse := 0.0, priority := 10) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = RADIO_FILL
	m.render_priority = priority
	m.set_shader_parameter("colour", c)
	m.set_shader_parameter("hatch", hatch)
	m.set_shader_parameter("pulse", pulse)
	return m


## A Radio point's marker: a 40 m stippled beam and a ground ring pulsing outward, white at full alpha when
## hot, half when cold. Real-time tween (radio mode slows the game); it frees with `parent`.
static func beacon(parent: Node, at: Vector3, hot := true) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = at
	var a := 1.0 if hot else 0.5
	var dashes := Node3D.new()  # a column of pixel diamonds rising 2 m a period, 40 m high, fading with height
	root.add_child(dashes)
	for k in 20:
		var d := pixel_sprite(DASH_ICON, 0.07)
		d.no_depth_test = true
		d.render_priority = 12
		d.modulate = Color(1, 1, 1, 0.8 * a * (1.0 - k / 20.0))
		d.position.y = 1.0 + k * 2.0
		dashes.add_child(d)
	var rise := dashes.create_tween().set_loops().set_ignore_time_scale(true)
	rise.tween_property(dashes, "position:y", 2.0, BEACON_PERIOD)
	rise.tween_property(dashes, "position:y", 0.0, 0.0)
	var ring := pixel_sprite(RING_ICON, 1.7 / 15.5, false)  # a pixel ring stepping outward on the ground
	ring.hframes = 5
	ring.axis = Vector3.AXIS_Y
	ring.no_depth_test = true
	ring.render_priority = 12
	ring.modulate = Color(1, 1, 1, 0.92 * a)
	ring.position.y = 0.05
	ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # stepped per frame, even when paused
	root.add_child(ring)
	var step := ring.create_tween().set_loops().set_ignore_time_scale(true)
	step.tween_method(func(t: float) -> void: ring.frame = mini(int(t * 5.0), 4), 0.0, 1.0, BEACON_PERIOD)
	return root
