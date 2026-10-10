# 06: Hearing + knock

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Guards hear the Operative: running footsteps within 6 m and a knock (V) within 10 m send them to suspicion at the noise, never to alert.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] Running footsteps are heard within 6 m, walking and crouching are silent; no wall occlusion
- [ ] V knocks from the Operative's position, 10 m, with a 1 s cooldown
- [ ] Noise only causes suspicion at the source; covered by an alert state machine test
