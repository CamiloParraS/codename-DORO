## Mission 1's tutorial, node-free: the first time a verb is relevant in the Encounter that teaches it, a
## contextual prompt and one Metis radio line (text keys tutorial.<verb>.prompt / .line). Each verb once, and
## never once the player has done it unprompted (MGS2's veteran flags). Only in the campaign's Mission 1.
## The deck (Encounter 1) teaches crouch, takedown, carry and eavesdrop; the yard (2) Hold-up then Fulton;
## Operations (3) nothing. LINE_ONLY verbs get no prompt, only Metis's line the first time they are used.
class_name Tutorial
extends RefCounted

const VERBS := ["crouch", "takedown", "carry", "tranq", "eavesdrop", "radio", "scanner", "magazine", "holdup", "fulton", "caution"]  # teaching order
const BY_ENCOUNTER := {1: ["crouch", "takedown", "carry", "eavesdrop"], 2: ["holdup", "fulton"]}
const LINE_ONLY := ["tranq", "radio", "scanner", "magazine", "caution"]

var seen := {}


## What is relevant right now, verb -> bool, from world: guard / down / spot (metres to the nearest unaware
## guard / Down guard / eavesdrop spot, INF for none), holdup (metres to the nearest unaware guard with a
## scripted Hold-up answer: the Foreman), fulton (a balloon could go up beside a guard now), enc (the
## Encounter the Operative is in, 0 for none). Only the verbs BY_ENCOUNTER lists for enc can be relevant.
static func relevant(world: Dictionary) -> Dictionary:
	var here: Array = BY_ENCOUNTER.get(world.enc, [])
	var near := {
		crouch = world.guard <= 14.0,
		takedown = world.guard <= 4.0,
		carry = world.down <= 2.0,
		eavesdrop = world.spot <= 6.0,
		holdup = world.holdup <= 12.0,
		fulton = world.fulton,
	}
	var out := {}
	for v: String in near:
		out[v] = near[v] and v in here
	return out


## Call each frame: the verb whose tip to show now, or "". Spends it.
func update(mission: int, campaign: bool, rel: Dictionary) -> String:
	if mission != 0 or not campaign:
		return ""
	for v: String in VERBS:
		if rel.get(v, false) and not seen.has(v):
			seen[v] = true
			return v
	return ""


## The player did `verb`. A tipped verb is just spent; a LINE_ONLY verb returns itself the first time (Metis
## says its line), "" otherwise.
func done(verb: String, mission: int, campaign: bool) -> String:
	if seen.has(verb):
		return ""
	seen[verb] = true
	return verb if verb in LINE_ONLY and mission == 0 and campaign else ""


static func prompt_key(verb: String) -> String:
	return "tutorial.%s.prompt" % verb


static func line_key(verb: String) -> String:
	return "tutorial.%s.line" % verb
