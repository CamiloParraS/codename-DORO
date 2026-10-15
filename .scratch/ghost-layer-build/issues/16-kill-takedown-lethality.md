# 16: Kill takedown + Lethality

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Operative can kill from behind with a dedicated key, and every death the Operative causes silently adds to Lethality: shown only in the overlay, folded into the campaign on completion.

**Blocked by:** 15, 14

**Status:** ready-for-agent

- [x] The prompt reads "E choke · X kill"; X kills in 0.5 s under the same conditions as the choke
- [x] Each death caused by the Operative adds 1 (Targets will add 3), including killing a Neutralized guard
- [x] The denominator counts guards actually spawned in the Mission (extras and reinforcements included)
- [x] Lethality is not shown on the HUD or post-Mission screen; F3 shows it
