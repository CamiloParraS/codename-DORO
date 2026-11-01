## The cut between screens: black dither cells sweep over the current screen, the scene changes underneath, and
## the cells sweep away from the new one (ui_dither_wipe.gdshader). The overlay lives on the root so it survives
## the change. Instant under reduced motion. Use `UiTransition.go(get_tree(), path)` for a UI-to-UI or Mission change.
class_name UiTransition
extends RefCounted

const SHADER := preload("res://ui/ui_dither_wipe.gdshader")
const IN_SECS := 0.2
const OUT_SECS := 0.26

static var _busy := false


static func go(tree: SceneTree, path: String) -> void:
	if _busy:
		return
	if UiMotion.reduced() or tree.root == null:
		tree.change_scene_to_file(path)
		return
	_busy = true
	var layer := CanvasLayer.new()
	layer.layer = 127
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var quad := ColorRect.new()
	quad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quad.mouse_filter = Control.MOUSE_FILTER_STOP  # nothing is clickable while the cut runs
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("progress", 0.0)
	quad.material = mat
	layer.add_child(quad)
	tree.root.add_child(layer)
	var t := layer.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	t.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 0.0, 1.0, IN_SECS)
	t.tween_callback(func() -> void:
		tree.paused = false
		tree.change_scene_to_file(path))
	t.tween_interval(0.05)
	t.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 1.0, 2.0, OUT_SECS)
	t.tween_callback(func() -> void:
		_busy = false
		layer.queue_free())
