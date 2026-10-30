## The UI's motion kit: hard cuts and stepped wipes, never eased drift. Every tween ignores time scale (the radio
## slows the world while it is open) and runs through pauses.
class_name UiMotion
extends RefCounted

const WIPE_SHADER := preload("res://ui/ui_wipe.gdshader")
const CUT_STEP := 0.04     # a cut is six steps: 0.24 s
const CUT_PATTERN := [0.0, 1.0, 0.0, 1.0, 0.4, 1.0]
const STAGGER := 0.035


## The progress values a wipe of `steps` steps visits, in order: 1/steps ... 1.
static func levels(steps: int) -> Array[float]:
	var n := maxi(steps, 1)
	var out: Array[float] = []
	for i in n:
		out.append(float(i + 1) / n)
	return out


## The modulate alphas a cut visits, in order.
static func flicker() -> Array:
	return CUT_PATTERN


## True under the reduced-motion setting: wipes and cuts land at once, the scan band and drift stay off.
static func reduced() -> bool:
	return GameSettings.current.get("reduce_motion", false)


static func _tween(c: Node) -> Tween:
	return c.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)


## Reveals `control` (and its children) from one edge in `steps` hard steps over `secs`. A new wipe or cut on the
## same control replaces one still running. `on_step` (optional) gets each progress level.
static func wipe(control: Control, from_left := true, steps := 8, secs := 0.3, on_step := Callable()) -> Tween:
	_kill(control)
	if reduced():
		steps = 1
		secs = 0.0
	var mat := ShaderMaterial.new()
	mat.shader = WIPE_SHADER
	mat.set_shader_parameter("from_left", from_left)
	mat.set_shader_parameter("progress", 0.0)
	var r: Rect2 = control.get_global_transform() * Rect2(Vector2.ZERO, control.size)  # canvas space, scale included
	mat.set_shader_parameter("span", Vector2(r.position.x, maxf(r.size.x, 1.0)))
	var kids := _share_material(control)
	control.material = mat
	control.visible = true
	var t := _tween(control)
	control.set_meta(&"motion", t)
	for p in levels(steps):
		t.tween_interval(secs / maxi(steps, 1))
		t.tween_callback(_set_progress.bind(mat, p, on_step))
	t.tween_callback(_unwipe.bind(control, kids))
	return t


static func _set_progress(mat: ShaderMaterial, p: float, on_step: Callable) -> void:
	mat.set_shader_parameter("progress", p)
	if on_step.is_valid():
		on_step.call(p)


## Children draw with the parent's material so one wipe clips the whole subtree.
static func _share_material(control: Control) -> Array[CanvasItem]:
	var kids: Array[CanvasItem] = []
	for n in control.find_children("*", "CanvasItem", true, false):
		var ci := n as CanvasItem
		if ci.material == null and not ci.use_parent_material:
			ci.use_parent_material = true
			kids.append(ci)
	return kids


static func _unwipe(control: Control, kids: Array[CanvasItem]) -> void:
	if not is_instance_valid(control):
		return
	control.material = null
	for k in kids:
		if is_instance_valid(k):
			k.use_parent_material = false


static func _kill(control: CanvasItem) -> void:
	if control.has_meta(&"motion"):
		var old: Tween = control.get_meta(&"motion")
		if old and old.is_valid():
			old.kill()
		control.remove_meta(&"motion")


## A 0.24 s flicker in: `control` snaps through bright and dark frames and settles fully lit. `delay` holds it
## dark first (stagger uses this).
static func cut(control: CanvasItem, delay := 0.0) -> Tween:
	_kill(control)
	control.modulate.a = 0.0
	var t := _tween(control)
	control.set_meta(&"motion", t)
	if delay > 0.0:
		t.tween_interval(delay)
	for a in ([1.0] if reduced() else CUT_PATTERN):
		t.tween_callback(_set_alpha.bind(control, a))
		t.tween_interval(0.0 if reduced() else CUT_STEP)
	t.tween_callback(_set_alpha.bind(control, 1.0))
	return t


static func _set_alpha(c: CanvasItem, a: float) -> void:
	if is_instance_valid(c):
		c.modulate.a = a


## Cuts each of `controls` in, one `step` after the last.
static func stagger(controls: Array, step := STAGGER) -> void:
	for i in controls.size():
		cut(controls[i], i * step)
