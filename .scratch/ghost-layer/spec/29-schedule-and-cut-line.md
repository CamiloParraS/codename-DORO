# Implementation Decisions: Schedule and cut line

| Week | Dates | Slice |
|---|---|---|
| W1 | 10-12→10-14 | Skeleton, LimboAI smoke test, PSX pass + camera rig lifted, player movement and verbs, Harbour greybox |
| W2 | 10-15→10-21 | Guard tree + perception + alert chain, Spoofing + Glaukopis, Profile + `plan_mission` with tests, 2–3 Countermeasures, F3 overlay, minimal Free mode. **Milestone 1** |
| W3 | 10-22→10-28 | Combat + Lethality, every Countermeasure step + HQ polls + Report in + reinforcements, Checkpoints, Mission flow, Mission 1 complete with tutorial, characters and animations |
| W4 | 10-29→11-04 | Relay station + Research annex (Sabotage, Targets), Scanner + Magazine, codec/subtitle player + Briefings + Profile chatter, CSV keys |
| W5 | 11-05→11-11 | Core Mission, finale, all English lines, menus + saves + settings, sounds. **Feature freeze 11-11** |
| W6 | 11-12→11-18 | Playthrough + balance, Spanish, generated tables, write-up, Windows export, rehearsal |

- **Milestone 1 is done when** the Harbour plays clean, and then Free mode with Butcher shows the same Harbour visibly fighting back, with the overlay showing why.
- **Cut list**, cut from the top: (1) the premise intro, (2) the Magazine, (3) video loops (stills only), (4) Epilogue → twist card, (5) chatter variants 2 → 1, (6) Target chatter, (7) save slots 3 → 1, (8) settings → sensitivity + language, (9) write-up → core sections + appendix, (10) Custom sliders, (11) Final debate → Dominant Voice alone, (12) the Scanner, (13) Spanish.
- **Slip rule:** at each week's end, if the build is more than one build day behind that week's slice, cut from the top until the plan fits. Never cut ahead of time.
- **Never-cut floor:** the 3 Missions + the Core finale, the six Habits with visible Countermeasures, Spoofing with Glaukopis, Lethality → Dominant Voice → three endings, Briefings that name the Habit, the post-Mission screen, the F3 overlay, Free mode with the four fixed Presets, and the Windows build. If the list runs dry, the Downs and Takedowns ladders shrink from 3 steps to 2 before anything on the floor goes.
