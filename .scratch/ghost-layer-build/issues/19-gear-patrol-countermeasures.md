# 19: Gear and patrol Countermeasures

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Every Stealth, Combat, Headshots and Takedowns Countermeasure step deploys and is visible in the world when planned.

**Blocked by:** 13, 16, 17

**Status:** ready-for-agent

- [x] Stealth L2 extra patrol, L3 overwatch sentries on high points
- [x] Combat L1 vests (stop tranq body shots, rifle body hits 2 → 4), L2 +2 guards, L3 2 reinforcements from the road entry once per alert
- [x] Headshots helmets at 33/66/100%
- [x] Takedowns L1 guards turn around more often, L2 patrols in pairs, L3 choke takes 3 s and makes noise within 6 m (the kill stays 0.5 s)
- [x] Each step is checked by loading a Preset in Free mode

## Comments

- No fixed Preset reaches Takedowns L3 (or Downs L2/L3), so Free mode's Custom sliders (ticket 33's criterion) landed with this ticket to load them. A Checkpoint restore now removes reinforcements that arrived since, and reinforcements are named `GuardRoad<n>`.
