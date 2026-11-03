## The moment a Countermeasure catches the Operative, said out loud: a guard (or HQ) names what Aigis
## deployed and who it was deployed against, the Operative's callsign (Dossier.callsign). Node-free.
## A moment speaks only while its Habit has a Countermeasure deployed, and the Area says each one at most
## once per COOLDOWN s, so the line lands as a beat, not a loop. The Area (harbour.gd) makes a fresh one per
## Mission; guards, the radio and HQ ask `area`.
class_name Caught
extends RefCounted

## Moment -> the Habit whose Countermeasure it shows.
const MOMENTS := {
	&"helmet": "headshots",   # a headshot stopped by a helmet
	&"vest": "combat",        # a dart or bullet stopped by a vest
	&"squad": "combat",       # a squad of Reinforcements sent in
	&"behind": "takedowns",   # spotted at arm's length: he turned round in time
	&"partner": "takedowns",  # a partner saw the choke
	&"found": "downs",        # a Down guard found
	&"silence": "downs",      # a polled guard didn't answer HQ
	&"exposed": "spoofing",   # a Spoofed transmission exposed
	&"sentry": "stealth",     # an overwatch sentry spotted the Operative
	&"camera": "stealth",     # a camera spotted the Operative
}
const HQ := [&"silence", &"camera", &"squad"]  # said by HQ on the radio, not by a guard
const COOLDOWN := 25.0
const VARIANTS := 2
const BEHIND := 4.0  # metres: a spotter this close turned round on the Operative

static var area := Caught.new()

var deployed := {}    # Habit -> level, the Mission's plan
var callsign := ""    # the callsign's text, already translated
var _next := {}       # moment -> time it may be said again


func _init(plan_deployed := {}, name := "") -> void:
	deployed = plan_deployed
	callsign = name


## Does this moment's Habit have a Countermeasure deployed.
func armed(moment: StringName) -> bool:
	return int(deployed.get(MOMENTS[moment], 0)) > 0


## The line's key for `moment` at `now` seconds ("" when it isn't armed or was said too recently), and
## starts its cooldown. variant: 0..VARIANTS-1.
func line(moment: StringName, now: float, variant := 0) -> String:
	if not armed(moment) or now < _next.get(moment, -INF):
		return ""
	_next[moment] = now + COOLDOWN
	return "caught.%s.%d" % [moment, variant % VARIANTS + 1]


static func by_hq(moment: StringName) -> bool:
	return moment in HQ
