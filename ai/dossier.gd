## Aigis's file on the Operative, node-free: what it can cite back at the player. Aigis.complete_mission keeps
## two optional record keys beside the Profile, and SaveSlots carries them:
##   seen: {event: count} over every completed Mission (the TRIGGERS events and kill)
##   last: the Mission just completed: {mission, counts: its tally's events, shifted: the Habit the Operative
##         dropped ("" for none), path: [x, y, ...] flat in diagram metres every PATH_EVERY s, marks: [[kind, t, x, y]],
##         bet: the forecast it made for that Mission, settled ({event, n, most, got, won}, or {}),
##         called: the callsign key it filed the Operative under before it}
## A Free mode Preset has neither, so its Briefing falls back to the plain lines.
## Evidence: the number behind a Habit, from the last Mission when it says enough, else the campaign's count.
class_name Dossier
extends RefCounted

## Per Habit, the tally events Aigis can cite, the first with enough behind it wins.
const EVIDENCE := {
	"stealth": ["quiet_down"],
	"combat": ["alert"],
	"headshots": ["headshot"],
	"takedowns": ["takedown"],
	"downs": ["fulton", "down_found", "woken"],
	"spoofing": ["spoof", "interrogated_voiceprint"],
}
const CITE_FROM := 2       # a count worth citing: one alone reads as chance (and keeps every line plural)
const MAX_PATH := 400      # trail points kept in a save; a longer trail is thinned evenly
const MARKS := ["down", "kill", "alert", "spotted"]
## The events Aigis bets on, in tie order; a bet asks for BET_SHARE of the last count again, rounded up.
const BET_EVENTS := ["takedown", "headshot", "quiet_down", "fulton", "down_found", "spoof", "alert"]
const BET_SHARE := 0.75
const CALLSIGNS := ["butcher", "none"]  # besides one per Habit


## The events a record keeps in `seen`.
static func tracked() -> Array:
	var out: Array = Aigis.TRIGGERS.keys()
	out.append("kill")
	return out


## seen plus one tally's tracked events: a new dictionary.
static func add_seen(seen: Dictionary, tally: Dictionary) -> Dictionary:
	var out := seen.duplicate()
	for e: String in tracked():
		var n := int(tally.get(e, 0))
		if n > 0:
			out[e] = int(out.get(e, 0)) + n
	return out


## The tracked events a tally had, missing and zero ones left out.
static func counts_of(tally: Dictionary) -> Dictionary:
	return add_seen({}, tally)


## The Habit the Operative stopped using: the strongest one at level 1 or more before the Mission that this
## Mission earned no points in, or "". gained: Aigis.mission_points for the Mission.
static func shifted(before: Dictionary, gained: Dictionary) -> String:
	var best := ""
	for h: String in Aigis.HABITS:
		var p := int(before.get(h, 0))
		if p >= Aigis.POINTS_PER_LEVEL and int(gained.get(h, 0)) == 0 and (best == "" or p > int(before.get(best, 0))):
			best = h
	return best


## Aigis's forecast for the next Mission, from the last one: the bet event it did most (CITE_FROM or more
## times), at least BET_SHARE of that count again; with none and no alarm, no alarm again (a ceiling of 0).
## {event, n, most: true when n is a ceiling}, or {} with no last Mission or nothing to bet on.
static func bet(record: Dictionary) -> Dictionary:
	var last: Dictionary = record.get("last", {})
	if last.is_empty():
		return {}
	var c: Dictionary = last.get("counts", {})
	var best := ""
	for e: String in BET_EVENTS:
		if int(c.get(e, 0)) >= CITE_FROM and (best == "" or int(c[e]) > int(c[best])):
			best = e
	if best != "":
		return {event = best, n = maxi(CITE_FROM, ceili(int(c[best]) * BET_SHARE)), most = false}
	if int(c.get("alert", 0)) == 0:
		return {event = "alert", n = 0, most = true}
	return {}


## A bet against the Mission's tally: the bet plus {got, won}, or {} for no bet.
static func settle(b: Dictionary, tally: Dictionary) -> Dictionary:
	if b.is_empty():
		return {}
	var got := int(tally.get(b.event, 0))
	var out := b.duplicate()
	out.got = got
	out.won = got <= int(b.n) if b.most else got >= int(b.n)
	return out


## The forecast as words: "bet.<event>" (or "bet.<event>.most") formatted with its n.
static func bet_text(b: Dictionary) -> String:
	return TranslationServer.translate("bet.%s%s" % [b.event, ".most" if b.most else ""]).format({n = int(b.n)})


## The name Aigis files the Operative under, as a key: "callsign.butcher" once the Lethality ratio reaches
## Gorgo's band, else the Habit with the most points ("callsign.<habit>", ties in Habit order), else
## "callsign.none" while nothing stands out.
static func callsign(record: Dictionary) -> String:
	var r := Aigis.lethality_ratio(record)
	if not is_nan(r) and r >= Aigis.GORGO_FROM:
		return "callsign.butcher"
	var best := ""
	var points: Dictionary = record.get("points", {})
	for h: String in Aigis.HABITS:
		if int(points.get(h, 0)) > 0 and (best == "" or int(points[h]) > int(points[best])):
			best = h
	return "callsign." + (best if best != "" else "none")


## What Aigis cites for a Habit: [line key, {n}], or [] when nothing says enough.
## "brief.evidence.<event>.last" when the last Mission had CITE_FROM or more, else ".total" from the campaign.
static func evidence(record: Dictionary, habit: String) -> Array:
	var last: Dictionary = record.get("last", {}).get("counts", {})
	var seen: Dictionary = record.get("seen", {})
	for when: String in ["last", "total"]:
		for e: String in EVIDENCE[habit]:
			var n := int((last if when == "last" else seen).get(e, 0))
			if n >= CITE_FROM:
				return ["brief.evidence.%s.%s" % [e, when], {n = n}]
	return []


## How often a Habit's events happened in the last Mission, for the guards' chatter.
static func last_count(record: Dictionary, habit: String) -> int:
	var last: Dictionary = record.get("last", {}).get("counts", {})
	var n := 0
	for e: String in EVIDENCE[habit]:
		n += int(last.get(e, 0))
	return n


## A Session log Mission's trail as the record keeps it: {path, marks}, the path thinned to MAX_PATH points
## and rounded to 0.1 m so it saves small.
static func trail(m: Dictionary) -> Dictionary:
	var pts: Array = m.get("path", [])
	var step := maxi(1, ceili(pts.size() / float(MAX_PATH)))
	var path := []
	for i in range(0, pts.size(), step):
		path.append_array([snappedf(pts[i].x, 0.1), snappedf(pts[i].y, 0.1)])
	var marks := []
	for k: Array in m.get("marks", []):
		marks.append([k[0], snappedf(k[1], 0.1), snappedf(k[2].x, 0.1), snappedf(k[2].y, 0.1)])
	return {path = path, marks = marks, every = SessionLog.PATH_EVERY * step}


# ----- save cleaning: a slot file is untrusted, a bad key drops it -----

## seen as read from JSON: event -> int, unknown events and bad values dropped.
static func clean_seen(v: Variant) -> Dictionary:
	var out := {}
	if v is Dictionary:
		for e: String in tracked():
			if v.get(e) is float and v[e] > 0:
				out[e] = int(v[e])
	return out


## last as read from JSON, or {} when it isn't one.
static func clean_last(v: Variant) -> Dictionary:
	if not (v is Dictionary and v.get("mission") is float and v.get("shifted", "") is String):
		return {}
	var shift: String = v.get("shifted", "")
	var out := {mission = int(v.mission), counts = clean_seen(v.get("counts")), shifted = shift if shift in Aigis.HABITS else ""}
	var b: Variant = v.get("bet")
	if b is Dictionary and b.get("event") in BET_EVENTS and b.get("most") is bool and b.get("won") is bool \
			and b.get("n") is float and b.get("got") is float:
		out.bet = {event = b.event, n = int(b.n), most = b.most, got = int(b.got), won = b.won}
	var called: Variant = v.get("called")
	if called is String and called.trim_prefix("callsign.") in Aigis.HABITS + CALLSIGNS:
		out.called = called
	var path: Variant = v.get("path")
	if path is Array and path.size() % 2 == 0 and path.all(func(x: Variant) -> bool: return x is float):
		out.path = path
		out.every = v.every if v.get("every") is float and v.every > 0.0 else SessionLog.PATH_EVERY
		var marks: Variant = v.get("marks")
		out.marks = marks.filter(func(k: Variant) -> bool:
			return k is Array and k.size() == 4 and k[0] in MARKS and k.slice(1).all(func(x: Variant) -> bool: return x is float)) if marks is Array else []
	return out
