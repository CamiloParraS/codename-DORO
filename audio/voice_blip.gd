class_name VoiceBlip
extends RefCounted
## Typewriter text with a per-character blip pitched per Voice. Node-free: advance(delta) returns the
## pitches to play (silent characters give none); skip() reveals the rest and blips no more.

const CPS := 30.0
## Bands are disjoint: the Voice is told apart by pitch alone. A character nudges it within ±12%.
const BASE := {"gorgo": 0.5, "promachos": 0.7, "nike": 1.0, "pallas": 1.4, "glaukopis": 2.0}
## Codec speakers beep too (their own scale: they are never heard beside a Briefing's Voices).
const CODEC := {"handler": 0.9, "analyst": 1.25, "operative": 0.6}
const SPREAD := 0.03

var _text: String
var _voice: String
var _t := 0.0
var _n := 0


func _init(text: String, voice: String) -> void:
	_text = text
	_voice = voice
	if base(voice) == 0.0:  # no Voice: shown at once, silent
		_n = text.length()


static func base(voice: String) -> float:
	return BASE.get(voice, CODEC.get(voice, 0.0))


static func pitch(voice: String, ch: String) -> float:
	if ch.strip_edges().is_empty():
		return 0.0
	return base(voice) * (1.0 + SPREAD * ((ch.unicode_at(0) % 9) - 4))


## "brief.<voice>.<what>" -> voice; anything else -> "".
static func voice_of(key: String) -> String:
	var p := key.split(".")
	return p[1] if p.size() >= 3 and p[0] == "brief" and BASE.has(p[1]) else ""


func advance(delta: float) -> Array[float]:
	var out: Array[float] = []
	_t += delta
	var want := mini(int(_t * CPS), _text.length())
	while _n < want:
		var p := pitch(_voice, _text[_n])
		if p > 0.0:
			out.append(p)
		_n += 1
	return out


func skip() -> void:
	_n = _text.length()


func done() -> bool:
	return _n >= _text.length()


func shown() -> String:
	return _text.substr(0, _n)
