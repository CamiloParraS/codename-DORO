## Autoload: the PSX look. 3D renders at 854x480 and is upscaled with nearest filtering at any window
## size, then a banding pass runs on layer -1, under every UI: the HUD, the menus, the Codec and the cards
## (all on layer 0 and up) render crisp at full resolution and never pick up the dither or the fringe. Also owns the default
## sky and far fog as the world's fallback environment: an Area's own WorldEnvironment (its mood) wins.
extends CanvasLayer

const INTERNAL_HEIGHT := 480
const SKY := Color(0.33, 0.37, 0.42)
const FOG_BEGIN := 20.0
const FOG_END := 60.0
## The optional passes of psx_post, off by name: set_effect(&"scanlines", true). The fringe is on.
const EFFECTS := {
	fringe = [0.0, 0.0015], scanlines = [0.0, 0.35],
}

var _mat := ShaderMaterial.new()


func _ready() -> void:
	layer = -1  # under the root canvas: only the 3D is banded
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.65)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = SKY
	env.fog_density = 1.0
	env.fog_depth_begin = FOG_BEGIN
	env.fog_depth_end = FOG_END
	get_viewport().find_world_3d().fallback_environment = env

	var post := ColorRect.new()
	post.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat.shader = load("res://assets/shaders/psx_post.gdshader")
	post.material = _mat
	add_child(post)

	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	get_window().size_changed.connect(_update_scale)
	_update_scale()


## 3D scale that makes the internal height 480 (854 wide at 16:9) whatever the window size.
func _update_scale() -> void:
	get_viewport().scaling_3d_scale = clampf(float(INTERNAL_HEIGHT) / get_window().size.y, 0.05, 1.0)


## Switch one of EFFECTS (fringe, scanlines) on or off.
func set_effect(effect: StringName, on: bool) -> void:
	if EFFECTS.has(effect):
		_mat.set_shader_parameter(effect, EFFECTS[effect][1 if on else 0])
