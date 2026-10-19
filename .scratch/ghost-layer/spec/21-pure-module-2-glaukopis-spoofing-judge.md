# Implementation Decisions: Pure module 2: Glaukopis (Spoofing judge)

`judge(facts, commit) -> {doubt, exposed, reasons}`. The scene gathers the facts. Deterministic doubt points; exposed at **40+** (**25+** with Spoofing L1):

| Fact | Doubt |
|---|---|
| Voiceprint already flagged | +100 |
| Speaker is the recipient | +100 |
| A recipient can see the speaker | +60 |
| Any guard knows the speaker is Down | +60 |
| "All clear" while a recipient sees the Operative | +100 |
| "All clear" < 15 s after an alert | +30 |
| Speaker busy searching | +30 for "all clear", +15 for other orders |
| Recipient is All units | +10 |
| Contradicts an order the same guard got < 30 s ago | +30 |
| Each transmission in the last 60 s | +15 |

- Orders: go check a place, hold position, all clear/stand down, **Report in** (answers a pending HQ poll as the polled guard and needs that guard's Voiceprint). Four named places per Area.
- Exposed: the Voiceprint is flagged for good; the recipients search a spot within ±5 m of where the Operative transmitted from; the recipient says the "You don't sound right" line. There is no other feedback to the player. Doubt and reasons go only to the debug overlay.
- Spoofing L2 callback: after a transmission, the recipient radios the speaker. A live speaker who is up denies it, which exposes the transmission. A Down speaker doesn't answer (the +60 rule applies only if some guard knows they're Down).
- Spoofing L3: a Voiceprint is flagged after one use, whether or not it was exposed.
- Capture: within 6 m during 2.5 s of a check-in; partial progress carries over between check-ins. Voiceprints never carry between Missions and roll back with Checkpoints.
- Radio UI: a radial menu with time slowed (speaker → recipient → order → place → confirm). The shape and slow-motion factor are tuned during the build.
