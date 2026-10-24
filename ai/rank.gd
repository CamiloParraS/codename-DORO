## A Mission attempt's Rank (S/A/B/C) from its run-wide counters. MissionRun keeps one per attempt, apart
## from the tally: a Checkpoint restore never rolls it back, and it never reads the Profile. Node-free.
class_name Rank
extends RefCounted

const PAR_PER_ENCOUNTER := 120.0  # s; Reinforcements don't add to it
const LETTERS := ["S", "A", "B", "C"]

var kills := 0      # guard deaths the Operative caused, Targets included
var alerts := 0     # completed Radio calls (Caution is free)
var found := 0      # Down guards a patrol found
var continues := 0  # Checkpoint restores: death, the pause menu, the sea
var seconds := 0.0  # runs through the Game Over screen, not the pause menu


static func par(mission: int) -> float:
	return PAR_PER_ENCOUNTER * Campaign.MISSIONS[mission].encounters


## S: 0 kills, 0 Alerts. A: at most 1 Alert. B: any non-lethal clear. C: a kill. Over par, two or more
## found and each Continue drop one letter, never below B (B is any non-lethal clear).
func grade(par_seconds: float) -> String:
	if kills > 0:
		return "C"
	var i := 0 if alerts == 0 else 1 if alerts == 1 else 2
	if found >= 2:
		i += 1
	if seconds > par_seconds:
		i += 1
	return LETTERS[mini(i + continues, 2)]


func bonuses() -> Array[String]:
	var out: Array[String] = []
	if alerts == 0 and found == 0:
		out.append("NO TRACES")
	if kills == 0:
		out.append("NO KILLS")
	return out


## This attempt as a Mission Record entry.
func stats(par_seconds: float) -> Dictionary:
	return {rank = grade(par_seconds), time = seconds, kills = kills, alerts = alerts}


## The Mission Record: four independent bests (Rank, fastest time, fewest kills, fewest Alerts). old {} = none.
static func best(old: Dictionary, run: Dictionary) -> Dictionary:
	if old.is_empty():
		return run.duplicate()
	return {
		rank = LETTERS[mini(LETTERS.find(old.rank), LETTERS.find(run.rank))],
		time = minf(old.time, run.time), kills = mini(old.kills, run.kills), alerts = mini(old.alerts, run.alerts),
	}
