## Autoload: the PSX look. 3D renders at 854x480 and is upscaled with nearest filtering at any window
## size, then a banding pass runs on layer 0 so the HUD (layer 1+) stays crisp. Also owns the default
## sky and far fog; an Area that wants its own WorldEnvironment can add one.
extends CanvasLayer

const INTERNAL_HEIGHT := 480
const SKY := Color(0.33, 0.37, 0.42)
const FOG_BEGIN := 20.0
const FOG_END := 60.0


func _ready() -> void:
	layer = 0
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
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var post := ColorRect.new()
	post.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.material = ShaderMaterial.new()
	(post.material as ShaderMaterial).shader = load("res://assets/shaders/psx_post.gdshader")
	add_child(post)

	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	get_window().size_changed.connect(_update_scale)
	_update_scale()


## 3D scale that makes the internal height 480 (854 wide at 16:9) whatever the window size.
func _update_scale() -> void:
	get_viewport().scaling_3d_scale = clampf(float(INTERNAL_HEIGHT) / get_window().size.y, 0.05, 1.0)
