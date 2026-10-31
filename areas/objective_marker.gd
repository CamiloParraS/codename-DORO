## What marks an objective in the world, in the HUD's sand (the Operative's own information, docs/DESIGN.md):
## a ring on the ground where a step is done, a light column over a place to walk into (the Extraction point's
## stands 30 m), and an intel item turning over its ring with a glint and a small lamp. The objective's own
## script builds them at runtime (intel_pickup.gd, relay_console.gd, extraction_point.gd), so they follow its
## visibility: MissionRun shows only the current step's.
class_name ObjectiveMarker
extends RefCounted

const COLOUR := HudPalette.SAND
const DOSSIER: PackedScene = preload("res://assets/models/props/intel_dossier.glb")
const RING: Shader = preload("res://assets/shaders/objective_ring.gdshader")
const BEAM: Shader = preload("res://assets/shaders/objective_beam.gdshader")
const GLINT: Shader = preload("res://assets/shaders/item_glint.gdshader")
const ITEM_LIFT := 0.12  # m the item floats over its pickup's origin (0.6 m up): clear of a 0.55 m plinth
const ITEM_TILT := 18.0  # degrees, so its face shows to a low camera
const ITEM_SCALE := 1.35  # over life size: a pickup has to read from across a room, as in the PSX games
const TURN_S := 4.0  # one full turn
const BOB_M := 0.03
const LAMP_RANGE := 1.2
const LAMP_ENERGY := 0.3


## A ring `radius` m across lying flat at the node's origin.
static func ring(radius: float) -> MeshInstance3D:
	var p := PlaneMesh.new()
	p.size = Vector2.ONE * radius * 2.0
	p.material = _mat(RING)
	return _instance("Ring", p)


## A light column `radius` m wide standing `height` m up from the node's origin, gone by `fade_m`.
static func beam(radius: float, height: float, fade_m: float) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.cap_top = false
	c.cap_bottom = false
	c.radial_segments = 16
	c.rings = 1
	var mat := _mat(BEAM)
	mat.set_shader_parameter("height", height)
	mat.set_shader_parameter("fade_m", fade_m)
	c.material = mat
	var m := _instance("Beam", c)
	m.position.y = height / 2.0
	return m


## The intel dossier, tilted and lit, turning and bobbing once it is in the tree. Its origin is the pickup's.
static func item() -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Item"
	pivot.position.y = ITEM_LIFT
	var tilt := Node3D.new()
	tilt.rotation_degrees.x = ITEM_TILT
	tilt.scale = Vector3.ONE * ITEM_SCALE
	pivot.add_child(tilt)
	var model: Node3D = DOSSIER.instantiate()
	tilt.add_child(model)
	var mesh: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]  # the glb holds one
	mesh.material_overlay = _mat(GLINT)
	model.position = -(mesh.transform * mesh.get_aabb()).get_center()  # turns about the folder's middle, not its spine
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.light_color = COLOUR
	lamp.omni_range = LAMP_RANGE
	lamp.light_energy = LAMP_ENERGY
	lamp.shadow_enabled = false
	pivot.add_child(lamp)
	pivot.tree_entered.connect(_animate.bind(pivot), CONNECT_ONE_SHOT)
	return pivot


## Drops `mark` (a child of an objective) onto the first solid surface within `reach` m under the objective's
## origin raised `from_y` m (negative starts under a desk top), after the physics frame that puts the Area's
## colliders in the space. It stays where it was put when nothing is hit.
static func ground(mark: Node3D, reach: float, from_y := 0.0) -> void:
	var host := mark.get_parent() as Node3D
	await host.get_tree().physics_frame
	if not is_instance_valid(mark):
		return
	var from := host.global_position + Vector3.UP * from_y
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * reach, Ragdoll.WORLD)
	var hit := host.get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		mark.global_position = hit.position + Vector3.UP * 0.02


static func _animate(pivot: Node3D) -> void:
	var spin := pivot.create_tween().set_loops()
	spin.tween_property(pivot, "rotation:y", TAU, TURN_S).from(0.0)
	var bob := pivot.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(pivot, "position:y", ITEM_LIFT + BOB_M, TURN_S / 4.0)
	bob.tween_property(pivot, "position:y", ITEM_LIFT - BOB_M, TURN_S / 4.0)


static func _mat(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("colour", COLOUR)
	return m


static func _instance(n: String, mesh: Mesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = n
	m.mesh = mesh
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m
