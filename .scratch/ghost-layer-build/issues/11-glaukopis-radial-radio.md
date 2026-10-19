# 11: Glaukopis + radial radio

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The Operative opens a slowed-time radial radio, sends a Spoofed transmission in a guard's voice, and guards obey, unless Glaukopis exposes it. In that case the recipient says "You don't sound right" and searches near where the Operative transmitted from.

**Blocked by:** 10

**Status:** done

- [x] Pure, node-free Glaukopis judge (judge(facts, commit) → doubt, exposed, reasons) with one test per doubt rule in the spec's table, the 40 threshold, and commit = false changing nothing
- [x] Q toggles a radial menu in E's white/grey with time slowed: speaker → recipient (guard or All units) → order (go check a place, hold position, all clear) → place → confirm; LMB confirms, RMB back, 1–9 shortcuts, Q/Esc close
- [x] Guards carry out a believed order
- [x] Exposure flags the Voiceprint for good, recipients search within ±5 m of the transmit point, and the recipient's "<X>? You don't sound right. Who is this?" line plays; no other player-facing feedback
- [x] Glaukopis's doubt and reasons are available for the debug overlay

## Comments

- 2026-10-10: built. `ai/glaukopis.gd` (pure judge, `tests/test_glaukopis.gd`), `ui/radio/radio_menu.gd` (node-free steps, `tests/test_radio_menu.gd`) and `ui/radio/radio.gd` (the radial in HudLayer: gathers the facts, slows time to 0.25, applies the verdict). Guards follow believed orders through a new "Radio order" branch in `guard_tree.tres`. Decisions: "all clear < 15 s after an alert" counts from the last moment any guard was in ALERT; "a recipient can see the speaker" and "all clear while a recipient sees the Operative" count once, not per recipient; an alerted guard ignores go/hold (only all clear stands it down); "any guard knows the speaker is Down" means some guard has had the Down speaker in sight (`Guard.known_down`, cleared on waking). The debug overlay reads `get_first_node_in_group("radio").glaukopis.last`. `expose_at` is a var so Spoofing L1 can set 25.
- 2026-10-10 (review fixes): "Contradicts an order the same guard got < 30 s ago" now adds +30 at most once per judgement, compared against each recipient's latest order from the last 30 s, and only orders that guard actually took count: an exposed transmission records no takers, and `radio.gd` drops the recipients who refused or were Down when they answer (`Glaukopis.history[i].accepted`). Every Down guard in a guard's sight is now `known_down` (before, only the strongest sighting). A believed go/hold gives its own reason ("X sent it to check a place", "X told it to hold position"), even to a patrolling guard. Voiceprint capture now needs the ((·)) mark (`Checkin.on_air`: a check-in by a guard on PATROL), so check-ins during suspicion, ALERT or EVASION don't record; radio acks and the "You don't sound right" line are subtitles only, with no ((·)) and no capture. Decision kept: "speaker busy searching" still means any state but PATROL (suspicious, alerted or searching).
