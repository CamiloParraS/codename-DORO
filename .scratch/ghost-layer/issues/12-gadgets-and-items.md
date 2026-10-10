# Gadgets and items

Type: grilling
Status: resolved
Blocked by: 06, 08

## Question

What does the Operative carry besides the two weapons settled in [Combat verbs and Lethality](07-combat-verbs-lethality.md), if anything? HUD E has one item card ([PSX look and HUD prototype](06-psx-look-and-hud-prototype.md)), and [Operator profile and countermeasures](08-operator-profile.md) ruled out a counter item. Candidates so far: a vision-cone gadget that shows guards' cones for a while (an idea from the stealth playtest; maybe something Aigis can counter), a loud weapon (deferred here from the combat verbs ticket), healing (rations), and distraction tools. "None" is a valid answer. For each item: what it does, how it's limited, and whether a Habit or Countermeasure reads it.

## Answer

Settled in a grilling session (2026-10-09). New glossary terms: **Scanner**, **Magazine**.

**Two items**, cycled on HUD E's item card (bindings go to the Input fog). Both are available from Mission 1 and taught in the Harbour tutorial through Metis's Codec calls.

- **Scanner:** shows the front and peripheral cones of guards and cameras within 30 m, through walls, as translucent white/grey ground decals (red for guards in alert). No patrol routes, no meter. 3 charges per Mission, ~10 s each, refilled at the resupply crate; the card shows the charges left. Usable at any time, including while carrying a body. It comes from the stealth playtest's idea: the cones stay off by default and the player calls them up when needed.
- **Magazine:** hold to show an arc, release to throw (~15 m). It lands as a knock (10 m, no wall occlusion): guards go to suspicion and investigate the landing point. Hitting a guard does nothing (no MGSV stun). 4 per Mission, refilled at the crate. Can't be thrown while carrying a body. It adds no new guard behaviour; it's a knock somewhere else.

**Profile:** items never feed it directly. They count only through what they lead to (a Magazine that pulls a guard into a choke scores Takedowns). The Habits stay at six; no Countermeasure reads an item.

**Ruled out**

- Rations: health already regenerates after 5 s without damage.
- A loud weapon: the rifle with a broken suppressor is the loud option, and Combat already reads it.
- A seventh Habit or a Countermeasure aimed at items.

**Cut line:** the Magazine is the first item cut if the schedule slips; the free knock covers most of what it does.
