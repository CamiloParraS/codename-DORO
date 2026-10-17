# Radio relay station diagram

Type: prototype
Status: resolved
Blocked by: 07

## Question

What should the Radio relay station look like? It gets the same diagram treatment as the Harbour:

- its own outline;
- the console Sabotage and the relay chief Target, each with 3 Approaches;
- a feel distinct from the Harbour;
- the lessons from the Harbour greybox applied;
- the MGS location it draws on.

## Prototype

`.scratch/area-redesign/prototypes/relay-station-diagram.html` on the `prototype/relay-station-diagram` branch (`git show prototype/relay-station-diagram:.scratch/area-redesign/prototypes/relay-station-diagram.html > d.html`). It holds three Relay station layouts and the chosen one (D). Switch between them with `?variant=A|B|C|D` or ← →:

- **A, Twin towers:** two towers joined by a catwalk over a gully.
- **B, Hillside terraces:** three terraces climbing to the mast, with the road coming in halfway up.
- **C, Ring compound:** a fenced hub round the mast, with three holes in the fence.

All three are anchored on the MGS1 Communications Tower. Each one's data is in `tools/build_harbour.gd`'s shape, so the winner ports straight to a generator. Two things are new in that shape: base heights on LAND and BUILDINGS, and a RAMPS list.

The page checks every Harbour greybox lesson that a machine can check:
- guards counted as spawned;
- no guard facing the start (cone plus line of sight, counting terrace edges and doorways);
- every terrace reachable;
- Crawlspaces 4–10 m long;
- no marker inside solid geometry;
- the Extraction beacon visible from the objectives;
- cut-off groups.

It also lists which standing guards see each Approach line. All three variants pass every check and the Approach rule.

## Answer

**B, Hillside terraces, with a short catwalk at the summit.** This is variant D in the prototype. Its data is the input for the build.

- **Shape:** B's three terraces climb to the mast:
  - the motor pool at 0 m;
  - the barracks terrace at 3 m;
  - the summit at 6 m.

  The road comes in halfway up. The east side (road and ramps) is the loud way, and the west side is the quiet way. Anchor: the climb of the MGS1 Communications Tower.
- **Catwalk:** A's crossing between the towers becomes one short crossing between two summit structures, a landmark rather than the Area's spine. It's 10 m long at 10 m high, from the mast to the office roof. The office was moved 6 m west to make room for it. Guards walk up to it by a stair on the office's south side. A Ladder at the mast end drops behind the console.
- **No Ladder as a refuge:** every raised place the Operative can reach is ground guards can walk to.
  - A scree path at the barracks terrace's west end replaces the summit Ladder. The west stays the quiet way up, and guards can follow up it.
  - The mast top has no Ladder. SentryMast still spawns there as a Countermeasure.
  - The west Ladder lands on a terrace that guards reach by the road ramp.

  The prototype checks this as lesson 9.
- **Two carry routes:** a carried chief can't go up a Ladder, so both routes are walked.
  - **West, up the scree:** about 60 m, open ground. B3's sweep crosses it.
  - **East, up the summit ramp:** about 95 m, past the pair and C1, with cover all the way.

  Where you drop him on his loop decides which one is nearer. The prototype checks this as lesson 10.
- **Escort spoofing stays as proposed:** the escort is an ordinary guard to the radio. Spoofing him away is the chief's deception Approach, a solution that works through deception rather than another way of staying unseen.
- **Build now, tune later:** build the geometry and the basic encounters now. Guard positions and difficulty stay provisional until the alert behaviour from [Guards and Ladders on alert](12-guards-and-ladders.md) is built in.

All three variants and D pass lessons 1–8. Only D passes lesson 9: A, B and C each have Ladder tops that guards can't walk to.

Graduated: [Relay station greybox](13-relay-station-greybox.md).
