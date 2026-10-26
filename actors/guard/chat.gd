## A chatting pair's turns: seat 0 talks, then seat 1, then a quiet spell, on a loop. One per pair,
## ticked by seat 0. A guard on its turn shows ((·)) and can be recorded like a check-in. Lines are text keys,
## [seat][exchange]: LINES for any pair, SMOKE for the Harbour's smoke break (it names the Foreman). Node-free.
class_name Chat
extends RefCounted

const TURN := 3.0
const QUIET := 4.0
const HEARD := 10.0  # metres from the Operative within which a chat line shows as a subtitle
const LINES := [
	["chat.idle.1.a", "chat.idle.2.a", "chat.idle.3.a", "chat.idle.4.a", "chat.idle.5.a", "chat.idle.6.a"],
	["chat.idle.1.b", "chat.idle.2.b", "chat.idle.3.b", "chat.idle.4.b", "chat.idle.5.b", "chat.idle.6.b"],
]
const SMOKE := [
	["chat.smoke.1.a", "chat.smoke.2.a", "chat.smoke.3.a", "chat.smoke.4.a", "chat.smoke.5.a"],
	["chat.smoke.1.b", "chat.smoke.2.b", "chat.smoke.3.b", "chat.smoke.4.b", "chat.smoke.5.b"],
]
## A chat post's meta value -> its lines; anything else (true) gets LINES.
const SETS := {"smoke": SMOKE}

var t := 2 * TURN  # starts quiet
var lines: Array
var _line := 0


func _init(l: Array = LINES) -> void:
	lines = l


## Advances the loop; on the frame a turn starts, returns that seat's line, otherwise "".
func tick(delta: float) -> String:
	var before := speaker()
	t = fmod(t + delta, 2 * TURN + QUIET)
	var now := speaker()
	if now == before or now < 0:
		return ""
	var line: String = lines[now][_line]
	if now == 1:
		_line = (_line + 1) % lines[1].size()
	return line


## The seat talking now, or -1 in the quiet spell.
func speaker() -> int:
	if t < TURN:
		return 0
	if t < 2 * TURN:
		return 1
	return -1
