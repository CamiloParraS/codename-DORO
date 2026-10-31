## Which spoken line Aigis's Voices and the guards say, as translation keys (text/lines.csv).
## Node-free. The Briefing's keys come from Aigis.plan_mission; this adds the post-Mission line and
## the guards' field chatter.
class_name VoiceLines
extends RefCounted

const WARN_FROM := 50  # points in a Habit at which guards start warning about its next Countermeasure
const VARIANTS := 2


## The Dominant Voice's post-Mission line: its band, and whether this Mission's Lethality was 0.
static func post_key(dominant: String, zero: bool) -> String:
	return "post.%s.%s" % [dominant, "clean" if zero else "blood"]


## No guard or Target died in this tally.
static func lethality_zero(counts: Dictionary) -> bool:
	return int(counts.get("kill", 0)) + int(counts.get("target_kill", 0)) == 0


## "confirm" once the Habit's Countermeasure is deployed, "warn" from WARN_FROM points before it is, else "".
static func chatter_state(points: int, deployed_level: int) -> String:
	if deployed_level > 0:
		return "confirm"
	return "warn" if points >= WARN_FROM else ""


static func chatter_key(habit: String, state: String, variant: int) -> String:
	return "chatter.%s.%s.%d" % [state, habit, variant + 1]


## [[habit, state], ...] in Habit-table order for every Habit that has chatter. A deployed Habit whose events
## the last Mission had Dossier.CITE_FROM times or more (record's Dossier keys) adds [habit, "evidence", n]
## after it: the guards repeat the number HQ gave them.
static func chatter_sets(points: Dictionary, deployed: Dictionary, record := {}) -> Array:
	var out := []
	for h: String in Aigis.HABITS:
		var s := chatter_state(int(points.get(h, 0)), int(deployed.get(h, 0)))
		if s != "":
			out.append([h, s])
		var n := Dossier.last_count(record, h)
		if s == "confirm" and n >= Dossier.CITE_FROM:
			out.append([h, "evidence", n])
	return out


## One random line's key from the sets, or "" with none.
static func pick(sets: Array, rng: RandomNumberGenerator) -> String:
	return pick_line(sets, rng)[0]


## One random line from the sets as [key, format args], or ["", {}] with none.
static func pick_line(sets: Array, rng: RandomNumberGenerator) -> Array:
	if sets.is_empty():
		return ["", {}]
	var s: Array = sets[rng.randi() % sets.size()]
	return [chatter_key(s[0], s[1], rng.randi() % VARIANTS), {n = s[2]} if s.size() > 2 else {}]


## Chatter is overheard like a chat: only within the same range.
static func heard(distance: float) -> bool:
	return distance <= Chat.HEARD
