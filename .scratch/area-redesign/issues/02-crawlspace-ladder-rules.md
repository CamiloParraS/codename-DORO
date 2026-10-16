# Crawlspace and Ladder rules

Type: grilling
Status: resolved
Blocked by:

## Question

How do Crawlspaces and Ladders work?

- **Crawlspace:**
  - What clearance does it need? The crouched capsule is 1.0 m tall.
  - Can guards see into one or hear through it?
  - Can the Operative carry a body through?
- **Ladder:**
  - How fast is the climb?
  - Can the Operative be seen or shot while climbing?
  - Do guards and sentries use Ladders, or only stand at the top?
  - Can the Operative carry a body up?
- **Both:** how do they appear in the shared Area script as optional spots, and how are they kept out of the guards' navmesh?

## Answer

**Crawlspace**
- Ceiling 1.2 m, opening 1.2 m wide, 4–10 m long. The crouched capsule (1.0 m) fits and the Operative can't stand inside. The Area's navmesh bake uses `agent_height` 1.8 m, so a Crawlspace is off the guards' navmesh with no extra work.
- Sight and hearing follow the existing rules: solid sides, so a guard sees in only through an open end along the tunnel axis, at the normal crouched-and-moving rate. Hearing stays radius-based and through walls.
- Guards never enter. They may **look in** from the mouth: face the tunnel axis for about 3 s, so the usual eye-to-chest ray sees what's inside. Two triggers, both existing behaviours: a search stop at a last-known point on a mouth, and a patrol stop at a mouth (one of the 2–3 new idle behaviours, see Guard idle behaviours). If a guard spots the Operative inside, normal alert rules apply. The tunnel is a dead end once seen at the entrance.
- No carrying: a small trigger at each mouth refuses entry while carrying ("put the body down").

**Ladder**
- Climb at 1.8 m/s (crouch speed), fixed.
- While climbing the Operative can be seen and shot by the normal rules, read as standing and walking. No firing, Takedown, Scanner or Countermeasure interaction on it. The Operative can drop off at any point.
- No carrying a body up (same trigger script as the Crawlspace).
- Guards never climb. Sentries are placed at the top (existing `sentry_high_point`). An alerted guard who loses the Operative at the top watches the Ladder base and doesn't climb. The top is a refuge but not a safe spot forever: the platform is small, the sentry's cone covers it and a guard at the base can shoot up.

**In the Area script**
- Plain scene geometry plus a small scripted trigger node, in `Crawlspaces` and `Ladders` containers. The shared Area script reads nothing new, so an Area without them still works.
- A Ladder has bottom and top Markers. Roofs stay unconnected navmesh islands and there is no navmesh link.
- Camera mounts and guard posts are placed to cover Crawlspace exits, with no code linking them.

**Aigis adaptation (option b)**
No new Habit. Crawlspace use feeds the existing Stealth personality's Habit, and its existing Countermeasures are placed to cover Crawlspace mouths: the extra patrol's route gets the look-in stop, and a camera mount sits on each exit. Whether Crawlspace use counts toward that Habit is left to Countermeasure tuning.

**Glossary:** Crawlspace now notes that a guard may look in from the mouth.
