## The shared Aigis telegraph, node-free: how long a cyan icon + pose shows, the Stealth head-check
## trigger, and Metis's first-sighting lines. The Guard draws it: Guard.telegraph(kind, icon, clip, mutter).
## Spoofing and Combat behaviours reuse that call with their own kind, icon and clip.
class_name Telegraph
extends RefCounted

const DURATION := 1.0
const MIN_SHARE := 0.25
const MAX_SHARE := 0.75
## Metis's one-line radio call the first time the Operative sees each kind in a Mission.
const METIS := {
	"head_check": "Guards are glancing back before they turn. Aigis is watching your exits.",
	"flank": "Reinforcements through the road entry, and they are coming round your side.",
}
## Combat: how far beside the Operative's spot a flanking reinforcement aims, in metres.
const FLANK_OFFSET := 8.0
## Shown over a reinforcement as it arrives; it stays up even though the guard is already on alert.
const FLANK_ICON := "!>"


## Share of patrol turns that get a head-check: 25% per Stealth level, held to 25-75%.
static func head_check_share(level: int) -> float:
	return clampf(MIN_SHARE * level, MIN_SHARE, MAX_SHARE)


## Does this turn get a head-check. level 0 (no Stealth Countermeasure) never does.
static func head_check(level: int, rng: RandomNumberGenerator) -> bool:
	return level > 0 and rng.randf() < head_check_share(level)


## Does this reinforcement take a flank path instead of the direct one. Same 25-75% share by Combat level.
static func flank(level: int, rng: RandomNumberGenerator) -> bool:
	return level > 0 and rng.randf() < head_check_share(level)


## A spot FLANK_OFFSET to a random side of `target`, perpendicular to the approach from `entry`.
static func flank_point(entry: Vector3, target: Vector3, rng: RandomNumberGenerator) -> Vector3:
	var dir := target - entry
	dir.y = 0.0
	if dir.is_zero_approx():
		return target
	var side := Vector3(-dir.z, 0.0, dir.x).normalized()
	return target + side * FLANK_OFFSET * (1.0 if rng.randf() < 0.5 else -1.0)


## True once per kind per `seen` (a Mission's dictionary).
static func first_sighting(seen: Dictionary, kind: String) -> bool:
	if seen.has(kind):
		return false
	seen[kind] = true
	return true
