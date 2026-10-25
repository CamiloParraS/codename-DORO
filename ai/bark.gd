class_name Bark
extends RefCounted
## Which sound folder a guard's spoken event uses, how often a guard may repeat it, and its voice pitch.
## Node-free; Guard asks request() and plays one of the takes in dir().

const COOLDOWN := 4.0  # seconds before the same guard repeats the same event
const LONG := {&"caution": 15.0, &"resolved": 10.0}
const BARKS := "res://assets/audio/barks/"
const GRUNTS := "res://assets/audio/grunts/"
const EVENTS := {
	&"suspicion": BARKS + "suspicion", &"spotted": BARKS + "spotted", &"chase": BARKS + "chase",
	&"search": BARKS + "search", &"giveup": BARKS + "giveup", &"caution": BARKS + "caution",
	&"partner": BARKS + "partner", &"holdup": BARKS + "holdup", &"balloon": BARKS + "balloon",
	&"contact": GRUNTS + "radio", &"resolved": BARKS + "radio", &"choke": GRUNTS + "choke", &"pain": GRUNTS + "pain",
}
const PREFIX := {&"contact": "contact", &"resolved": "situation resolved"}  # these folders mix other lines
const RADIO := [&"contact", &"resolved"]  # spoken over the radio: the Radio bus

var _next := {}  # "who/event" -> time it may be said again


static func dir(event: StringName) -> String:
	return EVENTS[event]


## Is this file a take for the event: an .ogg or .mp3, with the event's line prefix if it has one.
static func wants(event: StringName, file: String) -> bool:
	return (file.ends_with(".ogg") or file.ends_with(".mp3")) and file.to_lower().begins_with(PREFIX.get(event, ""))


static func on_radio(event: StringName) -> bool:
	return event in RADIO


## True (and starts the cooldown) when `who` may say `event` at `now` seconds.
func request(who: String, event: StringName, now: float) -> bool:
	var key := "%s/%s" % [who, event]
	if now < _next.get(key, -INF):
		return false
	_next[key] = now + LONG.get(event, COOLDOWN)
	return true


## A guard's voice: the same every time, 0.92..1.08 by its name.
static func pitch(who: String) -> float:
	return 0.92 + (hash(who) % 17) * 0.01
