## The small motions of story delivery, as pure functions of the seconds since the motion began: the Codec's
## tune-in, a portrait's talk flap and blink, a Voice glyph's pulse. All 0.1-0.3 s; none loops.
class_name StoryMotion
extends RefCounted

const TUNE := 0.25         # static while the frequency settles
const CUT := 0.12          # the screen goes dark on a call's close
const FLAP := 0.15         # seconds per portrait frame while the line types
const BLINK_EVERY := 3.0
const BLINK := 0.12
const PULSE := 0.25
const PULSE_SWELL := 0.4   # extra scale at the pulse's peak
const GLYPHS := {promachos = "/\\", nike = ">>", pallas = "[]", gorgo = "XX", glaukopis = "()"}  # a Voice's mark


static func tuning(t: float) -> bool:
	return t < TUNE


## The frequency text: digits wander (in 30 Hz steps) until TUNE, then it reads `final`.
static func frequency(t: float, final: String) -> String:
	if not tuning(t):
		return final
	var s := ""
	for i in final.length():
		s += final[i] if final[i] == "." else str((int(t * 30.0) * 7 + i * 3 + final.unicode_at(i)) % 10)
	return s if s != final else final.reverse()


## Which of a portrait's two frames to show: the speaker flips while the line types, and blinks at rest.
static func frame(t: float, speaking: bool, typing: bool) -> int:
	if not speaking:
		return 0
	if typing:
		return int(t / FLAP) % 2
	return 1 if fmod(t, BLINK_EVERY) < BLINK and t >= BLINK_EVERY else 0


## A glyph's scale `t` seconds after its line starts: swells and settles, then stays 1.
static func pulse(t: float) -> float:
	return 1.0 + PULSE_SWELL * sin(PI * t / PULSE) if t > 0.0 and t < PULSE else 1.0


## True while the settings panel is open: story motion holds still.
static func still(node: Node) -> bool:
	return node.get_tree().get_first_node_in_group("settings_open") != null


## Draws a Voice's glyph at `at` (baseline-left), swelling `t` seconds after its line starts. Call inside _draw.
static func draw_glyph(ci: CanvasItem, font: Font, at: Vector2, voice: String, t: float, col: Color) -> void:
	var w: float = GLYPHS[voice].length() * 8.0
	var k := pulse(t)
	ci.draw_set_transform(at + Vector2(w / 2, -4) , 0.0, Vector2(k, k))
	ci.draw_string(font, Vector2(-w / 2, 4), GLYPHS[voice], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
	ci.draw_set_transform(Vector2.ZERO)
