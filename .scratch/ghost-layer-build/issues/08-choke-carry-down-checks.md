# 08: Choke takedown, carry, Down checks

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Operative can sneak up and choke a guard, carry the Neutralized body over the shoulder to hide it, and guards who spot a Down guard walk over, check and wake them.

**Blocked by:** 05

**Status:** done

- [x] Prompt "E choke" appears within ~1.5 m of a non-alerted guard when outside their front cone; the choke takes 2 s and Neutralizes
- [x] Neutralized guards wake after ~90 s; choking again resets the timer
- [x] E toggles carry: fixed shoulder pose, walk speed (slower crouched), detection treats the Operative as standing and walking
- [x] Guards see Down guards with the same meter: suspicion → walk over → wake a Neutralized guard (who joins in suspicion and remembers nothing); the dead-guard alert hooks in once kills exist
- [x] The Down-guard check is covered by an alert state machine test

## Comments

- The wake clock pauses while a guard is carried, on purpose: a body on the shoulder can't wake mid-carry. A carried guard is never checked or woken by another guard.
- "Choking again" is the pickup: E on a Neutralized guard hoists it and re-chokes it, so its 90 s start over (E twice resets the clock without moving the body). No separate 2 s re-choke.
