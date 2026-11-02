## Mission 1's tutorial, node-free: the first time a verb is relevant in the Encounter that teaches it, a
## contextual prompt under the verb's name and one Metis radio line (text keys tutorial.<verb>.prompt / .title /
## .line). Each verb once, and never once the player has done it unprompted (MGS2's veteran flags). Only in the
## campaign's Mission 1.
## The deck (Encounter 1) paces its tips by place: at the safe start, O1 in view, sneaking (aim, fire, crouch: one tip,
## tranq) and switching weapons; closing on a guard, the Hold-up, then the magazine; up close the takedown, then carry; at the smoke break the
## eavesdrop; and last the Scanner, once the eavesdrop is spent (looking at the guarded exits; in the yard if the
## player left without it). The yard (2): Hold-up (if the deck never taught it) then Fulton. Operations (3): nothing. LINE_ONLY verbs get no
## prompt, only Metis's line the first time they are used.
## One tip at a time: it stays up until the player does it (or WAIT_MAX), then it clears (cleared(): the HUD fades
## it) and the next waits a BEAT, never coming before MIN_SHOW. An URGENT tip (a chance that passes: the Hold-up as
## the player closes on a guard) cuts in instead of waiting, and the tip it cut off comes back after it.
## A verb in NEEDS waits for one of its listed verbs to be spent (no carry tip before the player knows how to put a
## guard down; the magazine after the Hold-up).
## The first sighting on the deck is a lesson too (sighted()): Metis says how to shake it off, and the deck's
## guards fill their meters at GRACE until that first sighting is over.
class_name Tutorial
extends RefCounted

const VERBS := ["tranq", "weapons", "holdup", "magazine", "takedown", "carry", "eavesdrop", "scanner", "radio", "fulton", "caution"]  # teaching order
const BY_ENCOUNTER := {1: ["tranq", "weapons", "holdup", "magazine", "takedown", "carry", "eavesdrop", "scanner"], 2: ["scanner", "holdup", "fulton"]}
const LINE_ONLY := ["radio", "caution"]
const NEEDS := {carry = ["takedown", "tranq"], scanner = ["eavesdrop"], magazine = ["holdup"]}  # any one of them spent
const URGENT := ["holdup", "carry", "eavesdrop"]  # a chance that passes: cuts in once the tip up has had MIN_SHOW; the one cut off comes back
const IN_VIEW := 30.0   # m to the nearest unaware guard: O1 from the start (about 19 m)
const CLOSING := 14.0   # m: closing on a guard, near enough that a thrown magazine would pull him
const HOLDUP_NEAR := 10.0  # m: closing on a deck guard for a Hold-up (its range is 6 m: Holdup.RANGE)
const MIN_SHOW := 1.5   # s a tip owns the screen before the next may replace it
const BEAT := 0.8       # s between a tip done and the next
const WAIT_MAX := 15.0  # s a tip stays up waiting to be done before the next may come (playtest 1: 6 s went before it was read)
const GRACE := 0.6      # the deck's sight fill until the first sighting is over
const SPOTTED := "spotted"  # the first sighting's tip and line (tutorial.spotted.*), not a verb

var seen := {}     # verbs tipped or done: spent
var did := {}      # verbs the player has done
var last := ""     # the verb tipped last
var since := INF   # s since the last tip
var since_done := INF  # s since the last tip was done
var grace := true  # the first sighting is not over yet
var _sighting := false
var _cleared := false  # the last tip was done or its sighting ended: the HUD should fade it


## What is relevant right now, verb -> bool, from world: guard / down / spot (metres to the nearest unaware
## guard / Down guard / eavesdrop spot, INF for none), holdup (metres to the nearest unaware guard with a
## scripted Hold-up answer: the Foreman), fulton (a balloon could go up beside a guard now), enc (the
## Encounter the Operative is in, 0 for none). Only the verbs BY_ENCOUNTER lists for enc can be relevant.
static func relevant(world: Dictionary) -> Dictionary:
	var here: Array = BY_ENCOUNTER.get(world.enc, [])
	var near := {
		tranq = world.guard <= IN_VIEW,
		weapons = world.guard <= IN_VIEW,
		magazine = world.guard <= CLOSING,
		takedown = world.guard <= 4.0,
		carry = world.down <= 2.0,
		eavesdrop = world.spot <= 6.0,
		scanner = world.guard <= IN_VIEW,
		holdup = world.holdup <= 12.0 or (world.enc == 1 and world.guard <= HOLDUP_NEAR),  # the Foreman in the yard; any guard on the deck
		fulton = world.fulton,
	}
	var out := {}
	for v: String in near:
		out[v] = near[v] and v in here
	return out


## Call each frame with its delta: the verb whose tip to show now, or "". Spends it.
func update(mission: int, campaign: bool, rel: Dictionary, delta := 0.0) -> String:
	since += delta
	since_done += delta
	if mission != 0 or not campaign:
		return ""
	var ready := _ready_for_next()
	var can_cut := since >= MIN_SHOW and not (last == SPOTTED and not did.has(SPOTTED))  # never over the sighting lesson
	for v: String in URGENT + VERBS:  # a chance that passes goes first, whatever the order
		if rel.get(v, false) and not seen.has(v) and _needs_met(v) and (ready or (v in URGENT and can_cut)):
			if not ready and last != "" and not did.has(last):
				seen.erase(last)  # cut off before it was done: it comes back once this one is
			seen[v] = true
			last = v
			since = 0.0
			return v
	return ""


## The player did `verb`. A tipped verb is just spent (the tip on screen clears if it is this one); a LINE_ONLY
## verb returns itself the first time (Metis says its line), "" otherwise.
func done(verb: String, mission: int, campaign: bool) -> String:
	if verb == last and not did.has(verb):
		since_done = 0.0
		_cleared = true
	did[verb] = true
	if seen.has(verb):
		return ""
	seen[verb] = true
	return verb if verb in LINE_ONLY and mission == 0 and campaign else ""


## True once after the tip on screen was done (or its sighting ended): the HUD fades it out.
func cleared() -> bool:
	var c := _cleared
	_cleared = false
	return c


## Call each frame with whether a guard of Encounter enc sees the Operative: SPOTTED the first time a deck guard
## does (show its tip, say its line; it takes the screen whatever is waiting), "" otherwise. Once that first
## sighting is over the grace ends and its tip clears.
func sighted(mission: int, campaign: bool, enc: int, seeing: bool) -> String:
	if mission != 0 or not campaign or not grace:
		return ""
	if _sighting and not seeing:
		grace = false
		if last == SPOTTED:
			did[SPOTTED] = true
			since_done = 0.0
			_cleared = true
		return ""
	if seeing and enc == 1 and not _sighting:
		_sighting = true
		last = SPOTTED
		since = 0.0
		return SPOTTED
	return ""


## The sight fill scale for a guard of Encounter enc: GRACE on the deck until its first sighting is over.
func sight_scale(mission: int, campaign: bool, enc: int) -> float:
	return GRACE if grace and enc == 1 and mission == 0 and campaign else 1.0


func _ready_for_next() -> bool:
	if since < MIN_SHOW:
		return false
	if last == "" or since >= WAIT_MAX:
		return true
	return did.has(last) and since_done >= BEAT


func _needs_met(verb: String) -> bool:
	return not NEEDS.has(verb) or NEEDS[verb].any(func(n: String) -> bool: return seen.has(n))


static func prompt_key(verb: String) -> String:
	return "tutorial.%s.prompt" % verb


static func title_key(verb: String) -> String:
	return "tutorial.%s.title" % verb


static func line_key(verb: String) -> String:
	return "tutorial.%s.line" % verb
