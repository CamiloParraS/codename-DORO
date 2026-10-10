# 11: Glaukopis + radial radio

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

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
