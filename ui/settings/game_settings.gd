## The settings file (user://settings.json), separate from the campaign slots so New game leaves it
## alone. load_file/save_file are node-free; apply() pushes a value set into the running game.
class_name GameSettings
extends RefCounted

const PATH := "user://settings.json"
const LANGUAGES := ["en", "es"]
## 0 is AUTO: no cap, vsync paces frames at the display's own rate. A fixed cap that doesn't divide the refresh rate
## (60 on a 144 Hz screen) holds frames for 2 or 3 refreshes in turn, and slow motion judders (the menu backdrop's push).
const FPS_CAPS := [0, 60, 120, 144]
## llm_key / llm_model: Aigis Voice's Gemini key (plain text, this machine only) and model (LlmClient).
const DEFAULTS := {sensitivity = 0.0025, invert_y = false, language = "en", fullscreen = false, volume = 1.0, reduce_motion = false, max_fps = 0,
	llm_key = "", llm_model = "gemini-3.5-flash-lite"}
const SENS_RANGE := Vector2(0.0005, 0.008)

static var current: Dictionary = DEFAULTS.duplicate()


static func load_file(path := PATH) -> Dictionary:
	var out := DEFAULTS.duplicate()
	var f := FileAccess.open(path, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
	if d is Dictionary:
		if d.get("sensitivity") is float:
			out.sensitivity = clampf(d.sensitivity, SENS_RANGE.x, SENS_RANGE.y)
		if d.get("invert_y") is bool:
			out.invert_y = d.invert_y
		if d.get("language") in LANGUAGES:
			out.language = d.language
		if d.get("fullscreen") is bool:
			out.fullscreen = d.fullscreen
		if d.get("reduce_motion") is bool:
			out.reduce_motion = d.reduce_motion
		if d.get("max_fps") is float and int(d.max_fps) in FPS_CAPS:
			out.max_fps = int(d.max_fps)
		if d.get("volume") is float:
			out.volume = clampf(d.volume, 0.0, 1.0)
		if d.get("llm_key") is String:
			out.llm_key = d.llm_key.strip_edges()
		if d.get("llm_model") is String and d.llm_model.strip_edges() != "":
			out.llm_model = d.llm_model.strip_edges()
	return out


static func save_file(settings: Dictionary, path := PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))


## Make `settings` the live set (language, window mode, master volume) and keep it in `current`.
static func apply(settings: Dictionary) -> void:
	current = settings
	TranslationServer.set_locale(settings.language)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.volume))
	Engine.max_fps = settings.max_fps
