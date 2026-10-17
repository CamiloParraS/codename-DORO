# Who answers an alert

Type: grilling
Status: open
Blocked by: 

## Question

When one guard raises an alert, which guards go to the spot and which stay where they are, so a body or a sighting far from the objective doesn't strip the objective bare?

In the [Research annex greybox](14-research-annex-greybox.md)'s fourth playtest (Countermeasures deployed), the Operative knocked out the first guard at the start. Another guard found him, and every guard in the Area went to check the body. That left the lab open, and the Operative carried the researcher out freely. A body dropped at the far end of the Area works as a lure that empties the objective, in every Area.

**Why it happens today:**
- `Guard._react()` radios every other guard whenever this guard's state change ends in ALERT.
- `GuardAlert.radio()` puts each of them in ALERT with `last_known` set to the radioed spot.
- In ALERT, a guard chases `goal()`, which is that spot. Nobody holds his post: the lab's indoor guards, the researcher's escort and the posts at the objectives all leave.
- **Downs L2** (`Deployment`: a guard who finds a Down guard alerts at once) makes the lure cheaper. Without it, finding a body only makes the finder suspicious, and he walks over alone.
- The same path runs when the Operative is spotted. Showing yourself at the far end is a lure too.

The [Harbour greybox](07-harbour-greybox.md)'s eighth lesson pulls the other way: isolated guard groups need a way to call for help. Whatever answers the alert must still bring help to a guard who's alone.

Options:
- **Radius:** only guards within some distance of the spot (or in earshot of the radio) go there. Everyone else goes to SUSPICION or a heightened alert at their own post. This is cheap: one distance check in `on_radio`.
- **The nearest few:** the 2–3 guards nearest the spot answer and the rest hold. This bounds how many leave regardless of where the alert is, but needs a sort over the guards per alert.
- **Anchored posts:** a post with `anchor` meta (the objective rooms, the escort, a vault or console guard) never leaves on a radioed alert. It turns to face the threat, or falls back to the objective. This is Area data, so each diagram decides which posts stay.
- **Mixes:** for example, the nearest few go, anchored posts hold, and the rest close in on the nearest objective.

Also decide:
- **The Target:** on alert today he runs to the SafeRoom. Should the escort go with him rather than answer the radio?
- **Combat L3:** reinforcements already come in from RoadEntry on alert. Does that become the "everyone comes" answer, with the base guards mostly holding?
- **The counter-play:** what does the Operative get against guards who now stay put (a lure that works on only the nearest guards, the escort spoof, Downs L2 becoming less of a threat)?
- **How it reads:** how does a player see that a guard is holding rather than searching (a line on the radio, a stance)?

This should come out as a build. Its outcome changes how hard every objective is, so it gates the final guard positions in [Countermeasure tuning](10-countermeasure-tuning.md).
