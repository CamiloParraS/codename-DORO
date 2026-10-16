# MGS level-design patterns for our Areas

Resolves [issue 01](../issues/01-mgs-pattern-research.md). Researched 2026-10-16.

## Source quality (read first)

Developer commentary on MGS layouts is thin. I found no GDC talk, and the MGS wiki (Fandom) blocked fetching. Each pattern is labelled:

- **[S]** backed by a cited source (below).
- **[G]** a design inference from how the games play. Nothing cited backs it, so verify it against footage before it goes in a ticket.

The location pairings and layouts are mostly [G]. The principles are mostly [S].

### Sources

1. Justin Reeve, ["Prospect and Refuge"](https://gamedeveloper.com/design/prospect-and-refuge), Game Developer, 2018. A level-design analysis of MGSV.
2. [MGSV level designer Jordan Amaro, Eurogamer interview, summarised by Metal Gear Informer](https://www.metalgearinformer.com/mgsv-level-designer-jordan-amaro-kojima-wants-you-to-feel-close-to-snake/). Developer interview.
3. [Wikipedia, MGS V: Ground Zeroes](https://en.wikipedia.org/wiki/Metal_Gear_Solid_V:_Ground_Zeroes). Cites Kojima's "one rail from A to B" quote.
4. [Wikipedia, MGS V: The Phantom Pain](https://en.wikipedia.org/wiki/Metal_Gear_Solid_V:_The_Phantom_Pain). Covers the stealth-first default, the four-ways mission video, enemies adapting to habits, and watching patrols over time.
5. [Wikipedia, Metal Gear Solid (1998)](https://en.wikipedia.org/wiki/Metal_Gear_Solid_(video_game)). Covers Soliton radar and vision cones, crawling under objects, vent entry, and Kojima's LEGO prototyping for camera views.
6. [FandomWire on Kojima's LEGO model](https://fandomwire.com/hideo-kojimas-designing-levels-in-metal-gear-solid/). Secondhand: a tweeted documentary clip with no named source. The LEGO claim is also in source 5.
7. [Wikipedia, MGS2](https://en.wikipedia.org/wiki/Metal_Gear_Solid_2:_Sons_of_Liberty). Covers squad AI, hanging off walkways to pass guards, and the Tanker/Big Shell split. It also records Kojima's 1999 design doc, which called for "vertical tension" in multi-level environments.
8. [Wikipedia, MGS3](https://en.wikipedia.org/wiki/Metal_Gear_Solid_3:_Snake_Eater). Snake starts miles from the base and works inward. Kojima also scaled back The End's fight after playtests found too many hiding spots.
9. [Complex, "Ground Zeroes deconstructed"](https://www.complex.com/pop-culture/a/steve-haske/ground-zeroes-deconstructed-feature). Camp Omega is compact but dense, with several avenues in. Guards react to noise by degree.
10. [GameRevolution on MGSV outposts](https://www.gamerevolution.com/features/11745-metal-gear-solid-v-the-phantom-pain-has-the-best-open-world). Each outpost "reveals possibilities" on arrival, and the game rarely says no to a creative plan.
11. [Michael Cook, "The Saturday Paper: Metal Gear Science"](https://www.gamedeveloper.com/design/the-saturday-paper-metal-gear-science). Research (Tremblay et al.) says stealth layouts must be judged over time: a spot safe at the start becomes unsafe as patrols move.
12. [Slant review of Ground Zeroes](https://www.slantmagazine.com/games/metal-gear-solid-v-ground-zeroes), read only through a search summary. It mentions perimeter towers with searchlights and AA guns on the helipads. Low weight.

## Cross-cutting principles (sourced)

- **No single rail.** Kojima set Ground Zeroes and MGSV against earlier games that "set [the player] on one rail to get from point A to point B" [3, 4]. This is our 3-Approach rule.
- **Build the space so no route is obvious.** Amaro's team assembles assets "in an organic way" so the player must observe and choose. They ask which route a first-time player takes and which one an expert takes [2]. In practice: author two entrances per objective, one obvious and one learned.
- **Prospect and refuge** [1]. Open ground is tense and cover is a rest. Refuge spots double as vantage points where you watch guards. Objectives often sit in refuge, and density varies by site. Vary exposure per zone.
- **Vantage points cut both ways.** Towers spot a careless sprinter [2]. The same high ground is where the player scouts [1].
- **Recon over HUD.** Binoculars and long waits let the player learn patrols [3, 4]. Time matters: safe cells change as patrols move [11]. This is a case for long loops and out-of-phase pairs. Our Scanner already stands in for the radar.
- **Compact and dense beats big.** Camp Omega is small but dense, with many avenues [9, 12]. That suits our 80x80 m budget.
- **Playtest for hiding spots.** Kojima cut The End's fight down after finding too many hiding spots [8]. Check each Area for a spot that is safe forever.
- **Previs in cheap blocks.** MGS1 was laid out in LEGO, including camera views [5, 6]. This fits our top-down diagram step.

## Harbour (Mission 1 and the tutorial)

**Mood anchor:** MGS1 Dock [G], with the MGS2 Tanker deck as the tutorial template. Kojima's MGS2 note on tutorials is useful: a veteran needs less hand-holding, so teach through the space [7].

| # | Pattern | How it translates | Guard placement |
|---|---|---|---|
| 1 | **Guided opening: a linear teaching stretch with one verb per beat** [G] | A shoreline strip from the drop-off to the main yard. Beats in order: crouch behind low cover, a lone guard to Takedown, carry past a gap, a Crawlspace under a raised pallet or between containers, then the yard opens up. The Ladder and Scanner come after. | One lone guard per beat. They face away and the loops are short, so the player can't fail by accident. |
| 2 | **Layered perimeter** [G, supported by 3, 12] | The outer layer is the quay and fence line. The middle is the warehouses and containers. The inner is the lift pad. Each layer offers a different Approach. | Outer layer: 3-4 on long loops. Middle: 3-4 with overlapping cones. Inner: 2 posted at the lift. |
| 3 | **Vantage point via a Ladder** [1, 2] | A crane gantry or warehouse roof gives a view of the yard. Reaching it takes a Ladder, and the top is exposed to a sentry's sight line. | One guard with a sight line to the Ladder top, in a different phase from the yard loops. |
| 4 | **Crawlspace bypass** [5, G] | A gap under a raised warehouse floor or between container stacks skips the main yard to the lift. It is crouch-only and guards never go in. | None in the gap. Put a guard whose cone covers its exit, so the bypass costs timing. |
| 5 | **Deception spot with a reachable Voiceprint guard** [G] | A radio shack or guard hut beside the yard. A guard on a short, readable loop passes within reach for a Voiceprint capture. | The Voiceprint guard walks a loop that touches cover. Keep his partner out of sight lines to the capture spot. |

## Core (lift, corridor, Aigis room)

**Mood anchor:** MGS1's underground facility approach [G]: a lift into a sealed interior. This pairing is the weakest, and the exact room is unverified.

| # | Pattern | How it translates | Guard placement |
|---|---|---|---|
| 1 | **Chokepoint post** [G] | The short corridor is the only way to the room, so guards post at the end instead of patrolling. This works because the corridor is narrow. | 1-2 static guards at the far end. Their cones cover the whole corridor. |
| 2 | **Arrival beat** [G] | The Operative leaves the lift into a hold-and-observe moment. Nobody sees you for a few seconds, but you see them, which is prospect. | Guard positions visible from the lift. None at the door. |
| 3 | **Layered final room** [G, 1] | A raised walkway or gantry around the Aigis room acts as refuge and vantage. The director's position is in the open middle. | 2-3 guards: one on the walkway, one near the director, one roaming. |
| 4 | **Crawlspace into the room** [5, G] | An under-floor gap bypasses the corridor chokepoint. | A guard covers the room-side exit only. |
| 5 | **Loud resupply at the lift** [G] | A resupply crate near the lift makes the direct assault a real option. | Back the loud route with the post guards. They are what you fight. |

## Radio relay station (Mission 2)

**Mood anchor:** MGS1 Communications Tower [G, 5 confirms the tower and the Hind D fight]. Mast, office, barracks and garage give the Area four distinct sub-zones.

| # | Pattern | How it translates | Guard placement |
|---|---|---|---|
| 1 | **Mast as vantage** [1, 2] | A Ladder up the mast gives the whole Area. A guard or sentry watching from its base discourages sprinting. | One sentry near the mast base. |
| 2 | **Sub-zones with different exposure** [1] | Garage and yard are open (prospect). Office and barracks are tighter (refuge). | 3-4 guards in the yard and garage, 2 in barracks, 1-2 in the office. |
| 3 | **Eavesdrop spot on a check-in route** [G, 4 for observing patrols] | A guard walks between barracks and garage and stops to radio in. Standing near the spot lets you hear the check-in. This supports Voiceprint capture. | The route has a stop of several seconds at a fixed point. |
| 4 | **Console reachable three ways** [3] | Sneak through the office side, deceive through a spoof spot, or go loud across the yard from the garage resupply. | Guards in the office are the stealth cost. A guard in the garage is the Voiceprint source. |
| 5 | **Crawlspace under a raised building** [5, G] | The barracks or office stands on stilts, so a crawl bypasses the yard. | Cone from the yard covers the entry. |

## Research annex (Mission 3)

**Mood anchor:** MGS3 Graniny Gorki Laboratory [G]. The little I could source is that it has a first floor and a split basement [secondhand guides], so use it as an atmosphere reference only.

| # | Pattern | How it translates | Guard placement |
|---|---|---|---|
| 1 | **Short sight lines through corridors and clutter** [G, 11] | Tighter lanes than the other Areas: staggered cover, corners and low walls. Guards see a short distance, so timing matters more than distance. | Many guards on short loops, spaced so cones barely overlap. |
| 2 | **Stacked levels via a Ladder** [7] | A mezzanine or roof gives a second layer. This borrows Kojima's "vertical tension" idea. | One guard watching below the Ladder. |
| 3 | **Crawlspace through the lab block** [5, G] | An under-floor run skips the main hall to the intel. | The exit sits in a guard's cone at a set phase. |
| 4 | **Target on a readable route** [G] | The lead researcher walks a loop between lab and office. Takedown and carry to the Extraction point need a clear exit path. | One bodyguard at most, so a carry stays feasible. |
| 5 | **Intel in refuge** [1] | The intel sits in a small enclosed room. The reward for reaching it is a breather. | Guard at the room entrance on a patrol, not a post. |

## Guard placement summary

- Short loops with deliberate gaps teach the player [11].
- Put out-of-phase pairs on any open ground and one post on each chokepoint.
- Each Approach has one guard acting as its toll. Sneak pays in timing, deception pays in a Voiceprint, loud pays in a fight.
- With 8-12 guards per Area, expect roughly 3 per sub-zone.
- The existing behaviours (loops of 2-3 points, standing still) cover all of this. The cheap new idle behaviours the map allows are a stop-and-radio pause and a lookout facing a fixed arc.

## Gaps

- No source describes MGS1 Dock, MGS2 Tanker, MGS3 Graniny Gorki or Groznyj Grad layouts. All pairings with those places are [G].
- Check footage of MGS1 Dock, MGS2 Tanker deck and MGS3 Graniny Gorki before the diagram ticket.
