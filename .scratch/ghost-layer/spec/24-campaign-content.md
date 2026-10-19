# Implementation Decisions: Campaign content

| # | Area | Objectives | Target | Cap / budget |
|---|---|---|---|---|
| 1 | Harbour | Extract intel (manifests → relay). Tutorial. Locked freight lift visible. | none | 0 / 0 |
| 2 | Radio relay station | Sabotage the relay | Relay chief | 1 / 2 |
| 3 | Research annex | Extract intel (the Core is under the Harbour) | Lead researcher | 2 / 4 |
| Core | Harbour fortified → freight lift → corridor → Core room (2–3 guards) | Reach the Core | Security director, beside Aigis | 3 / 6 |

- Each Area is ~80×80 m with 8–10 base guards, 2–3 approaches, 1 road entry, 2+ sentry high points, 4 camera mounts, 1 resupply crate, 1 Extraction point, 1 Checkpoint per objective step, and four named places for spoof orders. **Every Countermeasure spot is built into all three Areas.**
- A Mission is data: an Area, objective steps, Targets, and the Mission index (which sets the cap and budget). The Area scene places Countermeasures from the plan.
- Targets are always required: killed on the spot (the objective completes), or Neutralized and carried to the Extraction point. They use the guard model with a distinct silhouette (a cap or beret and a different colour), the same tree, a fixed 2–3-point route and one escort. They are unarmed and run to a safe room on alert until evasion ends. A carried Target is a Down guard if spotted.
- Sabotage: hold to interact for 5 s, which exposes the Operative. About 30 s later HQ radios "Relay's offline. All units, sweep the station." and every guard goes to suspicion. No alert.
- The Core room is the Extraction point. After the director, the Operative uses the terminal and the finale plays.
- Linear: Briefing → Codec call → Mission → post-Mission screen → next. No replays. Each Mission takes ~10–15 min on a first clear.

**Presets** (Free mode; any Mission; the cap still applies by Mission index):

| Preset | Habit levels | Ratio | Dominant Voice |
|---|---|---|---|
| Clean slate | all 0 | undefined | Pallas |
| Ghost | Stealth 3, Takedowns 2, Downs 2 | 0.0 | Pallas |
| Trickster | Spoofing 3, Stealth 1, Headshots 2 | 0.25 | Nike |
| Butcher | Combat 3, Headshots 3, Takedowns 1 | 0.6 | Gorgo |
| Custom | a slider per Habit (0–3) | slider (0–1) | from the ratio |
