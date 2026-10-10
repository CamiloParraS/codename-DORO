# Architecture of the five Voices

Type: grilling
Status: resolved
Blocked by: 08

## Question

How do the five Voices (Promachos, Nike, Pallas, Gorgo, Glaukopis) work as utility considerations? Which decisions does Aigis make (between Missions: which countermeasures to deploy; during a Mission: how to respond to an alert or a Spoofed transmission?), how does each Voice score the options, how do their weights shift with the profile and Lethality, and how does that same system resolve the ending (three branches)? What does the debug overlay show?

## Comments

- 2026-10-09 (from Combat verbs and Lethality): Lethality is a single weighted tally (guard 1, Eliminate target 3). The thresholds for the three endings are decided here. It is silent to the player, so the Voices' commentary is the only place it surfaces outside the debug overlay.
- 2026-10-09 (from Operator profile and countermeasures): Profile levels **unlock** Countermeasures; the Voices choose which ones to deploy each Mission. Decide here: the per-Mission deployment budget, and how the rule "the Operative's strongest Habit is always answered" fits the scoring. Also which Voice names the top 1–2 Habits in the briefing, and comments on lethal takedowns (Takedowns L3 makes the choke slow and noisy, which pushes toward the kill).
- 2026-10-09 (from Narrative delivery): the ending content follows the draft pitch, mapped onto these bands: **Pallas** shuts down (the region burns), **Nike** goes dormant, **Gorgo** shields itself and the shutdown fails ("you are not the exception"). The fortress becomes how Gorgo survives. The final debate comes after a scripted last Spoofed transmission at the Core terminal. Bands, weights and deployment are unchanged.

## Answer

Settled in a grilling session (2026-10-09). New glossary term: **Dominant Voice**; **Voice** widened to say it sponsors Countermeasures. ADR: [Aigis plans only between Missions](../../../docs/adr/0001-aigis-plans-only-between-missions.md).

**Scope: Aigis is a between-Missions utility AI**

- The Voices decide only between Missions: which Countermeasures to deploy, what the briefing says, and the ending.
- During a Mission, guards run the behaviour tree from the stealth prototype (LimboAI). The only Aigis logic in the field is Glaukopis's Spoofing judge, which is unaffected by Voice weights (Spoofing L1 sets its threshold).
- The write-up's story: a behaviour tree for guards, a utility AI for the commander, and profiling feeding the commander.

**Doctrines (from the pitch) and sponsorship**

Each Countermeasure step has one sponsor Voice.

| Voice | Doctrine | Sponsors |
|---|---|---|
| Promachos | fights in front: pre-emptive strike | Stealth L2 extra patrol, Combat L2 more guards, Combat L3 reinforcements |
| Gorgo | the shield-face: defence as the only value | Combat L1 vests, Headshots L1–L3 helmets, Stealth L3 overwatch sentries, Takedowns L2 pairs |
| Pallas | strategy, doubt, modelling contradiction; the profiler | Takedowns L1 turn more often, Downs L1 + L3 HQ polls |
| Glaukopis | owl-eyed: perception and truth-verification | Stealth L1 cameras, Spoofing L1–L3 |
| Nike | victory by any means | Downs L2 instant alert, Takedowns L3 noisy choke |

**Deployment (`plan_mission`)**

- **Budget** counted in response levels (how far up a Habit's unlocked ladder Aigis goes; steps deploy in order): Mission 1: 0, Mission 2: 2, Mission 3: 4, core: 6. Unspent budget is fine.
- **Pin:** before any scoring, the strongest Habit (highest level, ties to more points) gets its full unlocked response.
- **Greedy fill:** the candidates are each Habit's next unlocked step. Score = sponsor Voice weight × that Habit's Profile points. Take the highest, repeat until the budget is spent, and break ties in Habit-table order.
- **Deterministic:** the same Profile and Lethality always give the same deployment (presets, tests, honest debug).

**Weights, Lethality and the ending**

- **Lethality ratio** = Lethality ÷ the most Lethality possible so far (guards in completed Missions + 3 per target). Before Mission 1 it is undefined and the band is Pallas.
- **Bands:** below 0.10 Pallas, 0.10–0.40 Nike, above 0.40 Gorgo (tuned in the build). A ratio exactly on a threshold goes to the higher band.
- **Weights are a step:** the band's Voice is the **Dominant Voice** at weight 2.0; every other Voice is 1.0. Recomputed at each briefing.
- **Side effect, accepted:** Lethality leaks into deployment. A lethal campaign gets more Gorgo gear, a merciful one more Pallas procedure, while the number stays silent and apart from the Profile.
- **Ending (`resolve_ending`):** the Dominant Voice after the core Mission picks the branch:
  - **Pallas:** the Operative spared its people, Aigis can't model the contradiction, and it doubts its doctrine.
  - **Nike:** cold calculus; victory is all, and the Operative is an equal player.
  - **Gorgo:** Aigis falls back to pure defence and becomes a fortress that sacrifices everything to protect its people.

**Lines**

- **Briefing** (3–4 lines, text plus radio beeps): Pallas names the top 1–2 Habits; for each Habit answered, the sponsor of its highest deployed step hints at the answer; the Dominant Voice closes with a line about the Operative (the main channel for Lethality). When Takedowns L3 is deployed, Nike says the quiet part out loud ("Make the mercy expensive. Let's see what they choose."). Mission 1 gets only the closing line.
- **Post-Mission screen:** one line from the Dominant Voice under the Habit icon strip, chosen by band × whether this Mission's Lethality was 0 or above 0 (6 lines).
- **No Voice lines during a Mission:** guard chatter stays the only voice in the field.

**Debug**

- **F1 overlay**, toggled on any screen: the five Voice weights and the Dominant Voice; Lethality raw, ratio, band and projected ending; the deployment plan (budget, pinned Habit, each greedy pick with its candidates and scores). The briefing screen shows the plan table while the overlay is on.
- **Preset profiles** carry Habit levels plus a Lethality ratio, so the presentation can jump to any ending.

**Code**

- `ai/aigis.gd`, pure and node-free:
  - `plan_mission(profile, lethality, mission_index) -> {weights, dominant, budget, pinned, picks[{step, sponsor, score, candidates}], briefing_keys}`
  - `resolve_ending(lethality) -> band`
- `ai/glaukopis.gd` stays separate (in-Mission Spoofing judge).
- The scene and UI only read the results. Both modules get unit tests.

**Handed to other tickets**

- Campaign plan: presets carry a Lethality ratio as well as Habit levels; the guard and target counts per Mission set the ratio's denominator.
- Narrative delivery: briefing lines (Pallas naming each Habit, a sponsor hint per Countermeasure step, a Dominant Voice close per band, Nike's Takedowns L3 line), 6 post-Mission lines, and the three endings (Pallas / Nike / Gorgo). The "final debate among the Voices" can stage the Dominant Voice winning.
