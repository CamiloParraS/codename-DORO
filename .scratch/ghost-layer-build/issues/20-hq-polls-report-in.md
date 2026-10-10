# 20: HQ polls + Report in + instant alert

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Downs ladder makes hiding bodies insufficient: HQ polls guards on the radio, found Down guards raise an instant alert, and the Operative can answer a poll with a "Report in" Spoofed transmission.

**Blocked by:** 13, 11

**Status:** ready-for-agent

- [ ] L1: about every 45 s HQ radios "<X>, report" to a random living guard, weighted toward Down guards; no answer in ~10 s sends the nearest guard to X's last position in suspicion
- [ ] L2: a found Down guard means an instant alert with no check (tested in the alert module)
- [ ] L3: HQ polls the guard nobody has seen for the longest, using a low-rate guard-on-guard sight check (fallback: random poll every 20 s)
- [ ] A fourth radio order, "Report in", answers a pending poll as X with X's Voiceprint, judged by Glaukopis
