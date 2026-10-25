## Mission 1's tutorial, node-free: the first time each verb is relevant it gets a contextual prompt and
## one Metis radio line (text keys tutorial.<verb>.prompt / .line). One tip at a time, GAP seconds apart,
## each only once, and only in the campaign's Mission 1 (never Free mode, never later Missions).
class_name Tutorial
extends RefCounted

const VERBS := ["crouch", "takedown", "carry", "tranq", "eavesdrop", "radio", "scanner", "magazine", "holdup", "fulton", "caution"]  # teaching order
const GAP := 8.0  # seconds between tips

var seen := {}
var _wait := 0.0


## What is relevant right now, verb -> bool, from world: guard / down / spot (metres to the nearest unaware
## guard / Down guard / eavesdrop spot, INF for none), prints (Voiceprints held), scanner (charges),
## magazines, tranq (the tranq pistol is in hand), holdup (metres to the nearest unaware guard with a scripted
## Hold-up answer: the Foreman), fulton (a balloon could go up beside a guard now), caution (the Area is in Caution).
static func relevant(world: Dictionary) -> Dictionary:
	return {
		crouch = world.guard <= 14.0,
		takedown = world.guard <= 4.0,
		carry = world.down <= 2.0,
		tranq = world.tranq and world.guard <= 14.0,
		eavesdrop = world.spot <= 6.0,
		radio = world.prints > 0,
		scanner = world.scanner > 0 and world.guard <= 25.0,
		magazine = world.magazines > 0 and world.guard <= 10.0,
		holdup = world.holdup <= 12.0,
		fulton = world.fulton,
		caution = world.caution,
	}


## Call each frame: the verb whose tip to show now, or "". Spends it.
func update(delta: float, mission: int, campaign: bool, rel: Dictionary) -> String:
	if mission != 0 or not campaign:
		return ""
	_wait = maxf(_wait - delta, 0.0)
	if _wait > 0.0:
		return ""
	for v: String in VERBS:
		if rel[v] and not seen.has(v):
			seen[v] = true
			_wait = GAP
			return v
	return ""


static func prompt_key(verb: String) -> String:
	return "tutorial.%s.prompt" % verb


static func line_key(verb: String) -> String:
	return "tutorial.%s.line" % verb
