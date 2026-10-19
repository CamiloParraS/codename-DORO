# 32: Finale

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The campaign ends: a scripted last Spoofed transmission feeds Aigis fabricated memories, the Voices hold the Final debate, the Dominant Voice's ending plays, and the Epilogue reveals that Metis profits from the war.

**Blocked by:** 31, 28

**Status:** ready-for-agent

- [x] The radial opens with the single order "Transmit memories" in slowed time; it cannot fail
- [x] Final debate: full-screen text, each Voice with a name and glyph, one line per Voice per band, Glaukopis's line varying with Spoofing level 0–3, the Dominant Voice last
- [x] Ending (resolve_ending): Pallas shutdown / Nike dormant / Gorgo failed shutdown, 4–6 lines, the last one addressed to the Operative
- [x] Epilogue: a paused Codec call per ending, handler + analyst
- [ ] PSX-processed stock stills with slow pan/zoom in this sequence only, each credited
- [x] Reachable directly from Free mode for any Preset

## Comments

- 2026-10-19 (review): the only open box is real stock stills; status stays `ready-for-agent` for that.
- 2026-10-19 (implementation): `ai/finale.gd` (node-free: order, debate by band + Spoofing level, ending, Epilogue, stills) plays in `ui/finale/finale.gd` (group `finale`; `core.gd` adds it, Free mode has a FINALE button for the picked Preset/Custom record). Lines in `text/lines.csv` (`finale.*`) are placeholders for ticket 36. Tested in `tests/test_finale.gd`. Left open: the stills box is unticked because the stills are stand-in CC0 textures (stone/metal/brick), not real stock stills; pick them, set `Finale.STILLS`, credit in CREDITS.md. Not played in a window: radial look, still pan/zoom feel, Core-to-finale handoff in the live scene, PSX banding on the stills.
