# 06: Hearing + knock

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Guards hear the Operative: running footsteps within 6 m and a knock (V) within 10 m send them to suspicion at the noise, never to alert.

**Blocked by:** 05

**Status:** done

- [x] Running footsteps are heard within 6 m, walking and crouching are silent; no wall occlusion
- [x] V knocks from the Operative's position, 10 m, with a 1 s cooldown
- [x] Noise only causes suspicion at the source; covered by an alert state machine test
