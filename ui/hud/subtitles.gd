## Bottom subtitles: the last two radio lines, each fading out by LIFE seconds. Node-free.
class_name Subtitles
extends RefCounted

const LIFE := 6.0
const FADE := 1.0
const LONG := 12.0  # a long line (the smoke break's): it outlasts the other guards' lines and isn't pushed out by them
const SHOWN := 2

var lines: Array = []  # {"who", "text", "age", "life"}


func add(who: String, text: String, long := false) -> void:
	lines.append({"who": who, "text": text, "age": 0.0, "life": LONG if long else LIFE})
	if lines.size() > SHOWN:
		var drop := lines.find_custom(func(l: Dictionary) -> bool: return l["life"] == LIFE and l != lines.back())  # the oldest ordinary line goes first
		if drop < 0 and lines.back()["life"] == LIFE:
			drop = lines.size() - 1  # only long lines are up: an ordinary one waits its turn rather than pushing one out
		lines.remove_at(maxi(drop, 0))


func tick(delta: float) -> void:
	for l in lines:
		l["age"] += delta
	lines = lines.filter(func(l): return l["age"] < l["life"])


static func alpha(age: float, life := LIFE) -> float:
	return clampf((life - age) / FADE, 0.0, 1.0)
