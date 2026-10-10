## What an Area puts in the world for a Mission plan: reads plan_mission's `deployed` levels and
## answers in counts and per-guard picks. Node-free; the Area places the result at its built-in spots.
## Only the Countermeasures that exist so far are here (the gear and patrol ticket adds the rest).
class_name Deployment
extends RefCounted

const HELMET_SHARE: Array[float] = [0.0, 0.33, 0.66, 1.0]  # by Headshots level


## Stealth L1: a security camera on every camera mount.
static func cameras(deployed: Dictionary) -> bool:
	return int(deployed.get("stealth", 0)) >= 1


## Stealth L2: one extra patrol (one more guard on an extra post's route).
static func extra_patrols(deployed: Dictionary) -> int:
	return 1 if int(deployed.get("stealth", 0)) >= 2 else 0


## Which of `guards` guards wear a helmet (Headshots L1-L3: 33/66/100%, rounded), spread evenly
## through the list so they aren't all in one corner of the Area.
static func helmets(deployed: Dictionary, guards: int) -> Array[bool]:
	var n := roundi(guards * HELMET_SHARE[int(deployed.get("headshots", 0))])
	var out: Array[bool] = []
	for i in guards:
		out.append(floori((i + 1) * n / float(guards)) > floori(i * n / float(guards)))
	return out
