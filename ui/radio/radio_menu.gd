## The radial radio's steps, node-free: speaker → recipient → order → place → confirm.
## "Hold position" and "all clear" skip the place step. The Radio node draws it and sends the pick.
class_name RadioMenu
extends RefCounted

const ORDERS := [["Go check", "go"], ["Hold position", "hold"], ["All clear", "all_clear"]]
const SAID := {go = "radio.said.go", hold = "radio.said.hold", all_clear = "radio.said.all_clear"}  # text keys; {to}, {place}
const REPORT_IN := [["Report in", "report_in"]]  # the only order to HQ, offered while HQ polls the speaker

var step := "speaker"   # speaker / to / order / place / confirm
var pick := {}          # speaker, recipients, all_units, order, place
var roles := {}         # guard name -> role: a guard is shown by his role, numbered when two share one
var hint_label := ""   # set: the speaker step also offers "Request hint" (needs no Voiceprint)
var _speakers: Array    # held Voiceprints
var _guards: Array      # guards who can take an order (up)
var _places: Array
var _polled: String      # the guard HQ is waiting on ("" = no poll pending)


func _init(speakers: Array, guards: Array, places: Array, polled := "") -> void:
	_speakers = speakers
	_guards = guards
	_places = places
	_polled = polled


## [label, value] for the current step.
func options() -> Array:
	match step:
		"speaker":
			var out: Array = _speakers.map(func(s): return [s, s])
			if hint_label != "":
				out.append([hint_label, "hint"])
			return out
		"to":
			var out: Array = _guards.map(func(g): return [g, [g]])
			out.append(["All units", _guards.filter(func(g): return g != pick.speaker)])
			if pick.speaker == _polled:
				out.push_front(["HQ", []])
			return out
		"order":
			return REPORT_IN if pick.recipients.is_empty() else ORDERS
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
			if v is String and v == "hint" and hint_label != "" and i == opts.size() - 1:
				pick.hint = true
				return true
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


## A guard as shown: his role ("Patroller 2" when two share it), else his name.
func shown(who: String) -> String:
	var role: String = roles.get(who, "")
	if role == "":
		return who
	var peers: Array = roles.keys().filter(func(g): return roles[g] == role)
	var label := tr("radio.role." + role)
	if peers.size() < 2:
		return label
	peers.sort()
	return "%s %d" % [label, peers.find(who) + 1]


## What the Operative says as the speaker, e.g. "Guard05, go check the Dock." (translated).
func line() -> String:
	if pick.order == "report_in":
		return tr("radio.said.report_in").format({who = shown(pick.speaker)})
	var to: String = tr("radio.opt.all_units") if pick.all_units else shown(pick.recipients[0])
	return tr(SAID[pick.order]).format({to = to, place = pick.place})


## What the world should light while option `hover` (-1: none) is hovered. hot: what that option names;
## cold: earlier picks; place: the hovered or confirmed Radio point ("" = none). Guard names only: the
## Radio node maps them to guards still in the Area.
func referents(hover: int) -> Dictionary:
	var out := {hot = [], cold = [], place = "", place_hot = false}
	if step == "confirm":
		out.hot = [pick.speaker] + pick.recipients
		if pick.place != "":
			out.place = pick.place
			out.place_hot = true
		return out
	if step != "speaker":
		out.cold.append(pick.speaker)
	if step in ["order", "place"]:
		out.cold.append_array(pick.recipients)
	var opts := options()
	if hover >= 0 and hover < opts.size():
		var v = opts[hover][1]
		match step:
			"speaker":
				if not (hint_label != "" and hover == opts.size() - 1):
					out.hot = [v]
			"to":
				out.hot = v
			"place":
				out.place = v
				out.place_hot = true
	out.cold = out.cold.filter(func(g): return not g in out.hot)
	return out


## Slice under a pointer offset from the centre, for `count` slices clockwise from the top;
## -1 inside the dead zone.
static func slice(pointer: Vector2, count: int, dead_zone := 12.0) -> int:
	if count <= 0 or pointer.length() < dead_zone:
		return -1
	var a := fposmod(pointer.angle() + PI / 2 + PI / count, TAU)  # 0 at the top, slice 0 centred there
	return mini(int(a / (TAU / count)), count - 1)
