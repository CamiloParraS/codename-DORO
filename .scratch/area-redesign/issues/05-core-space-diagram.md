# Core space diagram

Type: prototype
Status: resolved
Blocked by: 04

## Question

What do the freight lift, the corridor and the Core room look like? The answer is a top-down diagram for the Core Mission covering:

- how the Operative reaches the lift through a fully fortified Harbour (cap 3, budget 6), including where the Core Mission starts: on the freighter deck again, or at the road. The Harbour is the Tanker berth layout, with the lift in the west cliff facing east;
- the lift ride;
- a short corridor;
- the Core room: 2–3 guards, the director as Target, the Aigis terminal, and the room serving as the extraction point;
- where the director's line triggers;
- the MGS location it draws on.

## Prototype

`.scratch/area-redesign/prototypes/core-space-diagram.html` (on the branch only): three Core Missions on the Tanker berth Harbour. Switch with `?variant=A|B|C` or ← →. Switch between Surface and Underground with 1 and 2, and light the real Core deployments with the Preset radios. A: bow start, straight hall. B: pier-tip start, gallery. C: road start, ring. The full prototype is on the `prototype/core-space-diagram` branch (`git show prototype/core-space-diagram:.scratch/area-redesign/prototypes/core-space-diagram.html > core-space-diagram.html`). The reference layout is a mix: variant A's surface data and variant B's underground data, with variant C's reinforcements.

## Answer

**A's start, B's room, C's reinforcements.**

- **Start:** the freighter's bow, Mission 1's insertion point. Spec story 87 stands as written. All 5 deck guards are back, carrying whatever Aigis gave them, and the Operative crosses the whole fortified Harbour.
- **Reaching the lift (3 Approaches, from variant A):**
  - Sneak: down the starboard rail, off the stern, under the pier, under the container stack, behind the low wall north of Warehouse A, then into the lift mouth while Y5 sweeps north.
  - Deception: spoof O5 off the gangway as in Mission 1, then spoof Y5 "go check the Gatehouse". Under single-use Voiceprints (Spoofing L3) these two spoofs need two different voices.
  - Loud: down the deck, take the crate at the gangway foot, follow the south lanes, then north into the lift. Reinforcements from the north road reach the lift in about 30 m, so Combat L3 bites here.
- **Lift ride:** reaching the lift opens its gate with the live call. The cage drops about 30 m in about 12 s, with an analyst line over the ride. Surface guards never ride it. A Checkpoint is taken on arrival at the bottom, so dying in the Core never replays the Harbour.
- **Alert across the lift:** if the Operative rides down under alert, HQ radios down and the Core guards start in suspicion (no alert). Arriving clean, they start calm.
- **Underground (variant B, the gallery), in the Harbour's frame under the yard, east of the lift:**
  - Lobby: the resupply crate.
  - Corridor: 11 m, east into the room's west door.
  - Core room: about 24 × 24 m, on two levels.
    - A walkway ring runs 4 m up, with two Ladders: one by the door, one in the SE corner.
    - Aigis is a 6 × 6 m column in the middle, with the terminal on its south face.
    - A cable trench Crawlspace (about 10 m) runs from the corridor wall to the room's SW corner, under the walkway, and bypasses the door post.
  - A vault off the east wall is the director's safe room.
- **Core guards:** 3, plus the director.
  - C1 is a floor post at the door, scanning up the corridor.
  - W1 walks the walkway ring and holds at the NE corner, looking down on the floor.
  - E1, the escort, circles the column. The director talks to him as he passes, which makes E1 recordable.
- **The director** is the Target. He stands at the terminal on the open floor and runs to the vault on alert. The whole room is the Extraction point, so killing or choking him completes the step with no carry. E at the terminal afterwards hands off to the finale.
- **The director's line** (one subtitle to Aigis) plays the first time the Operative is inside the room by any way in: the door, the trench or the walkway.
- **Countermeasures underground:** gear and orders always reach the Core (vests, helmets, turn-arounds, pairs, the noisy choke, HQ polls, the Spoofing ladder). Of the spot-based ones, **only Combat L3**: its 2 reinforcements per alert arrive by the lift, so the lift lobby is the Core's road entry. No Stealth spots go underground: no Core camera mount, trench post or walkway sentry.
- **Approaches to the director:**
  - Sneak: the trench, then wait for E1 to round the column, then choke the director at the terminal. Closed by the Takedowns ladder: turn-arounds (L1), pairs (L2), and at L3 the noisy choke with E1 passing within 6 m.
  - Deception: record W1's check-in from the corridor. Spoof E1 "go check LiftControl" in W1's voice, which sends E1 to the lift lobby. Take the Ladder up, go round the walkway behind W1 and down the SE Ladder to the lone director. Closed by the Spoofing ladder: the L2 callback goes to W1, who is in sight on the walkway.
  - Loud: crate, kill C1 at the door, fight W1 shooting down from the walkway, and catch the director before the vault. Closed by vests and helmets, plus reinforcements down the lift behind you (Combat L3).
- **MGS anchor:** MGS1's underground base, with the raised walkway round the final room that the research pairs with it.
- **Known weaknesses, carried forward:**
  - Ghost's Stealth ladder never reaches the Core room, so a pure-stealth player meets only the Takedowns and Downs answers there. This is accepted.
  - It is the longest Mission: the deck, then the yard, then the Core. Check the time in the greybox.
  - The gallery is the most build in a room used once: a walkway ring, 2 Ladders and a Crawlspace.
- **For the shared Area script:** a second reinforcement entry (the lift lobby) beside RoadEntry, used only by the Core Mission. Spoofing "go check LiftControl" from underground sends Core guards to the lift lobby.
