# Schedule and cut line

Type: grilling
Status: resolved
Blocked by: 14, 15

## Question

How do the 6 weeks (2026-10-08 to around 2026-11-19) split up into slices, with Milestone 1 a vertical slice at the end of week 2? What is in that vertical slice? What is the single ordered cut list if things slip? Do the extra Missions (Relay station revisit between Mission 3 and the Core, then Annex revisit) fit, and where would they go?

## Comments

- 2026-10-09 (from the map's fog): known cut candidates so far: the Magazine first ([Gadgets and items](12-gadgets-and-items.md)), the narrative word count's set cut order ([Narrative delivery](11-narrative-delivery.md)), and the write-up's fallback to sections 2, 5 and 8 ([AI write-up](13-ai-write-up.md)). The extra Missions candidates come from [Campaign plan](10-campaign-plan.md). Light and night was ruled out of scope.
- 2026-10-09 (from [Persistence](15-persistence.md)): build work to schedule: the slot file and picker, in-memory checkpoints with the guard-reset rule, and the pause and main menus. Saving to disk happens only between Missions, so none of it touches the world state.

## Answer

Settled in a grilling session (2026-10-09). No glossary changes.

**Calendar:** Thursday-to-Wednesday weeks from 2026-10-08. Build starts Mon 10-12 once planning ends. Plan for about 5 build days a week, with weekends as slack. Milestone 1 is a self-imposed gate on Wed 10-21. These dates can move.

**Prototype code:** leaf pieces are lifted whole (the PSX shader and post-process, the two-spring-arm camera rig, the detection arc widget). Anything that crosses systems (guard perception and state, Spoofing, alert propagation) is rewritten on LimboAI with `ai/` kept node-free, reusing the tuned numbers from the prototypes.

**Vertical slice (Milestone 1):** the Harbour greyboxed at full size (80×80 m, 8–10 guards on a LimboAI tree with the tested perception and alert timings). Player verbs: walk, crouch, shoulder camera, tranq pistol, choke takedown, carry. Spoofing (eavesdrop, radial, Glaukopis). Profile + `plan_mission` with tests, the F3 debug overlay, a bare post-Mission screen, 2–3 Countermeasures spawning in the world, minimal Free mode with Presets, and the PSX look on. Left out: the rifle and kill, the Magazine and Scanner, Targets, Sabotage, Codec calls and Briefings, menus, saves, Spanish, the other Areas. **Done when:** you play the Harbour clean, then Free mode with Butcher shows the same Harbour visibly fighting back, with the overlay showing why.

**Weekly slices**

| Week | Dates | Slice |
|---|---|---|
| W1 | 10-12→10-14 | Project skeleton, LimboAI smoke test on 4.7, PSX pass + camera rig lifted, player movement and verbs, Harbour greybox |
| W2 | 10-15→10-21 | Guard tree + perception + alert chain, Spoofing + Glaukopis, Profile + `plan_mission` with tests, 2–3 Countermeasures, F3 overlay, minimal Free mode. **Milestone 1** |
| W3 | 10-22→10-28 | Combat + Lethality (rifle, suppressor, kill, headshots, wake-up and Down checks), every Countermeasure step + HQ polls + Report in + reinforcements, checkpoints, Mission flow (objective → Extraction point → post-Mission screen → next), Mission 1 complete with tutorial prompts, Quaternius characters and animations |
| W4 | 10-29→11-04 | Relay station (Sabotage, relay chief, Target behaviour) + Research annex (lead researcher, intel), Scanner + Magazine, codec/subtitle player + Briefings + Profile chatter, CSV keys in place |
| W5 | 11-05→11-11 | Core Mission (fortified Harbour, lift, Core room, director), finale (last spoof, debate, endings, epilogue), all English lines, menus + 3 save slots + settings, sounds. **Feature freeze 11-11** |
| W6 | 11-12→11-18 | Full playthrough + balance, Spanish pass, generated deployment tables, write-up, Windows export, demo rehearsal. Nothing new enters. |

**Cut list** (cut from the top first; it merges the orders already set in Gadgets, Narrative and Write-up):

1. The optional premise intro
2. The Magazine
3. Stock footage video loops (stills with pan/zoom only)
4. Epilogue → the single twist card
5. Chatter variants from 2 to 1
6. Target chatter
7. Save slots from 3 to 1
8. Settings reduced to sensitivity + language
9. Write-up → sections 2, 5 and 8 plus the demo appendix
10. Free mode's Custom sliders (the four fixed Presets stay)
11. Final debate → the Dominant Voice alone
12. The Scanner
13. Spanish translation (ship English only; the write-up stays in Spanish)

**Slip rule:** at the end of each week, compare the build against that week's slice. If the week is more than one build day behind, cut from the top of the list until the remaining plan fits. Never cut ahead of time.

**Never-cut floor:** the 3 Missions + the Core finale, the six Habits with visible Countermeasures, Spoofing with Glaukopis, the Lethality → Dominant Voice → three endings chain, Briefings that name the Habit, the post-Mission screen, the F3 overlay, Free mode with the four fixed Presets, and the playable Windows build. If the list runs dry, the Countermeasure ladders on Downs and Takedowns shrink from 3 steps to 2 before anything on the floor goes.

**Extra Missions:** the Relay station revisit and the Annex revisit (with the favourite-flank Habit) are ruled **out of scope**. Each costs about 3–4 days, and a "build only if there's time" item keeps the Core's cap and budget in doubt. If the game is done early, polishing the existing Missions makes a better presentation.
