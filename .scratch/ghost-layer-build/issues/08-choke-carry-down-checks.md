# 08: Choke takedown, carry, Down checks

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Operative can sneak up and choke a guard, carry the Neutralized body over the shoulder to hide it, and guards who spot a Down guard walk over, check and wake them.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] Prompt "E choke" appears within ~1.5 m of a non-alerted guard when outside their front cone; the choke takes 2 s and Neutralizes
- [ ] Neutralized guards wake after ~90 s; choking again resets the timer
- [ ] E toggles carry: fixed shoulder pose, walk speed (slower crouched), detection treats the Operative as standing and walking
- [ ] Guards see Down guards with the same meter: suspicion → walk over → wake a Neutralized guard (who joins in suspicion and remembers nothing); the dead-guard alert hooks in once kills exist
- [ ] The Down-guard check is covered by an alert state machine test
