# 02: Alert beat

**Spec:** decisions in [polish map](../../polish/map.md); see [alert loop prototype](../../polish/issues/03-alert-loop-prototype.md) and [stings research](../../polish/research/stings.md). Prototype branch `prototype/alert-loop` is throwaway reference.

**What to build:** Going from patrol to suspicion, alert, evasion and back reads instantly: a ~0.2 s hit-stop on the alert, a "?" blip on suspicion, a "!" sting on alert, and a relief cue when Evasion ends, with the existing phase chips as the countdown.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Auditioned and approved CC0 stings (Kenney picks or alternates) replace the rejected ones; nothing horror-toned
- [ ] Hit-stop restores time scale reliably, including on death or pause during it
- [ ] Each of the four beats is distinct by sound alone
- [ ] `CREDITS.md` updated for every file used
