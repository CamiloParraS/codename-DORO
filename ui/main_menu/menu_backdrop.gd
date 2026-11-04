## The title and main menu's backdrop: screenshots of the Areas, one after another, each arriving over the last as
## a smooth crossfade while it pushes in and pans slowly (a Ken Burns). Each is graded towards one
## duotone (teal-black shadows, pale highlights) so the six read as one camera, and a MenuFeed over them captions the
## Area and locks onto the people in it. Drawn under the UiScan. Under reduced motion it holds the first picture, still.
class_name MenuBackdrop
extends Control

## Each picture: its texture, the Area's name key, the feed's time of day, and the people in it as (x, y, height)
## in fractions of the picture, centred on them. The Annex and the Yard show nobody; the feed
## watches them empty.
const SLIDES: Array[Dictionary] = [
	{tex = preload("res://ui/main_menu/backdrop.png"), area = "intro.m1.area", time = "19:42",
		marks = [Vector3(0.603, 0.6, 0.075), Vector3(0.653, 0.6, 0.075)]},
	{tex = preload("res://ui/main_menu/backdrop_annex.png"), area = "intro.m3.area", time = "22:41", marks = []},
	{tex = preload("res://ui/main_menu/backdrop_mast.png"), area = "intro.m2.area", time = "02:13",
		marks = [Vector3(0.664, 0.83, 0.08), Vector3(0.88, 0.866, 0.08)]},
	{tex = preload("res://ui/main_menu/backdrop_core.png"), area = "ui.mission_short.3", time = "03:07",
		marks = [Vector3(0.406, 0.632, 0.22)]},
	{tex = preload("res://ui/main_menu/backdrop_bow.png"), area = "intro.m1.area", time = "20:18",
		marks = [Vector3(0.572, 0.478, 0.055)]},
	{tex = preload("res://ui/main_menu/backdrop_yard.png"), area = "intro.m2.area", time = "01:56", marks = []},
]
const MARK_ASPECT := 0.75  # a person's bracket is this wide for its height
const HOLD := 9.0    # s each picture is the front one
const SHADER := preload("res://ui/main_menu/menu_dissolve.gdshader")
const FADE := 1.2    # s the next one takes to fade in
const ZOOM := Vector2(1.08, 1.15)  # scale at the start and end of a picture's life: a slow push reads smooth
const PAN := 0.025   # of the stage size, either side of centre (the start zoom leaves 0.04 spare)
const DIRS: Array[Vector2] = [Vector2(1, 0.3), Vector2(-1, -0.3), Vector2(0.6, -1), Vector2(-0.6, 1)]

var _rects: Array[TextureRect] = []
var feed := MenuFeed.new()  # the owner may add it higher up (over its shade); otherwise it goes on top of the pictures
var _t := 0.0
var _shown := -1  # the slide index on top


## Scale and offset (in stage fractions) of slide `index` `age` seconds after it became the front one.
static func pose(index: int, age: float) -> Dictionary:
	var u := clampf(age / (HOLD + FADE), 0.0, 1.0)
	return {scale = lerpf(ZOOM.x, ZOOM.y, u), shift = DIRS[index % DIRS.size()].normalized() * PAN * (u * 2.0 - 1.0)}


## Where mark `m` (x, y, height in picture fractions) of picture `index` lands `age` s in, in px of a `view`-sized
## backdrop showing a `tex`-sized picture covered (cropped to fill) and posed.
static func place(m: Vector3, index: int, age: float, view: Vector2, tex: Vector2) -> Rect2:
	var fit := maxf(view.x / tex.x, view.y / tex.y)
	var drawn := tex * fit
	var local := (view - drawn) / 2.0 + Vector2(m.x, m.y) * drawn
	var p := pose(index, age)
	var at: Vector2 = p.shift * view + view / 2.0 + (local - view / 2.0) * p.scale
	var h: float = m.z * drawn.y * p.scale
	return Rect2(at - Vector2(h * MARK_ASPECT, h) / 2.0, Vector2(h * MARK_ASPECT, h))


## The slide on top `t` seconds in.
static func front(t: float) -> int:
	return int(t / HOLD)


## How much of the front slide shows `age` seconds in, eased: the first is simply there, the rest fade in over the
## last.
static func opacity(index: int, age: float) -> float:
	return 1.0 if index == 0 else smoothstep(0.0, 1.0, age / FADE)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	modulate = Color(0.9, 0.9, 0.92)  # the grade already holds the highlights down
	for i in 2:
		var r := TextureRect.new()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE  # the shader crops to cover and poses, at sub-pixel precision
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.material = ShaderMaterial.new()
		r.material.shader = SHADER
		r.material.set_shader_parameter("shadow", HudPalette.GLASS)
		r.material.set_shader_parameter("highlight", HudPalette.SOFT)
		add_child(r)
		_rects.append(r)
	(func() -> void: if not feed.get_parent(): add_child(feed)).call_deferred()
	resized.connect(_apply)
	_apply()
	set_process(not UiMotion.reduced())


func _process(delta: float) -> void:
	_t += delta
	_apply()


func _apply() -> void:
	var i := front(_t)
	if i != _shown:
		_shown = i
		var top := _rects[i % 2]
		top.texture = SLIDES[i % SLIDES.size()].tex
		move_child(top, _rects.size() - 1)  # on top of the other picture, under the feed
		if i > 0:
			_rects[(i - 1) % 2].texture = SLIDES[(i - 1) % SLIDES.size()].tex
	var age := _t - i * HOLD
	_place(_rects[i % 2], i, age, opacity(i, age))
	if i > 0:
		_place(_rects[(i - 1) % 2], i - 1, age + HOLD, 1.0)
	_watch(i, age)


## Hands the feed the front picture and its people, posed as it is drawn now.
func _watch(i: int, age: float) -> void:
	var slide: Dictionary = SLIDES[i % SLIDES.size()]
	var tex: Vector2 = slide.tex.get_size()
	feed.slide = slide
	feed.index = i
	feed.age = age
	feed.marks.clear()
	for m: Vector3 in slide.marks:
		feed.marks.append(place(m, i, age, size, tex))
	feed.queue_redraw()


func _place(r: TextureRect, index: int, age: float, alpha: float) -> void:
	var p := pose(index, age)
	var tex := r.texture.get_size()
	var cover := Vector2(1.0, tex.x * size.y / (tex.y * size.x)) if size.x / size.y > tex.x / tex.y 			else Vector2(tex.y * size.x / (tex.x * size.y), 1.0)
	var m := r.material as ShaderMaterial
	m.set_shader_parameter("zoom", p.scale)
	m.set_shader_parameter("shift", p.shift)
	m.set_shader_parameter("cover", cover)
	m.set_shader_parameter("progress", alpha)
