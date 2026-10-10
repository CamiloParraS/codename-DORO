# Campaign plan

Type: grilling
Status: resolved
Blocked by: 08

## Question

What are the 3 Areas and the 3+ Missions? Objectives per Mission (infiltrate, extract intel, sabotage, eliminate/avoid), in which order the countermeasures can show up, what the core finale Mission is like, and which extra Missions (revisits) are candidates if there's time. Also which preset profiles the debug/free mode offers.

## Comments

- 2026-10-09 (from Combat verbs and Lethality): if Eliminate Missions exist, the target can be killed (completes on the spot, counts 3 toward Lethality) or neutralized and carried to an extraction point. No Mission may require a death.
- 2026-10-09 (from Operator profile and countermeasures): the Habit level cap rises by Mission (Mission 1: 0, Mission 2: 1, Mission 3: 2, core: 3), so Mission 1 has no Countermeasures. Each Area needs an entry point for reinforcements (Combat L3), high points for overwatch sentries (Stealth L3), and camera spots (Stealth L1). Preset profiles for debug mode are sets of Habit levels.
- 2026-10-09 (from Architecture of the five Voices): preset profiles are Habit levels **plus a Lethality ratio** (Lethality ÷ the most possible so far), so the presentation can show all three endings. The guards and targets in each Mission set that ratio's denominator. Deployment budget per Mission: 0 / 2 / 4 / 6 response levels.

## Answer

Settled in a grilling session (2026-10-09). New glossary terms: **Target**, **Extraction point**, **Core**, **Free mode**, **Preset**.

**Premise:** Palladion is a private security contractor with a remote coastal compound defended by Aigis. Metis is hired to find out what Aigis is. (How much story gets told belongs to Narrative delivery.)

**Areas** (simple PSone-era geometry: containers, huts, fences, towers)

1. **Harbour / supply depot**: the way in; the Core lies underneath, behind a freight lift.
2. **Radio relay station** on a ridge: the Spoofing theme, with natural high points.
3. **Research annex**: where Aigis's people work.

Each Area is about **80×80 m** playable, with **8–10 base guards** (Combat L2 adds 2, reinforcements 2 more), 2–3 distinct approaches, 1 road entry for reinforcements, 2+ high points for sentries, 4 camera mounts, 1 resupply crate, 1 Extraction point, and 1 checkpoint per objective step. **Every Countermeasure spot is built into all three Areas**, even though the Harbour only uses them in the Core Mission.

**Objective types:** Extract intel, Sabotage, Eliminate. Infiltration is part of every Mission; Rescue was dropped because it repeats Eliminate's carry.

**Campaign:** strictly linear (briefing → Mission → post-Mission screen → next), with no replays of completed Missions. Each Mission takes about 10–15 minutes on a first clear.

| # | Area | Objectives | Target | Cap / budget |
|---|---|---|---|---|
| 1 | Harbour | Extract intel (manifests that point to the relay). Also the tutorial. The locked freight lift is visible, foreshadowing the Core. | none | 0 / 0 |
| 2 | Radio relay station | Sabotage the relay | Relay chief | 1 / 2 |
| 3 | Research annex | Extract intel (the Core's location, under the Harbour) | Lead researcher (main objective) | 2 / 4 |
| Core | Harbour, fortified, then the freight lift, a short corridor and the Core room (2–3 guards) | Reach the Core | Palladion's security director, beside Aigis | 3 / 6 |

- **Targets are always required** (from Mission 2 on): kill, or Neutralize and carry to the Extraction point. An optional Target would let a player skip the Lethality choice entirely.
- **Target behaviour:** the guard model with a distinct silhouette (cap or beret plus a different colour), the same behaviour tree, a fixed route between 2–3 points, and one escorting guard. Targets are unarmed. On an alert they run to a safe room and stay there until evasion ends. Tranq, takedown and rifle rules are the same as for guards. A carried Target counts as a Down guard if spotted.
- **Sabotage:** hold to interact for 5 s at the relay console, which exposes the Operative. About 30 s after it's done, HQ radios "Relay's offline. All units, sweep the station." and every guard goes into suspicion and searches. There's no alert and no loud event, so Sabotage doesn't feed Combat by itself.
- **Mission 1 is the tutorial**, with no separate training area. Contextual prompts appear on first use (crouch, takedown, carry, tranq, eavesdrop for a Voiceprint, radio menu), with one Metis radio line each. Spoofing is taught at a pre-placed eavesdrop spot, because Spoofing L1 can deploy as early as Mission 2.
- **The Core Mission** uses the same insertion point as Mission 1, so the player walks a familiar route and sees what changed: the same Area with no Countermeasures and then with the most, which is the strongest visible-adaptation moment in the game. The **Core room is the Extraction point**, so killing or choking the director completes the objective with no carry. The campaign's last Lethality decision, weighing 3, happens beside Aigis just before the ending is decided. After it, the Operative interacts with the Core terminal and the ending plays.

**Order of Countermeasures:** follows from the cap and budget already set. Mission 1 has none, Mission 2 shows only L1 steps (the pinned Habit plus one), Mission 3 up to L2, and the Core up to L3.

**Lethality denominator:** the guards **actually spawned** in each completed Mission (Countermeasure extras and reinforcements included), plus 3 per Target. Every kill then has a unit in the denominator and the ratio stays ≤ 1.0. Base counts only matter for Presets.

**Free mode Presets** (Habit levels plus a Lethality ratio; any Mission; the cap still applies by Mission index, so "Ghost on Mission 2" shows only L1 steps; nothing touches the campaign's Profile):

| Preset | Habit levels | Ratio | Dominant Voice | Shows |
|---|---|---|---|---|
| Clean slate | all 0 | undefined | Pallas | the baseline |
| Ghost | Stealth 3, Takedowns 2, Downs 2 | 0.0 | Pallas | cameras, sentries, pairs, HQ polls |
| Trickster | Spoofing 3, Stealth 1, Headshots 2 | 0.25 | Nike | callbacks, single-use Voiceprints, helmets |
| Butcher | Combat 3, Headshots 3, Takedowns 1 | 0.6 | Gorgo | vests, more guards, reinforcements, full helmets |
| Custom | a slider per Habit (0–3) | slider (0–1) | from the ratio | anything |

**Extra Missions (only if there's time, and the first thing cut):**

- **Relay station revisit:** a new objective (extract intel from the repaired relay) and a different insertion point. It goes between Mission 3 and the Core, at cap 2 and budget 4, so the Core keeps cap 3 and budget 6. It would also bring in the **favourite flank** Habit (Aigis guards the approach used last time), only if it gets built.
- **Annex revisit:** the lower-priority candidate.
- Whether either gets built is decided in the Schedule and cut line fog.

**Handed to other tickets**

- Narrative delivery: premise; intel contents (manifests → relay; Core location → Harbour); HQ's relay-offline line; tutorial prompts plus one Metis line each; the three Targets as characters (relay chief, lead researcher, security director); the ending plays at the Core terminal, right after the director choice.
- AI write-up: the four fixed Presets give repeatable deployment tables; the Harbour at Mission 1 versus the Core is the before/after screenshot pair.

- 2026-10-09 (from [Schedule and cut line](16-schedule-and-cut-line.md)): both extra Missions (the Relay station and Annex revisits, plus the favourite-flank Habit) were ruled out of scope. The campaign is Mission 1–3 + the Core, at caps 0/1/2/3.
