# Implementation Decisions: Pure module 1: guard alert state machine

Interface shape from the prototype: `tick(delta, seen_rate, seen_pos, why, at_target)`, `hear(...)`, `radio(...)`; each returns a reason string for the debug overlay. States: patrol → suspicion → alert → evasion → patrol.

- Meter at 0.35 = suspicion (shows "?", a 1 s turn-and-look beat, then investigate, then a 5 s look-around). Full meter = alert ("!", radio call alerts every guard). Drains 0.25/s. Alert is lost after 3 s unseen. Evasion searches the last known position for 12 s; seeing the Operative there means alert again.
- Fill rate (computed by the scene, passed in as `seen_rate`): front cone 30° half-angle × 16 m, plus a peripheral cone 60° × 6 m at half rate. Line of sight is a ray to the chest. Multipliers: crouched ×0.5; still ×0.6, walking ×1, running ×1.5; closer than 3 m ×4; faster with less distance. A carried body makes the Operative count as standing and walking.
- Hearing: running footsteps 6 m, knock and Magazine landing 10 m, loud shot 40 m, noisy choke (Takedowns L3) 6 m. No wall occlusion. Noise means suspicion at the source, never alert.
- Down guard seen (same meter): suspicion → walk over and check → radio an alert if dead, or wake them if Neutralized (the woken guard joins in suspicion and remembers nothing). Downs L2 replaces the check with an instant alert.
- Security cameras use the same meter (front cone only); a full meter is a radio alert with no suspicion step.
