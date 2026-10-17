# Guards and Ladders on alert

Type: grilling
Status: open
Blocked by: 

## Question

How do guards deal with an Operative on a Ladder's roof, so a loud player isn't stuck up there?

The [Crawlspace and Ladder rules](02-crawlspace-ladder-rules.md) say guards never climb: an alerted guard who loses the Operative at the top watches the Ladder base. The [Harbour greybox](07-harbour-greybox.md) built that rule (`Guard.goal()` / `ladder_foot()`). In the loud playtest, every guard in the Area came and waited at the foot of Warehouse B's Ladder. That leaves two outcomes, and both play badly: the player waits on the roof until the guards give up, or they search for better angles to shoot from.

Options:
- **Guards climb.** This matches MGS, and the user leans this way. It's the most work: a guard climbing state, navmesh links over each Ladder (`NavigationLink3D` from Bottom to Top), guard vision and shooting while climbing, and a climbing guard's vulnerability (a free shot or a kick off the top?).
- **Few watch, the rest flank.** 1–2 guards hold the foot. The others move to navmesh points with a line of sight to the roof and shoot. This needs a "find a firing spot" search: sample navmesh points around last_known, then raycast.
- **Watchers give up.** The foot watchers leave after the search time. That's the cheapest option but the weakest, and it's roughly the stalemate the playtest hit.
- **Mixes:** for example, the first guard climbs, a second holds the foot, and the rest flank.

Also decide:
- What does the Operative get against the guard at the foot (tranq from above, a thrown distraction, a second way down)?
- ~~Does this change the Ladder vantage principle for the Relay station's Comm Tower?~~ Settled by the [Radio relay station diagram](08-relay-station-diagram.md): every Relay station Ladder lands on ground guards can walk to (the catwalk by the office stair, the terraces by ramp and scree). There, guards can already follow by walking. This ticket decides what they do when they get there. Its outcome gates the Relay station's final guard positions and difficulty, so it should come out as a build.
