## The shared Aigis telegraph, node-free: how long a cyan icon + pose shows, the Stealth head-check
## trigger, and Metis's first-sighting lines. The Guard draws it: Guard.telegraph(kind, icon, clip, mutter).
## Spoofing and Combat behaviours reuse that call with their own kind, icon and clip.
class_name Telegraph
extends RefCounted

const DURATION := 1.0
const MIN_SHARE := 0.25
const MAX_SHARE := 0.75
## Seconds of patrolling between Spoofing radio-check rolls.
const RADIO_CHECK_EVERY := 12.0
## Metis's one-line radio call the first time the Operative sees each kind in a Mission.
const METIS := {
	"radio_check": "A guard just keyed the radio to call HQ back. Aigis is double-checking transmissions.",
	"head_check": "Guards are glancing back before they turn. Aigis is watching your exits.",
}


## Share of patrol turns that get a head-check: 25% per Stealth level, held to 25-75%.
static func head_check_share(level: int) -> float:
	return clampf(MIN_SHARE * level, MIN_SHARE, MAX_SHARE)


## Does this turn get a head-check. level 0 (no Stealth Countermeasure) never does.
static func head_check(level: int, rng: RandomNumberGenerator) -> bool:
	return level > 0 and rng.randf() < head_check_share(level)


## Spoofing: share of radio-check rolls that fire; the same 25-75% curve as the head-check.
static func radio_check_share(level: int) -> float:
	return head_check_share(level)


## Does this roll make a guard stop and call HQ back. level 0 (no Spoofing Countermeasure) never does.
static func radio_check(level: int, rng: RandomNumberGenerator) -> bool:
	return level > 0 and rng.randf() < radio_check_share(level)


## True once per kind per `seen` (a Mission's dictionary).
static func first_sighting(seen: Dictionary, kind: String) -> bool:
	if seen.has(kind):
		return false
	seen[kind] = true
	return true
