# Spoofing prototype

Type: prototype
Status: resolved
Blocked by: 04

## Question

Is the Spoofing loop fun and clear? Capture a Voiceprint from a guard → open the radio menu → send a Spoofed transmission (order + target) → patrols react → Glaukopis checks how plausible it is (wrong time, wrong Voiceprint, contradictory orders, too many in a row) and can expose it. How does the player find out a transmission was exposed?

## Comments

- 2026-10-09: playable prototype at `res://areas/proto_spoof/` (open `proto_spoof.tscn`, F6). Throwaway; it moves to branch `prototype/spoofing` once the verdict is in. Built on the stealth-core copy, plus Guard D as a sentry on the extraction point. Capture by eavesdropping (6 m, 2.5 s of a guard's radio check-in). Q opens the radio menu (Voiceprint → recipient → order → place → confirm). Glaukopis is node-free in `proto_glaukopis.gd`: doubt points (Voiceprint already flagged, ordering yourself, a recipient can see the speaker, all clear while a recipient sees the Operative or soon after an alert, speaker busy, all units, a contradicting order, recent transmissions); 40+ exposes it, flags the Voiceprint and sends the recipients to search near the Operative. Toggles under test: F1 exposure feedback (Glaukopis on the radio / guards' chatter / silent), F6 risk preview in the menu, F7 radio pauses the game. Waiting for the playtest.
- 2026-10-09: playtested. Prototype captured on branch `prototype/spoofing` and removed from main.

## Answer

Yes: the Spoofing loop is fun and challenging. Validated as the baseline for the spec:

- **Capture:** eavesdrop. Guards radio a routine check-in every 20–30 s (shown as ((·)) over the head and as a line in the radio log). Staying within 6 m during 2.5 s of a check-in records the Voiceprint. Partial progress carries over between check-ins. Getting close enough is the tension.
- **Sending:** speaker (Voiceprint) → recipient (one guard or All units) → order (go check a place / hold position / all clear, stand down) → place → confirm. The three orders and the four named places were enough.
- **Glaukopis's check:** deterministic doubt points, exposed at 40+. The rules felt fair and readable as they are: Voiceprint already flagged +100, speaker = recipient +100, a recipient can see the speaker +60, all clear while a recipient sees the Operative +100, all clear < 15 s after an alert +30, speaker busy searching +30 (all clear) / +15 (other orders), All units +10, contradicts an order the same guard got < 30 s ago +30, +15 per transmission in the last 60 s. Pure, node-free module: `proto_glaukopis.gd` on the prototype branch, `judge(facts, commit)` returns `{doubt, exposed, reasons}`; the scene gathers the facts.
- **Consequences of exposure:** the Voiceprint is flagged for good, and the recipients search a spot near where the Operative transmitted from (radio triangulation, ±5 m).
- **How the player finds out (the ticket's question): guards' chatter.** The recipient says "<X>? You don't sound right. Who is this?" over the radio and over their head, then goes searching. No Glaukopis announcement or banner, no "flagged" mark in the Voiceprint list. Beat the explicit Glaukopis radio line and the silent variant.
- **Radio menu: a radial menu with time slowed**, not a paused list and not real time. Not prototyped; take it as the spec's default (radial menu shape and slow-motion factor are build-time tuning).
- **Doubt preview: debug only.** Glaukopis's doubt score and reasons go in the debug overlay, never in the player's radio menu.
- **Carry-forward, not decided here:** whether a Down guard's Voiceprint can be used (and how much doubt that adds) depends on the combat verbs. Default for the spec: +60 if any guard knows the speaker is Down.
