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
var _lens_mat := ShaderMaterial.new()
var _lens_layer := CanvasLayer.new()


func _ready() -> void:
	layer = -1  # under the root canvas: only the 3D is banded
	process_mode = Node.PROCESS_MODE_ALWAYS  # the lens must notice a pause to switch off
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

	# The lens sits above the HUD (layer 1), under the take's bars (3): it bends everything beneath it, so it is only up
	# in live play (_process); the menus, pause and the Codec stay flat.
	var lens_layer := _lens_layer
	lens_layer.layer = 2
	lens_layer.visible = false
	var lens := ColorRect.new()
	lens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lens_mat.shader = load("res://assets/shaders/hud_lens.gdshader")
	lens.material = _lens_mat
	lens_layer.add_child(lens)
	add_child(lens_layer)

	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	get_window().size_changed.connect(_update_scale)
	_update_scale()


## 3D scale that makes the internal height 480 (854 wide at 16:9) whatever the window size.
func _update_scale() -> void:
	get_viewport().scaling_3d_scale = clampf(float(INTERNAL_HEIGHT) / get_window().size.y, 0.05, 1.0)


func _process(_delta: float) -> void:
	_lens_layer.visible = lens_on(_hud_shown(), get_tree().paused)


## The lens bends the whole frame, so it is on only in live play: the HUD up and the game running. A menu, the
## pause screen, the Codec or a take (each pauses the game or hides the HUD) gets a flat screen.
static func lens_on(hud_shown: bool, paused: bool) -> bool:
	return hud_shown and not paused


## The HUD (group radio_log) is drawn: visible itself and on a visible layer.
func _hud_shown() -> bool:
	var hud := get_tree().get_first_node_in_group("radio_log") as CanvasItem
	if hud == null or not hud.is_visible_in_tree():
		return false
	var n: Node = hud.get_parent()
	while n:
		if n is CanvasLayer and not n.visible:
			return false
		n = n.get_parent()
	return true


## The lens' bend: 0 is flat, 0.03-0.08 is subtle.
func set_lens(strength: float) -> void:
	_lens_mat.set_shader_parameter(&"strength", strength)


## Switch one of EFFECTS (fringe, scanlines) on or off.
func set_effect(effect: StringName, on: bool) -> void:
	if EFFECTS.has(effect):
		_mat.set_shader_parameter(effect, EFFECTS[effect][1 if on else 0])
