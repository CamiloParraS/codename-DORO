## Aigis Voice (ADR 0002): an LLM words Aigis's read of the Mission just played; it never decides anything.
## Node-free. facts() gathers what Aigis already decided, prompt() asks for it in one Voice, parse() takes the
## reply only when it passes every check, and fallback() says the same from Dossier lines when it doesn't.
class_name AigisVoice
extends RefCounted

const MAX_LINES := 3
const MAX_CHARS := 140  # a line wraps to at most three rows of the saw page's 540 px column

## The reply the model must give (JSON Schema). parse() checks it again: a schema is a request, not a promise.
const SCHEMA := {
	"type": "object",
	"properties": {
		"voice": {"type": "string", "enum": ["promachos", "nike", "pallas", "gorgo", "glaukopis"]},
		"lines": {"type": "array", "items": {"type": "string"}, "minItems": 1, "maxItems": MAX_LINES},
	},
	"required": ["voice", "lines"],
}
## How each Voice talks, from the Countermeasures it sponsors and its Briefing lines.
const MANNER := {
	promachos = "the front line: blunt, counts men and guns, wants more of both",
	nike = "victory: cold and efficient, keeps score, hates losing twice",
	pallas = "the watcher: calm, analytical, studies the intruder's habits",
	gorgo = "armour and dread: menacing, promises to be ready",
	glaukopis = "the bright eye: cameras and radio, suspicious of every voice",
}

static var _number := RegEx.create_from_string("\\d+(?:[.,]\\d+)?")
static var _speaker := RegEx.create_from_string("^[^:]{1,12}: ")  # a Briefing line's "Pallas: "


## What the model is told, from a record just through complete_mission (its `last` filled in) and the plan for
## the Mission it moves on to. Text in the current locale; keys left out when the record has nothing to say.
static func facts(after: Dictionary, plan: Dictionary) -> Dictionary:
	var last: Dictionary = after.get("last", {})
	var played := int(last.get("mission", after.mission - 1))
	var f := {
		mission = _tr("ui.mission.%d" % played),
		language = TranslationServer.get_locale().left(2),
		voice = plan.dominant,
		callsign = _tr(Dossier.callsign(after)),
		events = _events(last.get("counts", {})),
	}
	if int(last.get("counts", {}).get("kill", 0)) > 0:
		f.kills = int(last.counts.kill)
	var hot: Dictionary = last.get("hot", {})
	if not hot.is_empty():
		f.hotspot = {place = _tr("place.%d.%d" % [played, hot.enc]), n = hot.n, seconds = hot.secs}
	var bet: Dictionary = last.get("bet", {})
	if not bet.is_empty():
		f.last_forecast = {forecast = Dossier.bet_text(bet), got = bet.got, came_true = bet.won}
	if last.get("shifted", "") != "":
		f.dropped_habit = last.shifted
	if after.mission < Campaign.MISSIONS.size():
		f.next_mission = _tr("ui.mission.%d" % after.mission)
		f.next_countermeasures = plan.picks.map(func(p: Dictionary) -> Dictionary:  # the Briefing's hint line: translated
			return {countermeasure = _speaker.sub(_tr("brief.%s.hint.%s.%d" % [p.sponsor, p.habit, p.level]), ""), sponsor = p.sponsor})
		var next := Dossier.bet(after)
		if not next.is_empty():
			f.next_forecast = Dossier.bet_text(next)
	return f


## The request in words, provider-neutral: {system, user}. The user text is the facts as JSON.
static func prompt(f: Dictionary) -> Dictionary:
	var voice: String = f.voice
	var system := "\n".join([
		"You are Aigis, the AI that commands the guards in a stealth game, speaking to the intruder after a Mission.",
		"Speak as %s, one of Aigis's five Voices: %s." % [voice.capitalize(), MANNER.get(voice, "")],
		"Write 1 to %d short lines, each at most %d characters, in the language \"%s\"." % [MAX_LINES, MAX_CHARS, f.get("language", "en")],
		"Comment on what the intruder did and hint at what waits next. Address the intruder as \"you\"; call the guards \"ours\".",
		"Use only the facts given. Every number you write must appear in the facts, written as digits; never invent a count, a time or a name.",
		"A fact that is missing did not happen: don't mention it.",
		"The facts: events are what Aigis counted in the Mission just played (\"last time\" is that Mission); kills: guards killed.",
		"hotspot: the place where the intruder put n of ours down within that many seconds. last_forecast: what Aigis predicted for",
		"this Mission, what it got, and whether it came true. dropped_habit: a habit the intruder stopped using. next_countermeasures:",
		"what Aigis deploys in next_mission against the intruder, and which Voice asked for it. next_forecast: Aigis's prediction for it.",
		"No speaker name, no quotes, no markdown. Reply with JSON: {\"voice\": \"%s\", \"lines\": [...]}." % voice,
	])
	return {system = system, user = JSON.stringify(f)}


## The comment without a model, from lines the Briefing already has, all in the Dominant Voice: what it counted
## for the strongest Habit that says enough, how its last forecast went, and its close. Never empty.
static func fallback(after: Dictionary, plan: Dictionary) -> Dictionary:
	var lines := []
	var habits := Aigis.HABITS.duplicate()
	var points: Dictionary = after.get("points", {})
	habits.sort_custom(func(a: String, b: String) -> bool:
		var pa := int(points.get(a, 0))
		var pb := int(points.get(b, 0))
		return pa > pb or (pa == pb and Aigis.HABITS.find(a) < Aigis.HABITS.find(b)))
	for h: String in habits:
		var ev := Dossier.evidence(after, h)
		if not ev.is_empty():
			lines.append(_tr(ev[0]).format(ev[1]))
			break
	var bet: Dictionary = after.get("last", {}).get("bet", {})
	if not bet.is_empty():
		lines.append(_tr("brief.%s.bet.%s" % [plan.dominant, "won" if bet.won else "lost"]).format({bet = Dossier.bet_text(bet), got = bet.got}))
	lines.append(_tr("brief.%s.close" % plan.dominant))
	return {voice = plan.dominant, lines = lines.map(func(l: String) -> String: return _speaker.sub(l, ""))}


## A Mission's counts as the Briefing's evidence lines ("5 of ours taken from behind last time."), in Habit
## order: the model reads them in the player's language instead of English event names.
static func _events(counts: Dictionary) -> Array:
	var out := []
	for h: String in Aigis.HABITS:
		for e: String in Dossier.EVIDENCE[h]:
			if int(counts.get(e, 0)) > 0:
				out.append(_tr("brief.evidence.%s.last" % e).format({n = int(counts[e])}))
	return out


static func _tr(key: String) -> String:
	return String(TranslationServer.translate(key))


## The reply text as {voice, lines}, or {} when it fails a check: JSON with one of the five Voices and 1 to
## MAX_LINES non-blank lines of at most MAX_CHARS, and no number in them that the facts don't hold.
static func parse(text: String, facts: Dictionary) -> Dictionary:
	var json := JSON.new()  # not JSON.parse_string: a bad reply is expected, not an engine error
	var d: Variant = json.data if json.parse(text) == OK else null
	if not (d is Dictionary and d.get("voice") in Aigis.VOICES and d.get("lines") is Array):
		return {}
	var lines: Array = d.lines
	if lines.is_empty() or lines.size() > MAX_LINES:
		return {}
	var known := _numbers_in(facts)
	for l: Variant in lines:
		if not (l is String and l.strip_edges() != "" and l.length() <= MAX_CHARS):
			return {}
		for m in _number.search_all(l):
			if not m.get_string() in known:
				return {}
	return {voice = d.voice, lines = lines.map(func(l: String) -> String: return l.strip_edges())}


## Every number anywhere in the facts, as the text a line would write it.
static func _numbers_in(v: Variant, out := {}) -> Dictionary:
	if v is Dictionary:
		for k: Variant in v:
			_numbers_in(v[k], out)
	elif v is Array:
		for x: Variant in v:
			_numbers_in(x, out)
	elif v is int:
		out[str(v)] = true
	elif v is float:
		out[str(int(v)) if v == roundf(v) else str(v)] = true
	elif v is String:
		for m in _number.search_all(v):
			out[m.get_string()] = true
	return out
