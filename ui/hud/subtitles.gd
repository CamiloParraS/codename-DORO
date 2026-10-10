## Bottom subtitles: the last two radio lines, each fading out by LIFE seconds. Node-free.
class_name Subtitles
extends RefCounted

const LIFE := 6.0
const FADE := 1.0
const SHOWN := 2

var lines: Array = []  # {"who", "text", "age"}


func add(who: String, text: String) -> void:
	lines.append({"who": who, "text": text, "age": 0.0})
	if lines.size() > SHOWN:
		lines.pop_front()


func tick(delta: float) -> void:
	for l in lines:
		l["age"] += delta
	lines = lines.filter(func(l): return l["age"] < LIFE)


static func alpha(age: float) -> float:
	return clampf((LIFE - age) / FADE, 0.0, 1.0)
