# 22: Mission flow + campaign loop

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** A campaign plays end to end in memory: each Mission is data (Area, objective steps, Targets, index), objectives advance through steps including intel pickups, and completing one goes to the post-Mission screen and on to the next Mission with its new plan.

**Blocked by:** 14, 18

**Status:** ready-for-agent

- [ ] Mission data defines the Area, ordered objective steps, Targets and Mission index (which sets cap and budget)
- [ ] Extract-intel pickups complete objective steps; each step is a Checkpoint
- [ ] The flow goes placeholder Briefing → Mission → post-Mission screen → next Mission, linear with no replays
- [ ] Mission 1 in the Harbour is completable with intel extraction
- [ ] The current objective is shown on a minimal pause screen
