## The loading screen between a Briefing (or a menu) and the Area (playtest 1: the Codec's picture hung, then black,
## then a freeze, then the take). It lives on the root, so it outlasts the scene change: it loads the Area on a
## thread with a progress bar, swaps it in, and stays over it until frames come steadily (the first frames compile
## the Area's shaders) before it fades. The intro take waits for it: MissionRun awaits `lifted`.
## `Loading.go(tree, path, setup)`; setup(area) configures the instanced Area before it enters the tree.
class_name Loading
extends CanvasLayer

signal lifted

const FADE := 0.3           # s the cover takes to go
const MIN_FRAMES := 6       # frames it stays over a new Area whatever their pace
const STEADY := 1.0 / 30.0  # s: a frame this quick counts toward settling
const STEADY_RUN := 4       # quick frames in a row that say the shaders are in
const MAX_SETTLE := 4.0     # s it waits for that at most
const DESIGN_H := 1080.0

var path := ""
var setup := Callable()
var title := ""             # MISSION 1
var area_name := ""         # HARBOUR
var _progress := 0.0
var _shown := 0.0           # the bar's eased fill
var _swapped := false
var _frames := 0
var _run := 0
var _waited := 0.0
var _fading := -1.0
var _canvas := Control.new()


## Covers the screen and loads `path`; the Area replaces the current scene once loaded. One at a time.
static func go(tree: SceneTree, area_path: String, configure: Callable, mission_title := "", area_title := "") -> void:
	if tree.root.get_node_or_null("Loading"):
		return
	var l := Loading.new()
	l.name = "Loading"
	l.path = area_path
	l.setup = configure
	l.title = mission_title
	l.area_name = area_title
	tree.root.add_child.call_deferred(l)  # the caller may be inside a _ready, with the root busy


## True once a new Area has had enough frames, quick ones in a row, or the wait has run out.
static func settled(frames: int, quick_run: int, waited: float) -> bool:
	return frames >= MIN_FRAMES and (quick_run >= STEADY_RUN or waited >= MAX_SETTLE)


func _ready() -> void:
	layer = 120  # over the Area's HUD and take bars, under UiTransition's cut (127)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("loading_cover")
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_cover)
	add_child(_canvas)
	if ResourceLoader.load_threaded_request(path) != OK:
		push_error("Loading: can't request %s" % path)


func _process(delta: float) -> void:
	_canvas.queue_redraw()
	if _fading >= 0.0:
		_fading += delta
		_canvas.modulate.a = 1.0 - clampf(_fading / FADE, 0.0, 1.0)
		if _fading >= FADE:
			queue_free()
		return
	if not _swapped:
		var p := []
		var status := ResourceLoader.load_threaded_get_status(path, p)
		_progress = float(p[0]) if not p.is_empty() else _progress
		_shown = lerpf(_shown, _progress * 0.9, minf(1.0, delta * 10.0))  # the last tenth is the settle
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_swap(ResourceLoader.load_threaded_get(path))
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Loading: %s failed" % path)
			queue_free()
		return
	_frames += 1
	_waited += delta
	_run = _run + 1 if delta <= STEADY else 0
	_shown = lerpf(_shown, 1.0, minf(1.0, delta * 6.0))
	if settled(_frames, _run, _waited):
		_fading = 0.0
		lifted.emit()


func _swap(scene: PackedScene) -> void:
	var area := scene.instantiate()
	if setup.is_valid():
		setup.call(area)
	_swapped = true
	get_tree().paused = false
	get_tree().change_scene_to_node(area)


## Black ground, the Mission and its Area bottom-left, a thin sand bar under them; design px, 1080 tall.
func _draw_cover() -> void:
	var c := _canvas
	var k := c.size.y / DESIGN_H
	c.draw_rect(Rect2(Vector2.ZERO, c.size), HudPalette.GROUND)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var d := c.size / k
	var x := 96.0
	var y := d.y - 150.0
	if title != "":
		HudPalette.hud_label(c, Vector2(x, y), title, 22, HudPalette.SAND, 0.3, HudPalette.LABEL, 0, false)
	if area_name != "":
		HudPalette.hud_label(c, Vector2(x, y + 46), area_name, 40, HudPalette.LIGHT, 0.2, HudPalette.LABEL, 0, false)
	var bar := Rect2(x, y + 72, 420, 4)
	c.draw_rect(bar, Color(HudPalette.LIGHT, 0.16))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_shown, 0.0, 1.0), bar.size.y)), HudPalette.SAND)
	var word := TranslationServer.translate("ui.loading").to_upper()
	var dots := ".".repeat(int(Time.get_ticks_msec() / 400.0) % 4)
	HudPalette.hud_label(c, Vector2(x, y + 104), word + dots, 16, HudPalette.LIGHT_3, 0.24, HudPalette.LABEL, 0, false)
