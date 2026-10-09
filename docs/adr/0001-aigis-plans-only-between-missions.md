# Aigis plans only between Missions

Aigis's five Voices are a utility AI that decides only between Missions: which Countermeasures to deploy, what the briefing says, and the ending. During a Mission, guards run their own behaviour tree, and the only Aigis logic in the field is Glaukopis's Spoofing judge. We chose this over Voice-driven alert responses (Promachos flanks, Pallas locks down chokepoints) for three reasons. Each response style would need its own Area work, which a solo six-week schedule can't afford. In-Mission styles would read as "the guards got harder" rather than visible adaptation. And it matches the Profile rule that nothing changes during a Mission.

## Consequences

- The planner (`ai/aigis.gd`) is pure, deterministic, and unit-testable from a Profile and a Lethality value. Preset profiles give the same deployment every time.
- Voice weights don't touch guard behaviour or Glaukopis's threshold. Adding in-Mission Voice behaviour later means feeding the weights into the guard behaviour tree, which is a new seam, not a tweak.
