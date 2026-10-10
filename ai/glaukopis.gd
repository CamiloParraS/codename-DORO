## Glaukopis, Aigis's in-Mission Spoofing judge: deterministic doubt points for a Spoofed transmission.
## Pure and node-free. The scene gathers the facts; this decides whether the transmission holds up.
## One instance per Mission (it remembers flagged Voiceprints and the transmissions so far).
class_name Glaukopis
extends RefCounted

const EXPOSE_AT := 40          # doubt at or above this exposes the transmission
const WINDOW := 60.0           # seconds a transmission counts toward "too many"
const PER_RECENT := 15         # doubt per earlier transmission inside WINDOW
const CONTRADICT_TIME := 30.0  # a different order to the same guard this soon contradicts the last one
const FRESH_ALERT := 15.0      # "all clear" this soon after an alert is the wrong time

var expose_at := EXPOSE_AT     # Spoofing L1 lowers it
var flagged: Array[String] = []  # Voiceprints exposed for good
var history: Array = []        # [{now, recipients, order, place}]
var last := {}                 # last committed judgement, for the debug overlay


## facts: {now (s), speaker, recipients (Array of names), all_units (bool), order ("go" / "hold" /
## "all_clear"), place, seen_by (recipients who can see the speaker), speaker_known_down (some guard
## knows the speaker is Down), sees_operative (recipients who see the Operative), since_alert (s since
## a guard was last alerted, INF if never), speaker_busy (the speaker is suspicious, alerted or searching)}.
## commit = false only previews: nothing is remembered or flagged.
## Returns {doubt, exposed, reasons: Array of [points, text]}.
func judge(facts: Dictionary, commit := true) -> Dictionary:
	var reasons: Array = []
	var sp: String = facts.speaker
	var all_clear: bool = facts.order == "all_clear"
	if sp in flagged:
		reasons.append([100, "%s's Voiceprint is already flagged" % sp])
	if sp in facts.recipients:
		reasons.append([100, "%s is ordering themself" % sp])
	if not facts.seen_by.is_empty():
		reasons.append([60, "%s can see %s isn't on the radio" % [_list(facts.seen_by), sp]])
	if facts.speaker_known_down:
		reasons.append([60, "%s is known to be Down" % sp])
	if all_clear and not facts.sees_operative.is_empty():
		reasons.append([100, "all clear while %s sees the intruder" % _list(facts.sees_operative)])
	if all_clear and facts.since_alert < FRESH_ALERT:
		reasons.append([30, "all clear %d s after an alert" % floori(facts.since_alert)])
	if facts.speaker_busy:
		reasons.append([30 if all_clear else 15, "%s is busy searching" % sp])
	if facts.all_units:
		reasons.append([10, "a guard ordering all units"])

	var recent := 0
	for h in history:
		var ago: float = facts.now - h.now
		if ago >= WINDOW:
			continue
		recent += 1
		var same: Array = h.recipients.filter(func(r): return r in facts.recipients)
		if ago < CONTRADICT_TIME and not same.is_empty() and (h.order != facts.order or h.place != facts.place):
			reasons.append([30, "contradicts the order %s got %d s ago" % [_list(same), floori(ago)]])
	if recent > 0:
		reasons.append([PER_RECENT * recent, "%d transmission(s) in the last minute" % recent])

	var doubt := 0
	for r in reasons:
		doubt += r[0]
	var out := {doubt = doubt, exposed = doubt >= expose_at, reasons = reasons}
	if commit:
		history.append({now = facts.now, recipients = facts.recipients, order = facts.order, place = facts.place})
		if out.exposed and sp not in flagged:
			flagged.append(sp)
		last = out
	return out


static func _list(names: Array) -> String:
	return ", ".join(PackedStringArray(names))
