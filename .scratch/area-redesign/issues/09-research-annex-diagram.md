# Research annex diagram

Type: prototype
Status: resolved
Blocked by: 07

## Question

What should the Research annex look like? Today it's a copy of the Relay station. It needs:

- its own outline and layout;
- the intel extraction and the lead researcher Target, each with 3 Approaches;
- a feel distinct from both other Areas, for example more of the play inside buildings, with tighter sight lines;
- the lessons from the Harbour greybox applied;
- the MGS location it draws on.

## Prototype

`.scratch/area-redesign/prototypes/research-annex-diagram.html` on the `prototype/research-annex-diagram` branch (`git show prototype/research-annex-diagram:.scratch/area-redesign/prototypes/research-annex-diagram.html > d.html`). Three layouts, switch with `?variant=A|B|C` or ← →, all anchored on MGS3 Graniny Gorki lab:

- **A, Main block:** one big lab with a 48 m corridor, rooms off it, a loading dock and a crawl under the back. Most of the play is indoors (4 of 10 guards).
- **B, Podium lab:** the campus on a 4 m podium. Stair west, freight ramp south, service Ladder north; two Crawlspaces; the Records room is the intel refuge. Extraction is a pad on the podium.
- **C, Cloister:** four wings round a courtyard, four corner passages, a vault for the files, a crawl under the south wing. Two towers.

Same data shape as the Relay station prototype, plus Wall* interior walls. Machine checks are the Harbour and Relay lessons plus two new ones: 11 (feel: guards indoors, building cover, doorways) and 12 (Approach and carry lines must not cross walls, cover or Crawlspace sides). All three pass 1-6, 8-12. Check 7 warns on all three: indoor objectives can't see the Extraction beacon, only their nearest door can. Each has 10 base guards plus an escort, 3 Approaches to each objective (sneak, deception, loud) and 2 carry routes for the researcher.

Viewed in a browser before choosing: all three render with no console errors.

## Answer

**A, Main block.** Its data is the input for the build.

- **Shape:** one big lab on a fenced plot, ground level throughout, rimmed on the east by a quarry pit (railed, no way down). Inside: a 48 m corridor with an office, the lab and the vault on the north side, the lobby, the Archive and the loading hall on the south. Outside: a small south yard with a stilted pump house, the dock on the east, and a thin north strip up to the gate. Two towers (gate and yard) are sentry decks reached by ramps. Anchor: MGS3 Graniny Gorki lab, read as one building.
- **Why A:** it's the only variant that differs clearly from both other Areas. The Relay station's identity is height, and B's podium repeats it. The Harbour's identity is the open yard, and C still plays round a ring outdoors. A puts the play indoors: 4 of 10 base guards inside, encounters at doorways, corners and rooms, and cones walled in. It's also the only variant with no cut-off guard groups.
- **Objective placement in Mission 3:**
  - the files are in the Archive, which has a back door reached by the pump house Crawlspace;
  - the lead researcher walks a loop between the lab and the office with one escort, and on alert he runs to the vault at the corridor's east end;
  - Extraction is in the north-east corner.
- **Approaches:** both objectives have sneak, deception and loud, each closed by a Countermeasure:
  - **files, sneak:** the pump house crawl to the Archive's back door;
  - **files, deception:** record the pair and spoof the lobby guard out;
  - **files, loud:** the crate, then the dock and the corridor;
  - **researcher, sneak:** the west lane and the north strip to the lab's north door;
  - **researcher, deception:** spoof the escort away;
  - **researcher, loud:** in by the dock, where he runs past you to the vault.

  The carry routes are 44 m along the open north strip and 58 m by the corridor and dock.
- **Guards:** 10 base guards on posts (the chatting pair counts as 2), plus the escort and the researcher. The Area has no Ladders, so [Guards and Ladders on alert](12-guards-and-ladders.md) doesn't touch it.
- **Interior walls** are SOLID boxes named `Wall*` with 2 m doorway gaps, so they fit the existing generator data shape.
- **Known weak points, accepted for now; the greybox playtest judges them:**
  - the 48 m corridor is one long sight line, and two of the three Approaches to the files end in it;
  - outside there's little cover;
  - both objectives are indoors, so the Extraction beacon is only visible from their nearest door (check 7 warns). The light column added in the [Harbour greybox](07-harbour-greybox.md) is meant to cover this.

A passes lessons 1–6 and 8–12. Lesson 7 is the warning above.

Graduated: [Research annex greybox](14-research-annex-greybox.md).
