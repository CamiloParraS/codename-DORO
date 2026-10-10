## HUD E's rules, node-free so they can be tested: which phase shows and for how long, and where and
## how each detection arc is drawn.
class_name HudModel
extends RefCounted


## [name, seconds left] for the right strip: ALERT counts down to losing the Operative, EVASION to the
## end of the search. Takes every guard's GuardAlert. ["", 0] when nobody is hunting.
static func phase(alerts: Array) -> Array:
	var alert_left := -1.0
	var evasion_left := -1.0
	for a: GuardAlert in alerts:
		if a.state == GuardAlert.State.ALERT:
			alert_left = maxf(alert_left, GuardAlert.LOSE_TIME - a.unseen)
		elif a.state == GuardAlert.State.EVASION:
			evasion_left = maxf(evasion_left, GuardAlert.SEARCH_TIME - a.timer)
	if alert_left >= 0.0:
		return ["ALERT", alert_left]
	if evasion_left >= 0.0:
		return ["EVASION", evasion_left]
	return ["", 0.0]


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


## White to yellow as the meter fills; red when alerted.
static func arc_color(fill: float, alerted: bool) -> Color:
	var c := Color(1, 0.2, 0.2) if alerted else Color.WHITE.lerp(Color(1, 0.85, 0.2), fill)
	c.a = 0.35 + 0.65 * fill
	return c


## Lit pips of a weapon card's column: a round left always lights at least one.
static func pips_lit(loaded: int, load_size: int, pips: int) -> int:
	return ceili(loaded * pips / float(load_size))
