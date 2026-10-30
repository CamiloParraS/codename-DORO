## The one effect layer on a full-screen UI: static scanlines, an optional slow light band, an optional drifting
## backdrop. Add one per screen, last, so it sits above everything; none on the HUD.
class_name UiScan
extends ColorRect

const SHADER := preload("res://ui/ui_scan.gdshader")


## `backdrop` (optional) is drawn under the lines and drifts slowly when `drift` is on.
static func make(backdrop: Texture2D = null, band := false, drift := false) -> UiScan:
	var s := UiScan.new()
	s.name = "UiScan"
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.color = Color.WHITE
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("band_on", band)
	if backdrop:
		m.set_shader_parameter("backdrop", backdrop)
		m.set_shader_parameter("use_backdrop", true)
		m.set_shader_parameter("drift", 1.0 if drift else 0.0)
	s.material = m
	return s
