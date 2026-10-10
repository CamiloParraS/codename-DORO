## The radial radio's steps, node-free: speaker → recipient → order → place → confirm.
## "Hold position" and "all clear" skip the place step. The Radio node draws it and sends the pick.
class_name RadioMenu
extends RefCounted

const ORDERS := [["Go check", "go"], ["Hold position", "hold"], ["All clear", "all_clear"]]
const SAID := {go = "go check the %s", hold = "hold your position", all_clear = "all clear, stand down"}

var step := "speaker"   # speaker / to / order / place / confirm
var pick := {}          # speaker, recipients, all_units, order, place
var _speakers: Array    # held Voiceprints
var _guards: Array      # guards who can take an order (up)
var _places: Array


func _init(speakers: Array, guards: Array, places: Array) -> void:
	_speakers = speakers
	_guards = guards
	_places = places


## [label, value] for the current step.
func options() -> Array:
	match step:
		"speaker":
			return _speakers.map(func(s): return [s, s])
		"to":
			var out: Array = _guards.map(func(g): return [g, [g]])
			out.append(["All units", _guards.filter(func(g): return g != pick.speaker)])
			return out
		"order":
			return ORDERS
		"place":
			return _places.map(func(p): return [p, p])
	return [["Send", true]]


## Take option i. True when the transmission is ready to send.
func choose(i: int) -> bool:
	var opts := options()
	if i < 0 or i >= opts.size():
		return false
	var v = opts[i][1]
	match step:
		"speaker":
			pick.speaker = v
			step = "to"
		"to":
			pick.recipients = v
			pick.all_units = opts[i][0] == "All units"
			step = "order"
		"order":
			pick.order = v
			pick.place = ""
			step = "place" if v == "go" else "confirm"
		"place":
			pick.place = v
			step = "confirm"
		"confirm":
			return true
	return false


## One step back. False when already at the first step (the caller closes the menu).
func back() -> bool:
	match step:
		"speaker":
			return false
		"to":
			step = "speaker"
		"order":
			step = "to"
		"place":
			step = "order"
		"confirm":
			step = "place" if pick.order == "go" else "order"
	return true


## What the Operative says in the speaker's voice, e.g. "Guard05, go check the Dock."
func line() -> String:
	var to: String = "All units" if pick.all_units else pick.recipients[0]
	var said: String = SAID[pick.order] % pick.place if pick.order == "go" else SAID[pick.order]
	return "%s, %s." % [to, said]


## Slice under a pointer offset from the centre, for `count` slices clockwise from the top;
## -1 inside the dead zone.
static func slice(pointer: Vector2, count: int, dead_zone := 12.0) -> int:
	if count <= 0 or pointer.length() < dead_zone:
		return -1
	var a := fposmod(pointer.angle() + PI / 2 + PI / count, TAU)  # 0 at the top, slice 0 centred there
	return mini(int(a / (TAU / count)), count - 1)
