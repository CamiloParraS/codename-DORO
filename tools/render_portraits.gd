## Renders the Codec portraits once: each cast member's character model, head and shoulders, through the PSX
## banding, two frames each (0 neutral, 1 head tilted, for the talk flap) to ui/codec/portraits/<id>_<frame>.png.
## Needs a window (not --headless):
##   godot --path . --script tools/render_portraits.gd
## Without the gitignored Mixamo bakes the models hold their rest pose.
extends SceneTree

const SIZE := 60  # px; the Codec draws it at 2x with nearest filtering
const OUT := "res://ui/codec/portraits"
## id: [kind, skin for a Nikita body (null keeps the kind's own), tint for the Target body].
const CAST := {
	operative = [CharacterModel.Kind.OPERATIVE, null, Color.WHITE],
	handler = [CharacterModel.Kind.GUARD, preload("res://assets/models/characters/guard/guard_21.png"), Color.WHITE],
	analyst = [CharacterModel.Kind.GUARD, preload("res://assets/models/characters/guard/guard_doctor.png"), Color.WHITE],
	chief = [CharacterModel.Kind.TARGET, null, Color(0.85, 0.8, 0.7)],
	researcher = [CharacterModel.Kind.TARGET, null, Color(1.15, 1.15, 1.2)],
	director = [CharacterModel.Kind.TARGET, null, Color(0.55, 0.55, 0.65)],
}
const TILT := 0.22  # rad the head rolls in frame 1


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for id in CAST:
		var vp := SubViewport.new()
		vp.size = Vector2i(SIZE, SIZE)
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vp)
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.1, 0.14, 0.12)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.75, 0.77, 0.8)
		env.ambient_light_energy = 1.1  # bright enough to read the face at 2x in the Codec
		var we := WorldEnvironment.new()
		we.environment = env
		vp.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.light_energy = 1.4  # the key light
		vp.add_child(sun)
		sun.look_at_from_position(Vector3(1, 2, -2), Vector3.ZERO)
		var holder := Node3D.new()
		holder.name = id.capitalize()
		vp.add_child(holder)
		var model: CharacterModel = load("res://actors/character/character_model.tscn").instantiate()
		model.kind = CAST[id][0]
		holder.add_child(model)
		await process_frame
		await process_frame
		_dress(model, CAST[id])
		model.process_mode = Node.PROCESS_MODE_DISABLED  # hold the pose so the tilt sticks
		var sk := model.skeleton
		var head := _head(sk)
		var at := sk.global_transform * sk.get_bone_global_pose(head).origin
		if model.kind != CharacterModel.Kind.TARGET:
			at.y += 0.1  # Nikita's head bone sits at the neck
		var cam := Camera3D.new()
		cam.fov = 30
		vp.add_child(cam)
		cam.look_at_from_position(at + Vector3(0.12, 0.0, -0.85), at + Vector3(0, -0.08, 0))  # the model faces -Z
		cam.make_current()
		var rest := sk.get_bone_pose_rotation(head)
		for frame in 2:
			sk.set_bone_pose_rotation(head, rest * Quaternion(Vector3.FORWARD, TILT * frame))
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			_band(img)
			var path := "%s/%s_%d.png" % [OUT, id, frame]
			img.save_png(path)
			print("saved ", path)
		vp.queue_free()
	quit()


## Strips gear and swaps the skin (handler, analyst) or tints the Target's suit.
static func _dress(model: CharacterModel, cast: Array) -> void:
	if cast[0] == CharacterModel.Kind.TARGET:
		for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for s in m.mesh.get_surface_count():
				var mat := m.get_active_material(s).duplicate() as BaseMaterial3D
				if mat:
					mat.albedo_color = cast[2]
					m.set_surface_override_material(s, mat)
		return
	for part in ["Helmet", "Vest", "Chest_rig", "Backpack", "Goggles", "Holster", "Knee_pads", "Shemag"]:
		model._part(part).visible = cast[0] == CharacterModel.Kind.OPERATIVE and part in CharacterModel.DRESS[cast[0]]
	if cast[1]:
		(model._part("Nikita").material_override as StandardMaterial3D).albedo_texture = cast[1]


## The head bone: the first whose name ends in "head" (Quaternius "head", Mixamo "mixamorig:Head").
static func _head(sk: Skeleton3D) -> int:
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).to_lower().ends_with("head"):
			return i
	return 0


## The PSX pass's 15-bit banding (assets/shaders/psx_post.gdshader), baked into the pixels.
static func _band(img: Image) -> void:
	img.convert(Image.FORMAT_RGB8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(roundf(c.r * 31) / 31, roundf(c.g * 31) / 31, roundf(c.b * 31) / 31))
