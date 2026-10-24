## What an Area puts in the world for a Mission plan: reads plan_mission's `deployed` levels and
## answers in counts and per-guard picks. Node-free; the Area places the result at its built-in spots.
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


## Stealth L3: overwatch sentries, one on every high point.
static func sentries(deployed: Dictionary) -> bool:
	return int(deployed.get("stealth", 0)) >= 3


## Combat L1: vests on every guard (tranq body shots stop, rifle body hits 2 -> 4).
static func vests(deployed: Dictionary) -> bool:
	return int(deployed.get("combat", 0)) >= 1


static func body_hits_to_kill(deployed: Dictionary) -> int:
	return 4 if vests(deployed) else 2


## Combat L2: two more guards on extra posts.
static func extra_guards(deployed: Dictionary) -> int:
	return 2 if int(deployed.get("combat", 0)) >= 2 else 0


## Reinforcements: the squad the road entry sends (3; Combat L3: 5, some flanking). Every Alert brings one.
static func squad_size(deployed: Dictionary) -> int:
	return Reinforcements.SQUAD_L3 if int(deployed.get("combat", 0)) >= 3 else Reinforcements.SQUAD


## Combat L3: a share of each squad flanks (Telegraph).
static func flanks(deployed: Dictionary) -> bool:
	return int(deployed.get("combat", 0)) >= 3


## Combat level, for the share of reinforcements that flank (Telegraph).
static func combat_level(deployed: Dictionary) -> int:
	return int(deployed.get("combat", 0))


## Stealth (any level): guards head-check before turning; the level sets how often (Telegraph).
static func head_check_level(deployed: Dictionary) -> int:
	return int(deployed.get("stealth", 0))


## Spoofing (any level): guards stop mid-patrol and radio HQ back; the level sets how often (Telegraph).
static func radio_check_level(deployed: Dictionary) -> int:
	return int(deployed.get("spoofing", 0))


## Takedowns L1: seconds between a patrolling guard glancing behind it (0 = never).
static func turn_around_every(deployed: Dictionary) -> float:
	return 6.0 if int(deployed.get("takedowns", 0)) >= 1 else 0.0


## Takedowns L2: patrolling guards walk in pairs.
static func pairs(deployed: Dictionary) -> bool:
	return int(deployed.get("takedowns", 0)) >= 2


## Takedowns L3: the choke takes 1.8 s (1.2 s before) and is heard within 6 m (the kill stays 0.5 s).
static func choke_time(deployed: Dictionary) -> float:
	return 1.8 if int(deployed.get("takedowns", 0)) >= 3 else 1.2


static func choke_noise(deployed: Dictionary) -> float:
	return 6.0 if int(deployed.get("takedowns", 0)) >= 3 else 0.0


## Downs L1: "random" HQ polls, L3: "targeted" ones (the guard nobody has seen longest); "" before L1.
static func hq_poll(deployed: Dictionary) -> String:
	var lvl := int(deployed.get("downs", 0))
	return "" if lvl < 1 else ("targeted" if lvl >= 3 else "random")


## Downs L2: a guard that finds a Down guard raises the alert at once.
static func instant_alert_on_down(deployed: Dictionary) -> bool:
	return int(deployed.get("downs", 0)) >= 2


## Spoofing L1: Glaukopis exposes a transmission at 25 doubt instead of 40.
static func expose_at(deployed: Dictionary) -> int:
	return 25 if int(deployed.get("spoofing", 0)) >= 1 else Glaukopis.EXPOSE_AT


## Spoofing L2: after a believed transmission, the recipient radios the speaker to check.
static func radio_callback(deployed: Dictionary) -> bool:
	return int(deployed.get("spoofing", 0)) >= 2


## Spoofing L3: a Voiceprint is flagged after one use, exposed or not.
static func single_use_voiceprints(deployed: Dictionary) -> bool:
	return int(deployed.get("spoofing", 0)) >= 3
