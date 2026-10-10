# 11: Glaukopis + radial radio

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Operative opens a slowed-time radial radio, sends a Spoofed transmission in a guard's voice, and guards obey, unless Glaukopis exposes it. In that case the recipient says "You don't sound right" and searches near where the Operative transmitted from.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] Pure, node-free Glaukopis judge (judge(facts, commit) → doubt, exposed, reasons) with one test per doubt rule in the spec's table, the 40 threshold, and commit = false changing nothing
- [ ] Q toggles a radial menu in E's white/grey with time slowed: speaker → recipient (guard or All units) → order (go check a place, hold position, all clear) → place → confirm; LMB confirms, RMB back, 1–9 shortcuts, Q/Esc close
- [ ] Guards carry out a believed order
- [ ] Exposure flags the Voiceprint for good, recipients search within ±5 m of the transmit point, and the recipient's "<X>? You don't sound right. Who is this?" line plays; no other player-facing feedback
- [ ] Glaukopis's doubt and reasons are available for the debug overlay
