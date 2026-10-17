# Harbour and onboarding diagram

Type: prototype
Status: resolved
Blocked by: 01, 02, 03

## Question

What should the Harbour look like? The answer is a top-down diagram that shows:

- **Outline:** the Area's outline (coastline and dock).
- **Onboarding stretch:** each verb introduced in order: crouch under cover, a lone guard to choke, a body to hide, a check-in to eavesdrop on, a radio spoof.
- **Main yard:** guard posts and their loops with idle behaviours, sight lines, low and full cover, Crawlspaces and Ladders.
- **Objectives:** the 3 Approaches to each one.
- **Placements:** where each Countermeasure spot goes, plus the crate, the safe room, the extraction point, and where the freight lift to the Core sits.
- **Reference:** the MGS location it draws on.

The diagram must pass the Approach rule before this ticket resolves.

## Prototype

`.scratch/area-redesign/prototypes/harbour-diagram.html` (on the branch only): three Harbour layouts, switch with `?variant=A|B|C` or ← →. A Quay strip (MGS1 Dock), B Tanker berth (MGS2 Tanker deck), C Basin (a U around the water). Each one passes the Approach rule for the manifests and the radio log. The full prototype is on the `prototype/harbour-diagram` branch (`git show prototype/harbour-diagram:.scratch/area-redesign/prototypes/harbour-diagram.html > harbour-diagram.html`). Its variant B data is the reference layout for the greybox.

## Answer

**Variant B, Tanker berth.** It's the hardest of the three to build, but it's the best one. A and C are rejected.

- **Reference:** the MGS2 Tanker deck for the opening and the MGS1 Dock for the yard.
- **Outline:**
  - The land fills the west and centre. The cliff runs along the west edge, and the north edge is a fence with the road gap.
  - The sea lies to the east and south.
  - A freighter is moored along the east side, about 12 × 56 m, bow north and bridge aft. A gangway at its middle crosses to the quay, and the stern rests against a pier.
  - A south pier runs out into the water, with the Extraction point at its tip.
- **Onboarding (Mission 1, on the deck, bow to stern):**
  1. Crouch behind the starboard hatches past a posted look-out facing the bow.
  2. Choke a port-side guard walking away from you.
  3. Hide the body in the gap between a container and the rail, out of the gangway post's sweep up the deck.
  4. Eavesdrop on a chatting pair taking a smoke break behind the bridge, from the starboard passage, with the bridge corner hiding you.
  5. Spoof the gangway's scanning post ("go check the Dock") to cross.

  Veterans can skip the gangway by dropping off the stern and crawling under the pier.
- **Yard, layered east to west:**
  - Quay: a crane with a Ladder and a vantage at the top, and the resupply crate at the gangway foot.
  - Containers and Warehouse B: Warehouse B is raised, with a Crawlspace under it and a Ladder to its roof.
  - Warehouse A: the manifests. It has an east door and a north door, and a Crawlspace under a container stack leads to it.
  - Gatehouse: the radio log, with the safe room in the back. It has a west door and a south door and sits by the north road.
  - The freight lift is set into the west cliff and faces east.
- **Guards:** 10 base. Of these, 5 are on deck: a posted guard, a loop, the chatting pair and the gangway scanning post. The other 5 are in the yard: a quay loop that holds facing the gangway foot, a scanning post on the manifests, a lane loop, the gatehouse post, the lift post, and a centre loop.
- **Countermeasure spots:**
  - Camera mounts on the Warehouse A north door, the stern-pier Crawlspace exit, the gatehouse west door and the lift mouth.
  - Sentries on the crane and on the Warehouse B roof.
  - PostExtra1's route looks into the Warehouse B and container-stack Crawlspaces.
  - PostExtra2 stands at the Warehouse A east door and PostExtra3 at the gatehouse south door.
  - Reinforcements come in at the north road.
  - Spoof places: Dock (south pier), Warehouse (Warehouse B), Gatehouse, LiftControl.
- **Approaches:** 3 per objective. The prototype's Approach-rule table spells each one out.
  - Manifests: stern pier, then the container Crawlspace, then the north door (sneak). Spoof the manifests guard to the Dock (deception). Gangway, crate, east door (loud).
  - Radio log: stern pier, then under Warehouse B, then the west door (sneak). Spoof the gatehouse post to Warehouse B (deception). Up the quay (loud).
- **Known weaknesses, carried forward:**
  - Reinforcements from the north road barely reach the manifests' loud Approach. Countermeasure tuning picks this up.
  - The ship adds the most geometry (hull, bridge, gangway). The Harbour greybox builds it from boxes.
- **Routed, not decided here:**
  - Whether 10 base guards is right: played and checked in the Harbour greybox.
  - Where the Core Mission starts (on the deck again, or at the road): the Core space diagram, which already owns the route through the fortified Harbour.
