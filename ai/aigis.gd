## Aigis's between-Missions brain (ADR-0001): folds a completed Mission into the campaign record,
## plans the next Mission's Countermeasures through the five Voices, and resolves the ending.
## Pure, node-free and deterministic: scenes build the inputs and only read the results.
##
## Record: {mission: the next Mission's index (0, 1, 2 = Missions 1-3, 3 = Core, 4 = campaign done),
##          points: {habit: int}, lethality: int, denominator: int}. Plain data, ready to save.
## Tally:  one Mission's event counts, missing keys = 0. The TRIGGERS events feed the Habits;
##         kill and target_kill feed Lethality; spawned (guards actually spawned) and targets feed
##         its denominator.
## Ratio:  Lethality ÷ denominator (lethality_ratio), NAN while undefined (before Mission 1).
class_name Aigis
extends RefCounted

## In Habit-table order, which breaks every tie.
const HABITS: Array[String] = ["stealth", "combat", "headshots", "takedowns", "downs", "spoofing"]
const VOICES: Array[String] = ["promachos", "nike", "pallas", "gorgo", "glaukopis"]

## Each Habit's Countermeasure ladder: [sponsor Voice, what deploys] for L1, L2, L3.
## A step's id is "<habit>.<level>", e.g. "headshots.2".
const LADDERS := {
	"stealth": [["glaukopis", "security cameras"], ["promachos", "one extra patrol"], ["gorgo", "overwatch sentries"]],
	"combat": [["gorgo", "vests"], ["promachos", "+2 guards"], ["promachos", "2 reinforcements per alert"]],
	"headshots": [["gorgo", "helmets on 33%"], ["gorgo", "helmets on 66%"], ["gorgo", "helmets on 100%"]],
	"takedowns": [["pallas", "guards turn around more often"], ["gorgo", "patrols in pairs"], ["nike", "slow, noisy choke"]],
	"downs": [["pallas", "random HQ poll"], ["nike", "found Down guard = instant alert"], ["pallas", "targeted HQ poll"]],
	"spoofing": [["glaukopis", "Glaukopis threshold 40 -> 25"], ["glaukopis", "radio callback"], ["glaukopis", "single-use Voiceprints"]],
}

const CAPS: Array[int] = [0, 1, 2, 3]     # Habit level cap by Mission index
const BUDGETS: Array[int] = [0, 2, 4, 6]  # response levels Aigis may deploy by Mission index
const POINTS_PER_LEVEL := 100

## Tally event -> [Habit, points]. Tuned during the build; the campaign simulation test checks it.
const TRIGGERS := {
	"quiet_down": ["stealth", 15],      # a guard put Down while no alert is active
	"alert": ["combat", 30],            # an alert raised; any alert also means "not a ghost Mission"
	"loud_shot": ["combat", 5],
	"alert_kill": ["combat", 15],       # a kill during an alert
	"headshot": ["headshots", 20],      # tranq or rifle
	"takedown": ["takedowns", 20],      # choke or kill from behind
	"down_found": ["downs", 25],        # a guard found a Down guard
	"woken": ["downs", 15],             # a Neutralized guard woken by another
	"spoof": ["spoofing", 20],          # a Spoofed transmission sent
	"spoof_exposed": ["spoofing", 20],  # extra weight when it was exposed
}
const NO_ALERT_POINTS := 50  # Stealth points for a Mission completed with no alert
const TUG_SHARE := 0.3       # a side wins the tug of war leading by 30% of both sides' points
const TUG_LOSS := 50         # points the losing side gives up
const DECAY := 50            # points an unused Habit (not Stealth or Combat) loses: half a level

const GUARD_DEATH := 1       # Lethality per guard killed, and the denominator per guard spawned
const TARGET_DEATH := 3      # the same for a Target

const DOMINANT_WEIGHT := 2.0
const OTHER_WEIGHT := 1.0
const NIKE_FROM := 0.10      # ratio bands; a value on a threshold goes to the higher band
const GORGO_FROM := 0.40

## Free mode Presets: Habit levels (missing = 0) and a Lethality ratio (NAN = undefined).
const PRESETS := {
	"clean_slate": {"levels": {}, "ratio": NAN},
	"ghost": {"levels": {"stealth": 3, "takedowns": 2, "downs": 2}, "ratio": 0.0},
	"trickster": {"levels": {"spoofing": 3, "stealth": 1, "headshots": 2}, "ratio": 0.25},
	"butcher": {"levels": {"combat": 3, "headshots": 3, "takedowns": 1}, "ratio": 0.6},
}


static func new_record() -> Dictionary:
	return {"mission": 0, "points": _zeros(), "lethality": 0, "denominator": 0}


## A Preset's Profile as points: level × 100 per Habit.
static func preset_profile(preset: String) -> Dictionary:
	return _level_points(PRESETS[preset].levels)


static func _level_points(levels: Dictionary) -> Dictionary:
	var out := _zeros()
	for h: String in levels:
		out[h] = levels[h] * POINTS_PER_LEVEL
	return out


## A Preset as a record about to play mission_index (Free mode). The ratio is stored as Lethality
## out of 100 (an undefined ratio leaves the denominator at 0).
static func preset_record(preset: String, mission_index: int) -> Dictionary:
	return custom_record(PRESETS[preset].levels, PRESETS[preset].ratio, mission_index)


## The same for Free mode's Custom sliders: any Habit levels and ratio.
static func custom_record(levels: Dictionary, ratio: float, mission_index: int) -> Dictionary:
	var r := {"mission": mission_index, "points": _level_points(levels), "lethality": 0, "denominator": 0}
	if not is_nan(ratio):
		r.lethality = roundi(ratio * 100)
		r.denominator = 100
	return r


## A Habit's level as a Mission sees it: points ÷ 100, held to that Mission's cap.
static func level(points: int, mission_index: int) -> int:
	return mini(floori(points / float(POINTS_PER_LEVEL)), cap(mission_index))


## A Mission's Habit-level cap. Past the Core (4 = campaign done) reads as the Core.
static func cap(mission_index: int) -> int:
	return CAPS[_last(mission_index)]


## The most points a completed Mission carries out: the next Mission's cap × 100 + 99.
static func carry_max(completed_index: int) -> int:
	return (cap(carry_index(completed_index)) + 1) * POINTS_PER_LEVEL - 1


## The Mission whose cap holds the points carried out of a completed one: the next Mission, so
## Mission 1 can carry L1 into Mission 2. The Core has no next Mission and keeps its own cap.
static func carry_index(completed_index: int) -> int:
	return _last(completed_index + 1)


## The points a tally earns per Habit (before the tug of war and decay), for the overlay too.
static func mission_points(tally: Dictionary) -> Dictionary:
	var out := _zeros()
	for event: String in TRIGGERS:
		out[TRIGGERS[event][0]] += TRIGGERS[event][1] * int(tally.get(event, 0))
	if tally.get("alert", 0) == 0:
		out.stealth += NO_ALERT_POINTS
	return out


## Folds a completed Mission into the record and returns a new one; the input is left untouched.
## An aborted or quit Mission is never passed here: its tally is simply discarded.
static func complete_mission(record: Dictionary, tally: Dictionary) -> Dictionary:
	var out := record.duplicate(true)
	var p: Dictionary = out.points
	for h in HABITS:
		p[h] = int(p.get(h, 0))
	var gained := mission_points(tally)
	match _tendency(tally, gained):
		"stealth":
			p.stealth += gained.stealth
			p.combat -= TUG_LOSS
		"combat":
			p.combat += gained.combat
			p.stealth -= TUG_LOSS
		_:
			p.stealth += gained.stealth
			p.combat += gained.combat
	for h in HABITS.slice(2):
		p[h] += gained[h] if gained[h] > 0 else -DECAY
	var most := carry_max(record.mission)
	for h in HABITS:
		p[h] = clampi(p[h], 0, most)
	out.lethality += GUARD_DEATH * int(tally.get("kill", 0)) + TARGET_DEATH * int(tally.get("target_kill", 0))
	out.denominator += GUARD_DEATH * int(tally.get("spawned", 0)) + TARGET_DEATH * int(tally.get("targets", 0))
	out.mission += 1
	return out


## Lethality ÷ denominator, or NAN before any Mission is completed.
static func lethality_ratio(record: Dictionary) -> float:
	if record.denominator == 0:
		return NAN
	return float(record.lethality) / record.denominator


## The Lethality band, which is the Dominant Voice and, after the Core, the ending.
static func resolve_ending(ratio: float) -> String:
	if is_nan(ratio) or ratio < NIKE_FROM:
		return "pallas"
	if ratio < GORGO_FROM:
		return "nike"
	return "gorgo"


## The Voices' plan for a Mission. profile: points per Habit; ratio: the Lethality ratio.
## mission_index 4 (campaign done) plans as the Core.
## Returns {weights, dominant, budget, pinned, picks, unlocked, deployed, briefing_keys}:
## - unlocked / deployed: level per Habit (deployed steps always run up the ladder from L1)
## - picks, in deploy order: {step, habit, level, sponsor, score, candidates}; candidates are every
##   Habit's next unlocked step with its score ([] for the pinned Habit's steps, which aren't scored
##   against anything)
## - pinned: the strongest Habit, answered in full first ("" when no Habit has a level)
static func plan_mission(profile: Dictionary, ratio: float, mission_index: int) -> Dictionary:
	var dominant := resolve_ending(ratio)
	var weights := {}
	for v in VOICES:
		weights[v] = DOMINANT_WEIGHT if v == dominant else OTHER_WEIGHT
	var unlocked := {}
	var deployed := {}
	for h in HABITS:
		unlocked[h] = level(int(profile.get(h, 0)), mission_index)
		deployed[h] = 0
	var ranked := HABITS.duplicate()
	ranked.sort_custom(func(a: String, b: String) -> bool: return _stronger(a, b, unlocked, profile))
	var budget: int = BUDGETS[_last(mission_index)]
	var left := budget
	var picks := []

	var pinned: String = ranked[0] if unlocked[ranked[0]] > 0 else ""
	while pinned and deployed[pinned] < unlocked[pinned] and left > 0:
		deployed[pinned] += 1
		var pick := _step(pinned, deployed[pinned], profile, weights)
		pick.candidates = []
		picks.append(pick)
		left -= 1

	while left > 0:
		var candidates := []
		for h in HABITS:
			if deployed[h] < unlocked[h]:
				candidates.append(_step(h, deployed[h] + 1, profile, weights))
		if candidates.is_empty():
			break
		var best: Dictionary = candidates[0]
		for c: Dictionary in candidates:
			if c.score > best.score:  # strictly greater: a tie stays with the earlier Habit
				best = c
		var pick := best.duplicate()
		pick.candidates = candidates
		picks.append(pick)
		deployed[best.habit] += 1
		left -= 1

	# Pallas names the top 1-2 answered Habits, each followed by the sponsor of its highest deployed
	# step; Nike speaks up when the noisy choke is deployed; the Dominant Voice closes.
	var keys := []
	for h: String in ranked.filter(func(x: String) -> bool: return deployed[x] > 0).slice(0, 2):
		keys.append("brief.pallas.habit.%s" % h)
		keys.append("brief.%s.hint.%s.%d" % [LADDERS[h][deployed[h] - 1][0], h, deployed[h]])
	if deployed.takedowns == 3:
		keys.append("brief.nike.noisy_choke")
	if deployed.stealth > 0:
		keys.append("brief.glaukopis.head_check")
	if deployed.spoofing > 0:
		keys.append("brief.glaukopis.radio_check")
	keys.append("brief.%s.close" % dominant)

	return {
		"weights": weights, "dominant": dominant, "budget": budget, "pinned": pinned, "picks": picks,
		"unlocked": unlocked, "deployed": deployed, "briefing_keys": keys,
	}


## A Mission index held to the Core: campaign done (4) plans and caps like the Core.
static func _last(mission_index: int) -> int:
	return clampi(mission_index, 0, CAPS.size() - 1)


static func _zeros() -> Dictionary:
	var out := {}
	for h in HABITS:
		out[h] = 0
	return out


## "stealth", "combat" or "draw". No alert means Stealth; otherwise the side leading by the margin.
## (An alert alone is worth 30 Combat points, so the margin is never trivially small.)
static func _tendency(tally: Dictionary, gained: Dictionary) -> String:
	if tally.get("alert", 0) == 0:
		return "stealth"
	var lead: int = gained.stealth - gained.combat
	var margin: float = TUG_SHARE * (gained.stealth + gained.combat)
	if lead >= margin:
		return "stealth"
	if -lead >= margin:
		return "combat"
	return "draw"


## Strongest first: higher level, then more points, then Habit-table order.
static func _stronger(a: String, b: String, unlocked: Dictionary, profile: Dictionary) -> bool:
	if unlocked[a] != unlocked[b]:
		return unlocked[a] > unlocked[b]
	var pa := int(profile.get(a, 0))
	var pb := int(profile.get(b, 0))
	if pa != pb:
		return pa > pb
	return HABITS.find(a) < HABITS.find(b)


static func _step(habit: String, lvl: int, profile: Dictionary, weights: Dictionary) -> Dictionary:
	var sponsor: String = LADDERS[habit][lvl - 1][0]
	return {
		"step": "%s.%d" % [habit, lvl], "habit": habit, "level": lvl, "sponsor": sponsor,
		"score": weights[sponsor] * int(profile.get(habit, 0)),
	}
