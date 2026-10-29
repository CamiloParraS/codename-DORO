## The HUD's rules, node-free so they can be tested: which phase shows and for how long, and where and
## how each detection arc is drawn.
class_name HudModel
extends RefCounted


## [name, seconds left, fraction left] for the top chip, from the Area's AlertChain: ALERT counts down
## to losing the Operative, EVASION to the end of the search, CAUTION to Normal. ["", 0, 0] in Normal.
static func phase(chain: AlertChain) -> Array:
	match chain.phase:
		AlertChain.Phase.ALERT:
			return ["ALERT", chain.left, chain.left / AlertChain.ALERT_TIME]
		AlertChain.Phase.EVASION:
			return ["EVASION", chain.left, chain.left / AlertChain.EVASION_TIME]
		AlertChain.Phase.CAUTION:
			return ["CAUTION", chain.left, chain.left / AlertChain.CAUTION_TIME]
	return ["", 0.0, 0.0]


## Fill 0..1 of the arc a guard shows, or -1 for none: a filling meter, or 1 for a guard that sees you
## while alerted.
static func arc_fill(a: GuardAlert, seeing: bool) -> float:
	if a.state == GuardAlert.State.ALERT:
		return 1.0 if seeing else -1.0
	if (a.state == GuardAlert.State.PATROL or a.state == GuardAlert.State.SUSPICION) and a.meter > 0.01:
		return a.meter
	return -1.0


## Screen angle (radians, 0 = right, y down) of a world offset on the ground plane, for a camera
## facing `forward` with `right` to its right: straight ahead is up (-PI/2).
static func screen_angle(offset: Vector3, forward: Vector3, right: Vector3) -> float:
	return atan2(offset.dot(right), offset.dot(forward)) - PI / 2


## How much of the Aigis layer shows, 0..1: none in Mission 1, then growing with Lethality (NAN = none
## killed yet). Escalation is the point: the HUD changes colour once Aigis has profiled you.
static func aigis_weight(mission: int, ratio: float) -> float:
	if mission <= 0:
		return 0.0
	if is_nan(ratio):
		return 0.4
	return clampf(0.4 + 0.6 * ratio / Aigis.GORGO_FROM, 0.4, 1.0)


## Habits whose tally events rose between two tally snapshots, for the "habit flagged" tick.
static func habits_risen(before: Dictionary, now: Dictionary) -> Array:
	var out := []
	for e: String in Aigis.TRIGGERS:
		var h: String = Aigis.TRIGGERS[e][0]
		if int(now.get(e, 0)) > int(before.get(e, 0)) and not h in out:
			out.append(h)
	return out


## Gorgo's deception: while she is the Dominant Voice the HUD hides the early part of a detection arc,
## so a guard noticing you looks calm until its meter passes GORGO_HIDE. Only the warning is delayed:
## guards, alerts and ALERT arcs are untouched, and the Voice tag stays lit as the tell.
const GORGO_HIDE := 0.45


static func deceive(fill: float, dominant: String) -> float:
	if dominant.to_lower() == "gorgo" and fill >= 0.0 and fill < GORGO_HIDE:
		return -1.0
	return fill


## Light toward Aigis cyan as `aigis` (0..1) rises, faint to full as the meter fills (the fill also grows
## along the arc, so hue is not the only cue); damage red when alerted.
static func arc_color(fill: float, alerted: bool, aigis := 1.0) -> Color:
	var c: Color = HudPalette.DMG if alerted else HudPalette.LIGHT.lerp(HudPalette.CYAN, aigis * 0.6)
	c.a = 0.35 + 0.65 * fill
	return c


## Lit pips of a weapon card's column: a round left always lights at least one.
static func pips_lit(loaded: int, load_size: int, pips: int) -> int:
	return ceili(loaded * pips / float(load_size))
